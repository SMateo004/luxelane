import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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

/// El chófer cierra sesión: se desconecta y se para todo.
class DriverSignedOut extends DriverEvent {
  const DriverSignedOut();
}

class _DriverProfileChanged extends DriverEvent {
  const _DriverProfileChanged(this.profile);
  final DriverProfile profile;
  @override
  List<Object?> get props => [profile];
}

class _DriverBookingsChanged extends DriverEvent {
  const _DriverBookingsChanged(this.bookings);
  final List<Booking> bookings;
  @override
  List<Object?> get props => [bookings];
}

class _DriverPendingChanged extends DriverEvent {
  const _DriverPendingChanged(this.pending);
  final List<Booking> pending;
  @override
  List<Object?> get props => [pending];
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
    this.vehicle,
    this.isTracking = false,
    this.pendingRequests = const [],
    this.declinedIds = const [],
    this.accepting = false,
    this.notice,
    this.noticeSeq = 0,
  });

  final User user;
  final DriverProfile profile;
  final Vehicle? vehicle;
  final bool isAvailable;
  final List<Booking> bookings;
  final bool isTracking;

  /// Reservas pendientes que el chófer puede leer (todas las clases).
  final List<Booking> pendingRequests;

  /// Solicitudes que el chófer rechazó en esta sesión.
  final List<String> declinedIds;

  /// Hay una aceptación en curso: evita dobles toques.
  final bool accepting;

  /// Aviso para el chófer (SnackBar). [noticeSeq] cambia con cada aviso para
  /// que la pantalla lo muestre una sola vez aunque el texto se repita.
  final String? notice;
  final int noticeSeq;

  /// Documentos verificados por un administrador y cuenta activa.
  bool get canWork => profile.documentsVerified && user.isActive;

  /// Conectado o en un viaje (el servidor marca ocupado al aceptar).
  bool get isOnline => isAvailable || activeBooking != null;

  VehicleClass? get vehicleClass => vehicle?.vehicleClass ?? user.vehicleClass;

  /// Solicitudes que este chófer puede aceptar ahora mismo: de la clase de su
  /// vehículo, no rechazadas y solo si está libre.
  List<Booking> get eligibleRequests {
    if (!canWork || !isAvailable || activeBooking != null) return const [];
    final vClass = vehicleClass;
    return pendingRequests
        .where((b) =>
            !declinedIds.contains(b.id) &&
            (vClass == null || b.vehicleClass == vClass))
        .toList();
  }

  /// La siguiente solicitud a mostrar.
  Booking? get currentRequest {
    final list = eligibleRequests;
    return list.isEmpty ? null : list.first;
  }

  Booking? get activeBooking {
    const active = {
      BookingStatus.confirmed,
      BookingStatus.driverArriving,
      BookingStatus.driverArrived,
      BookingStatus.inProgress,
    };
    for (final b in bookings) {
      if (active.contains(b.status)) return b;
    }
    return null;
  }

  List<Booking> get completedBookings =>
      bookings.where((b) => b.status == BookingStatus.completed).toList();

  /// Viajes completados hoy (hora local).
  List<Booking> get completedToday {
    final now = DateTime.now();
    return completedBookings.where((b) {
      final d = b.updatedAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  /// Reparto de un viaje: el fijado por el servidor al completarlo o, si aún
  /// no existe, uno provisional con la comisión por defecto.
  BookingSettlement earningsOf(Booking b) =>
      b.settlementOr(kDefaultCommissionPct);

  /// Ganancias netas del chófer (tarifa menos comisión de la plataforma).
  double get totalEarnings => _sum(completedBookings, (s) => s.driverPayout);

  /// Ganancias netas de hoy.
  double get todayEarnings => _sum(completedToday, (s) => s.driverPayout);

  /// Total facturado a los pasajeros por sus viajes.
  double get grossEarnings => _sum(completedBookings, (s) => s.amount);

  double get totalCommission =>
      _sum(completedBookings, (s) => s.platformCommission);

  /// Algún viaje aún sin reparto confirmado por el servidor.
  bool get hasProvisionalEarnings =>
      completedBookings.any((b) => b.settlement == null);

  double _sum(List<Booking> list, double Function(BookingSettlement) f) {
    final total = list.fold(0.0, (s, b) => s + f(earningsOf(b)));
    return (total * 100).roundToDouble() / 100;
  }

  @override
  List<Object?> get props => [
        user,
        profile,
        vehicle,
        isAvailable,
        bookings,
        isTracking,
        pendingRequests,
        declinedIds,
        accepting,
        notice,
        noticeSeq,
      ];

  DriverLoaded copyWith({
    User? user,
    DriverProfile? profile,
    Vehicle? vehicle,
    bool? isAvailable,
    List<Booking>? bookings,
    bool? isTracking,
    List<Booking>? pendingRequests,
    List<String>? declinedIds,
    bool? accepting,
  }) =>
      DriverLoaded(
        user: user ?? this.user,
        profile: profile ?? this.profile,
        vehicle: vehicle ?? this.vehicle,
        isAvailable: isAvailable ?? this.isAvailable,
        bookings: bookings ?? this.bookings,
        isTracking: isTracking ?? this.isTracking,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        declinedIds: declinedIds ?? this.declinedIds,
        accepting: accepting ?? this.accepting,
        notice: notice,
        noticeSeq: noticeSeq,
      );

  DriverLoaded withNotice(String message) => DriverLoaded(
        user: user,
        profile: profile,
        vehicle: vehicle,
        isAvailable: isAvailable,
        bookings: bookings,
        isTracking: isTracking,
        pendingRequests: pendingRequests,
        declinedIds: declinedIds,
        accepting: accepting,
        notice: message,
        noticeSeq: noticeSeq + 1,
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
    on<DriverBookingAccepted>(
        (e, emit) => _step(e.bookingId, BookingStatus.driverArriving, emit));
    on<DriverArrivedAtPickup>(
        (e, emit) => _step(e.bookingId, BookingStatus.driverArrived, emit));
    on<DriverTripStarted>(
        (e, emit) => _step(e.bookingId, BookingStatus.inProgress, emit));
    on<DriverTripCompleted>(
        (e, emit) => _step(e.bookingId, BookingStatus.completed, emit));
    on<DriverRequestAccepted>(_onAcceptRequest);
    on<DriverRequestDeclined>(_onDeclineRequest);
    on<DriverSignedOut>(_onSignedOut);
    on<_DriverProfileChanged>(_onProfileChanged);
    on<_DriverBookingsChanged>(_onBookingsChanged);
    on<_DriverPendingChanged>(_onPendingChanged);
  }

  final BookingRepository _bookingRepo;
  final UserRepository _userRepo;
  final VehicleRepository _vehicleRepo;
  final MapsService _mapsService;

  Timer? _locationTimer;
  StreamSubscription<DriverProfile?>? _profileSub;
  StreamSubscription<List<Booking>>? _bookingsSub;
  StreamSubscription<List<Booking>>? _pendingSub;
  String? _userId;

  DriverLoaded? get _loaded =>
      state is DriverLoaded ? state as DriverLoaded : null;

  // ── Startup ───────────────────────────────────────────────────────────────

  Future<void> _onStart(DriverStarted event, Emitter<DriverState> emit) async {
    await _cancelAll();
    _userId = event.userId;
    try {
      final user = (await _userRepo.getUserById(event.userId))
          .fold((_) => null, (u) => u);
      if (user == null) {
        emit(const DriverError(
            'No pudimos cargar tu cuenta. Revisa tu conexión e inténtalo de nuevo.'));
        return;
      }
      if (user.role != UserRole.driver) {
        emit(const DriverError(
            'Esta app es solo para chóferes de Luxelane. Usa la app de pasajero.'));
        return;
      }
      if (!user.isActive) {
        emit(const DriverError(
            'Tu cuenta está suspendida. Contacta con soporte de Luxelane.'));
        return;
      }

      final profile = (await _userRepo.getDriverProfile(event.userId))
          .fold((_) => null, (p) => p);
      if (profile == null || profile.licenseNumber.isEmpty) {
        emit(const DriverOnboardingRequired());
        return;
      }

      final vehicle = (await _vehicleRepo.getVehicleByDriver(event.userId))
          .fold((_) => null, (v) => v);

      emit(DriverLoaded(
        user: user,
        profile: profile,
        vehicle: vehicle,
        isAvailable: profile.isAvailable && profile.documentsVerified,
        bookings: const [],
      ));

      _profileSub = _userRepo.watchDriverProfile(event.userId).listen(
        (p) {
          if (p != null) add(_DriverProfileChanged(p));
        },
        onError: (Object e) => debugPrint('[Driver] perfil: $e'),
      );
      add(DriverBookingsWatched(driverId: event.userId));
      add(const DriverPendingBookingsWatched());
      _syncTracking(emit);
    } catch (e) {
      debugPrint('[Driver] arranque: $e');
      emit(const DriverError(
          'No pudimos cargar tu cuenta. Revisa tu conexión e inténtalo de nuevo.'));
    }
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Reservas asignadas a este chófer (confirmadas, en curso y completadas).
  Future<void> _onWatchBookings(
    DriverBookingsWatched event,
    Emitter<DriverState> emit,
  ) async {
    await _bookingsSub?.cancel();
    _bookingsSub = _bookingRepo.watchDriverBookings(event.driverId).listen(
          (b) => add(_DriverBookingsChanged(b)),
          onError: (Object e) => debugPrint('[Driver] viajes: $e'),
        );
  }

  /// Solicitudes pendientes. Las reglas solo dejan leerlas a un chófer
  /// verificado y activo, así que no se escucha hasta que lo esté.
  Future<void> _onWatchPending(
    DriverPendingBookingsWatched event,
    Emitter<DriverState> emit,
  ) async {
    final cur = _loaded;
    if (cur == null || !cur.canWork) return;
    await _pendingSub?.cancel();
    _pendingSub = _bookingRepo.streamPendingBookings().listen(
      (p) => add(_DriverPendingChanged(p)),
      onError: (Object e) {
        debugPrint('[Driver] solicitudes: $e');
        _pendingSub = null;
      },
    );
  }

  void _onBookingsChanged(
      _DriverBookingsChanged event, Emitter<DriverState> emit) {
    final cur = _loaded;
    if (cur == null) return;
    emit(cur.copyWith(bookings: event.bookings));
    _syncTracking(emit);
  }

  void _onPendingChanged(
      _DriverPendingChanged event, Emitter<DriverState> emit) {
    final cur = _loaded;
    if (cur == null) return;
    // Solo las que siguen sin chófer; las rechazadas que ya no existen se
    // olvidan para que la lista no crezca sin límite.
    final pending = event.pending
        .where((b) => b.driverId == null || b.driverId!.isEmpty)
        .toList();
    final ids = pending.map((b) => b.id).toSet();
    emit(cur.copyWith(
      pendingRequests: pending,
      declinedIds: cur.declinedIds.where(ids.contains).toList(),
    ));
  }

  void _onProfileChanged(
      _DriverProfileChanged event, Emitter<DriverState> emit) {
    final cur = _loaded;
    if (cur == null) return;
    final wasVerified = cur.profile.documentsVerified;
    final next = cur.copyWith(
      profile: event.profile,
      isAvailable: event.profile.isAvailable && event.profile.documentsVerified,
    );
    if (!wasVerified && event.profile.documentsVerified) {
      emit(next.withNotice(
          'Tu cuenta fue verificada. Ya puedes conectarte y recibir viajes.'));
      add(const DriverPendingBookingsWatched());
    } else {
      emit(next);
      if (_pendingSub == null && next.canWork) {
        add(const DriverPendingBookingsWatched());
      }
    }
    _syncTracking(emit);
  }

  // ── Availability & location ───────────────────────────────────────────────

  Future<void> _onToggleAvailability(
    DriverAvailabilityToggled event,
    Emitter<DriverState> emit,
  ) async {
    final cur = _loaded;
    if (cur == null) return;

    if (!event.isAvailable && cur.activeBooking != null) {
      emit(cur.withNotice('Termina el viaje en curso antes de desconectarte.'));
      return;
    }
    if (event.isAvailable && !cur.canWork) {
      emit(cur.withNotice(cur.user.isActive
          ? 'Tu cuenta está pendiente de verificación. Te avisaremos cuando '
              'un administrador revise tus documentos.'
          : 'Tu cuenta está suspendida. Contacta con soporte de Luxelane.'));
      return;
    }
    if (event.isAvailable && cur.activeBooking != null) return;

    emit(cur.copyWith(isAvailable: event.isAvailable));
    _syncTracking(emit);
    final result = await _userRepo.setDriverAvailability(
      userId: event.userId,
      isAvailable: event.isAvailable,
    );
    result.fold((_) {
      final now = _loaded;
      if (now == null) return;
      emit(now.copyWith(isAvailable: !event.isAvailable).withNotice(
          event.isAvailable
              ? 'No pudimos conectarte. Revisa tu conexión.'
              : 'No pudimos desconectarte. Revisa tu conexión.'));
      _syncTracking(emit);
    }, (_) {
      // Primera posición al conectarse, sin esperar al temporizador.
      if (event.isAvailable) add(_DriverLocationTick(userId: event.userId));
    });
  }

  /// La ubicación se comparte mientras el chófer está conectado o en un
  /// viaje (el pasajero sigue al coche aunque el servidor lo marque ocupado).
  void _syncTracking(Emitter<DriverState> emit) {
    final cur = _loaded;
    if (cur == null) return;
    final uid = cur.user.id;
    final shouldTrack = cur.isOnline;
    if (shouldTrack && _locationTimer == null) {
      _locationTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => add(_DriverLocationTick(userId: uid)),
      );
    } else if (!shouldTrack && _locationTimer != null) {
      _locationTimer?.cancel();
      _locationTimer = null;
    }
    if (cur.isTracking != shouldTrack) {
      emit(cur.copyWith(isTracking: shouldTrack));
    }
  }

  Future<void> _onStartTracking(
    DriverLocationTrackingStarted event,
    Emitter<DriverState> emit,
  ) async {
    _userId ??= event.userId;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => add(_DriverLocationTick(userId: event.userId)),
    );
    final cur = _loaded;
    if (cur != null) emit(cur.copyWith(isTracking: true));
  }

  Future<void> _onStopTracking(
    DriverLocationTrackingStopped event,
    Emitter<DriverState> emit,
  ) async {
    _locationTimer?.cancel();
    _locationTimer = null;
    final cur = _loaded;
    if (cur != null) emit(cur.copyWith(isTracking: false));
  }

  Future<void> _onLocationTick(
    _DriverLocationTick event,
    Emitter<DriverState> emit,
  ) async {
    try {
      final pos = await _mapsService.getCurrentPosition();
      if (pos == null) return;
      await _userRepo.updateDriverLocation(
        userId: event.userId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (e) {
      debugPrint('[Driver] ubicación: $e');
    }
  }

  // ── Ride progression ──────────────────────────────────────────────────────

  static const _stepErrors = {
    BookingStatus.driverArriving: 'No pudimos marcar que vas en camino.',
    BookingStatus.driverArrived: 'No pudimos marcar tu llegada.',
    BookingStatus.inProgress: 'No pudimos iniciar el viaje.',
    BookingStatus.completed: 'No pudimos finalizar el viaje.',
  };

  Future<void> _step(
    String bookingId,
    BookingStatus to,
    Emitter<DriverState> emit,
  ) async {
    final result = await _bookingRepo.updateBookingStatus(
        bookingId: bookingId, status: to);
    result.fold((_) {
      final cur = _loaded;
      if (cur == null) return;
      // Si el pasajero canceló mientras tanto, la regla lo rechaza.
      final booking = cur.bookings.where((b) => b.id == bookingId).firstOrNull;
      emit(cur.withNotice(booking?.status == BookingStatus.cancelled
          ? 'El pasajero canceló este viaje.'
          : '${_stepErrors[to] ?? 'No se pudo actualizar el viaje.'} '
              'Revisa tu conexión e inténtalo de nuevo.'));
    }, (_) {});
  }

  // ── Incoming request ──────────────────────────────────────────────────────

  /// El chófer acepta una solicitud. Lo resuelve el servidor en una
  /// transacción: si otro chófer la tomó antes, se avisa y se pasa a la
  /// siguiente.
  Future<void> _onAcceptRequest(
    DriverRequestAccepted event,
    Emitter<DriverState> emit,
  ) async {
    final cur = _loaded;
    if (cur == null || cur.accepting) return;
    if (cur.activeBooking != null) {
      emit(cur.withNotice('Termina el viaje en curso antes de aceptar otro.'));
      return;
    }
    if (!cur.canWork) {
      emit(cur.withNotice(
          'Tu cuenta está pendiente de verificación. Aún no puedes aceptar viajes.'));
      return;
    }

    emit(cur.copyWith(accepting: true));
    final result = await _bookingRepo.acceptBooking(event.bookingId);
    final now = _loaded;
    if (now == null) return;
    final done = now.copyWith(accepting: false);

    result.fold(
      (f) => emit(done.withNotice(f.message)),
      (outcome) {
        switch (outcome) {
          case AcceptOutcome.accepted:
            emit(done
                .copyWith(
                  pendingRequests: done.pendingRequests
                      .where((b) => b.id != event.bookingId)
                      .toList(),
                )
                .withNotice('Viaje aceptado. Dirígete al punto de recogida.'));
          case AcceptOutcome.alreadyTaken:
            emit(done.copyWith(declinedIds: [
              ...done.declinedIds,
              event.bookingId
            ]).withNotice(
                'Otro chófer tomó este viaje o el pasajero lo canceló.'));
          case AcceptOutcome.driverBusy:
            emit(done.withNotice(
                'Conéctate (y termina tu viaje en curso) para aceptar viajes.'));
          case AcceptOutcome.notVerified:
            emit(done.withNotice(
                'Tu cuenta está pendiente de verificación. Aún no puedes aceptar viajes.'));
          case AcceptOutcome.wrongClass:
            emit(done.copyWith(declinedIds: [
              ...done.declinedIds,
              event.bookingId
            ]).withNotice('Este viaje es para otra clase de vehículo.'));
          case AcceptOutcome.notAllowed:
            emit(done.withNotice(
                'Tu cuenta o tu vehículo no están habilitados. Contacta con soporte.'));
        }
      },
    );
  }

  /// Rechazo local: la solicitud sigue disponible para otros chóferes.
  Future<void> _onDeclineRequest(
    DriverRequestDeclined event,
    Emitter<DriverState> emit,
  ) async {
    final cur = _loaded;
    if (cur != null && !cur.declinedIds.contains(event.bookingId)) {
      emit(cur.copyWith(declinedIds: [...cur.declinedIds, event.bookingId]));
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> _onSignedOut(
    DriverSignedOut event,
    Emitter<DriverState> emit,
  ) async {
    final cur = _loaded;
    final uid = _userId ?? cur?.user.id;
    await _cancelAll();
    _userId = null;
    // Se desconecta para no recibir viajes con la sesión cerrada (el
    // servidor además ignora chóferes sin señal reciente).
    if (cur != null && uid != null && cur.isAvailable) {
      try {
        await _userRepo.setDriverAvailability(userId: uid, isAvailable: false);
      } catch (_) {}
    }
    emit(const DriverInitial());
  }

  Future<void> _cancelAll() async {
    _locationTimer?.cancel();
    _locationTimer = null;
    await _profileSub?.cancel();
    await _bookingsSub?.cancel();
    await _pendingSub?.cancel();
    _profileSub = null;
    _bookingsSub = null;
    _pendingSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelAll();
    return super.close();
  }
}
