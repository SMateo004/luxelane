import '../../l10n/gen/app_localizations.dart';
import '../models/models.dart';

/// Free waiting time included in every fixed price.
/// Mirrors `freeWaitEnd` in functions/src/policy.ts.
abstract class WaitingPolicy {
  static const airportFreeMinutes = 60;
  static const cityFreeMinutes = 15;

  /// Airport pickups are the ones with a flight number.
  static bool isAirport(Booking b) => (b.flightNumber ?? '').trim().isNotEmpty;

  static int freeMinutes(Booking b) => isAirport(b) ? airportFreeMinutes : cityFreeMinutes;

  /// Airport: from landing (or pickup if unknown).
  /// City: from the later of pickup time and the chauffeur's arrival.
  static DateTime waitStart(Booking b) {
    if (isAirport(b)) return b.flight?.estimatedArrival ?? b.effectivePickup;
    final arrived = b.driverArrivedAt;
    final pickup = b.effectivePickup;
    return arrived != null && arrived.isAfter(pickup) ? arrived : pickup;
  }

  static DateTime freeUntil(Booking b) => waitStart(b).add(Duration(minutes: freeMinutes(b)));

  /// Remaining free wait, or null once it is over.
  static Duration? remaining(Booking b, {DateTime? now}) {
    final left = freeUntil(b).difference(now ?? DateTime.now());
    return left.isNegative ? null : left;
  }

  static String localizedSummary(AppLocalizations l, Booking b) => isAirport(b)
      ? l.waitAirportSummary(airportFreeMinutes)
      : l.waitCitySummary(cityFreeMinutes);

  @Deprecated('Use localizedSummary')
  static String summary(Booking b) => isAirport(b)
      ? '$airportFreeMinutes min de espera gratuita desde el aterrizaje'
      : '$cityFreeMinutes min de espera gratuita';
}
