import 'package:dartz/dartz.dart';

import '../enums/enums.dart';
import '../error/failures.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// AuthRepository
// ---------------------------------------------------------------------------

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

  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> sendVerificationEmail();
  Future<Either<Failure, void>> sendPhoneVerification(String phone);
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
}

// ---------------------------------------------------------------------------
// VehicleRepository
// ---------------------------------------------------------------------------

abstract class VehicleRepository {
  Future<Either<Failure, Vehicle>> getVehicleById(String vehicleId);
  Future<Either<Failure, Vehicle>> getVehicleByDriver(String driverId);
  Future<Either<Failure, List<Vehicle>>> getAvailableVehicles(VehicleClass vehicleClass);
  Future<Either<Failure, void>> createVehicle(Vehicle vehicle);
  Future<Either<Failure, void>> updateVehicle(Vehicle vehicle);
}

// ---------------------------------------------------------------------------
// BookingRepository
// ---------------------------------------------------------------------------

abstract class BookingRepository {
  Future<Either<Failure, Booking>> createBooking(Booking booking);
  Future<Either<Failure, Booking>> getBookingById(String bookingId);
  Future<Either<Failure, List<Booking>>> getBookingsByRider(String riderId);
  Future<Either<Failure, List<Booking>>> getPendingBookings();
  Stream<List<Booking>> streamPendingBookings();
  Stream<List<Booking>> watchDriverBookings(String driverId);
  Future<Either<Failure, void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  });
  Future<Either<Failure, void>> assignDriver({
    required String bookingId,
    required String driverId,
  });
  Future<Either<Failure, void>> cancelBooking(String bookingId);
  Stream<Booking> watchBooking(String bookingId);
}

// ---------------------------------------------------------------------------
// RideRepository
// ---------------------------------------------------------------------------

abstract class RideRepository {
  Future<Either<Failure, Ride>> createRide(Ride ride);
  Future<Either<Failure, Ride>> getRideById(String rideId);
  Future<Either<Failure, Ride>> getRideByBooking(String bookingId);
  Future<Either<Failure, List<Ride>>> getRidesByRider(String riderId);
  Future<Either<Failure, List<Ride>>> getRidesByDriver(String driverId);
  Future<Either<Failure, void>> appendRoutePoint({
    required String rideId,
    required double latitude,
    required double longitude,
  });
  Future<Either<Failure, void>> completeRide({
    required String rideId,
    required double distanceKm,
    required int durationMin,
  });
  Future<Either<Failure, void>> submitRating({
    required String rideId,
    required double rating,
    required bool isRiderRating,
  });
  Stream<Ride> watchRide(String rideId);
}

// ---------------------------------------------------------------------------
// PaymentRepository
// ---------------------------------------------------------------------------

abstract class PaymentRepository {
  Future<Either<Failure, String>> createPaymentIntent({
    required double amount,
    required String currency,
    required String stripeCustomerId,
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
  Future<Either<Failure, List<Map<String, dynamic>>>> getSavedCards(String stripeCustomerId);
  Future<Either<Failure, void>> addCard({
    required String stripeCustomerId,
    required String paymentMethodId,
  });
  Future<Either<Failure, void>> removeCard({
    required String stripeCustomerId,
    required String paymentMethodId,
  });
}
