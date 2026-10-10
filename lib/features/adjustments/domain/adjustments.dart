import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';

/// Mirrors functions/src/adjustments.ts.
abstract final class Adjustments {
  static const maxAmount = 2000.0;

  /// From the chauffeur's arrival until the ride is completed, and not for
  /// card payments (they can't be charged more after capture).
  static bool canAdjust(Booking b) =>
      b.paymentMethod != 'card' &&
      (b.status == BookingStatus.driverArrived ||
          b.status == BookingStatus.inProgress ||
          b.status == BookingStatus.completed);

  static double _round2(double v) => (v * 100).round() / 100;

  /// Total after adding [amount].
  static double totalWith(Booking b, double amount) => _round2(b.paidAmount + amount);

  static String? validate(Booking b, AdjustmentType? type, double? amount, String note) {
    if (type == null) return 'adjust/type';
    if (amount == null || amount == 0 || ((amount * 100) - (amount * 100).round()).abs() > 1e-6 || amount.abs() > maxAmount) {
      return 'adjust/amount';
    }
    if (amount < 0 && type != AdjustmentType.correction) return 'adjust/amount';
    final total = totalWith(b, amount);
    if (total < 0 || total < b.refundedAmount) return 'adjust/below-zero';
    if (type == AdjustmentType.correction && note.trim().length < 3) return 'adjust/note';
    return null;
  }
}
