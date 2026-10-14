import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/utils/route_geometry.dart';
import 'package:luxelane/core/widgets/lux_map.dart';

// Santa Cruz: Colinas del Urubó → Clara Chuchío (como en la captura).
const _pickup = Place(address: 'Colinas del Urubó', lat: -17.755, lng: -63.205);
const _dropoff = Place(address: 'Clara Chuchío', lat: -17.70, lng: -63.17);

RouteInfo _road(int n) => RouteInfo(
      distanceKm: 9.4,
      durationMin: 18,
      polylinePoints: [
        for (var i = 0; i < n; i++)
          LatLng(_pickup.lat + (_dropoff.lat - _pickup.lat) * i / (n - 1),
              _pickup.lng + (_dropoff.lng - _pickup.lng) * i / (n - 1) + 0.01),
      ],
    );

void main() {
  group('route_geometry', () {
    test('el centro por defecto es Santa Cruz de la Sierra', () {
      expect(kSantaCruzCenter.latitude, closeTo(-17.78, 0.01));
      expect(kSantaCruzCenter.longitude, closeTo(-63.18, 0.01));
    });

    test('solo cuenta como recorrido real si sigue las calles', () {
      expect(hasRoadPath(null), isFalse);
      expect(
          hasRoadPath(RouteInfo(
              distanceKm: 1,
              durationMin: 1,
              polylinePoints: [_pickup.latLng, _dropoff.latLng])),
          isFalse);
      expect(hasRoadPath(_road(20)), isTrue);
    });

    test('el encuadre incluye el recorrido aunque se salga de los puntos', () {
      final b = boundsOf(
          [_pickup.latLng, _dropoff.latLng, const LatLng(-17.72, -63.10)])!;
      expect(b.northeast.longitude, -63.10);
      expect(b.southwest.latitude, _pickup.lat);
      expect(boundsOf(const []), isNull);
      final single = boundsOf([_pickup.latLng])!;
      expect(single.northeast.latitude, greaterThan(single.southwest.latitude));
    });
  });

  group('LuxMap', () {
    late List<(Place, Place)> calls;

    setUp(() {
      LuxMap.clearRouteCache();
      calls = [];
      LuxMap.routeLoader = (o, d) async {
        calls.add((o, d));
        return _road(30);
      };
    });

    Future<LuxMapState> pump(WidgetTester t, Widget map) async {
      await t.pumpWidget(
          MaterialApp(home: SizedBox(width: 400, height: 300, child: map)));
      await t.pump();
      return t.state<LuxMapState>(find.byType(LuxMap));
    }

    testWidgets('sin lugares se centra en Santa Cruz', (t) async {
      final s = await pump(t, const LuxMap());
      expect(s.initialCenter, kSantaCruzCenter);
      expect(calls, isEmpty);
    });

    testWidgets('calcula y dibuja el recorrido real si no se lo pasan',
        (t) async {
      final s =
          await pump(t, const LuxMap(origin: _pickup, destination: _dropoff));
      expect(calls, hasLength(1));
      expect(s.route?.polylinePoints, hasLength(30));
      // La cámara encuadra el recorrido entero, no solo los dos marcadores.
      expect(s.framePoints, hasLength(32));
    });

    testWidgets('si recibe solo la línea recta, pide el recorrido real',
        (t) async {
      final straight = RouteInfo(
          distanceKm: 0,
          durationMin: 0,
          polylinePoints: [_pickup.latLng, _dropoff.latLng]);
      final s = await pump(t,
          LuxMap(origin: _pickup, destination: _dropoff, routeInfo: straight));
      expect(calls, hasLength(1));
      expect(s.route?.polylinePoints, hasLength(30));
    });

    testWidgets('usa el recorrido recibido sin volver a pedirlo', (t) async {
      final s = await pump(t,
          LuxMap(origin: _pickup, destination: _dropoff, routeInfo: _road(12)));
      expect(calls, isEmpty);
      expect(s.route?.polylinePoints, hasLength(12));
    });

    testWidgets('no repite la consulta para la misma ruta', (t) async {
      await pump(t, const LuxMap(origin: _pickup, destination: _dropoff));
      await t.pumpWidget(const SizedBox());
      await pump(t, const LuxMap(origin: _pickup, destination: _dropoff));
      expect(calls, hasLength(1));
    });

    testWidgets('si Google no devuelve ruta no inventa una línea', (t) async {
      LuxMap.routeLoader = (o, d) async => null;
      final s =
          await pump(t, const LuxMap(origin: _pickup, destination: _dropoff));
      expect(s.route, isNull);
    });
  });
}
