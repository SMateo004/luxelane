import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/personalization/rider_insights.dart';

final _now = DateTime(2026, 10, 18, 9);

const _hotel = Place(
  name: 'Hotel Los Tajibos',
  address: 'Equipetrol',
  lat: -17.765,
  lng: -63.196,
);

Booking _b(
  String id,
  String dest, {
  double lat = -17.7,
  double lng = -63.1,
  BookingStatus status = BookingStatus.completed,
  VehicleClass vc = VehicleClass.business,
  Duration ago = const Duration(days: 1),
  DateTime? at,
}) => Booking(
  id: id,
  riderId: 'u1',
  origin: _hotel,
  destination: Place(name: dest, address: dest, lat: lat, lng: lng),
  scheduledAt: at ?? _now.subtract(ago),
  vehicleClass: vc,
  serviceType: ServiceType.oneWay,
  status: status,
  estimatedPrice: 100,
  createdAt: (at ?? _now.subtract(ago)).subtract(const Duration(hours: 1)),
  updatedAt: _now,
);

void main() {
  group('RiderInsights', () {
    test('sin viajes no propone nada', () {
      final i = RiderInsights.from(const [], now: _now);
      expect(i.recentPlaces, isEmpty);
      expect(i.favoriteClass, isNull);
      expect(i.nextTrip, isNull);
    });

    test(
      'sus lugares: destinos recientes primero, sin repetir ni cancelados',
      () {
        final i = RiderInsights.from([
          _b('1', 'Aeropuerto', lat: -17.64, lng: -63.13),
          _b(
            '2',
            'Ventura Mall',
            lat: -17.75,
            lng: -63.19,
            ago: const Duration(days: 3),
          ),
          _b(
            '3',
            'Aeropuerto (otra vez)',
            lat: -17.6401,
            lng: -63.1301,
            ago: const Duration(days: 5),
          ),
          _b(
            '4',
            'Cancelado',
            lat: -17.8,
            lng: -63.3,
            status: BookingStatus.cancelled,
          ),
        ], now: _now);
        expect(i.recentPlaces.map((p) => p.name), [
          'Aeropuerto',
          'Ventura Mall',
          'Hotel Los Tajibos',
        ]);
      },
    );

    test('su clase habitual aparece desde el segundo viaje', () {
      expect(
        RiderInsights.from([
          _b('1', 'A', vc: VehicleClass.firstClass),
        ], now: _now).favoriteClass,
        isNull,
      );
      final i = RiderInsights.from([
        _b('1', 'A', vc: VehicleClass.firstClass),
        _b('2', 'B', vc: VehicleClass.firstClass),
        _b('3', 'C'),
      ], now: _now);
      expect(i.favoriteClass, VehicleClass.firstClass);
    });

    test('el próximo viaje es el reservado más cercano', () {
      final i = RiderInsights.from([
        _b(
          'later',
          'Más tarde',
          status: BookingStatus.confirmed,
          at: _now.add(const Duration(days: 2)),
        ),
        _b(
          'soon',
          'Pronto',
          status: BookingStatus.pending,
          at: _now.add(const Duration(hours: 1)),
        ),
        _b('done', 'Hecho'),
      ], now: _now);
      expect(i.nextTrip?.id, 'soon');
      expect(i.lastTrip?.id, 'done');
    });
  });

  group('contextualPrompt', () {
    test('cambia con la hora del día', () {
      expect(
        contextualPrompt(DateTime(2026, 1, 1, 8)),
        '¿A dónde empieza tu día?',
      );
      expect(
        contextualPrompt(DateTime(2026, 1, 1, 22)),
        '¿Volvemos con calma?',
      );
    });

    test('prioriza un viaje en marcha', () {
      final trip = _b(
        'x',
        'X',
        status: BookingStatus.driverArriving,
        at: _now.add(const Duration(minutes: 10)),
      );
      expect(contextualPrompt(_now, nextTrip: trip), 'Tu chófer va en camino.');
    });
  });

  group('RidePreferences', () {
    test('ida y vuelta por JSON', () {
      const p = RidePreferences(
        quiet: true,
        temperature: CabinTemperature.cool,
        music: false,
        openDoor: true,
      );
      expect(RidePreferences.fromJson(p.toJson()), p);
    });

    test('sin datos equivale a sin preferencias', () {
      expect(RidePreferences.fromJson(null).isEmpty, isTrue);
      expect(
        RidePreferences.fromJson({'temperature': 'raro'}).temperature,
        isNull,
      );
    });

    test('notas para el chófer en orden de uso', () {
      const p = RidePreferences(
        quiet: true,
        music: false,
        openDoor: true,
        luggageHelp: true,
      );
      expect(p.driverNotes, [
        'Abrir la puerta',
        'Ayuda con el equipaje',
        'Viaje en silencio',
        'Sin música',
      ]);
    });
  });
}
