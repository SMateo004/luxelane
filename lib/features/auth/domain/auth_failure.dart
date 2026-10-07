import '../../../core/error/failures.dart';

/// An auth failure that keeps the backend error code (e.g. Firebase's
/// `wrong-password`, `email-already-in-use`) so the UI can show a translated
/// message instead of the provider's English text.
class AuthCodeFailure extends AuthFailure {
  const AuthCodeFailure(this.code, [super.message]);
  final String code;
}
