import 'package:cloud_firestore/cloud_firestore.dart';

/// Pago de una reserva (bookings/{id}/payment/state). Lo escribe solo el
/// servidor y lo leen solo el pasajero dueño y central: el chófer no ve
/// importes ni retenciones (pagos, A1). Importes en céntimos de boliviano.

enum BookingPaymentStatus {
  awaitingPayment,
  paid,
  refundPending,
  refunded,
  partiallyRefunded,
  failed,
  expired,
  unknown;

  static BookingPaymentStatus fromString(String? s) => switch (s) {
        'awaiting_payment' => awaitingPayment,
        'paid' => paid,
        'refund_pending' => refundPending,
        'refunded' => refunded,
        'partially_refunded' => partiallyRefunded,
        'failed' => failed,
        'expired' => expired,
        _ => unknown,
      };
}

/// Métodos que conoce el servidor (payment_model.ts, PAYMENT_METHODS).
abstract class PayMethod {
  static const manualQr = 'manual_qr';
  static const card = 'card';
}

DateTime? _date(Object? v) => switch (v) {
      Timestamp t => t.toDate(),
      int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
      _ => null,
    };

int _cents(Object? v) => v is num ? v.round() : 0;

class BookingPayment {
  const BookingPayment({
    required this.bookingId,
    required this.status,
    required this.amountDue,
    this.method,
    this.amountPaid = 0,
    this.amountRetained = 0,
    this.amountRefunded = 0,
    this.refundDue = 0,
    this.balanceDue = 0,
    this.paymentRef,
    this.paymentDeadline,
    this.paidAt,
    this.riderReportedAt,
    this.riderOperationNumber,
    this.rejectedAt,
    this.methodsOffered = const [],
  });

  factory BookingPayment.fromJson(String bookingId, Map<String, dynamic> j) =>
      BookingPayment(
        bookingId: bookingId,
        status: BookingPaymentStatus.fromString(j['paymentStatus'] as String?),
        method: j['paymentMethod'] as String?,
        amountDue: _cents(j['amountDue']),
        amountPaid: _cents(j['amountPaid']),
        amountRetained: _cents(j['amountRetained']),
        amountRefunded: _cents(j['amountRefunded']),
        refundDue: _cents(j['refundDue']),
        balanceDue: _cents(j['balanceDue']),
        paymentRef: j['paymentRef'] as String?,
        paymentDeadline: _date(j['paymentDeadline']),
        paidAt: _date(j['paidAt']),
        riderReportedAt: _date(j['riderReportedAt']),
        riderOperationNumber: j['riderOperationNumber'] as String?,
        rejectedAt: _date(j['rejectedAt']),
        methodsOffered: [
          for (final m in (j['methodsOffered'] as List?) ?? const [])
            if (m is String) m,
        ],
      );

  final String bookingId;
  final BookingPaymentStatus status;
  final String? method;

  /// Céntimos de boliviano.
  final int amountDue;
  final int amountPaid;
  final int amountRetained;
  final int amountRefunded;
  final int refundDue;
  final int balanceDue;
  final String? paymentRef;
  final DateTime? paymentDeadline;
  final DateTime? paidAt;
  final DateTime? riderReportedAt;
  final String? riderOperationNumber;
  final DateTime? rejectedAt;

  /// Métodos activos cuando se creó la reserva (startPayment los revalida).
  final List<String> methodsOffered;

  /// Se puede (volver a) pagar.
  bool get payable =>
      status == BookingPaymentStatus.awaitingPayment ||
      status == BookingPaymentStatus.failed;

  /// Avisó «ya pagué» y central aún no respondió.
  bool get reported =>
      status == BookingPaymentStatus.awaitingPayment && riderReportedAt != null;

  /// Central no encontró el pago avisado.
  bool get rejected => status == BookingPaymentStatus.failed;

  /// Hubo dinero de por medio: hay comprobante que mostrar.
  bool get hasReceipt => amountPaid > 0;

  static double bs(int cents) => cents / 100;
}

/// Datos de cobro del pago manual (config/ops.paymentInstructions.manual_qr).
class ManualInstructions {
  const ManualInstructions({
    required this.holderName,
    this.bankName,
    this.accountType,
    this.accountNumber,
    this.qrImageUrl,
    this.note,
  });

  factory ManualInstructions.fromJson(Map<String, dynamic> j) =>
      ManualInstructions(
        holderName: j['holderName'] as String? ?? '',
        bankName: j['bankName'] as String?,
        accountType: j['accountType'] as String?,
        accountNumber: j['accountNumber'] as String?,
        qrImageUrl: j['qrImageUrl'] as String?,
        note: j['note'] as String?,
      );

  final String holderName;
  final String? bankName;
  final String? accountType;
  final String? accountNumber;
  final String? qrImageUrl;
  final String? note;
}

/// Respuesta de startPayment.
class PaymentStart {
  const PaymentStart({
    required this.method,
    required this.amountDue,
    required this.paymentRef,
    this.paymentDeadline,
    this.instructions,
    this.clientSecret,
  });

  factory PaymentStart.fromJson(Map<String, dynamic> j) => PaymentStart(
        method: j['method'] as String? ?? PayMethod.manualQr,
        amountDue: _cents(j['amountDue']),
        paymentRef: j['paymentRef'] as String? ?? '',
        paymentDeadline: _date(j['paymentDeadline']),
        instructions: j['instructions'] is Map
            ? ManualInstructions.fromJson(
                Map<String, dynamic>.from(j['instructions'] as Map),
              )
            : null,
        clientSecret: j['clientSecret'] as String?,
      );

  final String method;
  final int amountDue;
  final String paymentRef;
  final DateTime? paymentDeadline;
  final ManualInstructions? instructions;
  final String? clientSecret;
}
