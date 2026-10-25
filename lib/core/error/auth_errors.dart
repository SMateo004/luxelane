/// Mensajes de entrada, registro y recuperación (B8). Ninguno dice si existe
/// una cuenta con ese correo: el mismo texto para «no existe» y «contraseña
/// incorrecta», y la recuperación responde igual en ambos casos. Se completa
/// con la protección contra la enumeración de correos de la consola de
/// Firebase (DEPLOY.md).
library;

import '../repositories/repositories.dart' show kBlockedAccountMessage;
import 'function_errors.dart'
    show kNoConnectionMessage, kTooManyAttemptsMessage;

const kBadCredentialsMessage = 'Correo o contraseña incorrectos.';

/// Mismo texto para el éxito y para «no hay cuenta».
String passwordResetSentMessage(String email) =>
    'Si hay una cuenta con $email, te enviamos un enlace para restablecer '
    'tu contraseña. Revisa también el correo no deseado.';

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
      'network-request-failed' => kNoConnectionMessage,
      _ => 'No pudimos iniciar sesión. Inténtalo de nuevo.',
    };

String registerErrorMessage(String code) => switch (code) {
      // No confirma que el correo ya tenga cuenta.
      'email-already-in-use' ||
      'credential-already-in-use' =>
        'No pudimos crear la cuenta con ese correo. Si ya te registraste, '
            'inicia sesión o recupera tu contraseña.',
      'invalid-email' => 'Ese correo no es válido. Revísalo.',
      'weak-password' =>
        'La contraseña es muy débil: usa al menos 6 caracteres.',
      'too-many-requests' => kTooManyAttemptsMessage,
      'network-request-failed' => kNoConnectionMessage,
      _ => 'No pudimos crear la cuenta. Inténtalo de nuevo.',
    };

/// null = se informa como enviado (también si no hay cuenta).
String? passwordResetErrorMessage(String code) => switch (code) {
      'user-not-found' => null,
      'invalid-email' => 'Ese correo no es válido. Revísalo.',
      'too-many-requests' => kTooManyAttemptsMessage,
      'network-request-failed' => kNoConnectionMessage,
      _ => 'No pudimos enviar el enlace. Inténtalo de nuevo.',
    };
