abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication error']);
}

/// The user closed the Google / provider sheet. Not an error to show.
class AuthCancelledFailure extends AuthFailure {
  const AuthCancelledFailure([super.message = 'Sign-in cancelled']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment error']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}
