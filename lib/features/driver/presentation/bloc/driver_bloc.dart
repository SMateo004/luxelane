import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:rxdart/rxdart.dart';

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
  const _DriverLocationTick(
      {required this.userId, required this.lat, required this.lng});
  final String userId;
  final double lat;
  final double lng;
  @override
  List<Object?> get props => [userId, lat, lng];
}

class _DriverLocationDenied extends DriverEvent {
  const _DriverLocationDenied();
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

/// Sigue el perfil en Firestore: el servidor cambia `isAvailable` al aceptar
/// y al cerrar un viaje.
class DriverProfileWatched extends DriverEvent {
  const DriverProfileWatched({required this.driverId});
  final String driverId;
  @override
  List<Object?> get props => [driverId];
}

/// La sesión terminó: se detiene el rastreo y se vuelve al estado inicial.
class DriverStopped extends DriverEvent {
  const DriverStopped();
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
    this.vehicleClass,
    this.notice,
    this.noticeSeq = 0,
  });

  final User user;
  final DriverProfile profile;
  final bool isAvailable;
  final List<Booking> bookings;
  final bool isTracking;

  /// Solicitudes abiertas (sin datos personales) que ve el chófer
  /// verificado.
  final List<OpenRequest> pendingRequests;

  /// IDs of pending bookings this driver has explicitly declined this session.
  final List<String> declinedIds;

  /// Clase del vehículo del chófer (de `vehicles`); sin vehículo, ninguna.
  final VehicleClass? vehicleClass;

  /// Aviso puntual para la pantalla (p. ej. "otro chófer ya aceptó").
  /// [noticeSeq] sube con cada aviso para que se muestre aunque se repita.
  final String? notice;
  final int noticeSeq;

  /// Solicitudes que este chófer puede atender: de su clase de vehículo y
  /// sin descartar.
  /// Una que el chófer acaba de aceptar ya está en [bookings] aunque el
  /// servidor aún no la haya retirado.
  List<OpenRequest> get matchingRequests => pendingRequests
      .where((r) =>
          !declinedIds.contains(r.id) &&
          !bookings.any((b) => b.id == r.id) &&
          vehicleClass != null &&
          r.vehicleClass == vehicleClass)
      .toList();

  /// Puede aceptar viajes: conectado, verificado y sin otro viaje en curso.
  bool get canAccept =>
      isAvailable && profile.documentsVerified && activeBooking == null;

  /// The next pending booking the driver can take.
  OpenRequest? get currentRequest {
    if (!canAccept) return null;
    final list = matchingRequests;
    return list.isEmpty ? null : list.first;
  }

  /// Viajes completados hoy (por la hora de recogida).
  List<Booking> get completedToday {
    final now = DateTime.now();
    return completedBookings
        .where((b) =>
            b.scheduledAt.year == now.year &&
            b.scheduledAt.month == now.month &&
            b.scheduledAt.day == now.day)
        .toList();
  }

  double get todayEarnings {
    final total =
        completedToday.fold(0.0, (s, b) => s + earningsOf(b).driverPayout);
    return (total * 100).roundToDouble() / 100;
  }

  /// El viaje que ocupa ahora al chófer (en curso o con recogida próxima).
  Booking? get activeBooking {
    for (final b in bookings) {
      if (b.occupiesDriver()) return b;
    }
    return null;
  }

  /// Viaje en el que el pasajero sigue al chófer en el mapa: de camino a la
  /// recogida hasta el final del trayecto.
  Booking? get liveBooking {
    for (final b in bookings) {
      if (b.status == BookingStatus.driverArriving ||
          b.status == BookingStatus.driverArrived ||
          b.status == BookingStatus.inProgress) {
        return b;
      }
    }
    return null;
  }

  List<Booking> get completedBookings =>
      bookings.where((b) => b.status == BookingStatus.completed).toList();

  /// Reparto de un viaje: el fijado por el servidor al completarlo o, si aún
  /// no existe, uno provisional con la comisión por defecto.
  /// Un viaje reembolsado no deja ganancias.
  BookingSettlement earningsOf(Booking b) => b.refunded
      ? const BookingSettlement(
          amount: 0, commissionPct: 0, platformCommission: 0, driverPayout: 0)
      : b.settlementOr(kDefaultCommissionPct);

  /// Ganancias netas del chófer (tarifa menos comisión de la plataforma).
  double get totalEarnings => _sum((s) => s.driverPayout);

  /// Total facturado a los pasajeros por sus viajes.
  double get grossEarnings => _sum((s) => s.amount);

  double get totalCommission => _sum((s) => s.platformCommission);

  /// Algún viaje aún sin reparto confirmado por el servidor.
  bool get hasProvisionalEarnings =>
      completedBookings.any((b) => b.settlement == null && !b.refunded);

  double _sum(double Function(BookingSettlement) f) {
    final total = completedBookings.fold(0.0, (s, b) => s + f(earningsOf(b)));
    return (total * 100).roundToDouble() / 100;
  }

  @override
  List<Object?> get props => [
        user,
        profile,
        isAvailable,
        bookings,
        isTracking,
        pendingRequests,
        declinedIds,
        vehicleClass,
        notice,
        noticeSeq,
      ];

  DriverLoaded copyWith({
    User? user,
    DriverProfile? profile,
    bool? isAvailable,
    List<Booking>? bookings,
    bool? isTracking,
    List<OpenRequest>? pendingRequests,
    List<String>? declinedIds,
    String? notice,
  }) =>
      DriverLoaded(
        user: user ?? this.user,
        profile: profile ?? this.profile,
        isAvailable: isAvailable ?? this.isAvailable,
        bookings: bookings ?? this.bookings,
        isTracking: isTracking ?? this.isTracking,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        declinedIds: declinedIds ?? this.declinedIds,
        vehicleClass: vehicleClass,
        notice: notice,
        noticeSeq: notice != null ? noticeSeq + 1 : noticeSeq,
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
    on<DriverBookingsWatched>(_onWatchBookings, transformer: _latest());
    on<DriverPendingBookingsWatched>(_onWatchPending, transformer: _latest());
    on<DriverAvailabilityToggled>(_onToggleAvailability);
    on<DriverLocationTrackingStarted>(_onStartTracking);
    on<DriverLocationTrackingStopped>(_onStopTracking);
    on<_DriverLocationTick>(_onLocationTick);
    on<_DriverLocationDenied>(_onLocationDenied);
    on<DriverBookingAccepted>(_onAccept);
    on<DriverArrivedAtPickup>(_onArrived);
    on<DriverTripStarted>(_onStartTrip);
    on<DriverTripCompleted>(_onCompleteTrip);
    on<DriverRequestAccepted>(_onAcceptRequest);
    on<DriverRequestDeclined>(_onDeclineRequest);
    on<DriverProfileWatched>(_onWatchProfile, transformer: _latest());
    on<DriverStopped>(_onStopped);
  }

  /// Un único listener por stream aunque DriverStarted se repita.
  static EventTransformer<E> _latest<E>() =>
      (events, mapper) => events.switchMap(mapper);

  final BookingRepository _bookingRepo;
  final UserRepository _userRepo;
  final VehicleRepository _vehicleRepo;
  final MapsService _mapsService;
  StreamSubscription<Position>? _positionSub;

  // ── Startup ───────────────────────────────────────────────────────────────

  Future<void> _onStart(DriverStarted event, Emitter<DriverState> emit) async {
    try {
      final userResult = await _userRepo.getUserById(event.userId);
      final user = userResult.fold((f) => null, (u) => u);

      if (user == null || user.role != UserRole.driver) {
        emit(const DriverError(
            'Esta cuenta aún no está habilitada como chófer. Luxelane la '
            'activa después de revisar tu solicitud.'));
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

      final vehicle = (await _vehicleRepo.getVehicleByDriver(event.userId))
          .fold((_) => null, (v) => v);

      emit(DriverLoaded(
        user: user,
        profile: profile,
        isAvailable: profile.isAvailable,
        bookings: const [],
        vehicleClass: vehicle?.isActive == true ? vehicle!.vehicleClass : null,
      ));

      add(DriverBookingsWatched(driverId: event.userId));
      // Las solicitudes solo se leen verificado y con la cuenta activa (las
      // reglas lo exigen).
      if (profile.documentsVerified && user.isActive) {
        add(const DriverPendingBookingsWatched());
      }
      add(DriverProfileWatched(driverId: event.userId));
      if (profile.isAvailable) {
        add(DriverLocationTrackingStarted(userId: event.userId));
      }
    } catch (e) {
      emit(const DriverError(
          'No pudimos cargar tu cuenta. Revisa tu conexión e inténtalo de '
          'nuevo.'));
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
        final next = (state as DriverLoaded).copyWith(bookings: bookings);
        // Con un viaje en curso la ubicación se comparte aunque el chófer
        // figure como ocupado.
        if (next.activeBooking != null && !next.isTracking) {
          add(DriverLocationTrackingStarted(userId: event.driverId));
        } else if (next.activeBooking == null &&
            !next.isAvailable &&
            next.isTracking) {
          // Terminó el viaje y el chófer está desconectado.
          add(const DriverLocationTrackingStopped());
        }
        return next;
      },
      // Tras cerrar sesión el listener falla por permisos: se ignora.
      onError: (e, _) => state is DriverLoaded
          ? (state as DriverLoaded)
              .copyWith(notice: 'No se pudieron cargar tus viajes.')
          : state,
    );
  }

  Future<void> _onWatchProfile(
    DriverProfileWatched event,
    Emitter<DriverState> emit,
  ) async {
    await emit.forEach<DriverProfile?>(
      _userRepo.watchDriverProfile(event.driverId),
      onData: (profile) {
        if (state is! DriverLoaded || profile == null) return state;
        final cur = state as DriverLoaded;
        // Recién verificado por el admin: empieza a ver solicitudes.
        if (profile.documentsVerified &&
            !cur.profile.documentsVerified &&
            cur.user.isActive) {
          add(const DriverPendingBookingsWatched());
        }
        return cur.copyWith(profile: profile, isAvailable: profile.isAvailable);
      },
      onError: (_, __) => state,
    );
  }

  /// Watches pending bookings (the driver's class is filtered in the state).
  Future<void> _onWatchPending(
    DriverPendingBookingsWatched event,
    Emitter<DriverState> emit,
  ) async {
    await emit.forEach<List<OpenRequest>>(
      _bookingRepo.streamOpenRequests(),
      onData: (pending) {
        if (state is! DriverLoaded) return state;
        return (state as DriverLoaded).copyWith(pendingRequests: pending);
      },
      onError: (_, __) => state is DriverLoaded
          ? (state as DriverLoaded).copyWith(
              notice: 'No se pudieron cargar las solicitudes de viaje.')
          : state,
    );
  }

  // ── Availability & location ───────────────────────────────────────────────

  Future<void> _onToggleAvailability(
    DriverAvailabilityToggled event,
    Emitter<DriverState> emit,
  ) async {
    if (state is DriverLoaded &&
        event.isAvailable &&
        (state as DriverLoaded).activeBooking != null) {
      emit((state as DriverLoaded)
          .copyWith(notice: 'Termina tu viaje actual antes de conectarte.'));
      return;
    }
    final result = await _userRepo.setDriverAvailability(
      userId: event.userId,
      isAvailable: event.isAvailable,
    );
    if (result.isLeft()) {
      if (state is DriverLoaded) {
        emit((state as DriverLoaded)
            .copyWith(notice: 'No se pudo cambiar tu estado. Reintenta.'));
      }
      return;
    }
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(isAvailable: event.isAvailable));
    }
    if (event.isAvailable) {
      add(DriverLocationTrackingStarted(userId: event.userId));
    } else if (state is! DriverLoaded ||
        (state as DriverLoaded).activeBooking == null) {
      // Con un viaje en curso se sigue compartiendo hasta terminarlo.
      add(const DriverLocationTrackingStopped());
    }
  }

  Future<void> _onStartTracking(
    DriverLocationTrackingStarted event,
    Emitter<DriverState> emit,
  ) async {
    await _positionSub?.cancel();
    DateTime? lastSent;
    // Flujo continuo (también con la app minimizada); se escribe como mucho
    // cada 10 s para no gastar batería ni escrituras.
    _positionSub = _mapsService.driverPositionStream().listen(
      (pos) {
        final now = DateTime.now();
        if (lastSent != null &&
            now.difference(lastSent!) < const Duration(seconds: 10)) {
          return;
        }
        lastSent = now;
        add(_DriverLocationTick(
            userId: event.userId, lat: pos.latitude, lng: pos.longitude));
      },
      onError: (_) => add(const _DriverLocationDenied()),
      cancelOnError: true,
    );
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(isTracking: true));
    }
  }

  Future<void> _onStopTracking(
    DriverLocationTrackingStopped event,
    Emitter<DriverState> emit,
  ) async {
    await _positionSub?.cancel();
    _positionSub = null;
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(isTracking: false));
    }
  }

  Future<void> _onLocationTick(
    _DriverLocationTick event,
    Emitter<DriverState> emit,
  ) async {
    await _userRepo.updateDriverLocation(
      userId: event.userId,
      latitude: event.lat,
      longitude: event.lng,
    );
    // El pasajero ve la posición en su reserva, no en el perfil del chófer.
    final live =
        state is DriverLoaded ? (state as DriverLoaded).liveBooking : null;
    if (live != null) {
      try {
        await _bookingRepo.publishDriverLocation(
          bookingId: live.id,
          latitude: event.lat,
          longitude: event.lng,
        );
      } catch (_) {}
    }
  }

  void _onLocationDenied(
      _DriverLocationDenied event, Emitter<DriverState> emit) {
    _positionSub = null;
    if (state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(
        isTracking: false,
        notice: 'Activa la ubicación para recibir viajes y que el pasajero '
            'vea dónde estás.',
      ));
    }
  }

  // ── Ride progression ──────────────────────────────────────────────────────

  Future<void> _onAccept(
    DriverBookingAccepted event,
    Emitter<DriverState> emit,
  ) async {
    await _advance(emit, event.bookingId, BookingStatus.driverArriving);
    // Sale a buscar al pasajero: deja de recibir otros viajes (el servidor
    // lo libera al cerrar este). Solo `isAvailable`: sigue `online`.
    if (state is DriverLoaded) {
      try {
        await _userRepo.markDriverBusy((state as DriverLoaded).user.id);
      } catch (_) {}
    }
  }

  Future<void> _onArrived(
    DriverArrivedAtPickup event,
    Emitter<DriverState> emit,
  ) async {
    await _advance(emit, event.bookingId, BookingStatus.driverArrived);
  }

  Future<void> _onStartTrip(
    DriverTripStarted event,
    Emitter<DriverState> emit,
  ) async {
    await _advance(emit, event.bookingId, BookingStatus.inProgress);
  }

  Future<void> _onCompleteTrip(
    DriverTripCompleted event,
    Emitter<DriverState> emit,
  ) async {
    await _advance(emit, event.bookingId, BookingStatus.completed);
  }

  Future<void> _advance(
      Emitter<DriverState> emit, String bookingId, BookingStatus to) async {
    final result = await _bookingRepo.updateBookingStatus(
        bookingId: bookingId, status: to);
    if (result.isLeft() && state is DriverLoaded) {
      emit((state as DriverLoaded).copyWith(
          notice: 'No se pudo actualizar el viaje. Puede que lo haya '
              'cancelado el pasajero; revisa tu conexión.'));
    }
  }

  // ── Incoming request ──────────────────────────────────────────────────────

  /// Driver accepts a pending booking — assigns themselves and sets confirmed.
  Future<void> _onAcceptRequest(
    DriverRequestAccepted event,
    Emitter<DriverState> emit,
  ) async {
    // La transacción comprueba que siga pendiente y que el chófer esté
    // verificado y libre, y lo marca ocupado hasta cerrar el viaje.
    final result = await _bookingRepo.assignDriver(
      bookingId: event.bookingId,
      driverId: event.driverId,
    );
    if (state is! DriverLoaded) return;
    final cur = state as DriverLoaded;
    result.fold(
      (f) => emit(cur.copyWith(
        declinedIds: [...cur.declinedIds, event.bookingId],
        notice: f.message,
      )),
      (_) => emit(cur.copyWith(notice: 'Viaje aceptado')),
    );
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

  Future<void> _onStopped(
      DriverStopped event, Emitter<DriverState> emit) async {
    await _positionSub?.cancel();
    _positionSub = null;
    emit(const DriverInitial());
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    return super.close();
  }
}
