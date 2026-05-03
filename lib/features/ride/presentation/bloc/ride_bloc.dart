import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class RideEvent extends Equatable {
  const RideEvent();
  @override
  List<Object?> get props => [];
}

class RideStarted extends RideEvent {
  const RideStarted({
    required this.bookingId,
    required this.riderId,
    required this.driverId,
  });
  final String bookingId;
  final String riderId;
  final String driverId;
  @override
  List<Object?> get props => [bookingId];
}

class RideLocationAppended extends RideEvent {
  const RideLocationAppended({
    required this.rideId,
    required this.lat,
    required this.lng,
  });
  final String rideId;
  final double lat;
  final double lng;
  @override
  List<Object?> get props => [rideId, lat, lng];
}

class RideCompleteRequested extends RideEvent {
  const RideCompleteRequested({
    required this.rideId,
    required this.distanceKm,
    required this.durationMin,
  });
  final String rideId;
  final double distanceKm;
  final int durationMin;
  @override
  List<Object?> get props => [rideId];
}

class RideWatched extends RideEvent {
  const RideWatched({required this.rideId});
  final String rideId;
  @override
  List<Object?> get props => [rideId];
}

class RideRatingSubmitted extends RideEvent {
  const RideRatingSubmitted({
    required this.rideId,
    required this.rating,
    required this.isRiderRating,
  });
  final String rideId;
  final double rating;
  final bool isRiderRating;
  @override
  List<Object?> get props => [rideId, rating];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class RideState extends Equatable {
  const RideState();
  @override
  List<Object?> get props => [];
}

class RideInitial extends RideState {
  const RideInitial();
}

class RideLoading extends RideState {
  const RideLoading();
}

class RideActive extends RideState {
  const RideActive(this.ride);
  final Ride ride;
  @override
  List<Object?> get props => [ride.id];
}

class RideLocationUpdated extends RideState {
  const RideLocationUpdated(this.ride);
  final Ride ride;
  @override
  List<Object?> get props => [ride.id, ride.driverRoute.length];
}

class RideCompletedState extends RideState {
  const RideCompletedState(this.ride);
  final Ride ride;
  @override
  List<Object?> get props => [ride.id];
}

class RideError extends RideState {
  const RideError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class RideBloc extends Bloc<RideEvent, RideState> {
  RideBloc({required RideRepository rideRepository})
      : _repo = rideRepository,
        super(const RideInitial()) {
    on<RideStarted>(_onStart);
    on<RideWatched>(_onWatch);
    on<RideLocationAppended>(_onLocation);
    on<RideCompleteRequested>(_onComplete);
    on<RideRatingSubmitted>(_onRating);
  }

  final RideRepository _repo;

  Future<void> _onStart(RideStarted event, Emitter<RideState> emit) async {
    emit(const RideLoading());
    final ride = Ride(
      id: '',
      bookingId: event.bookingId,
      riderId: event.riderId,
      driverId: event.driverId,
      startedAt: DateTime.now(),
      driverRoute: const [],
    );
    final result = await _repo.createRide(ride);
    result.fold(
      (f) => emit(RideError(f.message)),
      (r) => emit(RideActive(r)),
    );
  }

  Future<void> _onWatch(RideWatched event, Emitter<RideState> emit) async {
    await emit.forEach<Ride>(
      _repo.watchRide(event.rideId),
      onData: (r) => r.completedAt != null ? RideCompletedState(r) : RideLocationUpdated(r),
      onError: (e, _) => RideError(e.toString()),
    );
  }

  Future<void> _onLocation(
    RideLocationAppended event,
    Emitter<RideState> emit,
  ) async {
    await _repo.appendRoutePoint(
      rideId: event.rideId,
      latitude: event.lat,
      longitude: event.lng,
    );
  }

  Future<void> _onComplete(
    RideCompleteRequested event,
    Emitter<RideState> emit,
  ) async {
    final result = await _repo.completeRide(
      rideId: event.rideId,
      distanceKm: event.distanceKm,
      durationMin: event.durationMin,
    );
    result.fold(
      (f) => emit(RideError(f.message)),
      (_) {},
    );
  }

  Future<void> _onRating(
    RideRatingSubmitted event,
    Emitter<RideState> emit,
  ) async {
    await _repo.submitRating(
      rideId: event.rideId,
      rating: event.rating,
      isRiderRating: event.isRiderRating,
    );
  }
}
