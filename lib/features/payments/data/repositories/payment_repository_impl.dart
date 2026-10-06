import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
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

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('payments');

  @override
  Future<Either<Failure, String>> createPaymentIntent({
    required String quoteId,
    required String stripeCustomerId,
  }) async {
    try {
      // The amount is taken from the server-side quote, never from the app.
      final result = await _fn.httpsCallable('createPaymentIntent').call({
        'quoteId': quoteId,
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
    // Capture runs server-side: the function reads the amount from the
    // booking and verifies the intent belongs to the rider. Payments are
    // normally captured automatically when the booking is completed.
    try {
      final result = await _fn
          .httpsCallable('capturePayment')
          .call({'bookingId': bookingId});
      final paymentId = result.data['paymentId'] as String?;
      if (paymentId == null) {
        return const Left(PaymentFailure('No se pudo registrar el pago'));
      }
      final doc = await _col.doc(paymentId).get();
      return Right(Payment.fromJson({'id': doc.id, ...doc.data()!}));
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
      // The function updates the payment doc (clients can't write payments).
      await _fn.httpsCallable('refundPayment').call({'paymentId': paymentId});
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
