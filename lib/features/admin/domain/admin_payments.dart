import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';

/// Bandejas de pagos del panel (adminPaymentInbox, pagos A11). Importes en
/// céntimos de boliviano. Sin datos de contacto del pasajero.
enum PaymentInboxKind {
  reported('reported', 'Por confirmar'),
  awaiting('awaiting', 'Pendientes de pago'),
  refunds('refunds', 'Devoluciones'),
  balances('balances', 'Saldos');

  const PaymentInboxKind(this.wire, this.label);
  final String wire;
  final String label;
}

DateTime? _ms(Object? v) =>
    v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

int _int(Object? v) => v is num ? v.round() : 0;

class PendingRefund {
  const PendingRefund({
    required this.entryId,
    required this.amount,
    this.method,
  });

  factory PendingRefund.fromJson(Map<String, dynamic> j) => PendingRefund(
        entryId: j['entryId'] as String? ?? '',
        amount: _int(j['amount']),
        method: j['method'] as String?,
      );

  final String entryId;
  final int amount;
  final String? method;

  /// Con tarjeta la devolución la hace el proveedor; manual, central.
  bool get byCard => method == 'card';
}

class PaymentInboxItem {
  const PaymentInboxItem({
    required this.bookingId,
    required this.paymentStatus,
    required this.amountDue,
    this.paymentRef,
    this.paymentMethod,
    this.amountPaid = 0,
    this.amountRetained = 0,
    this.refundDue = 0,
    this.balanceDue = 0,
    this.paymentDeadline,
    this.riderReportedAt,
    this.riderOperationNumber,
    this.bookingStatus,
    this.scheduledAt,
    this.vehicleClass,
    this.pickupArea,
    this.pendingRefunds = const [],
  });

  factory PaymentInboxItem.fromJson(Map<String, dynamic> j) {
    final b = j['booking'] is Map
        ? Map<String, dynamic>.from(j['booking'] as Map)
        : const <String, dynamic>{};
    return PaymentInboxItem(
      bookingId: j['bookingId'] as String? ?? '',
      paymentStatus: j['paymentStatus'] as String? ?? '',
      paymentRef: j['paymentRef'] as String?,
      paymentMethod: j['paymentMethod'] as String?,
      amountDue: _int(j['amountDue']),
      amountPaid: _int(j['amountPaid']),
      amountRetained: _int(j['amountRetained']),
      refundDue: _int(j['refundDue']),
      balanceDue: _int(j['balanceDue']),
      paymentDeadline: _ms(j['paymentDeadline']),
      riderReportedAt: _ms(j['riderReportedAt']),
      riderOperationNumber: j['riderOperationNumber'] as String?,
      bookingStatus: b['status'] as String?,
      scheduledAt: _ms(b['scheduledAt']),
      vehicleClass: b['vehicleClass'] as String?,
      pickupArea: b['pickupArea'] as String?,
      pendingRefunds: [
        for (final r in (j['pendingRefunds'] as List?) ?? const [])
          if (r is Map) PendingRefund.fromJson(Map<String, dynamic>.from(r)),
      ],
    );
  }

  final String bookingId;
  final String paymentStatus;
  final String? paymentRef;
  final String? paymentMethod;
  final int amountDue;
  final int amountPaid;
  final int amountRetained;
  final int refundDue;
  final int balanceDue;
  final DateTime? paymentDeadline;
  final DateTime? riderReportedAt;
  final String? riderOperationNumber;
  final String? bookingStatus;
  final DateTime? scheduledAt;
  final String? vehicleClass;
  final String? pickupArea;
  final List<PendingRefund> pendingRefunds;
}

abstract class AdminPaymentsRepository {
  Future<Either<Failure, List<PaymentInboxItem>>> inbox(PaymentInboxKind kind);

  /// Pago manual recibido: importe exacto en bolivianos, número de
  /// operación del banco y motivo (auditoría).
  Future<Either<Failure, void>> confirm({
    required String bookingId,
    required double amountReceived,
    required String operationNumber,
    required String reason,
  });

  /// El «ya pagué» no llegó.
  Future<Either<Failure, void>> reject({
    required String bookingId,
    required String reason,
  });

  /// Cierra un asiento de devolución: manual con la referencia del banco;
  /// con tarjeta lo pide al proveedor.
  Future<Either<Failure, void>> recordRefund({
    required String bookingId,
    required String entryId,
    required String reason,
    String? externalRef,
  });

  /// Cobra un saldo pendiente (adminCollectBalance): [amount] en
  /// bolivianos, el saldo o menos; [method] `manual_qr` o `card`.
  Future<Either<Failure, void>> collectBalance({
    required String bookingId,
    required double amount,
    required String operationNumber,
    required String method,
    required String reason,
  });
}

/// Quién causa una cancelación desde el panel (adminUpdateBooking, pagos
/// A7). Solo con el pasajero se aplica la política de retención sobre lo
/// pagado; chófer o plataforma: se devuelve todo. El importe lo calcula
/// siempre el servidor.
enum AdminCancelCause {
  platform('platform', 'Central o la plataforma',
      'Sin retención: se devuelve todo lo pagado.'),
  driver('driver', 'El chófer', 'Sin retención: se devuelve todo lo pagado.'),
  rider('rider', 'El pasajero',
      'Se aplica la política de cancelación a lo pagado.');

  const AdminCancelCause(this.wire, this.label, this.effect);
  final String wire;
  final String label;
  final String effect;
}
