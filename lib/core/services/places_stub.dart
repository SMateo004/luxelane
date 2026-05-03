// Non-web stub — all methods return null/empty.
// On mobile the HTTP paths in MapsService are used instead.
import '../models/place_model.dart';

Future<List<PlaceSuggestion>> webAutocomplete(String input,
        {double lat = -17.7833, double lng = -63.1821}) async =>
    [];

Future<Place?> webPlaceDetails(String placeId, {String? address}) async => null;

Future<Place?> webReverseGeocode(double lat, double lng) async => null;

Future<RouteInfo?> webGetRoute(
        {required Place origin, required Place destination}) async =>
    null;
