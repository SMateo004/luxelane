import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';

/// Reglas de operación que el panel admin aplica sobre las reservas.
///
/// Un único mapa de transiciones evita estados imposibles (p. ej. volver a
/// "pendiente" una reserva ya cobrada) y mantiene coherentes las finanzas.
///
/// `verified` e `in_progress` no se fijan desde el panel: verificar es del
/// chófer con el código del pasajero (o «Forzar verificación», con motivo,
/// por adminOverrideVerify) e iniciar el viaje es del chófer.
abstract class AdminOperations {
  static const Map<BookingStatus, List<BookingStatus>> _transitions = {
    BookingStatus.pending: [BookingStatus.cancelled],
    BookingStatus.confirmed: [
      BookingStatus.driverArriving,
      BookingStatus.cancelled,
    ],
    BookingStatus.driverArriving: [
      BookingStatus.driverArrived,
      BookingStatus.cancelled,
    ],
    BookingStatus.driverArrived: [BookingStatus.cancelled],
    BookingStatus.verified: [BookingStatus.cancelled],
    BookingStatus.inProgress: [BookingStatus.completed],
    BookingStatus.completed: [],
    BookingStatus.cancelled: [],
  };

  /// Estados a los que el admin puede mover una reserva.
  static List<BookingStatus> nextStatuses(BookingStatus from) =>
      _transitions[from] ?? const [];

  static bool canTransition(BookingStatus from, BookingStatus to) =>
      nextStatuses(from).contains(to);

  /// Estados con un chófer ocupado (no disponible para otra reserva).
  static const activeStatuses = {
    BookingStatus.confirmed,
    BookingStatus.driverArriving,
    BookingStatus.driverArrived,
    BookingStatus.verified,
    BookingStatus.inProgress,
  };

  static bool isActive(BookingStatus s) => activeStatuses.contains(s);

  /// Viajes de [driverId] confirmados o en curso, por hora de recogida: los
  /// que hay que reasignar antes de bloquearlo (al bloquearlo deja de verlos).
  static List<Booking> activeTripsOf(
    Iterable<Booking> bookings,
    String driverId,
  ) =>
      bookings
          .where((b) => b.driverId == driverId && isActive(b.status))
          .toList()
        ..sort((a, c) => a.scheduledAt.compareTo(c.scheduledAt));

  /// Se puede forzar la verificación (adminOverrideVerify): el chófer está
  /// en la recogida y el pasajero aún no dio el código.
  static bool canForceVerify(Booking b) =>
      b.status == BookingStatus.driverArrived;

  static bool isClosed(BookingStatus s) =>
      s == BookingStatus.completed || s == BookingStatus.cancelled;

  /// Se puede asignar o reasignar chófer antes de que empiece el viaje.
  static bool canAssignDriver(Booking b) =>
      b.status == BookingStatus.pending ||
      b.status == BookingStatus.confirmed ||
      b.status == BookingStatus.driverArriving;

  /// El importe final solo se ajusta antes de completar el viaje (y dentro
  /// del límite de config/ops, que comprueba el servidor). Después se
  /// corrige el cobro manual o se reembolsa.
  static bool canAdjustFinalPrice(Booking b) =>
      b.status != BookingStatus.completed &&
      b.status != BookingStatus.cancelled;

  /// Solo los cobros registrados a mano y cobrados se corrigen.
  static bool canCorrectPayment(Payment? p) =>
      p != null &&
      p.stripePaymentIntentId.isEmpty &&
      p.status == PaymentStatus.captured;
}

/// Texto del aviso que pone el servidor cuando una reserva no respeta la
/// tarifa vigente.
String? pricingReviewLabel(Booking b) {
  switch (b.pricingReviewReason) {
    case null:
      return null;
    case 'below_fare':
      return 'Precio por debajo de la tarifa vigente';
    case 'fare_disabled':
      return 'Reservada con un servicio desactivado';
    case 'maintenance':
      return 'Reservada en modo mantenimiento';
    case 'class_disabled':
      return 'Reservada con una clase desactivada';
    default:
      return 'Tarifa no reconocida';
  }
}

extension PaymentStatusLabel on PaymentStatus {
  String get displayLabel {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.captured:
        return 'Cobrado';
      case PaymentStatus.refunded:
        return 'Reembolsado';
      case PaymentStatus.failed:
        return 'Fallido';
    }
  }
}

extension UserRoleLabel on UserRole {
  String get displayLabel {
    switch (this) {
      case UserRole.rider:
        return 'Pasajero';
      case UserRole.driver:
        return 'Chófer';
      case UserRole.admin:
        return 'Administrador';
    }
  }
}

/// Cambio de licencia o vehículo que hace un admin cuando el chófer lo pide
/// a central (tras verificar, el chófer no puede: matriz, H4). Solo viajan
/// los campos que cambian, con sus nombres reales en Firestore.
class DriverDocumentsEdit {
  const DriverDocumentsEdit({
    this.licenseNumber,
    this.licenseExpiry,
    this.plate,
    this.vehicleClass,
    this.make,
    this.model,
    this.year,
  });

  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? plate;
  final VehicleClass? vehicleClass;
  final String? make;
  final String? model;
  final int? year;

  /// driverProfiles/{uid}: licenseNumber, licenseExpiry.
  Map<String, Object> profileChanges(DriverProfile p) => {
        if (licenseNumber != null && licenseNumber != p.licenseNumber)
          'licenseNumber': licenseNumber!,
        if (licenseExpiry != null && licenseExpiry != p.licenseExpiry)
          'licenseExpiry': licenseExpiry!,
      };

  /// vehicles/{id}: plate, class (con su capacidad), make, model, year.
  Map<String, Object> vehicleChanges(Vehicle? v) => v == null
      ? const {}
      : {
          if (plate != null && plate != v.plate) 'plate': plate!,
          if (vehicleClass != null && vehicleClass != v.vehicleClass) ...{
            'class': vehicleClass!.name,
            'capacity': vehicleClass!.capacity,
          },
          if (make != null && make != v.make) 'make': make!,
          if (model != null && model != v.model) 'model': model!,
          if (year != null && year != v.year) 'year': year!,
        };
}
