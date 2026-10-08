/// Luxelane Circle tiers (mirrors functions/src/loyalty.ts).
enum LoyaltyTierId { silver, gold, platinum }

LoyaltyTierId? tierIdFrom(Object? v) {
  for (final t in LoyaltyTierId.values) {
    if (t.name == v) return t;
  }
  return null;
}

class LoyaltyTier {
  const LoyaltyTier({required this.id, required this.minRides, required this.discountPct});

  final LoyaltyTierId id;

  /// Completed rides in the last 12 months needed for this tier.
  final int minRides;
  final double discountPct;

  static LoyaltyTier? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = tierIdFrom(raw['id']);
    if (id == null) return null;
    return LoyaltyTier(
      id: id,
      minRides: (raw['minRides'] as num?)?.toInt() ?? 0,
      discountPct: (raw['discountPct'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id.name, 'minRides': minRides, 'discountPct': discountPct};
}

/// The rider's standing, from the myLoyalty Cloud Function.
class LoyaltyStatus {
  const LoyaltyStatus({required this.enabled, this.rides = 0, this.tier, this.next, this.tiers = const []});

  static const off = LoyaltyStatus(enabled: false);

  final bool enabled;

  /// Completed rides in the last 12 months.
  final int rides;
  final LoyaltyTier? tier;
  final LoyaltyTier? next;
  final List<LoyaltyTier> tiers;

  int get ridesToNext => next == null ? 0 : (next!.minRides - rides).clamp(0, 1 << 30);

  /// Progress from the current tier (or zero) towards the next one, 0–1.
  double get progress {
    final n = next;
    if (n == null) return 1;
    final from = tier?.minRides ?? 0;
    return ((rides - from) / (n.minRides - from)).clamp(0, 1).toDouble();
  }

  factory LoyaltyStatus.fromJson(Map<String, dynamic> j) => LoyaltyStatus(
        enabled: j['enabled'] == true,
        rides: (j['rides'] as num?)?.toInt() ?? 0,
        tier: LoyaltyTier.fromJson(j['tier']),
        next: LoyaltyTier.fromJson(j['next']),
        tiers: (j['tiers'] as List? ?? const []).map(LoyaltyTier.fromJson).whereType<LoyaltyTier>().toList(),
      );
}

abstract final class Loyalty {
  static const maxDiscount = 20.0;

  /// Whole Bolivianos, rounded down (same as the server).
  static double discount(double fare, double pct) => pct <= 0 ? 0 : (fare * pct / 100).floorToDouble().clamp(0, fare);

  /// Same checks as the server: climbing thresholds and discounts.
  static String? configError(List<LoyaltyTier> tiers) {
    if (tiers.isEmpty) return 'loyalty/no-tiers';
    for (final t in tiers) {
      if (t.minRides < 1) return 'loyalty/min-rides';
      if (t.discountPct < 0 || t.discountPct > maxDiscount) return 'loyalty/discount-range';
    }
    for (var i = 1; i < tiers.length; i++) {
      if (tiers[i].minRides <= tiers[i - 1].minRides) return 'loyalty/thresholds-order';
      if (tiers[i].discountPct < tiers[i - 1].discountPct) return 'loyalty/discounts-order';
    }
    return null;
  }
}
