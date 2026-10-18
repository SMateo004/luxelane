import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
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

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('payments');

  @override
  Future<Either<Failure, String?>> createPaymentIntent({
    required String quoteId,
    required DateTime scheduledAt,
    required String paymentMethodId,
  }) async {
    try {
      // The amount comes from the server-side quote, never from the app.
      final result = await _fn.httpsCallable('createPaymentIntent').call({
        'quoteId': quoteId,
        'scheduledAt': scheduledAt.millisecondsSinceEpoch,
        'paymentMethodId': paymentMethodId,
      });
      if (result.data['deferred'] == true) return const Right(null);
      return Right(result.data['clientSecret'] as String);
    } on FirebaseFunctionsException catch (e) {
      return Left(PaymentFailure(e.code == 'failed-precondition'
          ? 'tu cuenta aún no tiene pagos habilitados'
          : 'no se pudo contactar con el servidor de pagos'));
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
    // Lo registra la Cloud Function: cobra el importe de la reserva (no el
    // que manda el cliente) y guarda el pago en centavos. Las reglas no
    // permiten a un pasajero crear pagos directamente.
    try {
      final result = await _fn.httpsCallable('capturePayment').call({
        'bookingId': bookingId,
        'stripePaymentIntentId': stripePaymentIntentId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return Right(Payment(
        id: data['paymentId'] as String,
        bookingId: bookingId,
        riderId: riderId,
        stripePaymentIntentId: stripePaymentIntentId,
        amount: (data['amount'] as num?)?.toDouble() ??
            Payment.toCents(amount).toDouble(),
        currency: data['currency'] as String? ?? currency,
        status: PaymentStatusX.fromString(data['status'] as String? ?? ''),
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> getPaymentByBooking(
    String bookingId,
  ) async {
    try {
      final snap =
          await _col.where('bookingId', isEqualTo: bookingId).limit(1).get();
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
      // La Cloud Function marca el pago como reembolsado.
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
      // En móvil llegan como Map<Object?, Object?>: se copian una a una.
      final cards = ((result.data['cards'] as List?) ?? const [])
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();
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
    } on FirebaseFunctionsException catch (e) {
      if (e.message == 'card-in-use') {
        return const Left(PaymentFailure(
            'Esta tarjeta paga una reserva pendiente. Cancélala o espera a '
            'que termine antes de quitar la tarjeta.'));
      }
      return const Left(
          PaymentFailure('No pudimos quitar la tarjeta. Inténtalo de nuevo.'));
    } catch (e) {
      return Left(PaymentFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultCard(String paymentMethodId) async {
    try {
      await _fn.httpsCallable('setDefaultPaymentMethod').call({
        'paymentMethodId': paymentMethodId,
      });
      return const Right(null);
    } catch (_) {
      return const Left(PaymentFailure(
          'No pudimos cambiar la tarjeta predeterminada. Inténtalo de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, String>> ensureStripeCustomer() async {
    try {
      final result =
          await _fn.httpsCallable('ensureStripeCustomer').call<dynamic>();
      return Right((result.data as Map)['customerId'] as String);
    } catch (_) {
      return const Left(PaymentFailure(
          'No pudimos preparar tu perfil de pagos. Inténtalo de nuevo.'));
    }
  }
}
