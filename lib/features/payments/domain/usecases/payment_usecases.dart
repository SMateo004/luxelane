import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecase.dart';

class CreatePaymentIntentUseCase
    implements UseCase<String, CreateIntentParams> {
  CreatePaymentIntentUseCase(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Either<Failure, String>> call(CreateIntentParams params) =>
      _repo.createPaymentIntent(
        amount: params.amount,
        currency: params.currency,
        stripeCustomerId: params.stripeCustomerId,
      );
}

class CreateIntentParams {
  const CreateIntentParams({
    required this.amount,
    required this.currency,
    required this.stripeCustomerId,
  });
  final double amount;
  final String currency;
  final String stripeCustomerId;
}

// ---------------------------------------------------------------------------

class CapturePaymentUseCase implements UseCase<Payment, CapturePaymentParams> {
  CapturePaymentUseCase(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Either<Failure, Payment>> call(CapturePaymentParams params) =>
      _repo.capturePayment(
        bookingId: params.bookingId,
        riderId: params.riderId,
        stripePaymentIntentId: params.stripePaymentIntentId,
        amount: params.amount,
        currency: params.currency,
      );
}

class CapturePaymentParams {
  const CapturePaymentParams({
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
}

// ---------------------------------------------------------------------------

class RefundPaymentUseCase implements UseCase<void, String> {
  RefundPaymentUseCase(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Either<Failure, void>> call(String paymentId) =>
      _repo.refundPayment(paymentId);
}

// ---------------------------------------------------------------------------

class GetRiderPaymentsUseCase implements UseCase<List<Payment>, String> {
  GetRiderPaymentsUseCase(this._repo);
  final PaymentRepository _repo;

  @override
  Future<Either<Failure, List<Payment>>> call(String riderId) =>
      _repo.getPaymentsByRider(riderId);
}
