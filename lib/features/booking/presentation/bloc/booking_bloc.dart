import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class BookingCreateRequested extends BookingEvent {
  const BookingCreateRequested({
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
  @override
  List<Object?> get props => [riderId, vehicleClass, scheduledAt, estimatedPrice];
}

class BookingStatusWatched extends BookingEvent {
  const BookingStatusWatched({required this.bookingId});
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

class BookingDriverAssigned extends BookingEvent {
  const BookingDriverAssigned({
    required this.bookingId,
    required this.driverId,
  });
  final String bookingId;
  final String driverId;
  @override
  List<Object?> get props => [bookingId, driverId];
}

class BookingCancelRequested extends BookingEvent {
  const BookingCancelRequested({required this.bookingId});
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

class BookingStatusChanged extends BookingEvent {
  const BookingStatusChanged({required this.booking});
  final Booking booking;
  @override
  List<Object?> get props => [booking.id, booking.status];
}

class BookingRiderTripsRequested extends BookingEvent {
  const BookingRiderTripsRequested({required this.riderId});
  final String riderId;
  @override
  List<Object?> get props => [riderId];
}

class BookingUpdateStatusRequested extends BookingEvent {
  const BookingUpdateStatusRequested({
    required this.bookingId,
    required this.status,
  });
  final String bookingId;
  final BookingStatus status;
  @override
  List<Object?> get props => [bookingId, status];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingCreated extends BookingState {
  const BookingCreated(this.booking);
  final Booking booking;
  @override
  List<Object?> get props => [booking.id];
}

class BookingStatusUpdated extends BookingState {
  const BookingStatusUpdated(this.booking);
  final Booking booking;
  @override
  List<Object?> get props => [booking.id, booking.status];
}

class BookingCancelled extends BookingState {
  const BookingCancelled();
}

class BookingTripsLoaded extends BookingState {
  const BookingTripsLoaded(this.bookings);
  final List<Booking> bookings;
  @override
  List<Object?> get props => [bookings];
}

class BookingError extends BookingState {
  const BookingError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({required BookingRepository bookingRepository})
      : _repo = bookingRepository,
        super(const BookingInitial()) {
    on<BookingCreateRequested>(_onCreate);
    on<BookingStatusWatched>(_onWatch);
    on<BookingDriverAssigned>(_onAssignDriver);
    on<BookingCancelRequested>(_onCancel);
    on<BookingStatusChanged>(_onStatusChanged);
    on<BookingRiderTripsRequested>(_onLoadTrips);
    on<BookingUpdateStatusRequested>(_onUpdateStatus);
  }

  final BookingRepository _repo;

  Future<void> _onCreate(
    BookingCreateRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    final now = DateTime.now();
    final booking = Booking(
      id: '',
      riderId: event.riderId,
      origin: event.origin,
      destination: event.destination,
      scheduledAt: event.scheduledAt,
      vehicleClass: event.vehicleClass,
      serviceType: event.serviceType,
      status: BookingStatus.pending,
      estimatedPrice: event.estimatedPrice,
      createdAt: now,
      updatedAt: now,
      notes: event.notes,
    );
    final result = await _repo.createBooking(booking);
    result.fold(
      (f) => emit(BookingError(f.message)),
      (b) => emit(BookingCreated(b)),
    );
  }

  Future<void> _onWatch(
    BookingStatusWatched event,
    Emitter<BookingState> emit,
  ) async {
    await emit.forEach<Booking>(
      _repo.watchBooking(event.bookingId),
      onData: (b) => BookingStatusUpdated(b),
      onError: (e, _) => BookingError(e.toString()),
    );
  }

  Future<void> _onAssignDriver(
    BookingDriverAssigned event,
    Emitter<BookingState> emit,
  ) async {
    final result = await _repo.assignDriver(
      bookingId: event.bookingId,
      driverId: event.driverId,
    );
    result.fold(
      (f) => emit(BookingError(f.message)),
      (_) {},
    );
  }

  Future<void> _onCancel(
    BookingCancelRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    final result = await _repo.cancelBooking(event.bookingId);
    result.fold(
      (f) => emit(BookingError(f.message)),
      (_) => emit(const BookingCancelled()),
    );
  }

  void _onStatusChanged(
    BookingStatusChanged event,
    Emitter<BookingState> emit,
  ) {
    emit(BookingStatusUpdated(event.booking));
  }

  Future<void> _onUpdateStatus(
    BookingUpdateStatusRequested event,
    Emitter<BookingState> emit,
  ) async {
    await _repo.updateBookingStatus(
      bookingId: event.bookingId,
      status: event.status,
    );
  }

  Future<void> _onLoadTrips(
    BookingRiderTripsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());
    final result = await _repo.getBookingsByRider(event.riderId);
    result.fold(
      (f) => emit(BookingError(f.message)),
      (list) => emit(BookingTripsLoaded(list)),
    );
  }
}
