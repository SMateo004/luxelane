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

  /// El precio final solo se ajusta en viajes completados sin cobro capturado
  /// ni reembolsado (después hay que reembolsar, no reescribir el importe).
  static bool canAdjustFinalPrice(Booking b, Payment? payment) =>
      b.status == BookingStatus.completed &&
      (payment == null ||
          payment.status == PaymentStatus.pending ||
          payment.status == PaymentStatus.failed);
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
