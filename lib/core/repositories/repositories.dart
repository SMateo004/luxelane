import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:dartz/dartz.dart';

import '../enums/enums.dart';
import '../error/failures.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// AuthRepository
// ---------------------------------------------------------------------------

/// Mensaje para una cuenta bloqueada desde el panel admin.
const kBlockedAccountMessage =
    'Tu cuenta está bloqueada. Escríbenos a soporte si crees que es un error.';

/// El chófer bloqueado: sin texto técnico, con a quién acudir.
const kDriverSuspendedMessage = 'Cuenta suspendida. Contacta con central.';

/// El mensaje de bloqueo según el rol de la cuenta.
String blockedAccountMessage(UserRole role) =>
    role == UserRole.driver ? kDriverSuspendedMessage : kBlockedAccountMessage;

bool isBlockedAccountMessage(String message) =>
    message == kBlockedAccountMessage || message == kDriverSuspendedMessage;

/// Cómo puede volver a identificarse la cuenta actual (decisión 6).
enum ReauthMethod { password, google, none }

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String phone,
    required String displayName,
    required UserRole role,
  });

  /// Google sign-in (popup on web, native account picker on Android/iOS).
  /// Creates the Firestore profile on first sign-in.
  Future<Either<Failure, User>> signInWithGoogle();

  Future<Either<Failure, void>> logout();

  /// Elimina la cuenta en el servidor (perfil, tarjetas y acceso). Falla si
  /// quedan viajes activos o reservados.
  Future<Either<Failure, void>> deleteAccount();

  /// Anota en el servidor que la cuenta acepta los términos vigentes
  /// (config/global.legalVersion), con la hora del servidor y la versión de
  /// la app (decisión 7).
  Future<Either<Failure, void>> acceptTerms();

  /// Proveedor con el que la cuenta actual puede volver a identificarse.
  ReauthMethod get reauthMethod;

  /// Vuelve a identificar a la cuenta actual ([password] o, sin ella,
  /// Google) y renueva el token, para que el servidor vea un inicio de
  /// sesión reciente (reauth_required). Si la cuenta tiene segundo factor,
  /// devuelve MfaRequiredFailure con el reto.
  Future<Either<Failure, void>> reauthenticate({String? password});

  /// Perfil en vivo de [uid] (null si no existe), para reflejar cambios del
  /// admin o del servidor (bloqueo, cliente de pagos…) sin reiniciar.
  Stream<User?> watchUser(String uid);

  /// Envía (o reenvía) el enlace de verificación del correo. Los errores
  /// llegan como [EmailVerificationFailure].
  Future<Either<Failure, void>> sendVerificationEmail();

  /// Recarga la cuenta y, si Auth da el correo por verificado, pide al
  /// servidor que lo anote (syncEmailVerification). true si ya está.
  Future<Either<Failure, bool>> refreshEmailVerification();

  /// La cuenta actual entra con correo y contraseña y aún no lo verificó.
  bool get needsEmailVerification;

  // El teléfono se recoge pero NO se verifica: en el piloto no hay
  // proveedor de SMS (decisión 1). No hay método de verificación.
  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, User>> getCurrentUser();

  /// Processed stream: Firebase user → Firestore lookup → app User.
  /// Used only for the initial one-shot auth check on app start.
  Stream<User?> get authStateChanges;

  /// Raw Firebase sign-in status (no Firestore lookup).
  /// Used to detect sign-out after initial check — never races with
  /// _onLogin / _onRegister.
  Stream<bool> get isSignedIn;
}

// ---------------------------------------------------------------------------
// UserRepository
// ---------------------------------------------------------------------------

abstract class UserRepository {
  Future<Either<Failure, User>> getUserById(String userId);
  Future<Either<Failure, void>> updateUser(User user);
  Future<Either<Failure, void>> updateFcmToken({
    required String userId,
    required String token,
  });
  Future<Either<Failure, DriverProfile>> getDriverProfile(String userId);
  Future<Either<Failure, void>> updateDriverProfile(DriverProfile profile);
  Future<Either<Failure, void>> updateDriverLocation({
    required String userId,
    required double latitude,
    required double longitude,
  });
  Future<Either<Failure, void>> setDriverAvailability({
    required String userId,
    required bool isAvailable,
  });

  Stream<DriverProfile?> watchDriverProfile(String driverId);

  /// Ocupado por un viaje, sin cambiar si el chófer quiere estar conectado.
  Future<void> markDriverBusy(String driverId);
}

// ---------------------------------------------------------------------------
// VehicleRepository
// ---------------------------------------------------------------------------

abstract class VehicleRepository {
  Future<Either<Failure, Vehicle>> getVehicleById(String vehicleId);
  Future<Either<Failure, Vehicle>> getVehicleByDriver(String driverId);
  Future<Either<Failure, List<Vehicle>>> getAvailableVehicles(
    VehicleClass vehicleClass,
  );
  Future<Either<Failure, void>> createVehicle(Vehicle vehicle);
  Future<Either<Failure, void>> updateVehicle(Vehicle vehicle);

  /// Lo único que el chófer cambia de su vehículo: color y foto.
  Future<Either<Failure, void>> updateVehicleAppearance(
    String vehicleId, {
    String? color,
    String? photoUrl,
  });
}

// ---------------------------------------------------------------------------
// BookingRepository
// ---------------------------------------------------------------------------

abstract class BookingRepository {
  /// Crea la reserva en el servidor (createBooking), que calcula el precio.
  /// Con [quotedPrice] (el que vio el pasajero), si el del servidor es
  /// mayor devuelve [PriceChangedFailure] y no crea nada.
  /// [requestId] (UUID v4) identifica el intento: reenviarlo tras un error
  /// de red o un cambio de precio nunca crea una segunda reserva.
  Future<Either<Failure, Booking>> createBooking(
    Booking booking, {
    double? quotedPrice,
    required String requestId,
  });

  /// Precio del servidor para el viaje de [trip], sin crear nada.
  Future<Either<Failure, BookingQuote>> quoteBooking(Booking trip);
  Future<Either<Failure, Booking>> getBookingById(String bookingId);
  Future<Either<Failure, List<Booking>>> getBookingsByRider(String riderId);

  /// Reservas del pasajero en vivo, las más recientes primero.
  Stream<List<Booking>> watchBookingsByRider(String riderId);

  /// Solicitudes pendientes sin datos personales (solo chóferes
  /// verificados y activos), las más próximas primero.
  Stream<List<OpenRequest>> streamOpenRequests();
  Stream<List<Booking>> watchDriverBookings(String driverId);

  /// Ubicación en vivo del chófer de la reserva (solo lat/lng). El pasajero
  /// solo puede leerla mientras el viaje está activo.
  Stream<GeoPoint?> watchDriverLocation(String bookingId);

  /// Teléfono del chófer asignado. El pasajero solo puede leerlo mientras
  /// el viaje está activo (lo escribe el servidor).
  Stream<String?> watchDriverPhone(String bookingId);

  /// El chófer asignado publica su posición durante el viaje activo.
  Future<void> publishDriverLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
  });
  Future<Either<Failure, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  });

  /// El pasajero valora (1–5) un viaje completado; solo una vez.
  Future<Either<Failure, void>> rateBooking({
    required String bookingId,
    required int rating,
    String comment = '',
  });

  Future<Either<Failure, void>> assignDriver({
    required String bookingId,
    required String driverId,
  });

  /// Lo que costaría cancelar ahora (cancelBooking con dryRun): la app lo
  /// muestra antes de confirmar.
  Future<Either<Failure, CancellationQuote>> previewCancellation(
    String bookingId, {
    String reason = 'other',
  });

  /// Cancela en el servidor (cancelBooking). [acceptedFee] es el recargo que
  /// vio el pasajero; si ahora es mayor, devuelve
  /// [CancellationFeeChangedFailure] sin cancelar.
  Future<Either<Failure, void>> cancelBooking(
    String bookingId, {
    String reason = 'other',
    double acceptedFee = 0,
  });
  Stream<Booking> watchBooking(String bookingId);
}

// ---------------------------------------------------------------------------
// TripFlowRepository — pasos del viaje desde la recogida (servidor, D1)
// ---------------------------------------------------------------------------

abstract class TripFlowRepository {
  /// Código de recogida de la reserva del pasajero, mientras el chófer
  /// espera (driver_arrived). Nunca se guarda en disco.
  Future<Either<Failure, PickupCode>> getPickupCode(String bookingId);

  /// Paso del chófer asignado (advanceBooking): en camino, llegué, iniciar
  /// y completar. Repetirlo tras un corte no duplica nada en el servidor.
  Future<Either<Failure, void>> advance({
    required String bookingId,
    required BookingStatus to,
    ({double lat, double lng})? location,
  });

  /// El chófer devuelve la reserva antes de llegar (releaseBooking), con un
  /// motivo de [kDriverReleaseReasons].
  Future<Either<Failure, void>> release({
    required String bookingId,
    required String reason,
    ({double lat, double lng})? location,
  });

  /// El chófer escribe el código que le da el pasajero (verifyPickup).
  Future<Either<Failure, void>> verifyPickup({
    required String bookingId,
    required String code,
    ({double lat, double lng})? location,
  });
}

// ---------------------------------------------------------------------------
// IncidentRepository — SOS (D1, F9)
// ---------------------------------------------------------------------------

abstract class IncidentRepository {
  /// Avisa a central (raiseIncident). Si no responde en 5 s o no hay red,
  /// devuelve [IncidentIssue.offline] para ofrecer llamada o SMS.
  Future<Either<Failure, IncidentRaise>> raise(
    String bookingId, {
    ({double lat, double lng})? location,
  });

  /// Falsa alarma: solo quien lo disparó (central recibe el aviso igual).
  Future<Either<Failure, void>> cancel(String incidentId);

  /// El incidente más reciente de [uid] en la reserva (solo lo lee él).
  Stream<Incident?> watchMine(String bookingId, String uid);

  /// Ubicación en vivo mientras el incidente siga abierto (las reglas
  /// limitan la frecuencia y los campos).
  Future<void> publishLocation(String incidentId, double lat, double lng);
}

// ---------------------------------------------------------------------------
// PaymentRepository
// ---------------------------------------------------------------------------

abstract class PaymentRepository {
  /// Autoriza la tarjeta para [bookingId]; devuelve el client secret, o
  /// null si el servidor la cobrará al completar (viaje lejano).
  Future<Either<Failure, String?>> createPaymentIntent({
    required String bookingId,
    required String paymentMethodId,
  });
  Future<Either<Failure, Payment>> capturePayment({
    required String bookingId,
    required String riderId,
    required String stripePaymentIntentId,
    required double amount,
    required String currency,
  });
  Future<Either<Failure, Payment>> getPaymentByBooking(String bookingId);
  Future<Either<Failure, List<Payment>>> getPaymentsByRider(String riderId);
  Future<Either<Failure, void>> refundPayment(String paymentId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getSavedCards(
    String stripeCustomerId,
  );
  Future<Either<Failure, void>> addCard({
    required String stripeCustomerId,
    required String paymentMethodId,
  });
  Future<Either<Failure, void>> removeCard({
    required String stripeCustomerId,
    required String paymentMethodId,
  });

  /// Tarjeta que se propone primero al reservar (se guarda en Stripe).
  Future<Either<Failure, void>> setDefaultCard(String paymentMethodId);

  /// Cliente de Stripe del usuario; lo crea si no se pudo al registrarse.
  Future<Either<Failure, String>> ensureStripeCustomer();
}

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<int> getUnreadCount(String userId);
  Future<void> createNotification(AppNotification notification);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> markAllRead(String userId);
}
