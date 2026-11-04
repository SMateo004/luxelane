import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/service_area.dart';

/// Vuelos: lo que la app lee del servidor (datos FICTICIOS de prueba).
void main() {
  final sched = DateTime.utc(2026, 11, 20, 18);
  test('lee el vuelo de la reserva y la copia del chófer', () {
    final f = FlightInfo.fromMap({
      'airportCode': 'VVI',
      'flightType': 'domestic',
      'airline': '',
      'flightNumber': 'ZZ123',
      'flightDate': '2026-11-20',
      'scheduledArrival': Timestamp.fromDate(sched),
      'estimatedArrival':
          Timestamp.fromDate(sched.add(const Duration(minutes: 40))),
      'status': 'delayed',
      'dataQuality': 'ok',
      'readyAt': Timestamp.fromDate(sched.add(const Duration(minutes: 65))),
      'source': 'auto',
      'manualLock': true,
    })!;
    expect(f.flightType, FlightType.domestic);
    expect(f.airline, isNull);
    expect(f.status, FlightStatus.delayed);
    expect(f.noLiveData, isFalse);
    expect(f.effectiveArrival!.toUtc(), sched.add(const Duration(minutes: 40)));
    expect(f.readyAt!.toUtc(), sched.add(const Duration(minutes: 65)));
    expect(f.source, FlightSource.auto);
    expect(f.manualLock, isTrue);
  });

  test('sin datos en vivo, estado desconocido y vuelo inválido', () {
    final f = FlightInfo.fromMap({
      'airportCode': 'VVI',
      'flightType': 'international',
      'flightNumber': 'ZZ9',
      'status': 'otro',
    })!;
    expect(f.status, FlightStatus.unknown);
    expect(f.noLiveData, isTrue);
    expect(f.source, isNull);
    expect(FlightInfo.fromMap({'flightType': 'domestic'}), isNull);
    expect(FlightStatus.cancelled.disrupted, isTrue);
    expect(FlightStatus.delayed.disrupted, isFalse);
  });

  test('aeropuerto: punto por tipo; sin punto, null', () {
    final a = Airport.fromMap('VVI', {
      'name': 'Aeropuerto (prueba)',
      'city': 'Santa Cruz',
      'pickupPoints': {
        'domestic': {
          'name': 'Salida nacional (ficticia)',
          'instructions': 'Puerta 1',
          'lat': -17.6,
          'lng': -63.1,
        },
        'international': null,
      },
    })!;
    expect(a.pointFor(FlightType.domestic)?.name, 'Salida nacional (ficticia)');
    expect(a.pointFor(FlightType.international), isNull);
  });
}
