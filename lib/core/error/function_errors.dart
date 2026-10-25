import '../config/app_check_setup.dart';

/// Los errores de las Cloud Functions llegan solo con un código y un motivo
/// corto (details.reason), nunca con texto del servidor. Aquí se traducen a
/// lo que ve la persona.
///
/// Códigos que manda el servidor (en el SDK, con guion): invalid-argument,
/// unauthenticated, permission-denied, failed-precondition,
/// resource-exhausted, not-found e internal. unavailable y
/// deadline-exceeded los genera el propio SDK cuando no hay red.

const kTooManyAttemptsMessage =
    'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
const kSessionExpiredMessage = 'Tu sesión expiró. Vuelve a iniciar sesión.';
const kMfaRequiredMessage = 'Activa la verificación en dos pasos (Perfil) y '
    'vuelve a iniciar sesión para continuar.';
const kReauthRequiredMessage =
    'Por seguridad, vuelve a iniciar sesión para continuar.';
const kNoConnectionMessage =
    'Sin conexión con el servidor. Revisa tu red e inténtalo de nuevo.';

/// El motivo corto del error, si lo hay.
String? functionErrorReason(Object? details) {
  final r = (details is Map ? details : const {})['reason'];
  return r is String ? r : null;
}

/// Mensaje para los casos que valen igual en cualquier pantalla (App
/// Check, límite de intentos, sesión, red). null si la pantalla debe usar
/// el suyo.
String? commonFunctionError(String code, Object? details) {
  final reason = functionErrorReason(details);
  if (reason == 'app_check_required') return kAppCheckFailedMessage;
  if (reason == 'mfa_required') return kMfaRequiredMessage;
  if (reason == 'reauth_required') return kReauthRequiredMessage;
  return switch (code) {
    'resource-exhausted' => kTooManyAttemptsMessage,
    'unauthenticated' => kSessionExpiredMessage,
    'unavailable' || 'deadline-exceeded' => kNoConnectionMessage,
    _ => null,
  };
}

/// Mensaje genérico por código, para las pantallas sin uno propio.
String functionErrorMessage(String code, Object? details) =>
    commonFunctionError(code, details) ??
    switch (code) {
      'invalid-argument' => 'Revisa los datos e inténtalo de nuevo.',
      'permission-denied' => 'No tienes permiso para hacer esto.',
      'failed-precondition' => 'Esto no se puede hacer en este momento.',
      'not-found' => 'No encontramos el registro.',
      _ => 'No se pudo completar. Inténtalo de nuevo.',
    };

/// deleteAccount: motivos propios y, si no, el mensaje genérico.
String deleteAccountErrorMessage(String code, Object? details) =>
    switch (functionErrorReason(details)) {
      'active-bookings' =>
        'Tienes viajes activos o reservados. Cancélalos o espera a que '
            'terminen antes de eliminar tu cuenta.',
      'admin_account' =>
        'Las cuentas de administración se eliminan desde la consola.',
      _ => commonFunctionError(code, details) ??
          'No pudimos eliminar tu cuenta. Inténtalo de nuevo.',
    };

/// Formulario de empresas (submitBusinessLead).
String businessLeadErrorMessage(String code, Object? details) => switch (code) {
      'resource-exhausted' =>
        'Ya recibimos varias solicitudes desde aquí. Inténtalo más tarde '
            'o escríbenos.',
      'invalid-argument' => 'Revisa los datos del formulario.',
      _ => commonFunctionError(code, details) ??
          'No pudimos enviar tu solicitud. Inténtalo de nuevo.',
    };
