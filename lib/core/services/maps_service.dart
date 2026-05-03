import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/place_model.dart';
// Web uses the Maps JS API (no CORS); mobile/desktop uses the HTTP REST API.
import 'places_web.dart' if (dart.library.io) 'places_stub.dart';

class MapsService {
  static const _base = 'maps.googleapis.com';
  String get _key => AppConfig.googleMapsKey;

  // Santa Cruz de la Sierra — bias center for all location queries
  static const _sczLat = -17.7833;
  static const _sczLng = -63.1821;

  // ---------------------------------------------------------------------------
  // Current device location
  // ---------------------------------------------------------------------------

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Reverse geocode lat/lng → Place
  // ---------------------------------------------------------------------------

  Future<Place?> reverseGeocode(double lat, double lng) async {
    // Web: use Maps JS Geocoder (no CORS issue)
    if (kIsWeb) return webReverseGeocode(lat, lng);

    // Mobile: HTTP REST API
    if (_key.isEmpty) return null;
    try {
      final uri = Uri.https(_base, '/maps/api/geocode/json', {
        'latlng': '$lat,$lng',
        'key': _key,
      });
      final res = await http.get(uri);
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final r = results.first as Map<String, dynamic>;
      return Place(
        address: r['formatted_address'] as String,
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Places Autocomplete
  // ---------------------------------------------------------------------------

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String? sessionToken,
  }) async {
    if (input.length < 2) return [];

    // Web: use Maps JS AutocompleteService (no CORS issue)
    if (kIsWeb) {
      return webAutocomplete(input);
    }

    // Mobile: HTTP REST API
    if (_key.isEmpty) return [];
    try {
      final params = <String, String>{
        'input': input,
        'key': _key,
        'types': 'geocode|establishment',
        'location': '$_sczLat,$_sczLng',
        'radius': '50000',
        'components': 'country:bo',
        'language': 'es',
      };
      if (sessionToken != null) params['sessiontoken'] = sessionToken;

      final uri = Uri.https(
        _base,
        '/maps/api/place/autocomplete/json',
        params,
      );
      final res = await http.get(uri);
      final data = json.decode(res.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List? ?? [];
      return predictions
          .map((p) => PlaceSuggestion.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Place Details (placeId → Place)
  // ---------------------------------------------------------------------------

  Future<Place?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? address,
  }) async {
    // Web: use Maps JS PlacesService (no CORS issue)
    if (kIsWeb) return webPlaceDetails(placeId, address: address);

    // Mobile: HTTP REST API
    if (_key.isEmpty) return null;
    try {
      final params = <String, String>{
        'place_id': placeId,
        'fields': 'geometry,name,formatted_address',
        'key': _key,
      };
      if (sessionToken != null) params['sessiontoken'] = sessionToken;

      final uri =
          Uri.https(_base, '/maps/api/place/details/json', params);
      final res = await http.get(uri);
      final data = json.decode(res.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final loc = (result['geometry'] as Map)['location'] as Map;
      return Place(
        name: result['name'] as String? ?? '',
        address: result['formatted_address'] as String,
        lat: (loc['lat'] as num).toDouble(),
        lng: (loc['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Directions (origin → destination)
  // ---------------------------------------------------------------------------

  Future<RouteInfo?> getRoute({
    required Place origin,
    required Place destination,
  }) async {
    // Web: use Maps JS DirectionsService (no CORS issue)
    if (kIsWeb) {
      return webGetRoute(origin: origin, destination: destination);
    }

    // Mobile: HTTP REST API (with mock fallback when no key)
    if (_key.isEmpty) {
      return RouteInfo(
        distanceKm: 25.0,
        durationMin: 30,
        polylinePoints: [origin.latLng, destination.latLng],
      );
    }
    try {
      final uri = Uri.https(_base, '/maps/api/directions/json', {
        'origin': '${origin.lat},${origin.lng}',
        'destination': '${destination.lat},${destination.lng}',
        'key': _key,
      });
      final res = await http.get(uri);
      final data = json.decode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final leg =
          (routes.first as Map)['legs'][0] as Map<String, dynamic>;
      final encodedPolyline =
          (routes.first as Map)['overview_polyline']['points'] as String;

      return RouteInfo(
        distanceKm:
            ((leg['distance'] as Map)['value'] as int) / 1000.0,
        durationMin:
            ((leg['duration'] as Map)['value'] as int) ~/ 60,
        polylinePoints: _decodePolyline(encodedPolyline),
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Polyline decoder (Google encoded polyline algorithm) — mobile only
  // ---------------------------------------------------------------------------

  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
