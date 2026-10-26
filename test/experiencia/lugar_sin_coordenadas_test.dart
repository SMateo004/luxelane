import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';

/// E30: Place.fromJson (y con él Booking.fromJson) lanzaba si un lugar no
/// traía coordenadas.
void main() {
  test('sin coordenadas: (0, 0) en vez de error', () {
    final p = Place.fromJson({'name': 'Plaza', 'address': 'Centro'});
    expect((p.lat, p.lng), (0.0, 0.0));
    expect(p.address, 'Centro');
  });

  test('sin dirección: vacía', () {
    expect(Place.fromJson({'coordinates': const GeoPoint(1, 2)}).address, '');
  });

  test('coordenadas como mapa {lat, lng}', () {
    final p = Place.fromJson({
      'address': 'x',
      'coordinates': {'lat': -17.7, 'lng': -63.1},
    });
    expect((p.lat, p.lng), (-17.7, -63.1));
  });

  test('GeoPoint, como siempre', () {
    final p = Place.fromJson({
      'address': 'x',
      'coordinates': const GeoPoint(-17.78, -63.18),
    });
    expect((p.lat, p.lng), (-17.78, -63.18));
  });
}
