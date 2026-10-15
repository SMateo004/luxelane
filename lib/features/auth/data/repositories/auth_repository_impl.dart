import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/config/env.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required fb.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth,
        _db = firestore,
        _googleOverride = googleSignIn;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn? _googleOverride;

  // Native Google account picker (Android/iOS). Created lazily: on web the
  // Firebase popup is used instead and this is never touched.
  late final GoogleSignIn _google = _googleOverride ??
      GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: AppConfig.googleIosClientId.isEmpty
            ? null
            : AppConfig.googleIosClientId,
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      );

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges().asyncMap(
        (fbUser) async {
          if (fbUser == null) return null;
          try {
            // Repara cuentas sin perfil (un registro que se cortó a medias).
            final user = await _ensureProfile(fbUser);
            if (!user.isActive) {
              await _auth.signOut();
              return null;
            }
            return user;
          } catch (_) {
            return null;
          }
        },
      );

  @override
  Stream<User?> watchCurrentUser(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        try {
          return User.fromJson({...doc.data()!, 'id': doc.id});
        } catch (_) {
          return null;
        }
      });

  /// Raw Firebase sign-in flag — no Firestore involved, so it never
  /// produces a false-negative that would accidentally sign the user out.
  @override
  Stream<bool> get isSignedIn => _auth.authStateChanges().map((u) => u != null);

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _ensureProfile(cred.user!);
      if (!user.isActive) {
        await _auth.signOut();
        return const Left(AuthFailure(suspendedMessage));
      }
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(authErrorMessage(e.code)));
    } catch (e) {
      return const Left(ServerFailure(_genericError));
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
    fb.UserCredential? cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = User(
        id: cred.user!.uid,
        email: email.trim(),
        phone: phone.trim(),
        displayName: displayName.trim(),
        // Las reglas solo aceptan altas propias como pasajero; los chóferes
        // y administradores los nombra un admin.
        role: UserRole.rider,
        createdAt: DateTime.now(),
        // Se verifica con el correo; las reglas rechazan un "true" falso.
        isVerified: false,
        isActive: true,
        fcmTokens: const [],
      );
      await _db.collection('users').doc(user.id).set(user.toJson());
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {/* no impide usar la app */}
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(authErrorMessage(e.code)));
    } catch (e) {
      // Si no se pudo guardar el perfil, se borra la cuenta recién creada
      // para que el usuario pueda volver a registrarse con el mismo correo.
      try {
        await cred?.user?.delete();
      } catch (_) {}
      return const Left(ServerFailure(
          'No pudimos crear tu cuenta. Revisa tu conexión e inténtalo de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final fb.UserCredential cred;
      if (kIsWeb) {
        final provider = fb.GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        cred = await _auth.signInWithPopup(provider);
      } else {
        final account = await _google.signIn();
        if (account == null) return const Left(AuthCancelledFailure());
        final tokens = await account.authentication;
        cred = await _auth.signInWithCredential(
          fb.GoogleAuthProvider.credential(
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
          ),
        );
      }
      final fbUser = cred.user;
      if (fbUser == null) return const Left(AuthFailure(_googleGenericError));
      final user = await _ensureProfile(fbUser);
      if (!user.isActive) {
        await _auth.signOut();
        return const Left(AuthFailure(suspendedMessage));
      }
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-cancelled') {
        return const Left(AuthCancelledFailure());
      }
      return Left(AuthFailure(_googleErrorMessage(e.code)));
    } on PlatformException catch (e) {
      // google_sign_in reports a closed picker as `sign_in_canceled`.
      if (e.code == GoogleSignIn.kSignInCanceledError) {
        return const Left(AuthCancelledFailure());
      }
      return Left(AuthFailure(e.code == GoogleSignIn.kNetworkError
          ? 'Sin conexión. Revisa tu internet e inténtalo de nuevo.'
          : _googleGenericError));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Returns the Firestore profile for [fbUser], creating it the first time
  /// someone signs in with Google. Existing profiles (e.g. an email/password
  /// account linked to the same address) are kept as they are.
  Future<User> _ensureProfile(fb.User fbUser) async {
    final ref = _db.collection('users').doc(fbUser.uid);
    final doc = await ref.get();
    if (doc.exists) return User.fromJson({'id': doc.id, ...doc.data()!});
    final email = (fbUser.email ?? '').toLowerCase();
    var name = (fbUser.displayName ?? '').trim();
    if (name.isEmpty) name = email.split('@').first;
    if (name.isEmpty) name = 'Pasajero';
    if (name.length > 80) name = name.substring(0, 80);
    final user = User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      phone: fbUser.phoneNumber ?? '',
      displayName: name,
      photoUrl: fbUser.photoURL,
      // Roles are granted server-side only (see firestore.rules).
      role: UserRole.rider,
      createdAt: DateTime.now(),
      // Google has already verified the address.
      isVerified: fbUser.emailVerified,
      isActive: true,
      fcmTokens: const [],
    );
    await ref.set(user.toJson());
    return user;
  }

  static const suspendedMessage =
      'Tu cuenta está suspendida. Contacta con soporte de Luxelane.';
  static const _genericError = 'Algo salió mal. Inténtalo de nuevo.';

  /// Errores de Firebase Auth en español y sin jerga técnica.
  static String authErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return suspendedMessage;
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo. Inicia sesión.';
      case 'weak-password':
        return 'La contraseña es muy débil: usa al menos 8 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
      case 'operation-not-allowed':
        return 'Este método de acceso no está habilitado.';
      case 'missing-email':
        return 'Escribe tu correo.';
      default:
        return _genericError;
    }
  }

  static const _googleGenericError =
      'No pudimos iniciar sesión con Google. Inténtalo de nuevo.';

  static String _googleErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Ya tienes una cuenta con este correo. Inicia sesión con tu '
            'contraseña.';
      case 'popup-blocked':
        return 'Tu navegador bloqueó la ventana de Google. Permite las '
            'ventanas emergentes e inténtalo de nuevo.';
      case 'unauthorized-domain':
        return 'Este dominio no está autorizado para iniciar sesión con '
            'Google.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con Google no está habilitado.';
      case 'user-disabled':
        return 'Esta cuenta está desactivada.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
      default:
        return _googleGenericError;
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Forget the chosen Google account so the picker shows next time.
      if (!kIsWeb) {
        try {
          if (await _google.isSignedIn()) await _google.signOut();
        } catch (_) {/* not signed in with Google */}
      }
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
      // Por privacidad no se revela si el correo tiene cuenta.
      if (e.code == 'user-not-found') return const Right(null);
      return Left(AuthFailure(authErrorMessage(e.code)));
    } catch (e) {
      return const Left(ServerFailure(_genericError));
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
