import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';

/// How a refund is paid back (mirrors functions/src/refunds.ts). Luxelane
/// charges without card processing, so refunds happen outside the app.
enum RefundMethod { qr, transfer, cash, invoiceCredit }

abstract final class Refunds {
  /// Left to refund on a completed ride, in Bs with cents.
  static double refundable(Booking b) =>
      ((b.paidAmount - b.refundedAmount) * 100).round().clamp(0, 1 << 40) / 100;

  static bool canRefund(Booking b) => b.status == BookingStatus.completed && refundable(b) > 0;

  /// Methods that fit the booking: company rides are credited on the invoice.
  static List<RefundMethod> methodsFor(Booking b) => b.isCorporate
      ? const [RefundMethod.invoiceCredit]
      : const [RefundMethod.qr, RefundMethod.transfer, RefundMethod.cash];

  /// Same checks as the server; returns a refund/* code or null.
  static String? validate(Booking b, double? amount, RefundMethod? method, String reason) {
    if (amount == null || amount <= 0 || (amount * 100).round() != amount * 100) return 'refund/amount';
    if (amount > refundable(b)) return 'refund/too-much';
    if (method == null || !methodsFor(b).contains(method)) return 'refund/method';
    if (reason.trim().length < 3) return 'refund/reason';
    return null;
  }
}
