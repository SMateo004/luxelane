import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';

Booking _booking({ServiceType service = ServiceType.oneWay}) => Booking(
      id: '',
      riderId: 'ana',
      origin: const Place(
          name: 'Viru Viru',
          address: 'Aeropuerto Internacional Viru Viru, Santa Cruz',
          lat: -17.6447,
          lng: -63.1353),
      destination: const Place(
          address: 'Calle Exacta 123, Santa Cruz de la Sierra',
          lat: -17.7833,
          lng: -63.1821),
      scheduledAt: DateTime(2025, 6),
      vehicleClass: VehicleClass.business,
      serviceType: service,
      status: BookingStatus.pending,
      estimatedPrice: 100,
      createdAt: DateTime(2025, 6),
      updatedAt: DateTime(2025, 6),
    );

void main() {
  group('bookingCreateData', () {
    test('guarda la zona (aeropuerto o ciudad), no la dirección exacta', () {
      final data = bookingCreateData(_booking());
      expect(data['pickupArea'], 'Aeropuerto Internacional Viru Viru');
      expect(data['dropoffArea'], 'Santa Cruz de la Sierra');
      expect(data['pickupArea'], isNot(contains('Calle')));
      expect(data['dropoffArea'], isNot(contains('Exacta')));
    });

    test('por horas no guarda zona de destino', () {
      final data = bookingCreateData(_booking(service: ServiceType.byTheHour));
      expect(data.containsKey('dropoffArea'), isFalse);
    });
  });
}
