import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';

/// Who collected the fare of a completed ride.
enum FareCollector {
  /// Paid to the chauffeur at the end of the trip (cash or QR).
  chauffeur,

  /// Billed to a company (monthly invoice) or charged to a card: Luxelane
  /// collects and owes the chauffeur their share.
  luxelane,
}

FareCollector collectorOf(Booking b) {
  if (b.isCorporate || b.paymentMethod == 'corporate') return FareCollector.luxelane;
  if (b.paymentMethod == 'card' || b.stripePaymentIntentId != null) return FareCollector.luxelane;
  return FareCollector.chauffeur;
}

/// Weekly settlement of one chauffeur.
///
/// [balance] > 0: Luxelane pays the chauffeur (their share of the rides
/// Luxelane collected, minus commission on the rides they collected).
/// [balance] < 0: the chauffeur owes Luxelane that commission.
class DriverSettlement {
  const DriverSettlement({
    required this.driverId,
    required this.driverName,
    required this.trips,
    required this.gross,
    required this.collectedByChauffeur,
    required this.collectedByLuxelane,
    required this.commission,
  });

  final String driverId;
  final String driverName;
  final int trips;

  /// Sum of fares of completed rides.
  final double gross;
  final double collectedByChauffeur;
  final double collectedByLuxelane;
  final double commission;

  /// What the chauffeur keeps from the week.
  double get earnings => gross - commission;

  double get balance => collectedByLuxelane - commission;
}

abstract final class Settlements {
  /// Monday 00:00 (local) of the week containing [d].
  static DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

  static DateTime weekEnd(DateTime start) => DateTime(start.year, start.month, start.day + 7);

  static double fare(Booking b) => b.finalPrice ?? b.estimatedPrice;

  /// Commission on one fare, rounded to cents.
  static double commissionOn(double fare, double pct) => (fare * pct / 100 * 100).roundToDouble() / 100;

  /// One settlement per chauffeur with completed rides whose pickup falls in
  /// the week starting [start]. Largest amounts first.
  static List<DriverSettlement> compute(List<Booking> bookings, DateTime start, double commissionPct) {
    final end = weekEnd(start);
    final acc = <String, _Acc>{};
    for (final b in bookings) {
      final id = b.driverId;
      final at = b.effectivePickup;
      if (b.status != BookingStatus.completed || id == null || id.isEmpty) continue;
      if (at.isBefore(start) || !at.isBefore(end)) continue;
      final a = acc.putIfAbsent(id, _Acc.new);
      final f = fare(b);
      a.trips++;
      a.gross += f;
      a.commission += commissionOn(f, commissionPct);
      if (collectorOf(b) == FareCollector.chauffeur) {
        a.byChauffeur += f;
      } else {
        a.byLuxelane += f;
      }
      final name = b.chauffeur?.name ?? '';
      if (name.isNotEmpty) a.name = name;
    }
    return [
      for (final e in acc.entries)
        DriverSettlement(
          driverId: e.key,
          driverName: e.value.name,
          trips: e.value.trips,
          gross: e.value.gross,
          collectedByChauffeur: e.value.byChauffeur,
          collectedByLuxelane: e.value.byLuxelane,
          commission: (e.value.commission * 100).roundToDouble() / 100,
        ),
    ]..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
  }

  static String recordId(String driverId, DateTime weekStart) =>
      '${driverId}_${weekStart.year}${weekStart.month.toString().padLeft(2, '0')}${weekStart.day.toString().padLeft(2, '0')}';

  /// Settlement table as CSV (RFC 4180, formula-safe).
  static String csv(List<DriverSettlement> rows, {required List<String> headers}) {
    String cell(String v) {
      var s = v;
      if (s.isNotEmpty && '=+-@'.contains(s[0])) s = "'$s";
      if (s.contains(RegExp(r'[",\n\r]'))) s = '"${s.replaceAll('"', '""')}"';
      return s;
    }

    final out = StringBuffer()..writeln(headers.map(cell).join(','));
    for (final r in rows) {
      out.writeln([
        cell(r.driverName.isEmpty ? r.driverId : r.driverName),
        r.trips,
        r.gross.toStringAsFixed(2),
        r.collectedByChauffeur.toStringAsFixed(2),
        r.collectedByLuxelane.toStringAsFixed(2),
        r.commission.toStringAsFixed(2),
        r.balance.toStringAsFixed(2),
      ].join(','));
    }
    return out.toString();
  }
}

class _Acc {
  int trips = 0;
  double gross = 0, byChauffeur = 0, byLuxelane = 0, commission = 0;
  String name = '';
}

/// A week marked as settled by an admin (settlements/{driverId}_{yyyyMMdd}).
class SettlementRecord {
  const SettlementRecord({
    required this.driverId,
    required this.weekStart,
    required this.balance,
    required this.commissionPct,
    this.paidAt,
  });

  final String driverId;
  final DateTime weekStart;

  /// Amount settled (same sign convention as [DriverSettlement.balance]).
  final double balance;
  final double commissionPct;
  final DateTime? paidAt;

  factory SettlementRecord.fromJson(Map<String, dynamic> j) => SettlementRecord(
        driverId: j['driverId'] as String? ?? '',
        weekStart: (j['weekStart'] as Timestamp?)?.toDate() ?? DateTime(2000),
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        commissionPct: (j['commissionPct'] as num?)?.toDouble() ?? 0,
        paidAt: (j['paidAt'] as Timestamp?)?.toDate(),
      );
}
