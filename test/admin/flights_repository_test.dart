import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/service_area.dart' show FlightType;
import 'package:luxelane/features/admin/data/flights_admin_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'flights_fakes.dart';

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock implements HttpsCallableResult<Object?> {}

/// Panel, vuelos (B3): la carga de cada callable, los motivos del
/// servidor en texto del panel y la lectura de bookings/{id}.flight.
void main() {
  late _Functions fn;
  late _Callable callable;
  late FirebaseFlightsAdminRepository repo;
  final names = <String>[];

  setUp(() {
    names.clear();
    fn = _Functions();
    callable = _Callable();
    repo = FirebaseFlightsAdminRepository(functions: fn);
    when(() => fn.httpsCallable(any())).thenAnswer((i) {
      names.add(i.positionalArguments.first as String);
      return callable;
    });
    final r = _Result();
    when(() => r.data).thenReturn(<String, Object?>{});
    when(() => callable.call<Object?>(any())).thenAnswer((_) async => r);
  });

  void fail(String code, Map<String, Object?> details) =>
      when(() => callable.call<Object?>(any())).thenThrow(
        FirebaseFunctionsException(
          code: code,
          message: code,
          details: details,
        ),
      );

  Map<String, dynamic> sent() =>
      verify(() => callable.call<Object?>(captureAny())).captured.single
          as Map<String, dynamic>;

  test('adminSetFlightInfo: estado, horas en ms y motivo sin espacios',
      () async {
    final r = await repo.setFlightInfo(
      'b1',
      FlightManualInput(
        status: FlightStatus.landed,
        estimatedArrival: null,
        actualArrival: fromLaPazWall(DateTime.utc(2026, 11, 20, 14, 50)),
        reason: '  Confirmado con la aerolínea  ',
      ),
    );
    expect(r.isRight(), isTrue);
    expect(names, ['adminSetFlightInfo']);
    expect(sent(), {
      'bookingId': 'b1',
      'status': 'landed',
      'estimatedArrival': null,
      'actualArrival':
          DateTime.utc(2026, 11, 20, 18, 50).millisecondsSinceEpoch,
      'reason': 'Confirmado con la aerolínea',
    });
  });

  test('adminClearFlightLock y adminForceNoShow', () async {
    await repo.clearFlightLock('b1', ' La fuente ya es fiable ');
    expect(names, ['adminClearFlightLock']);
    expect(sent(), {'bookingId': 'b1', 'reason': 'La fuente ya es fiable'});

    clearInteractions(callable);
    await repo.forceNoShow('b2', 'Pasajero sin aparecer');
    expect(names.last, 'adminForceNoShow');
    expect(sent(), {'bookingId': 'b2', 'reason': 'Pasajero sin aparecer'});
  });

  test('adminUpsertAirport: punto nuevo, null para quitar y sin clave si no',
      () async {
    await repo.upsertAirport(
      const AirportInput(
        code: 'VVI',
        name: ' Aeropuerto Prueba ',
        city: 'Ciudad Prueba',
        points: {
          FlightType.domestic: SetPickupPoint(kFakePoint),
          FlightType.international: RemovePickupPoint(),
        },
        reason: 'Alta del aeropuerto de prueba',
      ),
    );
    expect(names, ['adminUpsertAirport']);
    expect(sent(), {
      'code': 'VVI',
      'name': 'Aeropuerto Prueba',
      'city': 'Ciudad Prueba',
      'timeZone': 'America/La_Paz',
      'pickupPoints': {
        'domestic': {
          'name': 'Salida 1',
          'instructions': 'Frente a la puerta',
          'lat': -17.64,
          'lng': -63.13,
        },
        'international': null,
      },
      'reason': 'Alta del aeropuerto de prueba',
    });
  });

  group('motivos del servidor', () {
    Future<String> messageFor(String code, String reason) async {
      fail(code, {'reason': reason});
      final r = await repo.setFlightInfo(
        'b1',
        const FlightManualInput(
          status: FlightStatus.delayed,
          estimatedArrival: null,
          actualArrival: null,
          reason: 'Motivo de prueba',
        ),
      );
      return r.fold((f) => f.message, (_) => 'ok');
    }

    test('flight_config_missing, booking_without_flight, booking_not_found',
        () async {
      expect(
        await messageFor('failed-precondition', 'flight_config_missing'),
        'Faltan los minutos de salida del aeropuerto en la configuración de '
        'operaciones.',
      );
      expect(
        await messageFor('failed-precondition', 'booking_without_flight'),
        'Esta reserva no tiene vuelo.',
      );
      expect(
        await messageFor('not-found', 'booking_not_found'),
        'La reserva ya no existe.',
      );
      expect(
        await messageFor('failed-precondition', 'invalid_transition'),
        'La reserva ya no está en «Chófer en el punto».',
      );
      expect(
        await messageFor('failed-precondition', 'no_show_disabled'),
        '«No se presentó» no está habilitado: falta la política de '
        'cancelación.',
      );
    });

    test('reauth_required y mfa_required usan los textos comunes', () async {
      fail('permission-denied', {'reason': 'reauth_required'});
      final r = await repo.clearFlightLock('b1', 'Motivo de prueba');
      final f = r.fold((f) => f, (_) => null)!;
      expect(f.message, kReauthRequiredMessage);
      expect(f.needsReauth, isTrue);

      expect(
        await messageFor('permission-denied', 'mfa_required'),
        kMfaRequiredMessage,
      );
    });

    test('datos no válidos al guardar un aeropuerto', () async {
      fail('invalid-argument', {});
      final r = await repo.upsertAirport(
        const AirportInput(
          code: 'VVI',
          name: 'Aeropuerto',
          city: 'Ciudad',
          points: {},
          reason: 'Motivo de prueba',
        ),
      );
      expect(
        r.fold((f) => f.message, (_) => 'ok'),
        'Algún dato no es válido: revisa código, nombre, ciudad y '
        'coordenadas.',
      );
    });
  });

  group('lectura de la reserva', () {
    test('vuelo con readyAt, fuente y bloqueo', () {
      final b = flightBookingFromDoc('b1', {
        'status': 'driver_arrived',
        'flightActive': true,
        'readyAt': Timestamp.fromDate(kReadyAt),
        'origin': {'address': 'Aeropuerto de prueba'},
        'flight': {
          'airportCode': 'VVI',
          'flightType': 'domestic',
          'airline': null,
          'flightNumber': 'OB760',
          'flightDate': '2026-11-20',
          'scheduledArrival':
              Timestamp.fromDate(DateTime.utc(2026, 11, 20, 18)),
          'hasCheckedBag': false,
          'estimatedArrival': null,
          'actualArrival': null,
          'status': 'delayed',
          'source': 'manual',
          'lastObservedAt': null,
          'lastChangeAt': Timestamp.fromDate(DateTime.utc(2026, 11, 20, 12)),
          'dataQuality': 'stale',
          'manualLock': true,
        },
      })!;
      expect(b.bookingStatus, BookingStatus.driverArrived);
      expect(b.flightActive, isTrue);
      expect(b.flight.readyAt!.isAtSameMomentAs(kReadyAt), isTrue);
      expect(b.flight.source, FlightSource.manual);
      expect(b.flight.manualLock, isTrue);
      expect(b.flight.dataQuality, FlightDataQuality.stale);
      expect(b.origin, 'Aeropuerto de prueba');
      expect(b.destination, isNull);
    });

    test('sin vuelo: null', () {
      expect(flightBookingFromDoc('b1', {'status': 'pending'}), isNull);
      expect(flightBookingFromDoc('b1', null), isNull);
    });
  });

  test('hora de La Paz: UTC−4 fijo, sin depender de la máquina', () {
    final instant = DateTime.utc(2026, 1, 1, 2, 30);
    final wall = laPazWall(instant);
    expect([wall.year, wall.month, wall.day, wall.hour, wall.minute],
        [2025, 12, 31, 22, 30]);
    expect(fromLaPazWall(wall), instant);
  });
}
