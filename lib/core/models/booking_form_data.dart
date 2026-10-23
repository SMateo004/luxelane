import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../enums/enums.dart';
import 'place_model.dart';

/// Antelación mínima de una recogida programada.
const kMinPickupLead = Duration(minutes: 15);

/// Si [t] ya no da tiempo a recoger, la primera hora válida (cuarto de hora
/// siguiente a 30 min); si no, null.
DateTime? adjustedPickup(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (!t.isBefore(n.add(kMinPickupLead))) return null;
  final m = n.add(const Duration(minutes: 30));
  final q = ((m.minute + 14) ~/ 15) * 15;
  return DateTime(m.year, m.month, m.day, m.hour).add(Duration(minutes: q));
}

class BookingFormData {
  const BookingFormData({
    required this.origin,
    this.destination,
    required this.serviceType,
    required this.scheduledAt,
    this.hours = 3,
    this.routeDistanceKm = 0,
    this.routeDurationMin = 0,
    this.polylinePoints = const [],
    this.preferredClass,
  });

  /// Clase elegida antes de reservar (p. ej. en una página de servicio).
  final VehicleClass? preferredClass;

  final Place origin;
  final Place? destination;
  final ServiceType serviceType;
  final DateTime scheduledAt;
  final int hours;
  final double routeDistanceKm;
  final int routeDurationMin;
  final List<LatLng> polylinePoints;

  /// La misma reserva con el recorrido real por calles.
  BookingFormData withRoute(RouteInfo route) => BookingFormData(
    origin: origin,
    destination: destination,
    serviceType: serviceType,
    scheduledAt: scheduledAt,
    hours: hours,
    routeDistanceKm: route.distanceKm,
    routeDurationMin: route.durationMin,
    polylinePoints: route.polylinePoints,
    preferredClass: preferredClass,
  );
}
