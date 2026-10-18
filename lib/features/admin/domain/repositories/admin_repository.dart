import 'package:dartz/dartz.dart';
import '../../../refunds/domain/refund.dart';
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
  Future<Either<Failure, void>> verifyDriver(String driverId);
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool active);
  Future<Either<Failure, void>> toggleVehicleStatus(
      String vehicleId, bool active);
  Future<Either<Failure, void>> toggleMaintenanceMode(bool active);
  Future<Either<Failure, void>> updateGlobalSettings(
      Map<String, dynamic> fields);

  // ── Operaciones vía servidor (auditadas, avisan a pasajero y chófer) ─────
  /// Runs the server dispatcher; Right(true) when a chauffeur was assigned.
  Future<Either<Failure, bool>> assignNearestDriver(Booking booking);

  /// Cancels via the backend (notifies passenger and chauffeur, audited).
  Future<Either<Failure, void>> cancelBooking(String bookingId, {String? reason});

  /// Takes the ride away from its chauffeur and back to dispatch (before
  /// the trip starts); rider and chauffeur are notified, audited.
  Future<Either<Failure, void>> releaseChauffeur(String bookingId, {String? reason});

  /// Adds an extra charge or a correction to a ride's price. Left carries
  /// an adjust/* code from the server when it refuses.
  Future<Either<Failure, double>> adjustPrice({
    required String bookingId,
    required AdjustmentType type,
    required double amount,
    String? note,
  });

  /// Records money given back for a completed ride (paid outside the app).
  /// Left carries a refund/* code from the server when it refuses.
  Future<Either<Failure, void>> recordRefund({
    required String bookingId,
    required double amount,
    required RefundMethod method,
    required String reason,
  });
  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role);
}
