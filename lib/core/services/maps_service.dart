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
  // Uses Places API (New) REST — works on web + mobile, no JS interop needed.
  // ---------------------------------------------------------------------------

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String? sessionToken,
  }) async {
    if (input.length < 2) return [];
    if (_key.isEmpty) return [];

    try {
      // ── Places API (New) ─────────────────────────────────────────────────────
      final uri = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _key,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.structuredFormat,'
              'suggestions.placePrediction.text',
        },
        body: json.encode({
          'input': input,
          'languageCode': 'es',
          'regionCode': 'BO',
          'locationBias': {
            'circle': {
              'center': {'latitude': _sczLat, 'longitude': _sczLng},
              'radius': 50000.0,
            },
          },
        }),
      );

      debugPrint('[Maps] Places v1 status=${res.statusCode} body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List? ?? [];
        final results = <PlaceSuggestion>[];
        for (final s in suggestions) {
          final pred = (s as Map<String, dynamic>)['placePrediction']
              as Map<String, dynamic>? ?? {};
          final placeId = pred['placeId'] as String? ?? '';
          if (placeId.isEmpty) continue;
          final structured = pred['structuredFormat']
              as Map<String, dynamic>? ?? {};
          final mainText = ((structured['mainText']
              as Map<String, dynamic>?)?['text'] as String?) ?? '';
          final secText = ((structured['secondaryText']
              as Map<String, dynamic>?)?['text'] as String?) ?? '';
          final fullText = ((pred['text']
              as Map<String, dynamic>?)?['text'] as String?) ?? '';
          results.add(PlaceSuggestion(
            placeId: placeId,
            description: fullText,
            mainText: mainText.isNotEmpty ? mainText : fullText,
            secondaryText: secText,
          ));
        }
        if (results.isNotEmpty) return results;
      }
    } catch (e) {
      debugPrint('[Maps] Places v1 exception: $e');
    }

    // ── Classic Places API fallback ──────────────────────────────────────────
    try {
      final params = <String, String>{
        'input': input,
        'key': _key,
        'location': '$_sczLat,$_sczLng',
        'radius': '50000',
        'components': 'country:bo',
        'language': 'es',
      };
      if (sessionToken != null) params['sessiontoken'] = sessionToken;
      final uri = Uri.https(_base, '/maps/api/place/autocomplete/json', params);
      final res = await http.get(uri);
      debugPrint('[Maps] Classic status=${res.statusCode}');
      if (res.statusCode != 200) {
        debugPrint('[Maps] Classic body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
      } else {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List? ?? [];
        debugPrint('[Maps] Classic predictions=${predictions.length}');
        if (predictions.isNotEmpty) {
          return predictions
              .map((p) => PlaceSuggestion.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[Maps] Classic exception: $e');
    }

    // ── Web JS API final fallback ─────────────────────────────────────────────
    // If both REST calls failed (CORS, key restrictions, etc.), try the Maps JS
    // API which is already loaded in the browser and bypasses all that.
    if (kIsWeb) {
      try {
        final jsResults = await webAutocomplete(input);
        debugPrint('[Maps] JS API results=${jsResults.length}');
        return jsResults;
      } catch (e) {
        debugPrint('[Maps] JS API exception: $e');
      }
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // Place Details (placeId → Place)
  // Uses Places API (New) REST — works on web + mobile.
  // ---------------------------------------------------------------------------

  Future<Place?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? address,
  }) async {
    if (_key.isEmpty) {
      // No key on web: fall back to JS geocoder
      if (kIsWeb) return webPlaceDetails(placeId, address: address);
      return null;
    }

    try {
      // ── Places API (New) ───────────────────────────────────────────────────
      final uri = Uri.parse(
          'https://places.googleapis.com/v1/places/$placeId');
      final res = await http.get(uri, headers: {
        'X-Goog-Api-Key': _key,
        'X-Goog-FieldMask': 'id,location,displayName,formattedAddress',
      });

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final loc = data['location'] as Map<String, dynamic>?;
        if (loc != null) {
          final displayName = (data['displayName']
              as Map<String, dynamic>?)?['text'] as String?;
          return Place(
            name: displayName ?? address?.split(',').first ?? '',
            address: data['formattedAddress'] as String? ?? address ?? '',
            lat: (loc['latitude'] as num).toDouble(),
            lng: (loc['longitude'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}

    // ── Classic Places API fallback ──────────────────────────────────────────
    try {
      final params = <String, String>{
        'place_id': placeId,
        'fields': 'geometry,name,formatted_address',
        'key': _key,
      };
      if (sessionToken != null) params['sessiontoken'] = sessionToken;
      final uri = Uri.https(_base, '/maps/api/place/details/json', params);
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
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
      // Last resort: JS geocoder on web
      if (kIsWeb) return webPlaceDetails(placeId, address: address);
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
