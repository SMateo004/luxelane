import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../l10n/l10n.dart';

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
    required String bookingId,
    required String paymentMethodId,
  }) async {
    try {
      final result = await _fn.httpsCallable('createPaymentIntent').call({
        'bookingId': bookingId,
        'paymentMethodId': paymentMethodId,
      });
      if (result.data['deferred'] == true) return const Right(null);
      return Right(result.data['clientSecret'] as String);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        PaymentFailure(
          commonFunctionError(e.code, e.details) ??
              (e.code == 'failed-precondition'
                  ? L10n.current.paymentAccountNotEnabled
                  : L10n.current.paymentServerUnreachable),
        ),
      );
    } catch (e) {
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
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
      return Right(
        Payment(
          id: data['paymentId'] as String,
          bookingId: bookingId,
          riderId: riderId,
          stripePaymentIntentId: stripePaymentIntentId,
          amount: (data['amount'] as num?)?.toDouble() ??
              Payment.toCents(amount).toDouble(),
          currency: data['currency'] as String? ?? currency,
          status: PaymentStatusX.fromString(data['status'] as String? ?? ''),
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, Payment>> getPaymentByBooking(String bookingId) async {
    try {
      final snap =
          await _col.where('bookingId', isEqualTo: bookingId).limit(1).get();
      if (snap.docs.isEmpty) return const Left(NotFoundFailure());
      final d = snap.docs.first;
      return Right(Payment.fromJson({'id': d.id, ...d.data()}));
    } catch (e) {
      return Left(ServerFailure(unexpectedErrorMessage(e)));
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
      return Right(
        snap.docs
            .map((d) => Payment.fromJson({'id': d.id, ...d.data()}))
            .toList(),
      );
    } catch (e) {
      return Left(ServerFailure(unexpectedErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> refundPayment(String paymentId) async {
    try {
      // La Cloud Function marca el pago como reembolsado.
      await _fn.httpsCallable('refundPayment').call({'paymentId': paymentId});
      return const Right(null);
    } catch (e) {
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
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
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
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
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
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
      if (functionErrorReason(e.details) == 'card-in-use') {
        return Left(PaymentFailure(L10n.current.paymentCardInUse));
      }
      return Left(
        PaymentFailure(
          commonFunctionError(e.code, e.details) ??
              L10n.current.paymentRemoveCardError,
        ),
      );
    } catch (e) {
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
    }
  }

  static String get _setDefaultError => L10n.current.paymentSetDefaultError;

  @override
  Future<Either<Failure, void>> setDefaultCard(String paymentMethodId) async {
    try {
      await _fn.httpsCallable('setDefaultPaymentMethod').call({
        'paymentMethodId': paymentMethodId,
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        PaymentFailure(
          commonFunctionError(e.code, e.details) ?? _setDefaultError,
        ),
      );
    } catch (_) {
      return Left(PaymentFailure(_setDefaultError));
    }
  }

  @override
  Future<Either<Failure, String>> ensureStripeCustomer() async {
    try {
      final result =
          await _fn.httpsCallable('ensureStripeCustomer').call<dynamic>();
      return Right((result.data as Map)['customerId'] as String);
    } catch (_) {
      return Left(PaymentFailure(L10n.current.paymentProfileError));
    }
  }
}
