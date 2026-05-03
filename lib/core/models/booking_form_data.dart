import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../enums/enums.dart';
import 'place_model.dart';

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
  });

  final Place origin;
  final Place? destination;
  final ServiceType serviceType;
  final DateTime scheduledAt;
  final int hours;
  final double routeDistanceKm;
  final int routeDurationMin;
  final List<LatLng> polylinePoints;
}
