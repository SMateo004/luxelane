import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
  Future<Either<Failure, String>> createPaymentIntent({
    required double amount,
    required String currency,
    required String stripeCustomerId,
  }) async {
    try {
      // El servidor usa el cliente Stripe de la cuenta y cobra en Bs.
      final result = await _fn.httpsCallable('createPaymentIntent').call({
        'amount': Payment.toCents(amount),
      });
      return Right(result.data['clientSecret'] as String);
    } catch (e) {
      return Left(_failure(e, 'No pudimos preparar el pago con tarjeta.'));
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
      // Reintento manual del admin: el servidor usa la retención vinculada
      // a la reserva (normalmente se cobra solo al completar el viaje).
      final result = await _fn.httpsCallable('capturePayment').call({
        'bookingId': bookingId,
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
      final result = await _fn.httpsCallable('listPaymentMethods').call({});
      final cards = (result.data['cards'] as List? ?? const [])
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();
      return Right(cards);
    } catch (e) {
      return Left(_failure(e, 'No pudimos cargar tus tarjetas.'));
    }
  }

  @override
  Future<Either<Failure, void>> addCard({
    required String stripeCustomerId,
    required String paymentMethodId,
  }) async {
    try {
      await _fn.httpsCallable('attachPaymentMethod').call({
        'paymentMethodId': paymentMethodId,
      });
      return const Right(null);
    } catch (e) {
      return Left(_failure(e, 'No pudimos guardar la tarjeta.'));
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
      return Left(_failure(e, 'No pudimos quitar la tarjeta.'));
    }
  }

  @override
  Future<Either<Failure, bool>> linkBookingPayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    try {
      final result = await _fn.httpsCallable('linkBookingPayment').call({
        'bookingId': bookingId,
        'paymentIntentId': paymentIntentId,
      });
      return Right((result.data as Map?)?['linked'] == true);
    } catch (e) {
      return Left(_failure(e, 'No pudimos asociar el pago a tu reserva.'));
    }
  }

  @override
  Future<void> releasePaymentHold(String paymentIntentId) async {
    try {
      await _fn
          .httpsCallable('releasePaymentHold')
          .call({'paymentIntentId': paymentIntentId});
    } catch (e) {
      // Si falla, Stripe la libera sola a los 7 días.
      debugPrint('[Payments] liberar retención: $e');
    }
  }

  /// Mensaje en español: nunca el error técnico de Firebase o Stripe.
  static Failure _failure(Object e, String fallback) {
    debugPrint('[Payments] $e');
    if (e is FirebaseFunctionsException && e.code == 'unavailable') {
      return const PaymentFailure('Sin conexión. Inténtalo de nuevo.');
    }
    return PaymentFailure(fallback);
  }
}
