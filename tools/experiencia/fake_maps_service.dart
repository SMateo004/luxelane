// Solo para el entorno de capturas (F5): lugares y rutas FICTICIOS para
// llegar a la pantalla de reserva sin clave de mapas. Nunca se importa desde
// lib/ ni entra en una build de producción (test/experiencia/
// mapas_ficticios_test.dart lo comprueba).
import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/utils/service_area.dart';

/// Marca visible en cada lugar: nadie debe confundirlos con datos reales.
const kFicticio = '(lugar ficticio)';

/// Lugares de Santa Cruz de la Sierra con coordenadas aproximadas.
const kLugaresFicticios = <String, Place>{
  'plaza': Place(
    name: 'Plaza 24 de Septiembre $kFicticio',
    address: 'Centro, Santa Cruz de la Sierra $kFicticio',
    lat: -17.7833,
    lng: -63.1821,
  ),
  'aeropuerto': Place(
    name: 'Aeropuerto Viru Viru $kFicticio',
    address: 'Aeropuerto Internacional Viru Viru $kFicticio',
    lat: -17.6448,
    lng: -63.1354,
  ),
  'equipetrol': Place(
    name: 'Equipetrol $kFicticio',
    address: 'Equipetrol Norte, Santa Cruz de la Sierra $kFicticio',
    lat: -17.7600,
    lng: -63.1975,
  ),
  // Para capturar «sin ruta»: getRoute no la encuentra.
  'sinruta': Place(
    name: 'Destino sin ruta $kFicticio',
    address: 'Sin recorrido calculable $kFicticio',
    lat: -17.8000,
    lng: -63.1600,
  ),
};

class FakeMapsService extends MapsService {
  @override
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String? sessionToken,
    SearchArea? restrictTo,
  }) async {
    final q = input.toLowerCase();
    final hits = kLugaresFicticios.entries.where(
      (e) => e.key.contains(q) || e.value.name.toLowerCase().contains(q),
    );
    return [
      for (final e in hits.isEmpty ? kLugaresFicticios.entries : hits)
        PlaceSuggestion(
          placeId: e.key,
          description: e.value.address,
          mainText: e.value.name,
          secondaryText: e.value.address,
        ),
    ];
  }

  @override
  Future<Place?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String? address,
  }) async =>
      kLugaresFicticios[placeId];

  @override
  Future<Place?> reverseGeocode(double lat, double lng) async => Place(
        name: 'Punto de prueba $kFicticio',
        address: 'Punto de prueba $kFicticio',
        lat: lat,
        lng: lng,
      );

  /// Línea recta con 20 puntos; distancia en línea recta × 1,3 y 30 km/h.
  @override
  Future<RouteInfo?> getRoute({
    required Place origin,
    required Place destination,
  }) async =>
      fakeRoute(origin, destination);
}

RouteInfo? fakeRoute(Place origin, Place destination) {
  if (destination.name.startsWith('Destino sin ruta')) return null;
  const n = 20;
  final points = [
    for (var i = 0; i <= n; i++)
      LatLng(
        origin.lat + (destination.lat - origin.lat) * i / n,
        origin.lng + (destination.lng - origin.lng) * i / n,
      ),
  ];
  final km = _haversineKm(origin, destination) * 1.3;
  return RouteInfo(
    distanceKm: double.parse(km.toStringAsFixed(1)),
    durationMin: (km / 30 * 60).round(),
    polylinePoints: points,
  );
}

double _haversineKm(Place a, Place b) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * 6371 * math.asin(math.sqrt(h));
}
