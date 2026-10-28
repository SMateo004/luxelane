import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/function_errors.dart';
import '../../domain/admin_payments.dart';
import '../../domain/repositories/admin_repository.dart'
    show kAdminReasonMinLength;

/// Motivos del servidor (pagos A4, A8, A11) en el texto del panel, sin
/// texto técnico.
String adminPaymentErrorMessage(String code, Object? details) {
  final common = commonFunctionError(code, details);
  if (common != null) return common;
  return switch (functionErrorReason(details)) {
    'amount_mismatch' =>
      'El importe no coincide con lo debido. Confirma solo el importe '
          'exacto; si llegó otro, contacta con el pasajero.',
    'operation_already_used' =>
      'Ese número de operación ya confirmó otro pago.',
    'already_paid' => 'Esta reserva ya tiene el pago confirmado.',
    'amount_exceeds_balance' =>
      'El importe supera el saldo pendiente. Registra el saldo o menos.',
    'no_balance_due' => 'Esta reserva ya no tiene saldo pendiente; recarga.',
    'not_awaiting_payment' => 'Este pago ya no está pendiente; recarga.',
    'method_disabled' => 'El pago manual está desactivado en la configuración.',
    'refund_not_found' => 'No se encontró esa devolución; recarga.',
    'already_refunded' => 'Esa devolución ya está registrada.',
    'refund_exceeds_paid' =>
      'La devolución supera lo pagado menos lo retenido y lo ya devuelto.',
    'provider_refund_failed' =>
      'El proveedor no pudo hacer la devolución. Reinténtalo más tarde.',
    'booking_not_found' => 'No se encontró la reserva.',
    'invalid_request' =>
      'Revisa los datos. El motivo necesita al menos $kAdminReasonMinLength '
          'caracteres y la referencia solo letras, números y . _ / -',
    _ => code == 'permission-denied'
        ? 'Permiso denegado: se necesita rol de administrador'
        : 'No se pudo completar. Inténtalo de nuevo en unos minutos.',
  };
}

class AdminPaymentsRepositoryImpl implements AdminPaymentsRepository {
  AdminPaymentsRepositoryImpl({FirebaseFunctions? functions})
      : _fnOverride = functions;

  final FirebaseFunctions? _fnOverride;
  FirebaseFunctions get _fn => _fnOverride ?? FirebaseFunctions.instance;

  Future<Either<Failure, T>> _run<T>(
    String name,
    Map<String, dynamic> data,
    T Function(Object? data) parse,
  ) async {
    try {
      final res = await _fn.httpsCallable(name).call<Object?>(data);
      return Right(parse(res.data));
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(adminPaymentErrorMessage(e.code, e.details)));
    } catch (_) {
      return const Left(ServerFailure(kNoConnectionMessage));
    }
  }

  @override
  Future<Either<Failure, List<PaymentInboxItem>>> inbox(
    PaymentInboxKind kind,
  ) =>
      _run('adminPaymentInbox', {'kind': kind.wire}, (d) {
        final items = (d is Map ? d['items'] : null) as List? ?? const [];
        return [
          for (final i in items)
            if (i is Map)
              PaymentInboxItem.fromJson(Map<String, dynamic>.from(i)),
        ];
      });

  @override
  Future<Either<Failure, void>> confirm({
    required String bookingId,
    required double amountReceived,
    required String operationNumber,
    required String reason,
  }) =>
      _run(
          'adminConfirmPayment',
          {
            'bookingId': bookingId,
            'amountReceived': amountReceived,
            'operationNumber': operationNumber.trim(),
            'reason': reason.trim(),
          },
          (_) {});

  @override
  Future<Either<Failure, void>> reject({
    required String bookingId,
    required String reason,
  }) =>
      _run(
          'adminRejectPayment',
          {
            'bookingId': bookingId,
            'reason': reason.trim(),
          },
          (_) {});

  @override
  Future<Either<Failure, void>> recordRefund({
    required String bookingId,
    required String entryId,
    required String reason,
    String? externalRef,
  }) =>
      _run(
          'adminRecordRefund',
          {
            'bookingId': bookingId,
            'entryId': entryId,
            'reason': reason.trim(),
            if (externalRef != null && externalRef.trim().isNotEmpty)
              'externalRef': externalRef.trim(),
          },
          (_) {});

  @override
  Future<Either<Failure, void>> collectBalance({
    required String bookingId,
    required double amount,
    required String operationNumber,
    required String method,
    required String reason,
  }) =>
      _run(
          'adminCollectBalance',
          {
            'bookingId': bookingId,
            'amount': amount,
            'operationNumber': operationNumber.trim(),
            'method': method,
            'reason': reason.trim(),
          },
          (_) {});
}
