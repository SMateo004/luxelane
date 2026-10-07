import '../../../l10n/l10n.dart';

/// Maps a Firebase Auth / Firestore error code to a message in the current
/// language. Unknown or missing codes get a generic message; the provider's
/// raw (English) text is never shown to users.
String authErrorMessage(AppLocalizations l, String? code) => switch (code) {
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        l.authErrorWrongCredentials,
      'user-not-found' => l.authErrorUserNotFound,
      'email-already-in-use' => l.authErrorEmailInUse,
      'weak-password' => l.authErrorWeakPassword,
      'invalid-email' => l.authErrorInvalidEmail,
      'user-disabled' => l.authErrorUserDisabled,
      'too-many-requests' => l.authErrorTooManyRequests,
      'network-request-failed' || 'unavailable' => l.commonConnectionError,
      _ => l.authErrorGeneric,
    };
