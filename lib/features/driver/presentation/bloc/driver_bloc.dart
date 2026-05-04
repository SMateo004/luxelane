import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/maps_service.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class DriverEvent extends Equatable {
  const DriverEvent();
  @override
  List<Object?> get props => [];
}

class DriverStarted extends DriverEvent {
  const DriverStarted({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class DriverBookingsWatched extends DriverEvent {
  const DriverBookingsWatched({required this.driverId});
  final String driverId;
  @override
  List<Object?> get props => [driverId];
}

class DriverPendingBookingsWatched extends DriverEvent {
  const DriverPendingBookingsWatched();
}

class DriverAvailabilityToggled extends DriverEvent {
  const DriverAvailabilityToggled({
    required this.userId,
    required this.isAvailable,
  });
  final String userId;
  final bool isAvailable;
  @override
  List<Object?> get props => [userId, isAvailable];
}

class DriverLocationTrackingStarted extends DriverEvent {
  const DriverLocationTrackingStarted({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class DriverLocationTrackingStopped extends DriverEvent {
  const DriverLocationTrackingStopped();
}

class _DriverLocationTick extends DriverEvent {
  const _DriverLocationTick({required this.userId});
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class DriverBookingAccepted extends DriverEvent {
  const DriverBookingAccepted({required this.bookingId});
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

class DriverArrivedAtPickup extends DriverEvent {
  const DriverArrivedAtPickup({required this.bookingId});
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

class DriverTripStarted extends DriverEvent {
  const DriverTripStarted({required this.bookingId});
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

class DriverTripCompleted extends DriverEvent {
  const DriverTripCompleted({required this.bookingId});
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

/// Driver taps "Accept" on the incoming request sheet.
class DriverRequestAccepted extends DriverEvent {
  const DriverRequestAccepted({
    required this.bookingId,
    required this.driverId,
  });
  final String bookingId;
  final String driverId;
  @override
  List<Object?> get props => [bookingId, driverId];
}

/// Driver taps "Decline" or the timer expires.
class DriverRequestDeclined extends DriverEvent {
  const DriverRequestDeclined({required this.bookingId});
  final String bookingId;
  @override
  List<Object?> get props => [bookingId];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class DriverState extends Equatable {
  const DriverState();
  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {
  const DriverInitial();
}

class DriverLoaded extends DriverState {
  const DriverLoaded({
    required this.user,
    required this.profile,
    required this.isAvailable,
    required this.bookings,
    this.isTracking = false,
    this.pendingRequests = const [],
    this.declinedIds = const [],
  });

  final User user;
  final DriverProfile profile;
  final bool isAvailable;
  final List<Booking> bookings;
  final bool isTracking;

  /// All pending bookings currently in Firestore.
  final List<Booking> pendingRequests;

  /// IDs of pending bookings this driver has explicitly declined this session.
  final List<String> declinedIds;

  /// The next pending booking the driver hasn't declined yet.
  Booking? get currentRequest {
    try {
      final vClass = user.vehicleClass;
      return pendingRequests.firstWhere((b) => 
        !declinedIds.contains(b.id) && (vClass == null || b.vehicleClass == vClass)
      );
    } catch (_) {
      return null;
    }
  }

  Booking? get activeBooking {
    const active = {
      BookingStatus.confirmed,
      BookingStatus.driverArriving,
      BookingStatus.driverArrived,
      BookingStatus.inProgress,
    };
    try {
      return bookings.firstWhere((b) => active.contains(b.status));
    } catch (_) {
      return null;
    }
  }

  List<Booking> get completedBookings =>
      bookings.where((b) => b.status == BookingStatus.completed).toList();

  double get totalEarnings => completedBookings.fold(
        0,
        (sum, b) => sum + (b.finalPrice ?? b.estimatedPrice),
      );

  @override
  List<Object?> get props =>
      [user, profile, isAvailable, bookings, isTracking, pendingRequests, declinedIds];

  DriverLoaded copyWith({
    User? user,
    DriverProfile? profile,
    bool? isAvailable,
    List<Booking>? bookings,
    bool? isTracking,
    List<Booking>? pendingRequests,
    List<String>? declinedIds,
  }) =>
      DriverLoaded(
        user: user ?? this.user,
        profile: profile ?? this.profile,
        isAvailable: isAvailable ?? this.isAvailable,
        bookings: bookings ?? this.bookings,
        isTracking: isTracking ?? this.isTracking,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        declinedIds: declinedIds ?? this.declinedIds,
      );
}

class DriverOnboardingRequired extends DriverState {
  const DriverOnboardingRequired();
}

class DriverError extends DriverState {
  const DriverError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  DriverBloc({
    required BookingRepository bookingRepository,
    required UserRepository userRepository,
    required VehicleRepository vehicleRepository,
    required MapsService mapsService,
  })  : _bookingRepo = bookingRepository,
        _userRepo = userRepository,
        _vehicleRepo = vehicleRepository,
        _mapsService = mapsService,
        super(const DriverInitial()) {
    on<DriverStarted>(_onStart);
    on<DriverBookingsWatched>(_onWatchBookings);
    on<DriverPendingBookingsWatched>(_onWatchPending);
    on<DriverAvailabilityToggled>(_onToggleAvailability);
    on<DriverLocationTrackingStarted>(_onStartTracking);
    on<DriverLocationTrackingStopped>(_onStopTracking);
    on<_DriverLocationTick>(_onLocationTick);
    on<DriverBookingAccepted>(_onAccept);
    on<DriverArrivedAtPickup>(_onArrived);
    on<DriverTripStarted>(_onStartTrip);
    on<DriverTripCompleted>(_onCompleteTrip);
    on<DriverRequestAccepted>(_onAcceptRequest);
    on<DriverRequestDeclined>(_onDeclineRequest);
  }

  final BookingRepository _bookingRepo;
  final UserRepository _userRepo;
  final VehicleRepository _vehicleRepo;
  final MapsService _mapsService;
  Timer? _locationTimer;

  // ── Startup ───────────────────────────────────────────────────────────────

  Future<void> _onStart(DriverStarted event, Emitter<DriverState> emit) async {
    try {
      final userResult = await _userRepo.getUserById(event.userId);
      final user = userResult.fold((f) => null, (u) => u);

      if (user == null || user.role != UserRole.driver) {
        emit(const DriverError('Unauthorized: Access restricted to drivers.'));
        return;
      }

      // Sync/Load DriverProfile
      final profileResult = await _userRepo.getDriverProfile(event.userId);
      DriverProfile? profile = profileResult.fold((_) => null, (p) => p);

      // If no real profile, driver must complete onboarding first
      if (profile == null || profile.licenseNumber.isEmpty) {
        emit(const DriverOnboardingRequired());
        return;
      }

      emit(DriverLoaded(
        user: user,
        profile: profile,
        isAvailable: profile.isAvailable, 
        bookings: const [],
      ));

      add(DriverBookingsWatched(driverId: event.userId));
      add(const DriverPendingBookingsWatched());
      if (profile.isAvailable) add(DriverLocationTrackingStarted(userId: event.userId));
    } catch (e) {
      emit(DriverError('Startup failed: ${e.toString()}'));
    }
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Watches bookings assigned to this driver (confirmed, active, completed).
  Future<void> _onWatchBookings(
    DriverBookingsWatched event,
    Emitter<DriverState> emit,
  ) async {
    await emit.forEach<List<Booking>>(
      _bookingRepo.watchDriverBookings(event.driverId),
      onData: (bookings) {
        if (state is! DriverLoaded) return state;
        return (state as DriverLoaded).copyWith(bookings: bookings);
      },
      onError: (e, _) => DriverError(e.toString()),
    );
  }

  /// Watches all pending bookings — filters by driver user vehicle class.
  Future<void> _onWatchPending(
    DriverPendingBookingsWatched event,
    Emitter<DriverState> emit,
  ) async {
    await emit.forEach<List<Booking>>(
      _bookingRepo.streamPendingBookings(),
      onData: (pending) {
        if (state is! DriverLoaded) return state;
        final cur = state as DriverLoaded;
        
        // DEBUG: Allow all for now to verify connection
        final filtered = pending; 

        return cur.copyWith(pendingRequests: filtered);
      },
      onError: (_, __) => state,
    );
  }

  // ── Availability & location ───────────────────────────────────────────────

  Future<void> _onToggleAvailability(
    DriverAvailabilityToggled event,
    Emitter<DriverState> emit,
  ) async {
    await _userRepo.setDriverAvailability(
      userId: event.userId,
      isAvailable: event.isAvailable,
    );
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(isAvailable: event.isAvailable));
    }
    if (event.isAvailable) {
      add(DriverLocationTrackingStarted(userId: event.userId));
    } else {
      add(const DriverLocationTrackingStopped());
    }
  }

  Future<void> _onStartTracking(
    DriverLocationTrackingStarted event,
    Emitter<DriverState> emit,
  ) async {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => add(_DriverLocationTick(userId: event.userId)),
    );
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(isTracking: true));
    }
  }

  Future<void> _onStopTracking(
    DriverLocationTrackingStopped event,
    Emitter<DriverState> emit,
  ) async {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(isTracking: false));
    }
  }

  Future<void> _onLocationTick(
    _DriverLocationTick event,
    Emitter<DriverState> emit,
  ) async {
    final pos = await _mapsService.getCurrentPosition();
    if (pos != null) {
      await _userRepo.updateDriverLocation(
        userId: event.userId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    }
  }

  // ── Ride progression ──────────────────────────────────────────────────────

  Future<void> _onAccept(
    DriverBookingAccepted event,
    Emitter<DriverState> emit,
  ) async {
    await _bookingRepo.updateBookingStatus(
      bookingId: event.bookingId,
      status: BookingStatus.driverArriving,
    );
  }

  Future<void> _onArrived(
    DriverArrivedAtPickup event,
    Emitter<DriverState> emit,
  ) async {
    await _bookingRepo.updateBookingStatus(
      bookingId: event.bookingId,
      status: BookingStatus.driverArrived,
    );
  }

  Future<void> _onStartTrip(
    DriverTripStarted event,
    Emitter<DriverState> emit,
  ) async {
    await _bookingRepo.updateBookingStatus(
      bookingId: event.bookingId,
      status: BookingStatus.inProgress,
    );
  }

  Future<void> _onCompleteTrip(
    DriverTripCompleted event,
    Emitter<DriverState> emit,
  ) async {
    await _bookingRepo.updateBookingStatus(
      bookingId: event.bookingId,
      status: BookingStatus.completed,
    );
  }

  // ── Incoming request ──────────────────────────────────────────────────────

  /// Driver accepts a pending booking — assigns themselves and sets confirmed.
  Future<void> _onAcceptRequest(
    DriverRequestAccepted event,
    Emitter<DriverState> emit,
  ) async {
    await _bookingRepo.assignDriver(
      bookingId: event.bookingId,
      driverId: event.driverId,
    );
    await _bookingRepo.updateBookingStatus(
      bookingId: event.bookingId,
      status: BookingStatus.confirmed,
    );
    // REMOVED: setDriverAvailability(false) - driver stays online
    
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(
        pendingRequests: const [],
      ));
    }
  }

  /// Driver declines — add to local declined list; booking stays pending for others.
  Future<void> _onDeclineRequest(
    DriverRequestDeclined event,
    Emitter<DriverState> emit,
  ) async {
    if (state is DriverLoaded) {
      final cur = state as DriverLoaded;
      if (!cur.declinedIds.contains(event.bookingId)) {
        emit(cur.copyWith(declinedIds: [...cur.declinedIds, event.bookingId]));
      }
    }
  }

  @override
  Future<void> close() {
    _locationTimer?.cancel();
    return super.close();
  }
}
