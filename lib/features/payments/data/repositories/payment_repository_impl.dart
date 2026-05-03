import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _db = firestore,
        _fn = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('payments');

  @override
  Future<Either<Failure, String>> createPaymentIntent({
    required double amount,
    required String currency,
    required String stripeCustomerId,
  }) async {
    try {
      final result = await _fn.httpsCallable('createPaymentIntent').call({
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'customerId': stripeCustomerId,
      });
      return Right(result.data['clientSecret'] as String);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> capturePayment({
    required String bookingId,
    required String riderId,
    required String stripePaymentIntentId,
    required double amount,
    required String currency,
  }) async {
    try {
      final id = _uuid.v4();
      final payment = Payment(
        id: id,
        bookingId: bookingId,
        riderId: riderId,
        stripePaymentIntentId: stripePaymentIntentId,
        amount: amount,
        currency: currency,
        status: PaymentStatus.captured,
        createdAt: DateTime.now(),
      );
      await _col.doc(id).set(payment.toJson());
      return Right(payment);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> getPaymentByBooking(
    String bookingId,
  ) async {
    try {
      final snap = await _col
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return const Left(NotFoundFailure());
      final d = snap.docs.first;
      return Right(Payment.fromJson({'id': d.id, ...d.data()}));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByRider(
    String riderId,
  ) async {
    try {
      final snap = await _col
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true)
          .get();
      return Right(snap.docs
          .map((d) => Payment.fromJson({'id': d.id, ...d.data()}))
          .toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> refundPayment(String paymentId) async {
    try {
      await _fn.httpsCallable('refundPayment').call({'paymentId': paymentId});
      await _col.doc(paymentId).update({'status': PaymentStatus.refunded.label});
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSavedCards(
    String stripeCustomerId,
  ) async {
    try {
      final result = await _fn.httpsCallable('listPaymentMethods').call({
        'customerId': stripeCustomerId,
      });
      final cards = List<Map<String, dynamic>>.from(result.data['cards'] ?? []);
      return Right(cards);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCard({
    required String stripeCustomerId,
    required String paymentMethodId,
  }) async {
    try {
      await _fn.httpsCallable('attachPaymentMethod').call({
        'customerId': stripeCustomerId,
        'paymentMethodId': paymentMethodId,
      });
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeCard({
    required String stripeCustomerId,
    required String paymentMethodId,
  }) async {
    try {
      await _fn.httpsCallable('detachPaymentMethod').call({
        'paymentMethodId': paymentMethodId,
      });
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }
}
