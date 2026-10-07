import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';

abstract class AdminRepository {
  Stream<List<Booking>> watchAllBookings();
  Stream<List<User>> watchAllUsers();
  Stream<List<DriverProfile>> watchAllDrivers();
  Stream<List<PricingRule>> watchPricingRules();
  Stream<List<Vehicle>> watchAllVehicles();
  Stream<List<AuditLog>> watchAuditLogs();
  Stream<Map<String, dynamic>> watchGlobalSettings();

  Future<Either<Failure, void>> updatePricingRule(PricingRule rule);
  Future<Either<Failure, void>> verifyDriver(String driverId);
  Future<Either<Failure, void>> toggleUserStatus(String userId, bool active);
  Future<Either<Failure, void>> toggleVehicleStatus(String vehicleId, bool active);
  Future<Either<Failure, void>> toggleMaintenanceMode(bool active);
  Future<Either<Failure, void>> updateGlobalSettings(Map<String, dynamic> fields);
  Future<Either<Failure, void>> deleteBooking(String bookingId);

  /// Runs the server dispatcher; Right(true) when a chauffeur was assigned.
  Future<Either<Failure, bool>> assignNearestDriver(Booking booking);

  /// Cancels via the backend (notifies passenger and chauffeur, audited).
  Future<Either<Failure, void>> cancelBooking(String bookingId);
  Future<Either<Failure, void>> updateUserRole(String userId, UserRole role);
}

