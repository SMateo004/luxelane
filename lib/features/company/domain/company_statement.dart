import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';

/// One line of a statement grouping (cost center or traveler).
class StatementGroup {
  const StatementGroup(this.key, this.trips, this.amount);

  /// Cost center name or rider uid; null = "no cost center".
  final String? key;
  final int trips;
  final double amount;
}

/// Monthly statement of a corporate account: what will be invoiced.
///
/// Only completed rides are billed, at the final price when set and at the
/// quoted price otherwise. Late cancellations are listed for information
/// (there is no cancellation fee yet).
class CompanyStatement {
  const CompanyStatement({
    required this.month,
    required this.bookings,
    required this.completed,
    required this.total,
    required this.upcoming,
    required this.cancelled,
    required this.lateCancellations,
    required this.byCostCenter,
    required this.byTraveler,
  });

  /// First day of the month (local time).
  final DateTime month;

  /// Every booking of the month, newest pickup first.
  final List<Booking> bookings;
  final int completed;
  final double total;
  final int upcoming;
  final int cancelled;
  final int lateCancellations;
  final List<StatementGroup> byCostCenter;
  final List<StatementGroup> byTraveler;

  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
  static DateTime nextMonth(DateTime m) => DateTime(m.year, m.month + 1);

  static double billable(Booking b) => b.finalPrice ?? b.estimatedPrice;

  factory CompanyStatement.compute(List<Booking> all, DateTime month) {
    final from = monthStart(month);
    final to = nextMonth(from);
    final list = all
        .where((b) => !b.scheduledAt.isBefore(from) && b.scheduledAt.isBefore(to))
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    var completed = 0, upcoming = 0, cancelled = 0, late = 0;
    var total = 0.0;
    final cc = <String?, (int, double)>{};
    final tr = <String, (int, double)>{};
    for (final b in list) {
      switch (b.status) {
        case BookingStatus.completed:
          final amount = billable(b);
          completed++;
          total += amount;
          final c = cc[b.costCenter] ?? (0, 0.0);
          cc[b.costCenter] = (c.$1 + 1, c.$2 + amount);
          final t = tr[b.riderId] ?? (0, 0.0);
          tr[b.riderId] = (t.$1 + 1, t.$2 + amount);
        case BookingStatus.cancelled:
          cancelled++;
          if (b.lateCancellation) late++;
        default:
          upcoming++;
      }
    }

    List<StatementGroup> groups<K>(Map<K, (int, double)> m) => [
          for (final e in m.entries) StatementGroup(e.key as String?, e.value.$1, e.value.$2),
        ]..sort((a, b) => b.amount.compareTo(a.amount));

    return CompanyStatement(
      month: from,
      bookings: list,
      completed: completed,
      total: total,
      upcoming: upcoming,
      cancelled: cancelled,
      lateCancellations: late,
      byCostCenter: groups(cc),
      byTraveler: groups(tr),
    );
  }

  /// Detail of the billed rides as CSV (RFC 4180, formula-safe). Headers and
  /// display values come from the caller so the file follows the app language.
  String csv({
    required List<String> headers,
    required String Function(Booking) date,
    required String Function(Booking) traveler,
    required String Function(Booking) vehicle,
  }) {
    final out = StringBuffer()..writeln(headers.map(_cell).join(','));
    for (final b in bookings.where((b) => b.status == BookingStatus.completed)) {
      out.writeln([
        _cell(date(b)),
        _cell(traveler(b)),
        _cell(b.passengerName ?? ''),
        _cell(b.origin.displayName),
        _cell(b.serviceType == ServiceType.byTheHour ? '' : b.destination.displayName),
        _cell(vehicle(b)),
        _cell(b.costCenter ?? ''),
        _cell(b.billingReference ?? ''),
        billable(b).toStringAsFixed(2),
      ].join(','));
    }
    return out.toString();
  }

  static String _cell(String v) {
    var s = v;
    if (s.isNotEmpty && '=+-@'.contains(s[0])) s = "'$s";
    if (s.contains(RegExp(r'[",\n\r]'))) s = '"${s.replaceAll('"', '""')}"';
    return s;
  }
}
