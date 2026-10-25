import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../error/failures.dart';
import '../models/models.dart';

/// Verificación en dos pasos con app autenticadora (TOTP), obligatoria para
/// chóferes y administradores (decisión 2). Primero se ofrece el alta y se
/// avisa; la exigencia la activa config/security.mfaEnforced (decisión 3).

/// Segundo paso de un inicio de sesión que lo pide.
abstract class MfaChallenge {
  /// La cuenta tiene una app autenticadora registrada.
  bool get hasTotp;

  /// Completa el inicio de sesión con el código de 6 cifras.
  Future<Either<Failure, User>> resolve(String code);
}

/// El inicio de sesión necesita el código de la app autenticadora.
class MfaRequiredFailure extends Failure {
  const MfaRequiredFailure(this.challenge)
      : super('Introduce el código de tu app autenticadora.');
  final MfaChallenge challenge;
}

/// Un alta de TOTP en curso: el secreto se muestra una vez y vence.
class TotpEnrollment {
  TotpEnrollment({
    required this.secretKey,
    required this.qrCodeUrl,
    this.deadline,
    this.handle,
  });

  /// Clave para escribirla a mano en la app autenticadora.
  final String secretKey;

  /// otpauth:// para el código QR.
  final String qrCodeUrl;
  final DateTime? deadline;

  /// El TotpSecret de firebase_auth (null en pruebas).
  final Object? handle;
}

/// Operaciones de alta del segundo factor (sustituible en pruebas).
abstract class MfaService {
  Future<bool> hasSecondFactor();
  Future<TotpEnrollment> startTotpEnrollment({required String accountName});
  Future<void> finishTotpEnrollment(TotpEnrollment enrollment, String code);

  /// Solo en móvil: abre el QR en la app autenticadora o el llavero.
  bool get canOpenInAuthenticator;
  Future<void> openInAuthenticator(TotpEnrollment enrollment);
}

/// Nombre que verá la persona en su app autenticadora.
const kTotpIssuer = 'Luxelane';

class FirebaseMfaService implements MfaService {
  FirebaseMfaService(this._auth);
  final fb.FirebaseAuth _auth;

  fb.User get _user {
    final u = _auth.currentUser;
    if (u == null) {
      throw fb.FirebaseAuthException(code: 'no-current-user');
    }
    return u;
  }

  @override
  Future<bool> hasSecondFactor() async =>
      (await _user.multiFactor.getEnrolledFactors()).isNotEmpty;

  @override
  Future<TotpEnrollment> startTotpEnrollment({
    required String accountName,
  }) async {
    final session = await _user.multiFactor.getSession();
    final secret = await fb.TotpMultiFactorGenerator.generateSecret(session);
    final url = await secret.generateQrCodeUrl(
      accountName: accountName,
      issuer: kTotpIssuer,
    );
    return TotpEnrollment(
      secretKey: secret.secretKey,
      qrCodeUrl: url,
      deadline: secret.enrollmentCompletionDeadline,
      handle: secret,
    );
  }

  @override
  Future<void> finishTotpEnrollment(TotpEnrollment e, String code) async {
    final assertion =
        await fb.TotpMultiFactorGenerator.getAssertionForEnrollment(
            e.handle! as fb.TotpSecret, code);
    await _user.multiFactor.enroll(assertion, displayName: 'App autenticadora');
  }

  @override
  bool get canOpenInAuthenticator => !kIsWeb;

  @override
  Future<void> openInAuthenticator(TotpEnrollment e) =>
      (e.handle! as fb.TotpSecret).openInOtpApp(e.qrCodeUrl);
}

/// Segundo paso con el resolver de Firebase.
class FirebaseTotpChallenge implements MfaChallenge {
  FirebaseTotpChallenge(this._resolver, this._finish);

  final fb.MultiFactorResolver _resolver;

  /// Lo que hace el repositorio tras entrar (perfil, bloqueo).
  final Future<Either<Failure, User>> Function(fb.User user) _finish;

  fb.MultiFactorInfo? get _totp =>
      _resolver.hints.where((h) => h.factorId == 'totp').firstOrNull;

  @override
  bool get hasTotp => _totp != null;

  @override
  Future<Either<Failure, User>> resolve(String code) async {
    final hint = _totp;
    if (hint == null) return Left(AuthFailure(mfaErrorMessage('no-totp')));
    try {
      final assertion = await fb.TotpMultiFactorGenerator.getAssertionForSignIn(
        hint.uid,
        code,
      );
      final cred = await _resolver.resolveSignIn(assertion);
      return _finish(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(mfaErrorMessage(e.code)));
    } catch (_) {
      return Left(AuthFailure(mfaErrorMessage('')));
    }
  }
}

/// Errores del segundo factor, sin texto técnico.
String mfaErrorMessage(String code) => switch (code) {
      'invalid-verification-code' ||
      'invalid-code' =>
        'Código incorrecto. Usa el código actual de tu app autenticadora '
            '(y revisa que la hora del teléfono sea automática).',
      'requires-recent-login' =>
        'Por seguridad, cierra sesión, vuelve a entrar y repite el alta.',
      'unverified-email' =>
        'Verifica tu correo antes de activar la verificación en dos pasos.',
      'network-request-failed' =>
        'Sin conexión. Revisa tu red e inténtalo de nuevo.',
      'session-expired' ||
      'totp-challenge-timeout' ||
      'code-expired' =>
        'El código QR venció. Empieza el alta de nuevo.',
      'operation-not-allowed' ||
      'admin-restricted-operation' =>
        'La verificación en dos pasos aún no está activada. Avisa a central.',
      'too-many-requests' =>
        'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      'no-totp' =>
        'Tu cuenta no tiene una app autenticadora registrada. Contacta con '
            'central.',
      _ => 'No se pudo completar la verificación. Inténtalo de nuevo.',
    };
