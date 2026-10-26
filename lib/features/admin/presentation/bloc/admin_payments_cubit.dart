import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/admin_payments.dart';

/// Bandejas de pagos del panel (B3). Cada acción va a su callable con 2FA
/// y motivo; tras una acción correcta se recarga la bandeja.
class AdminPaymentsState extends Equatable {
  const AdminPaymentsState({
    this.kind = PaymentInboxKind.reported,
    this.items = const [],
    this.loading = false,
    this.error,
    this.busyId,
    this.message,
    this.seq = 0,
  });

  final PaymentInboxKind kind;
  final List<PaymentInboxItem> items;
  final bool loading;

  /// Error al cargar o al actuar (texto para la persona).
  final String? error;

  /// Reserva con una acción en curso.
  final String? busyId;

  /// Aviso de éxito de la última acción.
  final String? message;

  /// Cambia con cada aviso, para mostrarlo una sola vez.
  final int seq;

  @override
  List<Object?> get props => [kind, items, loading, error, busyId, seq];
}

class AdminPaymentsCubit extends Cubit<AdminPaymentsState> {
  AdminPaymentsCubit(this._repo) : super(const AdminPaymentsState());

  final AdminPaymentsRepository _repo;

  Future<void> load([PaymentInboxKind? kind]) async {
    final k = kind ?? state.kind;
    emit(AdminPaymentsState(kind: k, loading: true, seq: state.seq));
    final r = await _repo.inbox(k);
    if (isClosed) return;
    r.fold(
      (f) => emit(
        AdminPaymentsState(kind: k, error: f.message, seq: state.seq + 1),
      ),
      (items) =>
          emit(AdminPaymentsState(kind: k, items: items, seq: state.seq)),
    );
  }

  Future<bool> _act(
    String bookingId,
    Future<dynamic> Function() call,
    String ok,
  ) async {
    emit(
      AdminPaymentsState(
        kind: state.kind,
        items: state.items,
        busyId: bookingId,
        seq: state.seq,
      ),
    );
    final r = await call();
    if (isClosed) return false;
    final failure = r.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(
        AdminPaymentsState(
          kind: state.kind,
          items: state.items,
          error: failure.message,
          seq: state.seq + 1,
        ),
      );
      return false;
    }
    await load();
    if (isClosed) return true;
    emit(
      AdminPaymentsState(
        kind: state.kind,
        items: state.items,
        error: state.error,
        message: ok,
        seq: state.seq + 1,
      ),
    );
    return true;
  }

  Future<bool> confirm(
    PaymentInboxItem item, {
    required double amountReceived,
    required String operationNumber,
    required String reason,
  }) =>
      _act(
        item.bookingId,
        () => _repo.confirm(
          bookingId: item.bookingId,
          amountReceived: amountReceived,
          operationNumber: operationNumber,
          reason: reason,
        ),
        'Pago confirmado. La reserva ya se ofrece a los chóferes.',
      );

  Future<bool> reject(PaymentInboxItem item, {required String reason}) => _act(
        item.bookingId,
        () => _repo.reject(bookingId: item.bookingId, reason: reason),
        'Pago rechazado. Se avisó al pasajero.',
      );

  Future<bool> recordRefund(
    PaymentInboxItem item,
    PendingRefund entry, {
    required String reason,
    String? externalRef,
  }) =>
      _act(
        item.bookingId,
        () => _repo.recordRefund(
          bookingId: item.bookingId,
          entryId: entry.entryId,
          reason: reason,
          externalRef: externalRef,
        ),
        'Devolución registrada. Se avisó al pasajero.',
      );
}
