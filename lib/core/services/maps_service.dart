import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/place_model.dart';
import '../utils/service_area.dart';
// Web uses the Maps JS API (no CORS); mobile/desktop uses the HTTP REST API.
import 'places_web.dart' if (dart.library.io) 'places_stub.dart';

class MapsService {
  static const _base = 'maps.googleapis.com';
  String get _key => AppConfig.googleMapsKey;

  // Santa Cruz de la Sierra — default center for location queries when the
  // user's own position is unknown or outside Bolivia.
  static const _sczLat = -17.7833;
  static const _sczLng = -63.1821;

  // Radius around the search center that results are biased to (~ a city).
  static const _cityRadiusMeters = 30000.0;

  // Search center, cached so we read the device position at most once per
  // [_centerTtl] instead of on every keystroke.
  static ({double lat, double lng})? _center;
  static DateTime? _centerAt;
  static const _centerTtl = Duration(minutes: 10);

  static bool _inBolivia(double lat, double lng) =>
      lat >= -22.95 && lat <= -9.65 && lng >= -69.7 && lng <= -57.4;

  /// Center for autocomplete: the user's position when location permission
  /// is already granted and they are in Bolivia, otherwise Santa Cruz.
  /// Never shows a permission prompt — typing in a search box shouldn't.
  Future<({double lat, double lng})> _searchCenter() async {
    final cached = _center;
    if (cached != null &&
        _centerAt != null &&
        DateTime.now().difference(_centerAt!) < _centerTtl) {
      return cached;
    }
    var center = (lat: _sczLat, lng: _sczLng);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
        if (_inBolivia(pos.latitude, pos.longitude)) {
          center = (lat: pos.latitude, lng: pos.longitude);
        }
      }
    } catch (_) {
      // Keep the Santa Cruz default.
    }
    _center = center;
    _centerAt = DateTime.now();
    return center;
  }

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

  /// Ubicación continua del chófer conectado. En Android corre como
  /// servicio en primer plano (con una notificación fija) y en iOS con el
  /// indicador azul, así sigue llegando con la app minimizada. Emite un
  /// error si no hay permiso de ubicación.
  Stream<Position> driverPositionStream() async* {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('location');
    }
    final LocationSettings settings;
    if (kIsWeb) {
      settings = const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 25);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Luxelane · estás conectado',
          notificationText:
              'Compartimos tu ubicación para asignarte viajes y guiar al '
              'pasajero.',
          notificationChannelName: 'Ubicación del chófer',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      settings = const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 25);
    }
    yield* Geolocator.getPositionStream(locationSettings: settings);
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

  /// With [restrictTo], only places inside that circle are returned (used to
  /// keep the destination in the pickup's city); otherwise results are only
  /// biased to the user's city.
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String? sessionToken,
    SearchArea? restrictTo,
  }) async {
    if (input.length < 2) return [];
    if (_key.isEmpty) return [];

    final center = restrictTo != null
        ? (lat: restrictTo.lat, lng: restrictTo.lng)
        : await _searchCenter();
    final radius = restrictTo?.radiusMeters ?? _cityRadiusMeters;
    final circle = {
      'circle': {
        'center': {'latitude': center.lat, 'longitude': center.lng},
        'radius': radius,
      },
    };

    try {
      // ── Places API (New) ─────────────────────────────────────────────────────
      final uri =
          Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _key,
          'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.structuredFormat,'
              'suggestions.placePrediction.text',
        },
        body: json.encode({
          'input': input,
          'languageCode': 'es',
          'regionCode': 'BO',
          // Only places in Bolivia; the user's city first (or only).
          'includedRegionCodes': ['bo'],
          if (restrictTo != null)
            'locationRestriction': circle
          else
            'locationBias': circle,
        }),
      );

      debugPrint(
          '[Maps] Places v1 status=${res.statusCode} body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List? ?? [];
        final results = <PlaceSuggestion>[];
        for (final s in suggestions) {
          final pred = (s as Map<String, dynamic>)['placePrediction']
                  as Map<String, dynamic>? ??
              {};
          final placeId = pred['placeId'] as String? ?? '';
          if (placeId.isEmpty) continue;
          final structured =
              pred['structuredFormat'] as Map<String, dynamic>? ?? {};
          final mainText = ((structured['mainText']
                  as Map<String, dynamic>?)?['text'] as String?) ??
              '';
          final secText = ((structured['secondaryText']
                  as Map<String, dynamic>?)?['text'] as String?) ??
              '';
          final fullText =
              ((pred['text'] as Map<String, dynamic>?)?['text'] as String?) ??
                  '';
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
        'location': '${center.lat},${center.lng}',
        'radius': '${radius.toInt()}',
        'components': 'country:bo',
        'language': 'es',
        if (restrictTo != null) 'strictbounds': 'true',
      };
      if (sessionToken != null) params['sessiontoken'] = sessionToken;
      final uri = Uri.https(_base, '/maps/api/place/autocomplete/json', params);
      final res = await http.get(uri);
      debugPrint('[Maps] Classic status=${res.statusCode}');
      if (res.statusCode != 200) {
        debugPrint(
            '[Maps] Classic body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
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
        final jsResults = await webAutocomplete(input,
            lat: center.lat,
            lng: center.lng,
            radiusMeters: radius,
            strict: restrictTo != null);
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
      final uri = Uri.parse('https://places.googleapis.com/v1/places/$placeId');
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

    // Mobile: HTTP REST API. Sin clave no hay ruta: nunca se inventa una
    // distancia (el precio lo calcula el servidor).
    if (_key.isEmpty) return null;
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

      final leg = (routes.first as Map)['legs'][0] as Map<String, dynamic>;
      final encodedPolyline =
          (routes.first as Map)['overview_polyline']['points'] as String;

      return RouteInfo(
        distanceKm: ((leg['distance'] as Map)['value'] as int) / 1000.0,
        durationMin: ((leg['duration'] as Map)['value'] as int) ~/ 60,
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
