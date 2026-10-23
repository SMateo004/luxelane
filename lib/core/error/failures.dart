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

/// El servidor calculó un precio mayor que el que vio el pasajero: la
/// reserva no se creó y hay que confirmar [price].
class PriceChangedFailure extends Failure {
  const PriceChangedFailure(this.price)
      : super('El precio de este viaje cambió.');
  final double price;
}

/// La app es más vieja que config/global.minAppVersion (o, la del chófer,
/// que minDriverAppVersion): hay que actualizar para cotizar, reservar o
/// avanzar un viaje. Los enlaces a las tiendas, si el admin los puso.
class AppUpdateRequiredFailure extends Failure {
  const AppUpdateRequiredFailure({
    this.androidStoreUrl,
    this.iosStoreUrl,
    this.forDriver = false,
  }) : super(forDriver
            ? 'Actualiza la app para seguir con tus viajes.'
            : 'Actualiza la app para reservar.');
  final String? androidStoreUrl;
  final String? iosStoreUrl;

  /// Lo pide el servidor a la app del chófer (minDriverAppVersion).
  final bool forDriver;
}

/// Qué salió mal en un paso del viaje (código de recogida, avanzar,
/// verificar). La pantalla decide qué mostrar según [issue].
enum TripIssue {
  network,
  notAtPickup,
  wrongCode,
  locked,
  expired,
  unavailable,
  notAllowed,
  invalidTransition,
  other,
}

class TripFailure extends Failure {
  const TripFailure(this.issue, super.message, {this.attemptsLeft});
  final TripIssue issue;

  /// Con [TripIssue.wrongCode], intentos que quedan antes del bloqueo.
  final int? attemptsLeft;
}

/// Por qué no se pudo avisar a central del SOS.
enum IncidentIssue { offline, outsideWindow, rateLimited, notAllowed, other }

class IncidentFailure extends Failure {
  const IncidentFailure(this.issue, super.message);
  final IncidentIssue issue;
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error']);
}
