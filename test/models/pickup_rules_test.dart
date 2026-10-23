import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/booking_form_data.dart';
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/utils/service_area.dart';

void main() {
  group('adjustedPickup', () {
    final now = DateTime(2026, 10, 17, 14, 7);

    test('una hora con antelación suficiente no se toca', () {
      expect(adjustedPickup(DateTime(2026, 10, 17, 16), now: now), isNull);
    });

    test('una hora pasada pasa al cuarto de hora tras 30 min', () {
      expect(
        adjustedPickup(DateTime(2026, 10, 17, 8), now: now),
        DateTime(2026, 10, 17, 14, 45),
      );
    });

    test('menos de 15 min de antelación también se ajusta', () {
      expect(
        adjustedPickup(DateTime(2026, 10, 17, 14, 15), now: now),
        isNotNull,
      );
    });
  });

  group('ServiceArea.originError', () {
    test('acepta una recogida en Santa Cruz', () {
      expect(
        ServiceArea.originError(
          const Place(address: 'Equipetrol', lat: -17.765, lng: -63.196),
        ),
        isNull,
      );
    });

    test('rechaza una recogida sin coordenadas', () {
      expect(
        ServiceArea.originError(
          const Place(address: 'Sin ubicar', lat: 0, lng: 0),
        ),
        isNotNull,
      );
    });

    test('rechaza una recogida fuera de las ciudades de servicio', () {
      // Uyuni (sin ciudad de servicio; su aeropuerto está a unos km).
      expect(
        ServiceArea.originError(
          const Place(address: 'Centro', lat: -20.20, lng: -66.30),
        ),
        isNotNull,
      );
    });
  });
}
