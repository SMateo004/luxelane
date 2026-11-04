import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/trip_share_repository.dart';

enum TripShareStatus { loading, inactive, active, working, error }

class TripShareState extends Equatable {
  const TripShareState({
    this.status = TripShareStatus.loading,
    this.message,
    this.sharePath,
    this.shareSeq = 0,
  });

  final TripShareStatus status;

  /// Error para la persona (ya traducido).
  final String? message;

  /// Ruta recién creada para abrir la hoja de compartir; [shareSeq] sube con
  /// cada enlace nuevo para que la hoja se abra una vez.
  final String? sharePath;
  final int shareSeq;

  @override
  List<Object?> get props => [status, message, sharePath, shareSeq];
}

/// Estado del enlace de una reserva: comprobar, crear y dejar de compartir.
class TripShareCubit extends Cubit<TripShareState> {
  TripShareCubit(this._repo, this.bookingId) : super(const TripShareState());

  final TripShareRepository _repo;
  final String bookingId;

  Future<void> load() async {
    emit(const TripShareState());
    final r = await _repo.isActive(bookingId);
    emit(r.fold(
      (f) => TripShareState(status: TripShareStatus.error, message: f.message),
      (active) => TripShareState(
          status: active ? TripShareStatus.active : TripShareStatus.inactive),
    ));
  }

  Future<void> share() async {
    emit(TripShareState(
        status: TripShareStatus.working, shareSeq: state.shareSeq));
    final r = await _repo.create(bookingId);
    emit(r.fold(
      (f) => TripShareState(
          status: TripShareStatus.error,
          message: f.message,
          shareSeq: state.shareSeq),
      (path) => TripShareState(
          status: TripShareStatus.active,
          sharePath: path,
          shareSeq: state.shareSeq + 1),
    ));
  }

  Future<void> stop() async {
    emit(TripShareState(
        status: TripShareStatus.working, shareSeq: state.shareSeq));
    final r = await _repo.revoke(bookingId);
    emit(r.fold(
      (f) => TripShareState(
          status: TripShareStatus.error,
          message: f.message,
          shareSeq: state.shareSeq),
      (_) => TripShareState(
          status: TripShareStatus.inactive, shareSeq: state.shareSeq),
    ));
  }
}
