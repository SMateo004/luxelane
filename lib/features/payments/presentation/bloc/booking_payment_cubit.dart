import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/booking_payment.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/card_payment_presenter.dart';

/// Pago de una reserva desde la app del pasajero (pagos, B1). El estado de
/// verdad es el del servidor (payment/state); aquí solo se guarda lo que la
/// pantalla necesita mientras tanto: el método elegido, las instrucciones y
/// los errores.
class BookingPaymentState extends Equatable {
  const BookingPaymentState({
    this.loaded = false,
    this.payment,
    this.start,
    this.busy = false,
    this.error,
    this.cardSubmitted = false,
  });

  final bool loaded;
  final BookingPayment? payment;

  /// Respuesta de startPayment para el método elegido.
  final PaymentStart? start;
  final bool busy;
  final String? error;

  /// El formulario de la tarjeta terminó; falta que el servidor lo confirme.
  final bool cardSubmitted;

  BookingPaymentState copyWith({
    bool? loaded,
    BookingPayment? payment,
    PaymentStart? start,
    bool clearStart = false,
    bool? busy,
    String? error,
    bool clearError = false,
    bool? cardSubmitted,
  }) =>
      BookingPaymentState(
        loaded: loaded ?? this.loaded,
        payment: payment ?? this.payment,
        start: clearStart ? null : (start ?? this.start),
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
        cardSubmitted: cardSubmitted ?? this.cardSubmitted,
      );

  @override
  List<Object?> get props => [
        loaded,
        payment?.status,
        payment?.riderReportedAt,
        payment?.amountDue,
        payment?.paymentDeadline,
        start?.method,
        start?.paymentRef,
        busy,
        error,
        cardSubmitted,
      ];
}

class BookingPaymentCubit extends Cubit<BookingPaymentState> {
  BookingPaymentCubit({
    required BookingPaymentRepository repository,
    required this.bookingId,
    required this.isWeb,
    this.cardPresenter,
  })  : _repo = repository,
        super(const BookingPaymentState()) {
    _sub = _repo.watch(bookingId).listen(_onPayment, onError: (_) {
      emit(state.copyWith(loaded: true, error: kPaymentLoadError));
    });
  }

  final BookingPaymentRepository _repo;
  final String bookingId;
  final bool isWeb;
  final CardPaymentPresenter? cardPresenter;
  StreamSubscription<BookingPayment?>? _sub;

  static String get kPaymentLoadError => L10n.current.paymentLoadError;

  /// Métodos que se pueden usar aquí: la web y una app sin formulario de
  /// tarjeta solo ofrecen el pago manual (E38).
  List<String> usableMethods(BookingPayment p) => [
        for (final m in p.methodsOffered)
          if (m == PayMethod.manualQr ||
              (m == PayMethod.card && !isWeb && cardPresenter != null))
            m,
      ];

  void _onPayment(BookingPayment? p) {
    if (p == null) {
      emit(BookingPaymentState(loaded: true, start: state.start));
      return;
    }
    emit(state.copyWith(loaded: true, payment: p));
    // Con un único método no hay nada que elegir: se piden sus datos (al
    // abrir, o si central rechaza el aviso con la pantalla abierta).
    if (p.payable &&
        !p.reported &&
        state.start == null &&
        !state.busy &&
        state.error == null) {
      final usable = usableMethods(p);
      if (usable.length == 1 && usable.first == PayMethod.manualQr) {
        choose(PayMethod.manualQr);
      }
    }
  }

  /// Elegir (o reintentar) un método.
  Future<void> choose(String method) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, clearError: true, cardSubmitted: false));
    final r = await _repo.start(bookingId, method);
    if (isClosed) return;
    await r.fold(
      (f) async => emit(state.copyWith(busy: false, error: f.message)),
      (start) async {
        emit(state.copyWith(busy: method == PayMethod.card, start: start));
        if (method == PayMethod.card) await _presentCard(start);
      },
    );
  }

  Future<void> _presentCard(PaymentStart start) async {
    final secret = start.clientSecret;
    final presenter = cardPresenter;
    if (secret == null || presenter == null) {
      emit(state.copyWith(busy: false, error: kCardUnavailable));
      return;
    }
    final r = await presenter.present(secret);
    if (isClosed) return;
    switch (r.outcome) {
      case CardSheetOutcome.completed:
        emit(state.copyWith(busy: false, cardSubmitted: true));
      case CardSheetOutcome.cancelled:
        emit(state.copyWith(busy: false));
      case CardSheetOutcome.failed:
        emit(state.copyWith(busy: false, error: kCardFailed));
    }
  }

  static String get kCardUnavailable => L10n.current.paymentCardUnavailable;
  static String get kCardFailed => L10n.current.paymentCardFailed;

  /// Volver a la elección de método.
  void changeMethod() =>
      emit(state.copyWith(clearStart: true, clearError: true));

  /// «Ya pagué», con el número de operación si lo escribió.
  Future<void> reportPaid({String? operationNumber}) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true, clearError: true));
    final r = await _repo.markSent(bookingId, operationNumber: operationNumber);
    if (isClosed) return;
    r.fold(
      (f) => emit(state.copyWith(busy: false, error: f.message)),
      (_) => emit(state.copyWith(busy: false)),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
