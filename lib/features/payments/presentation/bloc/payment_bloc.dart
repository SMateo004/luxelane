import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class PaymentIntentRequested extends PaymentEvent {
  const PaymentIntentRequested({
    required this.amount,
    required this.currency,
    required this.stripeCustomerId,
  });
  final double amount;
  final String currency;
  final String stripeCustomerId;
  @override
  List<Object?> get props => [amount, currency, stripeCustomerId];
}

class PaymentCaptureRequested extends PaymentEvent {
  const PaymentCaptureRequested({
    required this.bookingId,
    required this.riderId,
    required this.stripePaymentIntentId,
    required this.amount,
    required this.currency,
  });
  final String bookingId;
  final String riderId;
  final String stripePaymentIntentId;
  final double amount;
  final String currency;
  @override
  List<Object?> get props => [bookingId, stripePaymentIntentId];
}

class PaymentRefundRequested extends PaymentEvent {
  const PaymentRefundRequested({required this.paymentId});
  final String paymentId;
  @override
  List<Object?> get props => [paymentId];
}

class CardsLoadRequested extends PaymentEvent {
  const CardsLoadRequested({required this.stripeCustomerId});
  final String stripeCustomerId;
  @override
  List<Object?> get props => [stripeCustomerId];
}

class CardAdded extends PaymentEvent {
  const CardAdded({
    required this.stripeCustomerId,
    required this.paymentMethodId,
  });
  final String stripeCustomerId;
  final String paymentMethodId;
  @override
  List<Object?> get props => [stripeCustomerId, paymentMethodId];
}

class CardRemoved extends PaymentEvent {
  const CardRemoved({
    required this.stripeCustomerId,
    required this.paymentMethodId,
  });
  final String stripeCustomerId;
  final String paymentMethodId;
  @override
  List<Object?> get props => [stripeCustomerId, paymentMethodId];
}

class DefaultCardSet extends PaymentEvent {
  const DefaultCardSet({required this.paymentMethodId});
  final String paymentMethodId;
  @override
  List<Object?> get props => [paymentMethodId];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentIntentCreated extends PaymentState {
  const PaymentIntentCreated(this.clientSecret);
  final String clientSecret;
  @override
  List<Object?> get props => [clientSecret];
}

class PaymentCaptured extends PaymentState {
  const PaymentCaptured(this.payment);
  final Payment payment;
  @override
  List<Object?> get props => [payment.id];
}

class PaymentRefunded extends PaymentState {
  const PaymentRefunded();
}

class CardsLoaded extends PaymentState {
  const CardsLoaded(this.cards);
  final List<Map<String, dynamic>> cards;
  @override
  List<Object?> get props => [cards.length];
}

class PaymentError extends PaymentState {
  const PaymentError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class CardOperationSuccess extends PaymentState {
  const CardOperationSuccess();
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc({required PaymentRepository paymentRepository})
      : _repo = paymentRepository,
        super(const PaymentInitial()) {
    on<PaymentIntentRequested>(_onIntent);
    on<PaymentCaptureRequested>(_onCapture);
    on<PaymentRefundRequested>(_onRefund);
    on<CardsLoadRequested>(_onLoadCards);
    on<CardAdded>(_onAddCard);
    on<CardRemoved>(_onRemoveCard);
    on<DefaultCardSet>(_onDefaultCard);
  }

  final PaymentRepository _repo;

  Future<void> _onIntent(
    PaymentIntentRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result = await _repo.createPaymentIntent(
      amount: event.amount,
      currency: event.currency,
      stripeCustomerId: event.stripeCustomerId,
    );
    result.fold(
      (f) => emit(PaymentError(f.message)),
      (secret) => emit(PaymentIntentCreated(secret)),
    );
  }

  Future<void> _onCapture(
    PaymentCaptureRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result = await _repo.capturePayment(
      bookingId: event.bookingId,
      riderId: event.riderId,
      stripePaymentIntentId: event.stripePaymentIntentId,
      amount: event.amount,
      currency: event.currency,
    );
    result.fold(
      (f) => emit(PaymentError(f.message)),
      (p) => emit(PaymentCaptured(p)),
    );
  }

  Future<void> _onRefund(
    PaymentRefundRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result = await _repo.refundPayment(event.paymentId);
    result.fold(
      (f) => emit(PaymentError(f.message)),
      (_) => emit(const PaymentRefunded()),
    );
  }

  Future<void> _onLoadCards(
    CardsLoadRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result = await _repo.getSavedCards(event.stripeCustomerId);
    result.fold(
      (f) => emit(PaymentError(f.message)),
      (cards) => emit(CardsLoaded(cards)),
    );
  }

  Future<void> _onAddCard(CardAdded event, Emitter<PaymentState> emit) async {
    await _repo.addCard(
      stripeCustomerId: event.stripeCustomerId,
      paymentMethodId: event.paymentMethodId,
    );
  }

  Future<void> _onRemoveCard(
    CardRemoved event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    final result = await _repo.removeCard(
      stripeCustomerId: event.stripeCustomerId,
      paymentMethodId: event.paymentMethodId,
    );
    result.fold(
      (f) => emit(PaymentError(f.message)),
      (_) => emit(const CardOperationSuccess()),
    );
  }

  void _onDefaultCard(DefaultCardSet event, Emitter<PaymentState> emit) {
    // Handled locally in UI — no server call needed for display
    emit(const CardOperationSuccess());
  }
}
