import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';

/// One calendar day of the report (local time).
class OpsDay {
  const OpsDay(this.day, {this.trips = 0, this.revenue = 0});
  final DateTime day;
  final int trips;
  final double revenue;
}

/// Per-chauffeur line of the report.
class OpsDriverRow {
  const OpsDriverRow({
    required this.driverId,
    required this.name,
    required this.trips,
    required this.revenue,
    this.avgRating,
    this.ratingCount = 0,
  });
  final String driverId;
  final String name;
  final int trips;
  final double revenue;
  final double? avgRating;
  final int ratingCount;
}

/// Operations report over bookings whose pickup falls in [from, to).
///
/// Pure and synchronous so it can be unit-tested and recomputed on every
/// period change. Revenue counts completed rides only, at the final price
/// when the backend set one and at the quoted price otherwise.
class OpsReport {
  const OpsReport({
    required this.from,
    required this.to,
    required this.total,
    required this.completed,
    required this.revenue,
    required this.cancelled,
    required this.lateCancellations,
    required this.unserved,
    required this.cancelledBy,
    required this.avgRating,
    required this.ratingCount,
    required this.days,
    required this.demandByHour,
    required this.byVehicle,
    required this.byService,
    required this.drivers,
  });

  final DateTime from;
  final DateTime to;

  /// Every booking with pickup in the window, any status.
  final int total;
  final int completed;
  final double revenue;
  final int cancelled;

  /// Rider cancellations inside the late-cancellation window.
  final int lateCancellations;

  /// Cancelled automatically because no chauffeur took them.
  final int unserved;

  /// Cancellations keyed by 'rider' / 'admin' / 'system'.
  final Map<String, int> cancelledBy;

  final double? avgRating;
  final int ratingCount;

  /// Completed trips and revenue per day, one entry per day in the window.
  final List<OpsDay> days;

  /// All bookings (demand, including cancelled) by local pickup hour, 0–23.
  final List<int> demandByHour;

  /// Completed trips per vehicle class / service type (every value present).
  final Map<VehicleClass, int> byVehicle;
  final Map<ServiceType, int> byService;

  /// Chauffeurs with at least one completed trip, most trips first.
  final List<OpsDriverRow> drivers;

  double get avgTicket => completed == 0 ? 0 : revenue / completed;
  double get cancellationRate => total == 0 ? 0 : cancelled / total;

  /// Report for the [days] calendar days ending today (inclusive).
  factory OpsReport.lastDays(
    List<Booking> bookings,
    int days, {
    DateTime? now,
    String Function(String driverId)? driverName,
  }) {
    final n = now ?? DateTime.now();
    final to = DateTime(n.year, n.month, n.day + 1);
    final from = DateTime(to.year, to.month, to.day - days);
    return OpsReport.compute(bookings, from, to, driverName: driverName);
  }

  /// The window of the same length immediately before this one.
  OpsReport previous(List<Booking> bookings,
          {String Function(String driverId)? driverName}) =>
      OpsReport.compute(
        bookings,
        DateTime(from.year, from.month, from.day - days.length),
        from,
        driverName: driverName,
      );

  factory OpsReport.compute(
    List<Booking> bookings,
    DateTime from,
    DateTime to, {
    String Function(String driverId)? driverName,
  }) {
    // Day keys built with DateTime(y, m, d + i) so DST shifts never skip a day.
    final dayKeys = <DateTime>[];
    for (var d = from;
        d.isBefore(to);
        d = DateTime(d.year, d.month, d.day + 1)) {
      dayKeys.add(d);
    }
    final dayTrips = {for (final d in dayKeys) d: 0};
    final dayRevenue = {for (final d in dayKeys) d: 0.0};

    var total = 0, completed = 0, cancelled = 0, late = 0, unserved = 0;
    var revenue = 0.0, ratingSum = 0, ratingCount = 0;
    final cancelledBy = <String, int>{};
    final byHour = List<int>.filled(24, 0);
    final byVehicle = {for (final v in VehicleClass.values) v: 0};
    final byService = {for (final s in ServiceType.values) s: 0};
    final drv = <String, _DriverAcc>{};

    for (final b in bookings) {
      final at = b.effectivePickup;
      if (at.isBefore(from) || !at.isBefore(to)) continue;
      total++;
      byHour[at.hour]++;

      if (b.status == BookingStatus.cancelled) {
        cancelled++;
        if (b.lateCancellation) late++;
        if (b.cancelReason == 'no_driver_assigned') unserved++;
        // scheduledCleanup does not write cancelledBy; its reason is enough.
        final who =
            b.cancelReason == 'no_driver_assigned' ? 'system' : b.cancelledBy;
        if (who != null) cancelledBy[who] = (cancelledBy[who] ?? 0) + 1;
        continue;
      }
      if (b.status != BookingStatus.completed) continue;

      final price = b.finalPrice ?? b.estimatedPrice;
      completed++;
      revenue += price;
      final key = DateTime(at.year, at.month, at.day);
      dayTrips[key] = (dayTrips[key] ?? 0) + 1;
      dayRevenue[key] = (dayRevenue[key] ?? 0) + price;
      byVehicle[b.vehicleClass] = byVehicle[b.vehicleClass]! + 1;
      byService[b.serviceType] = byService[b.serviceType]! + 1;
      final r = b.riderRating;
      if (r != null) {
        ratingSum += r;
        ratingCount++;
      }

      final id = b.driverId;
      if (id != null && id.isNotEmpty) {
        final acc = drv.putIfAbsent(id, _DriverAcc.new);
        acc.trips++;
        acc.revenue += price;
        if (r != null) {
          acc.ratingSum += r;
          acc.ratingCount++;
        }
        final snap = b.chauffeur?.name ?? '';
        if (snap.isNotEmpty) acc.name = snap;
      }
    }

    final drivers = [
      for (final e in drv.entries)
        OpsDriverRow(
          driverId: e.key,
          name: e.value.name.isNotEmpty
              ? e.value.name
              : (driverName?.call(e.key) ?? ''),
          trips: e.value.trips,
          revenue: e.value.revenue,
          avgRating: e.value.ratingCount == 0
              ? null
              : e.value.ratingSum / e.value.ratingCount,
          ratingCount: e.value.ratingCount,
        ),
    ]..sort((a, b) => b.trips != a.trips
        ? b.trips.compareTo(a.trips)
        : b.revenue.compareTo(a.revenue));

    return OpsReport(
      from: from,
      to: to,
      total: total,
      completed: completed,
      revenue: revenue,
      cancelled: cancelled,
      lateCancellations: late,
      unserved: unserved,
      cancelledBy: cancelledBy,
      avgRating: ratingCount == 0 ? null : ratingSum / ratingCount,
      ratingCount: ratingCount,
      days: [
        for (final d in dayKeys)
          OpsDay(d, trips: dayTrips[d]!, revenue: dayRevenue[d]!),
      ],
      demandByHour: byHour,
      byVehicle: byVehicle,
      byService: byService,
      drivers: drivers,
    );
  }

  /// Daily table as CSV (RFC 4180), header labels supplied by the caller so
  /// the export follows the app language.
  String dailyCsv({
    required String dateHeader,
    required String tripsHeader,
    required String revenueHeader,
  }) {
    final b = StringBuffer()
      ..writeln([dateHeader, tripsHeader, revenueHeader].map(_csv).join(','));
    for (final d in days) {
      final date = '${d.day.year.toString().padLeft(4, '0')}-'
          '${d.day.month.toString().padLeft(2, '0')}-'
          '${d.day.day.toString().padLeft(2, '0')}';
      b.writeln('$date,${d.trips},${d.revenue.toStringAsFixed(2)}');
    }
    return b.toString();
  }

  /// Chauffeur table as CSV.
  String driversCsv({
    required String nameHeader,
    required String tripsHeader,
    required String revenueHeader,
    required String ratingHeader,
  }) {
    final b = StringBuffer()
      ..writeln([nameHeader, tripsHeader, revenueHeader, ratingHeader]
          .map(_csv)
          .join(','));
    for (final d in drivers) {
      b.writeln([
        _csv(d.name.isEmpty ? d.driverId : d.name),
        d.trips,
        d.revenue.toStringAsFixed(2),
        d.avgRating?.toStringAsFixed(2) ?? '',
      ].join(','));
    }
    return b.toString();
  }

  static String _csv(String v) {
    // Neutralise spreadsheet formulas from user-controlled names.
    var s = v;
    if (s.isNotEmpty && '=+-@'.contains(s[0])) s = "'$s";
    if (s.contains(RegExp(r'[",\n\r]'))) s = '"${s.replaceAll('"', '""')}"';
    return s;
  }
}

class _DriverAcc {
  int trips = 0;
  double revenue = 0;
  int ratingSum = 0;
  int ratingCount = 0;
  String name = '';
}
