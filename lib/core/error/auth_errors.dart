/// Mensajes de entrada, registro y recuperación (B8). Ninguno dice si existe
/// una cuenta con ese correo: el mismo texto para «no existe» y «contraseña
/// incorrecta», y la recuperación responde igual en ambos casos. Se completa
/// con la protección contra la enumeración de correos de la consola de
/// Firebase (DEPLOY.md).
library;

import '../../l10n/l10n.dart';
import '../repositories/repositories.dart' show kBlockedAccountMessage;
import 'function_errors.dart' show kTooManyAttemptsMessage;

String get kBadCredentialsMessage => L10n.current.errorBadCredentials;

/// Mismo texto para el éxito y para «no hay cuenta».
String passwordResetSentMessage(String email) =>
    L10n.current.errorPasswordResetSent(email);

String loginErrorMessage(String code) => switch (code) {
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' =>
        kBadCredentialsMessage,
      // Bloqueada desde el panel (B3 la deshabilita en Auth).
      'user-disabled' => kBlockedAccountMessage,
      'too-many-requests' => kTooManyAttemptsMessage,
      'network-request-failed' => L10n.current.errorNoConnection,
      _ => L10n.current.errorLoginFailed,
    };

String registerErrorMessage(String code) => switch (code) {
      // No confirma que el correo ya tenga cuenta.
      'email-already-in-use' ||
      'credential-already-in-use' =>
        L10n.current.errorRegisterEmailInUse,
      'invalid-email' => L10n.current.errorInvalidEmail,
      'weak-password' => L10n.current.errorWeakPassword,
      'too-many-requests' => kTooManyAttemptsMessage,
      'network-request-failed' => L10n.current.errorNoConnection,
      _ => L10n.current.errorRegisterFailed,
    };

/// null = se informa como enviado (también si no hay cuenta).
String? passwordResetErrorMessage(String code) => switch (code) {
      'user-not-found' => null,
      'invalid-email' => L10n.current.errorInvalidEmail,
      'too-many-requests' => kTooManyAttemptsMessage,
      'network-request-failed' => L10n.current.errorNoConnection,
      _ => L10n.current.errorPasswordResetFailed,
    };
