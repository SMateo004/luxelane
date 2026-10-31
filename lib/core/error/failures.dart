import '../../l10n/l10n.dart';
import 'function_errors.dart' show kNoConnectionMessage, kSessionExpiredMessage;

abstract class Failure {
  const Failure(this._message);
  final String _message;

  /// Texto para la persona, en el idioma activo. Los dos mensajes que siguen
  /// siendo `const` en español (otros bloques los usan en expresiones const)
  /// se traducen aquí.
  String get message => switch (_message) {
        kNoConnectionMessage => L10n.current.errorNoConnection,
        kSessionExpiredMessage => L10n.current.errorSessionExpired,
        _ => _message,
      };
}

/// Mensaje por defecto de los fallos que se crean sin texto.
String _orDefault(String message, String fallback) =>
    message.isEmpty ? fallback : message;

class ServerFailure extends Failure {
  const ServerFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorServerDefault);
}

/// Por qué no se pudo enviar o comprobar la verificación del correo.
enum EmailVerificationIssue { tooManyRequests, network, other }

class EmailVerificationFailure extends Failure {
  const EmailVerificationFailure(this.issue, super.message);
  final EmailVerificationIssue issue;
}

/// Reservar exige el correo verificado (createBooking: email_not_verified).
class EmailNotVerifiedFailure extends Failure {
  const EmailNotVerifiedFailure() : super('');

  @override
  String get message => L10n.current.errorEmailNotVerified;
}

/// Reservar exige aceptar los términos vigentes (createBooking:
/// terms_required).
class TermsRequiredFailure extends Failure {
  const TermsRequiredFailure() : super('');

  @override
  String get message => L10n.current.errorTermsRequired;
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorAuthDefault);
}

/// The user closed the Google / provider sheet. Not an error to show.
class AuthCancelledFailure extends AuthFailure {
  const AuthCancelledFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorAuthCancelledDefault);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorNetworkDefault);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorNotFoundDefault);
}

class PaymentFailure extends Failure {
  const PaymentFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorPaymentDefault);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorPermissionDefault);
}

/// El servidor calculó un precio mayor que el que vio el pasajero: la
/// reserva no se creó y hay que confirmar [price].
class PriceChangedFailure extends Failure {
  const PriceChangedFailure(this.price) : super('');
  final double price;

  @override
  String get message => L10n.current.errorPriceChanged;
}

/// Al confirmar la cancelación el recargo ya no es el que vio el pasajero
/// (pasó el plazo gratuito mientras decidía): se le vuelve a mostrar.
class CancellationFeeChangedFailure extends Failure {
  const CancellationFeeChangedFailure(this.fee) : super('');
  final double fee;

  @override
  String get message => L10n.current.errorCancellationFeeChanged;
}

/// La app es más vieja que config/global.minAppVersion (o, la del chófer,
/// que minDriverAppVersion): hay que actualizar para cotizar, reservar o
/// avanzar un viaje. Los enlaces a las tiendas, si el admin los puso.
class AppUpdateRequiredFailure extends Failure {
  const AppUpdateRequiredFailure({
    this.androidStoreUrl,
    this.iosStoreUrl,
    this.forDriver = false,
  }) : super('');
  final String? androidStoreUrl;
  final String? iosStoreUrl;

  /// Lo pide el servidor a la app del chófer (minDriverAppVersion).
  final bool forDriver;

  @override
  String get message => forDriver
      ? L10n.current.errorAppUpdateDriver
      : L10n.current.errorAppUpdateRider;
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

  /// «El pasajero no aparece» antes del tiempo de espera de la política.
  tooEarly,

  /// El paso necesita la ubicación del chófer.
  locationRequired,
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
  const ValidationFailure([super.message = '']);

  @override
  String get message =>
      _orDefault(super.message, L10n.current.errorValidationDefault);
}

/// La reserva que se escucha no existe (o se borró): no es un fallo de red.
class BookingNotFoundException implements Exception {
  const BookingNotFoundException(this.bookingId);
  final String bookingId;
}
