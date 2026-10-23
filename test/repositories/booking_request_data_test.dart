import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';

Booking _booking({ServiceType service = ServiceType.oneWay}) => Booking(
  id: '',
  riderId: 'ana',
  origin: const Place(
    name: 'Viru Viru',
    address: 'Aeropuerto Internacional Viru Viru',
    lat: -17.6447,
    lng: -63.1353,
  ),
  destination: const Place(
    address: 'Calle Exacta 123',
    lat: -17.7833,
    lng: -63.1821,
  ),
  scheduledAt: DateTime.utc(2026, 11, 1, 14),
  vehicleClass: VehicleClass.business,
  serviceType: service,
  status: BookingStatus.pending,
  estimatedPrice: 999,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  hours: service == ServiceType.byTheHour ? 3 : null,
  notes: 'Llevar agua',
  flightNumber: 'OB760',
  flightType: 'domestic',
  passengerCount: 2,
  luggageCount: 1,
  guest: const BookingGuest(
    firstName: 'Carla',
    phone: '+59170000001',
    email: 'viejo@x.com',
  ),
);

void main() {
  group('bookingRequestData', () {
    test('solo datos del viaje: nunca precio, estado ni ids', () {
      final data = bookingRequestData(
        _booking(),
        quotedPrice: 86,
        requestId: '3f2b1c9e-8d7a-4b6c-9e5f-1a2b3c4d5e6f',
      );
      for (final k in ['estimatedPrice', 'status', 'riderId', 'pickupArea']) {
        expect(data.containsKey(k), isFalse, reason: k);
      }
      expect(data['quotedPrice'], 86);
      expect(data['requestId'], '3f2b1c9e-8d7a-4b6c-9e5f-1a2b3c4d5e6f');
      expect(
        data['scheduledAt'],
        DateTime.utc(2026, 11, 1, 14).millisecondsSinceEpoch,
      );
      expect(data['origin'], {
        'name': 'Viru Viru',
        'address': 'Aeropuerto Internacional Viru Viru',
        'lat': -17.6447,
        'lng': -63.1353,
      });
      // El correo de una reserva antigua no se reenvía.
      expect(data['guest'], {'firstName': 'Carla', 'phone': '+59170000001'});
    });

    test('la cotización no lleva datos personales', () {
      final data = bookingRequestData(_booking(), quote: true);
      expect(data.keys.toSet(), {
        'origin',
        'destination',
        'scheduledAt',
        'vehicleClass',
        'serviceType',
      });
    });

    test('por horas manda horas y no destino', () {
      final data = bookingRequestData(_booking(service: ServiceType.byTheHour));
      expect(data['hours'], 3);
      expect(data.containsKey('destination'), isFalse);
    });
  });

  test('manda la versión de la app al cotizar y al reservar', () {
    expect(
      bookingRequestData(
        _booking(),
        quote: true,
        appVersion: '1.2.0',
      )['appVersion'],
      '1.2.0',
    );
    expect(
      bookingRequestData(
        _booking(),
        requestId: 'r',
        appVersion: '1.2.0',
      )['appVersion'],
      '1.2.0',
    );
  });

  group('bookingFailureFor', () {
    test('app_update_required trae los enlaces de las tiendas', () {
      final f = bookingFailureFor('failed-precondition', {
        'reason': 'app_update_required',
        'androidStoreUrl': 'https://play.example/luxelane',
      });
      expect(f, isA<AppUpdateRequiredFailure>());
      expect(
        (f as AppUpdateRequiredFailure).androidStoreUrl,
        'https://play.example/luxelane',
      );
    });

    test('price_changed trae el precio nuevo', () {
      final f = bookingFailureFor('failed-precondition', {
        'reason': 'price_changed',
        'price': 120,
      });
      expect(f, isA<PriceChangedFailure>());
      expect((f as PriceChangedFailure).price, 120);
    });

    test('los errores llegan en español y sin texto técnico', () {
      for (final reason in [
        'pricing_unavailable',
        'out_of_area',
        'class_unavailable',
        'invalid_hours',
        'invalid_request',
        'inactive_user',
        null,
      ]) {
        final msg = bookingFailureFor('internal', {'reason': reason}).message;
        expect(msg, isNot(contains('_')), reason: '$reason');
        expect(msg, isNot(contains('Error')), reason: '$reason');
      }
      expect(
        bookingFailureFor('failed-precondition', {
          'reason': 'pricing_unavailable',
        }).message,
        contains('No pudimos calcular el precio'),
      );
    });
  });
}
