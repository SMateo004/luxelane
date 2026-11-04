import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/admin/data/flights_admin_repository.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_flights_tab.dart';

import 'flights_fakes.dart';

/// Panel, vuelos (B3): editor de aeropuertos y puntos de recogida
/// (adminUpsertAirport), con la validación de coordenadas del servidor.
void main() {
  late FakeFlightsRepo repo;

  setUp(() => repo = FakeFlightsRepo());

  Future<void> pump(WidgetTester t) async {
    await pumpPanel(t, FlightsTab(repository: repo));
    await t.tap(find.byKey(const ValueKey('flights-view-airports')));
    await t.pumpAndSettle();
  }

  Finder field(String key) => find.byKey(ValueKey(key));

  Future<void> type(WidgetTester t, String key, String text) async {
    await t.ensureVisible(field(key));
    await t.enterText(field(key), text);
    await t.pump();
  }

  Future<void> tap(WidgetTester t, String key) async {
    await t.ensureVisible(field(key));
    await t.pumpAndSettle();
    await t.tap(field(key));
    await t.pumpAndSettle();
  }

  testWidgets('lista vacía', (t) async {
    await pump(t);
    expect(find.byKey(const ValueKey('airports-empty')), findsOneWidget);
    expect(find.text('Aún no hay aeropuertos'), findsOneWidget);
  });

  testWidgets('lista con el estado de cada punto', (t) async {
    repo.airportsAnswer = Right([fakeAirport(international: kFakePoint)]);
    await pump(t);
    expect(find.text('VVI · Aeropuerto Prueba'), findsOneWidget);
    expect(find.text('Nacional: sin punto'), findsOneWidget);
    expect(find.text('Internacional: con punto'), findsOneWidget);
  });

  testWidgets('error al leer: mensaje y reintentar', (t) async {
    repo.airportsAnswer = const Left(FlightAdminFailure('Sin conexión'));
    await pump(t);
    expect(find.byKey(const ValueKey('airports-error')), findsOneWidget);
    expect(find.text('No se pudieron cargar los aeropuertos'), findsOneWidget);
  });

  testWidgets('nuevo: valida código, coordenadas y (0, 0)', (t) async {
    await pump(t);
    await tap(t, 'airport-add');
    expect(find.text('Nuevo aeropuerto'), findsWidgets);
    await type(t, 'airport-code', 'vv');
    await type(t, 'airport-name', 'Aeropuerto Prueba');
    await type(t, 'airport-city', 'Ciudad Prueba');
    await tap(t, 'airport-domestic-add');
    await type(t, 'airport-domestic-name', 'Salida nacional');
    await type(t, 'airport-domestic-lat', '-91');
    await type(t, 'airport-domestic-lng', '181');
    await type(t, 'flight-reason', 'Alta del aeropuerto de prueba');
    await tap(t, 'airport-save');

    expect(repo.upsertCalls, isEmpty);
    expect(
        find.text('Tres letras mayúsculas, por ejemplo VVI'), findsOneWidget);
    expect(find.text('Latitud entre -90 y 90'), findsOneWidget);
    expect(find.text('Longitud entre -180 y 180'), findsOneWidget);
    expect(find.text('Revisa los campos marcados'), findsOneWidget);

    await type(t, 'airport-code', 'VVI');
    await type(t, 'airport-domestic-lat', '0');
    await type(t, 'airport-domestic-lng', '0');
    await tap(t, 'airport-save');
    expect(repo.upsertCalls, isEmpty);
    expect(find.text('Las coordenadas (0, 0) no son válidas'), findsOneWidget);

    // Coma decimal aceptada.
    await type(t, 'airport-domestic-lat', '-17,64');
    await type(t, 'airport-domestic-lng', '-63.13');
    await tap(t, 'airport-save');
    expect(find.byKey(const ValueKey('airport-editor')), findsNothing);
    expect(find.text('Aeropuerto guardado'), findsOneWidget);
    expect(repo.upsertCalls.single.toPayload(), {
      'code': 'VVI',
      'name': 'Aeropuerto Prueba',
      'city': 'Ciudad Prueba',
      'timeZone': 'America/La_Paz',
      // El internacional no se tocó: no se manda.
      'pickupPoints': {
        'domestic': {
          'name': 'Salida nacional',
          'instructions': '',
          'lat': -17.64,
          'lng': -63.13,
        },
      },
      'reason': 'Alta del aeropuerto de prueba',
    });
  });

  testWidgets('editar: el código no cambia y «Quitar punto» manda null',
      (t) async {
    repo.airportsAnswer = Right([
      fakeAirport(domestic: kFakePoint, international: kFakePoint),
    ]);
    await pump(t);
    await tap(t, 'airport-row-VVI');
    expect(find.text('Editar aeropuerto VVI'), findsOneWidget);
    expect(
      t.widget<TextFormField>(field('airport-code')).enabled,
      isFalse,
    );
    expect(find.text('El código no se cambia una vez creado'), findsOneWidget);

    await tap(t, 'airport-international-remove');
    expect(find.text('El punto se quitará al guardar.'), findsOneWidget);
    await type(t, 'airport-domestic-instructions', 'Puerta 3, junto al café');
    await type(t, 'flight-reason', 'El punto internacional cambió');
    await tap(t, 'airport-save');

    final payload = repo.upsertCalls.single.toPayload();
    final points = payload['pickupPoints'] as Map;
    expect(points.containsKey('international'), isTrue);
    expect(points['international'], isNull);
    expect(points['domestic'], {
      'name': 'Salida 1',
      'instructions': 'Puerta 3, junto al café',
      'lat': -17.64,
      'lng': -63.13,
    });
    expect(payload['code'], 'VVI');
  });

  testWidgets('sin motivo de 10 caracteres no se puede guardar', (t) async {
    repo.airportsAnswer = Right([fakeAirport(domestic: kFakePoint)]);
    await pump(t);
    await tap(t, 'airport-row-VVI');
    final save = field('airport-save');
    expect(t.widget<FilledButton>(save).onPressed, isNull);
    await type(t, 'flight-reason', 'corto');
    expect(t.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('un error del servidor se ve en el editor', (t) async {
    repo.airportsAnswer = Right([fakeAirport(domestic: kFakePoint)]);
    repo.writeAnswer = Left(
      FlightAdminFailure(airportAdminErrorMessage('invalid-argument', null)),
    );
    await pump(t);
    await tap(t, 'airport-row-VVI');
    await type(t, 'flight-reason', 'Cambio de prueba del nombre');
    await tap(t, 'airport-save');
    expect(find.byKey(const ValueKey('airport-editor')), findsOneWidget);
    expect(
      find.text(
        'Algún dato no es válido: revisa código, nombre, ciudad y coordenadas.',
      ),
      findsOneWidget,
    );
  });
}
