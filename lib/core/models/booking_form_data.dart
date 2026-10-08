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
    this.days = 1,
    this.routeDistanceKm = 0,
    this.routeDurationMin = 0,
    this.polylinePoints = const [],
    this.pickupNote = '',
  });

  final Place origin;
  final Place? destination;
  final ServiceType serviceType;
  final DateTime scheduledAt;
  final int hours;

  /// Chauffeur by the day (hourly service only).
  final int days;
  final double routeDistanceKm;
  final int routeDurationMin;
  final List<LatLng> polylinePoints;

  /// Meeting point for the chauffeur (e.g. a partner hotel's lobby); added
  /// to the booking notes.
  final String pickupNote;
}
