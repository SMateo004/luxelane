import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../l10n/l10n.dart';
import '../config/app_check_setup.dart';

/// Los errores de las Cloud Functions llegan solo con un código y un motivo
/// corto (details.reason), nunca con texto del servidor. Aquí se traducen a
/// lo que ve la persona.
///
/// Códigos que manda el servidor (en el SDK, con guion): invalid-argument,
/// unauthenticated, permission-denied, failed-precondition,
/// resource-exhausted, not-found e internal. unavailable y
/// deadline-exceeded los genera el propio SDK cuando no hay red.

String get kTooManyAttemptsMessage => L10n.current.errorTooManyAttempts;
String get kMfaRequiredMessage => L10n.current.errorMfaRequired;
String get kReauthRequiredMessage => L10n.current.errorReauthRequired;

/// Siguen siendo `const` porque otros bloques los usan en expresiones const
/// (`const AuthFailure(kSessionExpiredMessage)`). Son el texto en español; lo
/// que se muestra sale de L10n.current.errorSessionExpired y
/// errorNoConnection, y [Failure.message] traduce estos dos al idioma activo.
const kSessionExpiredMessage =
    'Tu sesión expiró. Vuelve a iniciar sesión.'; // i18n-ignore: const en español, se muestra con L10n.current.errorSessionExpired
const kNoConnectionMessage =
    'Sin conexión con el servidor. Revisa tu red e inténtalo de nuevo.'; // i18n-ignore: const en español, se muestra con L10n.current.errorNoConnection

/// Volver a identificarse (reauth_required). Aquí la cuenta ya es conocida:
/// decir que la contraseña no coincide no revela nada.
String reauthErrorMessage(String code) => switch (code) {
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        L10n.current.errorReauthWrongPassword,
      'user-mismatch' => L10n.current.errorReauthUserMismatch,
      'too-many-requests' => kTooManyAttemptsMessage,
      'network-request-failed' ||
      'network_error' =>
        L10n.current.errorNoConnection,
      _ => L10n.current.errorReauthFailed,
    };

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
    'unauthenticated' => L10n.current.errorSessionExpired,
    'unavailable' || 'deadline-exceeded' => L10n.current.errorNoConnection,
    _ => null,
  };
}

/// Mensaje genérico por código, para las pantallas sin uno propio.
String functionErrorMessage(String code, Object? details) =>
    commonFunctionError(code, details) ??
    switch (code) {
      'invalid-argument' => L10n.current.errorInvalidArgument,
      'permission-denied' => L10n.current.errorPermissionDenied,
      'failed-precondition' => L10n.current.errorFailedPrecondition,
      'not-found' => L10n.current.errorNotFound,
      _ => L10n.current.errorGeneric,
    };

/// Error inesperado (el `catch` final de los repositorios y los streams):
/// nunca el texto técnico de la excepción, que es lo que se veía antes
/// («HttpException: Invalid HTTP date…», E6).
String unexpectedErrorMessage(Object error) => switch (error) {
      FirebaseFunctionsException(:final code, :final details) =>
        functionErrorMessage(code, details),
      FirebaseException(code: 'permission-denied') =>
        L10n.current.errorPermissionDenied,
      FirebaseException(code: 'unavailable' || 'deadline-exceeded') ||
      TimeoutException() =>
        L10n.current.errorNoConnection,
      _ => L10n.current.errorGeneric,
    };

/// deleteAccount: motivos propios y, si no, el mensaje genérico.
String deleteAccountErrorMessage(String code, Object? details) =>
    switch (functionErrorReason(details)) {
      'active-bookings' => L10n.current.errorDeleteActiveBookings,
      'admin_account' => L10n.current.errorDeleteAdminAccount,
      _ => commonFunctionError(code, details) ??
          L10n.current.errorDeleteAccountFailed,
    };

/// acceptTerms: si cambió la versión mientras se leía, se vuelve a aceptar.
String acceptTermsErrorMessage(String code, Object? details) =>
    switch (functionErrorReason(details)) {
      'terms_outdated' => L10n.current.errorTermsOutdated,
      _ => commonFunctionError(code, details) ??
          L10n.current.errorAcceptTermsFailed,
    };

/// Formulario de empresas (submitBusinessLead).
String businessLeadErrorMessage(String code, Object? details) => switch (code) {
      'resource-exhausted' => L10n.current.errorBusinessLeadTooMany,
      'invalid-argument' => L10n.current.errorBusinessLeadInvalid,
      _ => commonFunctionError(code, details) ??
          L10n.current.errorBusinessLeadFailed,
    };

/// Registro de chóferes (startDriverApplication, saveDriverStep,
/// registerDocumentUpload, submitApplication y las del panel): cada motivo
/// del servidor con su texto; si no, los comunes y uno genérico del paso.
String registrationErrorMessage(String code, Object? details) {
  final t = L10n.current;
  return switch (functionErrorReason(details)) {
    'has_bookings' => t.regErrorHasBookings,
    'driver_account' => t.regErrorDriverAccount,
    'not_a_rider' => t.regErrorNotARider,
    'admin_account' => t.regErrorAdminAccount,
    'inactive_user' => t.regErrorInactiveUser,
    'email_not_verified' => t.errorEmailNotVerified,
    'profile_not_found' => t.regErrorProfileNotFound,
    'not_a_driver' => t.regErrorNotADriver,
    'locked_after_approval' => t.regErrorLockedAfterApproval,
    'application_closed' => t.regErrorApplicationClosed,
    'plate_in_use' => t.regErrorPlateInUse,
    'invalid_file' => t.regErrorInvalidFile,
    'file_missing' => t.regErrorFileMissing,
    'unexpected_version' => t.regErrorUnexpectedVersion,
    'document_expired' => t.regErrorDocumentExpired,
    'requirements_not_configured' => t.regErrorRequirementsNotConfigured,
    'steps_incomplete' => t.regErrorStepsIncomplete,
    'documents_missing' => t.regErrorDocumentsMissing,
    'invalid_request' => t.regErrorInvalidRequest,
    'driver_docs_blocked' => t.regErrorDriverDocsBlocked,
    'documents_not_approved' => t.regErrorDocumentsNotApproved,
    'not_decidable' => t.regErrorNotDecidable,
    'not_reviewable' => t.regErrorNotReviewable,
    'stale_version' => t.regErrorStaleVersion,
    'document_not_found' => t.regErrorDocumentNotFound,
    'driver_not_found' => t.regErrorDriverNotFound,
    'application_not_found' => t.regErrorApplicationNotFound,
    'purge_disabled' => t.regErrorPurgeDisabled,
    _ => commonFunctionError(code, details) ?? t.regErrorGeneric,
  };
}

/// Motivos del registro de chóferes que tienen texto propio (el test
/// comprueba que cubren todos los que lanza el servidor).
const kRegistrationReasons = [
  'has_bookings', 'driver_account', 'not_a_rider', 'admin_account', //
  'inactive_user', 'email_not_verified', 'profile_not_found', 'not_a_driver',
  'locked_after_approval', 'application_closed', 'plate_in_use',
  'invalid_file', 'file_missing', 'unexpected_version', 'document_expired',
  'requirements_not_configured', 'steps_incomplete', 'documents_missing',
  'invalid_request', 'driver_docs_blocked', 'documents_not_approved',
  'not_decidable', 'not_reviewable', 'stale_version', 'document_not_found',
  'driver_not_found', 'application_not_found', 'purge_disabled',
];
