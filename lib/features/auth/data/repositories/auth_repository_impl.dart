import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
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
    FirebaseFunctions? functions,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth,
        _db = firestore,
        _functionsOverride = functions,
        _googleOverride = googleSignIn;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
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
            final doc = await _db.collection('users').doc(fbUser.uid).get();
            if (!doc.exists) return null;
            final user = User.fromJson({'id': doc.id, ...doc.data()!});
            // Una cuenta bloqueada por el admin pierde la sesión abierta.
            if (!user.isActive) {
              await _auth.signOut();
              throw const AuthFailure(kBlockedAccountMessage);
            }
            return user;
          } on AuthFailure {
            rethrow;
          } catch (_) {
            return null;
          }
        },
      );

  @override
  Stream<User?> watchUser(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((doc) =>
          doc.exists ? User.fromJson({'id': doc.id, ...doc.data()!}) : null);

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
        email: email,
        password: password,
      );
      // Si el registro creó la cuenta pero no llegó a guardar el perfil, se
      // crea ahora en vez de dejar la cuenta inservible.
      return _activeOrBlocked(await _ensureProfile(cred.user!));
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_emailErrorMessage(e.code)));
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
        // firestore.rules only accepts self-signups as `rider`; other roles
        // are granted by an admin.
        role: role,
        createdAt: DateTime.now(),
        isVerified: true,
        isActive: true,
        fcmTokens: const [],
      );
      await _db.collection('users').doc(user.id).set(user.toJson());
      // Unirse a una empresa exige el correo verificado.
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {/* no impide usar la app */}
      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_emailErrorMessage(e.code)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return _activeOrBlocked(await _ensureProfile(fbUser));
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
    final name = (fbUser.displayName ?? '').trim();
    final user = User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      phone: fbUser.phoneNumber ?? '',
      displayName: name.isNotEmpty ? name : email.split('@').first,
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

  /// Un chófer que cierra sesión deja de figurar como disponible; después
  /// ya no podría escribir su perfil. Si está en un viaje, el servidor lo
  /// vuelve a liberar al cerrarlo.
  Future<void> _beforeSignOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    // El dispositivo deja de recibir los avisos de esta cuenta.
    if (!kIsWeb) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _db.collection('users').doc(uid).update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          });
        }
      } catch (_) {/* sin token o sin conexión */}
    }
    try {
      final ref = _db.collection('driverProfiles').doc(uid);
      if ((await ref.get()).exists) {
        await ref.update({'isAvailable': false, 'online': false});
      }
    } catch (_) {
      // Pasajeros (sin perfil de chófer) o sin conexión: no bloquea la salida.
    }
  }

  /// Las cuentas bloqueadas desde el panel admin no pueden entrar.
  Future<Either<Failure, User>> _activeOrBlocked(User user) async {
    if (user.isActive) return Right(user);
    await _auth.signOut();
    return const Left(AuthFailure(kBlockedAccountMessage));
  }

  static String _emailErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo. Inicia sesión.';
      case 'weak-password':
        return 'La contraseña es muy débil: usa al menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta cuenta está desactivada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
      default:
        return 'No pudimos iniciar sesión. Inténtalo de nuevo.';
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
      await _beforeSignOut();
      await _auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _functions.httpsCallable('deleteAccount').call();
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      if (e.message == 'active-bookings') {
        return const Left(ServerFailure(
            'Tienes viajes activos o reservados. Cancélalos o espera a que '
            'terminen antes de eliminar tu cuenta.'));
      }
      if (e.code == 'failed-precondition' && e.message != null) {
        return Left(ServerFailure(e.message!));
      }
      return const Left(
          ServerFailure('No pudimos eliminar tu cuenta. Inténtalo de nuevo.'));
    } catch (_) {
      return const Left(
          ServerFailure('No pudimos eliminar tu cuenta. Revisa tu conexión.'));
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
      return Left(AuthFailure(switch (e.code) {
        'invalid-email' => 'Ese correo no es válido. Revísalo.',
        'user-not-found' => 'No hay ninguna cuenta con ese correo.',
        'too-many-requests' =>
          'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
        'network-request-failed' =>
          'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
        _ => 'No pudimos enviar el enlace. Inténtalo de nuevo.',
      }));
    } catch (_) {
      return const Left(
          ServerFailure('No pudimos enviar el enlace. Inténtalo de nuevo.'));
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
