import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';

abstract class AdminRepository {
  Stream<List<Booking>> watchAllBookings();
  Stream<List<Payment>> watchAllPayments();
  Stream<List<User>> watchAllUsers();
  Stream<List<DriverProfile>> watchAllDrivers();
  Stream<List<PricingRule>> watchPricingRules();
  Stream<List<Vehicle>> watchAllVehicles();
  Stream<List<AuditLog>> watchAuditLogs();

  /// Avisos del servidor, los más recientes primero.
  Stream<List<AdminAlert>> watchAdminAlerts();

  /// Marca una alerta como revisada (callable resolveAlert, auditada en el
  /// servidor).
  Future<Either<Failure, void>> resolveAlert(String alertId, {String note});

  /// Pasos registrados por el servidor para una reserva, con la ubicación
  /// del chófer (solo el admin la lee).
  Stream<List<BookingEvent>> watchBookingEvents(String bookingId);

  /// Excepción operativa (adminOverrideVerify): deja la reserva verificada
  /// con [reason], que queda en el registro y crea una alerta.
  Future<Either<Failure, void>> forceVerify(String bookingId, String reason);

  /// Incidentes SOS sin cerrar (abiertos, reconocidos o cancelados por
  /// quien los disparó), los más recientes primero.
  Stream<List<Incident>> watchOpenIncidents();
  Stream<List<IncidentLogEntry>> watchIncidentLog(String incidentId);

  /// Última ubicación publicada por quien disparó el incidente.
  Stream<({double lat, double lng})?> watchIncidentLocation(String incidentId);

  /// Ubicación en vivo del chófer de la reserva (tracking/driver).
  Stream<({double lat, double lng})?> watchDriverTracking(String bookingId);
  Future<Either<Failure, void>> acknowledgeIncident(String incidentId);

  /// Cierre con nota obligatoria (mínimo 10 caracteres).
  Future<Either<Failure, void>> closeIncident(String incidentId, String note);
  Stream<Map<String, dynamic>> watchGlobalSettings();
  Stream<Map<String, dynamic>> watchFinanceSettings();

  /// Máximo de reservas que se cargan; las cifras avisan si se alcanza.
  int get bookingsLimit;

  // ── Tarifas ──────────────────────────────────────────────────────────────
  Future<Either<Failure, void>> updatePricingRule(PricingRule rule);
  Future<Either<Failure, void>> resetPricingRule(PricingRule rule);

  // ── Operaciones ──────────────────────────────────────────────────────────
  Future<Either<Failure, void>> changeBookingStatus(
      Booking booking, BookingStatus status,
      {String reason = ''});
  Future<Either<Failure, void>> assignDriver(Booking booking, String driverId);
  Future<Either<Failure, void>> adjustFinalPrice(
      Booking booking, double finalPrice, String reason);

  // ── Finanzas ─────────────────────────────────────────────────────────────
  Future<Either<Failure, void>> refundPayment(Payment payment, String reason);
  Future<Either<Failure, void>> markPaymentCollected(
      Booking booking, String method, String reference);

  /// Asigna el reparto plataforma / chófer a los viajes completados que aún
  /// no lo tienen. Devuelve cuántos se repartieron.
  Future<Either<Failure, int>> backfillSettlements();
  Future<Either<Failure, void>> updateFinanceSettings(
      Map<String, dynamic> fields);

  // ── Personas, flota y sistema ────────────────────────────────────────────
  /// Verifica los documentos del chófer. Su vehículo solo se activa si el
  /// admin marcó [vehicleReviewed] (revisión de condición del vehículo).
  Future<Either<Failure, void>> verifyDriver(String driverId,
      {required bool vehicleReviewed, String vehicleNote = ''});
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool active);
  Future<Either<Failure, void>> toggleVehicleStatus(
      String vehicleId, bool active);
  Future<Either<Failure, void>> toggleMaintenanceMode(bool active);
  Future<Either<Failure, void>> updateGlobalSettings(
      Map<String, dynamic> fields);
  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role);
}
