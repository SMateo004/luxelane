import 'dart:math' as math;

/// Rough arrival estimate from the chauffeur's live position.
///
/// Straight-line distance × a city road factor, at an average urban speed.
/// Good enough for "llega en 6 min"; not a routing engine.
abstract class Eta {
  static const roadFactor = 1.35;

  /// Average door-to-door speed in the city (km/h).
  static const citySpeedKmh = 25.0;

  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  static Duration estimate({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final km = haversineKm(fromLat, fromLng, toLat, toLng) * roadFactor;
    final minutes = (km / citySpeedKmh * 60).ceil();
    return Duration(minutes: math.max(1, minutes));
  }

  /// "4 min", "1 h 05 min".
  static String format(Duration d) {
    final m = d.inMinutes;
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${(m % 60).toString().padLeft(2, '0')} min';
  }
}
