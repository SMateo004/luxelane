import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/models/booking_payment.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../l10n/l10n.dart';

/// Fallo del servidor, en el idioma activo.
String get kPaymentOurFault => L10n.current.paymentOurFault;

/// Mensaje para el pasajero según el motivo del servidor. Sin texto
/// técnico; un fallo del servidor no se presenta como culpa suya (E37).
String paymentFailureFor(String code, Object? details) {
  final common = commonFunctionError(code, details);
  if (common != null) return common;
  final t = L10n.current;
  return switch (functionErrorReason(details)) {
    'method_disabled' => t.paymentMethodDisabled,
    'already_paid' => t.paymentAlreadyPaid,
    'not_awaiting_payment' => t.paymentNotAwaiting,
    'booking_not_found' || 'not_owner' => t.paymentBookingNotFound,
    _ when code == 'invalid-argument' => t.paymentInvalidOperationNumber,
    _ => t.paymentOurFault,
  };
}

class BookingPaymentRepositoryImpl implements BookingPaymentRepository {
  BookingPaymentRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _db = firestore,
        _fn = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  @override
  Stream<BookingPayment?> watch(String bookingId) => _db
          .collection('bookings')
          .doc(bookingId)
          .collection('payment')
          .doc('state')
          .snapshots()
          .map((s) {
        final d = s.data();
        return d == null ? null : BookingPayment.fromJson(bookingId, d);
      });

  @override
  Future<Either<Failure, PaymentStart>> start(
    String bookingId,
    String method,
  ) async {
    try {
      final res = await _fn.httpsCallable('startPayment').call({
        'bookingId': bookingId,
        'method': method,
      });
      return Right(
        PaymentStart.fromJson(Map<String, dynamic>.from(res.data as Map)),
      );
    } on FirebaseFunctionsException catch (e) {
      return Left(PaymentFailure(paymentFailureFor(e.code, e.details)));
    } catch (e) {
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markSent(
    String bookingId, {
    String? operationNumber,
  }) async {
    final op = operationNumber?.trim();
    try {
      await _fn.httpsCallable('markPaymentSent').call({
        'bookingId': bookingId,
        if (op != null && op.isNotEmpty) 'operationNumber': op,
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(PaymentFailure(paymentFailureFor(e.code, e.details)));
    } catch (e) {
      return Left(PaymentFailure(unexpectedErrorMessage(e)));
    }
  }
}
