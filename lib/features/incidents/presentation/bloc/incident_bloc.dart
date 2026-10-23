import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

typedef LatLngLite = ({double lat, double lng});

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class IncidentEvent extends Equatable {
  const IncidentEvent();
  @override
  List<Object?> get props => [];
}

/// Empieza a seguir el incidente propio de la reserva.
class IncidentWatched extends IncidentEvent {
  const IncidentWatched();
}

/// Mantener pulsado (o confirmar) SOS.
class IncidentRaised extends IncidentEvent {
  const IncidentRaised();
}

/// Falsa alarma, con confirmación previa en la pantalla.
class IncidentCancelled extends IncidentEvent {
  const IncidentCancelled();
}

class _IncidentChanged extends IncidentEvent {
  const _IncidentChanged(this.incident);
  final Incident? incident;
  @override
  List<Object?> get props => [incident?.id, incident?.status, incident?.count];
}

class _IncidentLocationTick extends IncidentEvent {
  const _IncidentLocationTick();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class IncidentState extends Equatable {
  const IncidentState({
    this.incident,
    this.sending = false,
    this.failure,
    this.lastLocation,
    this.presses = 0,
  });

  /// El incidente propio más reciente de la reserva, si hay.
  final Incident? incident;
  final bool sending;

  /// Último intento fallido; con [IncidentIssue.offline] la pantalla ofrece
  /// llamar o enviar SMS a central.
  final IncidentFailure? failure;

  /// Para el SMS de respaldo: la última ubicación que se obtuvo.
  final LatLngLite? lastLocation;

  /// Veces que se pulsó en esta pantalla (para el texto «enviado N veces»).
  final int presses;

  bool get live => incident?.isLive == true;
  bool get offline => failure?.issue == IncidentIssue.offline;

  IncidentState copyWith({
    Incident? incident,
    bool clearIncident = false,
    bool? sending,
    IncidentFailure? failure,
    bool clearFailure = false,
    LatLngLite? lastLocation,
    int? presses,
  }) =>
      IncidentState(
        incident: clearIncident ? null : incident ?? this.incident,
        sending: sending ?? this.sending,
        failure: clearFailure ? null : failure ?? this.failure,
        lastLocation: lastLocation ?? this.lastLocation,
        presses: presses ?? this.presses,
      );

  @override
  List<Object?> get props => [
        incident?.id,
        incident?.status,
        incident?.count,
        sending,
        failure?.issue,
        lastLocation,
        presses,
      ];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class IncidentBloc extends Bloc<IncidentEvent, IncidentState> {
  IncidentBloc({
    required IncidentRepository repository,
    required this.bookingId,
    required this.uid,
    Future<LatLngLite?> Function()? currentLocation,
    this.publishEvery = const Duration(seconds: 10),
  })  : _repo = repository,
        _currentLocation = currentLocation ?? (() async => null),
        super(const IncidentState()) {
    on<IncidentWatched>(_onWatched);
    on<IncidentRaised>(_onRaised);
    on<IncidentCancelled>(_onCancelled);
    on<_IncidentChanged>(_onChanged);
    on<_IncidentLocationTick>(_onTick);
  }

  final IncidentRepository _repo;
  final String bookingId;
  final String uid;
  final Future<LatLngLite?> Function() _currentLocation;

  /// Igual que el tramo que exigen las reglas: una ubicación cada 10 s.
  final Duration publishEvery;

  StreamSubscription<Incident?>? _sub;
  Timer? _timer;

  Future<void> _onWatched(
      IncidentWatched event, Emitter<IncidentState> emit) async {
    await _sub?.cancel();
    _sub = _repo.watchMine(bookingId, uid).listen(
          (i) => add(_IncidentChanged(i)),
          onError: (_) {},
        );
  }

  Future<LatLngLite?> _locate() async {
    try {
      return await _currentLocation();
    } catch (_) {
      return null;
    }
  }

  Future<void> _onRaised(
      IncidentRaised event, Emitter<IncidentState> emit) async {
    if (state.sending) return;
    emit(state.copyWith(
        sending: true, clearFailure: true, presses: state.presses + 1));
    final location = await _locate();
    if (location != null) emit(state.copyWith(lastLocation: location));
    final result = await _repo.raise(bookingId, location: location);
    result.fold(
      (f) => emit(state.copyWith(
        sending: false,
        failure: f is IncidentFailure
            ? f
            : IncidentFailure(IncidentIssue.other, f.message),
      )),
      (_) => emit(state.copyWith(sending: false, clearFailure: true)),
    );
  }

  Future<void> _onCancelled(
      IncidentCancelled event, Emitter<IncidentState> emit) async {
    final id = state.incident?.id;
    if (id == null) return;
    final result = await _repo.cancel(id);
    result.fold(
      (f) => emit(state.copyWith(
          failure: f is IncidentFailure
              ? f
              : IncidentFailure(IncidentIssue.other, f.message))),
      (_) => emit(state.copyWith(clearFailure: true)),
    );
  }

  void _onChanged(_IncidentChanged event, Emitter<IncidentState> emit) {
    emit(event.incident == null
        ? state.copyWith(clearIncident: true)
        : state.copyWith(incident: event.incident));
    // Ubicación en vivo solo mientras esté abierto o reconocido.
    if (state.live) {
      if (_timer == null) {
        _timer = Timer.periodic(
            publishEvery, (_) => add(const _IncidentLocationTick()));
        add(const _IncidentLocationTick());
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _onTick(
      _IncidentLocationTick event, Emitter<IncidentState> emit) async {
    final incident = state.incident;
    if (incident == null || !incident.isLive) return;
    final location = await _locate();
    if (location == null) return;
    emit(state.copyWith(lastLocation: location));
    try {
      await _repo.publishLocation(incident.id, location.lat, location.lng);
    } catch (_) {
      // Tramo ya usado o sin red: el siguiente tick lo intenta de nuevo.
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _timer?.cancel();
    return super.close();
  }
}
