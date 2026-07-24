// Web-only — uses Google Maps JS API (already loaded in browser, no CORS).
// Requires Maps JavaScript API + Places API (New) enabled in Cloud Console.
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place_model.dart';

const _sczLat = -17.7833;
const _sczLng = -63.1821;

void _dbg(String msg) {
  // ignore: avoid_print
  print('[Places] $msg');
}

// ── String extractor that handles both String and FormattableText {text:str} ──
String _str(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) return raw;
  // FormattableText object — use js_util (works on Promise-resolved objects)
  try { return js_util.getProperty(raw as Object, 'text') as String? ?? ''; }
  catch (_) {}
  // Fallback: dart:js [] operator
  try { return (raw as js.JsObject)['text'] as String? ?? ''; }
  catch (_) { return ''; }
}

// ── Property access that works on Promise-resolved JS objects ─────────────────
dynamic _prop(dynamic obj, String key) {
  if (obj == null) return null;
  // Try js_util first (for promise-resolved values)
  try { return js_util.getProperty(obj as Object, key); } catch (_) {}
  // Fallback to dart:js [] (for JsObject instances)
  try { return (obj as js.JsObject)[key]; } catch (_) { return null; }
}

// ── Autocomplete ──────────────────────────────────────────────────────────────

Future<List<PlaceSuggestion>> webAutocomplete(
  String input, {
  double lat = _sczLat,
  double lng = _sczLng,
}) async {
  try {
    final google = js.context['google'];
    if (google == null) { _dbg('google not loaded'); return []; }
    final maps = _prop(google, 'maps');
    if (maps == null) { _dbg('maps not loaded'); return []; }
    final places = _prop(maps, 'places');
    if (places == null) { _dbg('places not loaded'); return []; }

    // ── New Places API (AutocompleteSuggestion) — required for post-Mar-2025 keys ──
    final newApiClass = _prop(places, 'AutocompleteSuggestion');
    if (newApiClass != null) {
      _dbg('Using new AutocompleteSuggestion API');
      return await _newAutocomplete(input, lat, lng, maps, newApiClass);
    }

    // ── Legacy fallback (AutocompleteService) — only for older API keys ──
    _dbg('Falling back to legacy AutocompleteService');
    return await _legacyAutocomplete(input, lat, lng, maps, places);
  } catch (e) {
    _dbg('webAutocomplete top error: $e');
    return [];
  }
}

Future<List<PlaceSuggestion>> _newAutocomplete(
  String input,
  double lat,
  double lng,
  dynamic maps,
  dynamic autocompleteSuggestionClass,
) async {
  try {
    // Build request as a plain JS object via jsify, then set LatLng bias separately
    final request = js_util.jsify({
      'input': input,
      'language': 'es',
      'region': 'bo',
    });
    // locationBias must be a real LatLng object, not a plain map
    final latLng = js.JsObject(
      (maps as js.JsObject)['LatLng'] as js.JsFunction,
      [lat, lng],
    );
    js_util.setProperty(request as Object, 'locationBias', latLng);

    final promise = js_util.callMethod(
      autocompleteSuggestionClass as Object,
      'fetchAutocompleteSuggestions',
      [request],
    );

    final raw = await js_util
        .promiseToFuture<dynamic>(promise as Object)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (raw == null) return [];

    final suggestionsRaw = _prop(raw, 'suggestions');
    if (suggestionsRaw == null) return [];

    final list = suggestionsRaw as List;
    final results = <PlaceSuggestion>[];

    for (int i = 0; i < list.length; i++) {
      final sugg = list[i];
      final pred = _prop(sugg, 'placePrediction');
      if (pred == null) continue;

      final placeId       = _prop(pred, 'placeId') as String? ?? '';
      final textObj       = _prop(pred, 'text');
      final mainTextObj   = _prop(pred, 'mainText');
      final secTextObj    = _prop(pred, 'secondaryText');

      final description  = _str(textObj);
      final mainText     = _str(mainTextObj);
      final secondaryText = _str(secTextObj);

      if (placeId.isEmpty && description.isEmpty) continue;

      results.add(PlaceSuggestion(
        placeId:       placeId,
        description:   description,
        mainText:      mainText.isNotEmpty ? mainText : description,
        secondaryText: secondaryText,
      ));
    }

    _dbg('New API returned ${results.length} suggestions');
    return results;
  } catch (e) {
    _dbg('_newAutocomplete error: $e');
    return [];
  }
}

Future<List<PlaceSuggestion>> _legacyAutocomplete(
  String input,
  double lat,
  double lng,
  dynamic maps,
  dynamic places,
) async {
  try {
    final service = js.JsObject(places['AutocompleteService'] as js.JsFunction);
    final completer = Completer<List<PlaceSuggestion>>();

    final request = js.JsObject.jsify({
      'input': input,
      'location': js.JsObject(maps['LatLng'] as js.JsFunction, [lat, lng]),
      'radius': 50000,
      'componentRestrictions': {'country': 'bo'},
      'language': 'es',
    });

    service.callMethod('getPlacePredictions', [
      request,
      js.allowInterop((dynamic predictions, dynamic status) {
        if (status == 'OK' && predictions != null) {
          try {
            final list = predictions as List;
            final results = <PlaceSuggestion>[];
            for (int i = 0; i < list.length; i++) {
              final jsP = js.JsObject.fromBrowserObject(list[i] as Object);
              final sf  = js.JsObject.fromBrowserObject(jsP['structured_formatting'] as Object);
              results.add(PlaceSuggestion(
                placeId:       jsP['place_id'] as String? ?? '',
                description:   jsP['description'] as String? ?? '',
                mainText:      sf['main_text'] as String? ?? '',
                secondaryText: sf['secondary_text'] as String? ?? '',
              ));
            }
            completer.complete(results);
          } catch (e) {
            completer.complete([]);
          }
        } else {
          _dbg('Legacy autocomplete status: $status');
          completer.complete([]);
        }
      }),
    ]);

    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => []);
  } catch (e) {
    _dbg('_legacyAutocomplete error: $e');
    return [];
  }
}

// ── Place Details ─────────────────────────────────────────────────────────────

Future<Place?> webPlaceDetails(String placeId, {String? address}) async {
  try {
    final google = js.context['google'];
    if (google == null) return null;
    final maps = google['maps'];
    if (maps == null) return null;

    final completer = Completer<Place?>();

    // Try Geocoder first as it's often more reliable for coordinates than PlacesService
    // especially regarding API restrictions.
    final geocoder = js.JsObject(maps['Geocoder'] as js.JsFunction);
    
    geocoder.callMethod('geocode', [
      js.JsObject.jsify({
        'placeId': placeId,
      }),
      js.allowInterop((dynamic results, dynamic status) {
        if (status == 'OK' && results != null && (results as List).isNotEmpty) {
          final res = js.JsObject.fromBrowserObject((results)[0] as Object);
          final geom = js.JsObject.fromBrowserObject(res['geometry'] as Object);
          final loc = js.JsObject.fromBrowserObject(geom['location'] as Object);
          
          completer.complete(Place(
            name: address?.split(',').first ?? '',
            address: res['formatted_address'] as String? ?? address ?? '',
            lat: (loc.callMethod('lat') as num).toDouble(),
            lng: (loc.callMethod('lng') as num).toDouble(),
          ));
        } else {
          // If PlaceId geocoding fails, try address string geocoding if provided
          if (address != null && address.isNotEmpty) {
            _dbg('Geocode by ID failed. Trying address string: $address');
            geocoder.callMethod('geocode', [
              js.JsObject.jsify({'address': address}),
              js.allowInterop((dynamic results2, dynamic status2) {
                if (status2 == 'OK' && results2 != null && (results2 as List).isNotEmpty) {
                   final res2 = js.JsObject.fromBrowserObject((results2)[0] as Object);
                   final geom2 = js.JsObject.fromBrowserObject(res2['geometry'] as Object);
                   final loc2 = js.JsObject.fromBrowserObject(geom2['location'] as Object);
                   
                   completer.complete(Place(
                     name: address.split(',').first,
                     address: res2['formatted_address'] as String? ?? address,
                     lat: (loc2.callMethod('lat') as num).toDouble(),
                     lng: (loc2.callMethod('lng') as num).toDouble(),
                   ));
                } else {
                  completer.complete(null);
                }
              }),
            ]);
          } else {
            completer.complete(null);
          }
        }
      }),
    ]);

    return completer.future
        .timeout(const Duration(seconds: 8), onTimeout: () => null);
  } catch (e) {
    _dbg('webPlaceDetails top error: $e');
    return null;
  }
}

// ── Reverse Geocode ───────────────────────────────────────────────────────────

Future<Place?> webReverseGeocode(double lat, double lng) async {
  try {
    final google = js.context['google'] as js.JsObject?;
    if (google == null) return null;
    final maps = google['maps'] as js.JsObject?;
    if (maps == null) return null;

    final geocoder = js.JsObject(maps['Geocoder'] as js.JsFunction);
    final completer = Completer<Place?>();

    geocoder.callMethod('geocode', [
      js.JsObject.jsify({'location': {'lat': lat, 'lng': lng}}),
      js.allowInterop((dynamic results, dynamic status) {
        if (status == 'OK' && results != null) {
          try {
            final arr = results as js.JsArray;
            if (arr.isNotEmpty) {
              final address =
                  (arr[0] as js.JsObject)['formatted_address'] as String? ??
                      '$lat,$lng';
              completer.complete(
                  Place(address: address, lat: lat, lng: lng));
              return;
            }
          } catch (_) {}
        }
        completer.complete(null);
      }),
    ]);

    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  } catch (_) {
    return null;
  }
}

// ── Directions ────────────────────────────────────────────────────────────────

Future<RouteInfo?> webGetRoute({
  required Place origin,
  required Place destination,
}) async {
  try {
    final google = js.context['google'] as js.JsObject?;
    if (google == null) return null;
    final maps = google['maps'] as js.JsObject?;
    if (maps == null) return null;

    final service = js.JsObject(maps['DirectionsService'] as js.JsFunction);
    final completer = Completer<RouteInfo?>();
    final travelMode = ((maps['TravelMode'] as js.JsObject)['DRIVING']) as dynamic;

    service.callMethod('route', [
      js.JsObject.jsify({
        'origin': {'lat': origin.lat, 'lng': origin.lng},
        'destination': {'lat': destination.lat, 'lng': destination.lng},
        'travelMode': travelMode,
      }),
      js.allowInterop((dynamic result, dynamic status) {
        if (status == 'OK' && result != null) {
          try {
            final r = result as js.JsObject;
            final routes = r['routes'] as js.JsArray;
            if (routes.isEmpty) { completer.complete(null); return; }
            final route = routes[0] as js.JsObject;
            final leg = (route['legs'] as js.JsArray)[0] as js.JsObject;
            final distM = ((leg['distance'] as js.JsObject)['value'] as num).toDouble();
            final durS  = ((leg['duration'] as js.JsObject)['value'] as num).toInt();
            final path  = route['overview_path'] as js.JsArray;
            final points = <LatLng>[];
            for (int i = 0; i < path.length; i++) {
              final pt = path[i] as js.JsObject;
              points.add(LatLng(
                (pt.callMethod('lat') as num).toDouble(),
                (pt.callMethod('lng') as num).toDouble(),
              ));
            }
            completer.complete(RouteInfo(
              distanceKm: distM / 1000,
              durationMin: durS ~/ 60,
              polylinePoints: points,
            ));
          } catch (_) { completer.complete(null); }
        } else { completer.complete(null); }
      }),
    ]);

    return completer.future
        .timeout(const Duration(seconds: 8), onTimeout: () => null);
  } catch (_) {
    return null;
  }
}
