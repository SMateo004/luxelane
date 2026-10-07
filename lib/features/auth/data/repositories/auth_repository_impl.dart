import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/config/legal.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required fb.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _auth = firebaseAuth,
        _db = firestore;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges().asyncMap(
        (fbUser) async {
          if (fbUser == null) return null;
          try {
            final doc = await _db.collection('users').doc(fbUser.uid).get();
            if (!doc.exists) return null;
            return User.fromJson({'id': doc.id, ...doc.data()!});
          } catch (_) {
            return null;
          }
        },
      );

  /// Raw Firebase sign-in flag — no Firestore involved, so it never
  /// produces a false-negative that would accidentally sign the user out.
  @override
  Stream<bool> get isSignedIn =>
      _auth.authStateChanges().map((u) => u != null);

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      // Admin role is granted server-side only (scripts/promote_admin.mjs).
      return Right(User.fromJson({'id': doc.id, ...doc.data()!}));
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Login failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String phone,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = User(
        id: cred.user!.uid,
        email: email,
        phone: phone,
        displayName: displayName,
        // Self-registration can only create riders or drivers; Firestore
        // rules reject any other role.
        role: role == UserRole.driver ? UserRole.driver : UserRole.rider,
        createdAt: DateTime.now(),
        isVerified: false,
        isActive: true,
        fcmTokens: const [],
      );
      await _db.collection('users').doc(user.id).set({
        ...user.toJson(),
        // Registration requires accepting the terms (see RegisterPage).
        'termsAcceptedAt': Timestamp.now(),
        'termsVersion': LegalInfo.lastUpdated,
      });
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Registration failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPhoneVerification(String phone) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Reset failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return const Left(AuthFailure('Not authenticated'));
      final doc = await _db.collection('users').doc(fbUser.uid).get();
      if (!doc.exists) return const Left(NotFoundFailure('User not found'));
      return Right(User.fromJson({'id': doc.id, ...doc.data()!}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
