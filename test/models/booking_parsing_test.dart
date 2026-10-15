import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';

void main() {
  final base = <String, dynamic>{
    'id': 'b1',
    'riderId': 'r1',
    'origin': {
      'address': 'Equipetrol',
      'coordinates': const GeoPoint(-17.76, -63.19)
    },
    'destination': {
      'address': 'Viru Viru',
      'coordinates': const GeoPoint(-17.64, -63.13)
    },
    'scheduledAt': Timestamp.fromDate(DateTime(2026, 10, 20, 9)),
    'class': 'business',
    'serviceType': 'oneWay',
    'status': 'confirmed',
    'estimatedPrice': 120,
  };

  test('lee los datos del chófer que copia el servidor', () {
    final b = Booking.fromJson({
      ...base,
      'driverName': 'Luis',
      'vehicleLabel': 'Toyota Camry Negro',
      'vehiclePlate': '123ABC',
      'riderRating': 5,
      'cancelledBy': null,
    });
    expect(b.driverName, 'Luis');
    expect(b.vehiclePlate, '123ABC');
    expect(b.riderRating, 5);
  });

  test('una reserva por horas sin destino usa el origen', () {
    final b = Booking.fromJson({
      ...base,
      'serviceType': 'byTheHour',
      'hours': 3,
      'destination': null,
    });
    expect(b.isHourly, isTrue);
    expect(b.destination, b.origin);
    expect(b.hours, 3);
  });

  test('acepta coordenadas sueltas, fechas pendientes y números como double',
      () {
    final b = Booking.fromJson({
      ...base,
      'origin': {'lat': -17.7, 'lng': -63.1},
      'createdAt': null,
      'passengerCount': 2.0,
    });
    expect(b.origin.lat, -17.7);
    expect(b.origin.address, '');
    expect(b.passengerCount, 2);
    expect(b.vehicleClass, VehicleClass.business);
  });

  test('una reserva sin origen no se puede leer', () {
    expect(() => Booking.fromJson({...base, 'origin': null}),
        throwsA(isA<FormatException>()));
  });

  test('el pasajero no envía campos del servidor al crear', () {
    final json = Booking.fromJson({...base, 'driverName': 'Luis'}).toJson();
    expect(json.containsKey('driverName'), isFalse);
    expect(json.containsKey('riderRating'), isFalse);
  });
}
