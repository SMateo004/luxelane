import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const Place({
    this.name = '',
    required this.address,
    required this.lat,
    required this.lng,
  });

  String get displayName => name.isNotEmpty ? name : address;

  GeoPoint get geoPoint => GeoPoint(lat, lng);
  LatLng get latLng => LatLng(lat, lng);

  factory Place.fromJson(Map<String, dynamic> json) {
    // Tolerante: documentos antiguos guardan lat/lng sueltos y algunos no
    // tienen dirección. Sin coordenadas no hay lugar válido.
    final geo = json['coordinates'];
    final double lat;
    final double lng;
    if (geo is GeoPoint) {
      lat = geo.latitude;
      lng = geo.longitude;
    } else if (json['lat'] is num && json['lng'] is num) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num).toDouble();
    } else {
      throw const FormatException('Lugar sin coordenadas');
    }
    final name = json['name'] as String? ?? '';
    return Place(
      name: name,
      address: json['address'] as String? ?? name,
      lat: lat,
      lng: lng,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'coordinates': GeoPoint(lat, lng),
      };

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.address == address &&
      other.lat == lat &&
      other.lng == lng;

  @override
  int get hashCode => Object.hash(address, lat, lng);
}

// ---------------------------------------------------------------------------
// Place autocomplete suggestion
// ---------------------------------------------------------------------------

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> j) {
    final sf = j['structured_formatting'] as Map<String, dynamic>?;
    return PlaceSuggestion(
      placeId: j['place_id'] as String,
      description: j['description'] as String,
      mainText: sf?['main_text'] as String? ?? j['description'] as String,
      secondaryText: sf?['secondary_text'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Route result from Directions API
// ---------------------------------------------------------------------------

class RouteInfo {
  const RouteInfo({
    required this.distanceKm,
    required this.durationMin,
    required this.polylinePoints,
  });

  final double distanceKm;
  final int durationMin;
  final List<LatLng> polylinePoints;
}
