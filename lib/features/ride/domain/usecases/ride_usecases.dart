import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecase.dart';

class StartRideUseCase implements UseCase<Ride, StartRideParams> {
  StartRideUseCase(this._repo);
  final RideRepository _repo;

  @override
  Future<Either<Failure, Ride>> call(StartRideParams params) {
    final ride = Ride(
      id: '',
      bookingId: params.bookingId,
      riderId: params.riderId,
      driverId: params.driverId,
      startedAt: DateTime.now(),
      driverRoute: const [],
    );
    return _repo.createRide(ride);
  }
}

class StartRideParams {
  const StartRideParams({
    required this.bookingId,
    required this.riderId,
    required this.driverId,
  });
  final String bookingId;
  final String riderId;
  final String driverId;
}

// ---------------------------------------------------------------------------

class WatchRideUseCase implements StreamUseCase<Ride, String> {
  WatchRideUseCase(this._repo);
  final RideRepository _repo;

  @override
  Stream<Either<Failure, Ride>> call(String rideId) =>
      _repo.watchRide(rideId).map<Either<Failure, Ride>>(Right.new);
}

// ---------------------------------------------------------------------------

class CompleteRideUseCase implements UseCase<void, CompleteRideParams> {
  CompleteRideUseCase(this._repo);
  final RideRepository _repo;

  @override
  Future<Either<Failure, void>> call(CompleteRideParams params) =>
      _repo.completeRide(
        rideId: params.rideId,
        distanceKm: params.distanceKm,
        durationMin: params.durationMin,
      );
}

class CompleteRideParams {
  const CompleteRideParams({
    required this.rideId,
    required this.distanceKm,
    required this.durationMin,
  });
  final String rideId;
  final double distanceKm;
  final int durationMin;
}

// ---------------------------------------------------------------------------

class SubmitRatingUseCase implements UseCase<void, SubmitRatingParams> {
  SubmitRatingUseCase(this._repo);
  final RideRepository _repo;

  @override
  Future<Either<Failure, void>> call(SubmitRatingParams params) =>
      _repo.submitRating(
        rideId: params.rideId,
        rating: params.rating,
        isRiderRating: params.isRiderRating,
      );
}

class SubmitRatingParams {
  const SubmitRatingParams({
    required this.rideId,
    required this.rating,
    required this.isRiderRating,
  });
  final String rideId;
  final double rating;
  final bool isRiderRating;
}

// ---------------------------------------------------------------------------

class AppendRoutePointUseCase implements UseCase<void, AppendRouteParams> {
  AppendRoutePointUseCase(this._repo);
  final RideRepository _repo;

  @override
  Future<Either<Failure, void>> call(AppendRouteParams params) =>
      _repo.appendRoutePoint(
        rideId: params.rideId,
        latitude: params.lat,
        longitude: params.lng,
      );
}

class AppendRouteParams {
  const AppendRouteParams({
    required this.rideId,
    required this.lat,
    required this.lng,
  });
  final String rideId;
  final double lat;
  final double lng;
}
