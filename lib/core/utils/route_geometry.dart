import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/place_model.dart';

/// Centro por defecto de todos los mapas: Santa Cruz de la Sierra.
const kSantaCruzCenter = LatLng(-17.7833, -63.1821);

/// Zoom con el que se ve la ciudad entera.
const kCityZoom = 12.0;

/// True si [route] trae el recorrido real por calles (no solo los dos
/// extremos en línea recta, que es lo que se tiene sin Directions).
bool hasRoadPath(RouteInfo? route) =>
    route != null && route.polylinePoints.length > 2;

/// Clave de caché de una ruta entre dos lugares (redondeada a ~1 m).
String routeKey(Place origin, Place destination) =>
    '${origin.lat.toStringAsFixed(5)},${origin.lng.toStringAsFixed(5)}'
    '|${destination.lat.toStringAsFixed(5)},${destination.lng.toStringAsFixed(5)}';

/// Rectángulo que contiene todos los [points], o null si no hay ninguno.
/// Si todos coinciden se amplía un poco para que la cámara pueda encuadrarlo.
LatLngBounds? boundsOf(Iterable<LatLng> points) {
  final list = points.toList();
  if (list.isEmpty) return null;
  var minLat = list.first.latitude, maxLat = minLat;
  var minLng = list.first.longitude, maxLng = minLng;
  for (final p in list.skip(1)) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  const minSpan = 0.002; // ~200 m
  if (maxLat - minLat < minSpan) {
    minLat -= minSpan / 2;
    maxLat += minSpan / 2;
  }
  if (maxLng - minLng < minSpan) {
    minLng -= minSpan / 2;
    maxLng += minSpan / 2;
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}
