import 'package:dartz/dartz.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecase.dart';

class CreateBookingUseCase implements UseCase<Booking, CreateBookingParams> {
  CreateBookingUseCase(this._repo);
  final BookingRepository _repo;

  @override
  Future<Either<Failure, Booking>> call(CreateBookingParams params) {
    final now = DateTime.now();
    final booking = Booking(
      id: '',
      riderId: params.riderId,
      origin: params.origin,
      destination: params.destination,
      scheduledAt: params.scheduledAt,
      vehicleClass: params.vehicleClass,
      serviceType: params.serviceType,
      status: BookingStatus.pending,
      estimatedPrice: params.estimatedPrice,
      createdAt: now,
      updatedAt: now,
      notes: params.notes,
    );
    return _repo.createBooking(booking);
  }
}

class CreateBookingParams {
  const CreateBookingParams({
    required this.origin,
    required this.destination,
    required this.vehicleClass,
    required this.serviceType,
    required this.scheduledAt,
    required this.riderId,
    required this.estimatedPrice,
    this.notes,
  });
  final Place origin;
  final Place destination;
  final VehicleClass vehicleClass;
  final ServiceType serviceType;
  final DateTime scheduledAt;
  final String riderId;
  final double estimatedPrice;
  final String? notes;
}

// ---------------------------------------------------------------------------

class WatchBookingUseCase implements StreamUseCase<Booking, String> {
  WatchBookingUseCase(this._repo);
  final BookingRepository _repo;

  @override
  Stream<Either<Failure, Booking>> call(String bookingId) =>
      _repo.watchBooking(bookingId).map<Either<Failure, Booking>>(Right.new);
}

// ---------------------------------------------------------------------------

class UpdateBookingStatusUseCase
    implements UseCase<void, UpdateBookingStatusParams> {
  UpdateBookingStatusUseCase(this._repo);
  final BookingRepository _repo;

  @override
  Future<Either<Failure, void>> call(UpdateBookingStatusParams params) =>
      _repo.updateBookingStatus(
        bookingId: params.bookingId,
        status: params.status,
      );
}

class UpdateBookingStatusParams {
  const UpdateBookingStatusParams({
    required this.bookingId,
    required this.status,
  });
  final String bookingId;
  final BookingStatus status;
}

// ---------------------------------------------------------------------------

class CancelBookingUseCase implements UseCase<void, String> {
  CancelBookingUseCase(this._repo);
  final BookingRepository _repo;

  @override
  Future<Either<Failure, void>> call(String bookingId) =>
      _repo.cancelBooking(bookingId);
}

// ---------------------------------------------------------------------------

class GetRiderBookingsUseCase implements UseCase<List<Booking>, String> {
  GetRiderBookingsUseCase(this._repo);
  final BookingRepository _repo;

  @override
  Future<Either<Failure, List<Booking>>> call(String riderId) =>
      _repo.getBookingsByRider(riderId);
}
