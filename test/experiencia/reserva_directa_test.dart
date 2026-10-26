import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/router/router.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/booking_form_data.dart';
import 'package:luxelane/core/models/models.dart';

/// E23: /booking abierto directamente mostraba «PRECIO FINAL Bs 20» sin
/// recorrido.
void main() {
  test('sin viaje elegido, vuelve al inicio', () {
    expect(bookingRouteRedirect(null), LuxRoutes.home);
    expect(bookingRouteRedirect('otra cosa'), LuxRoutes.home);
  });

  test('con el viaje de Inicio, se queda', () {
    final data = BookingFormData(
      origin: const Place(address: 'Aeropuerto', lat: -17.64, lng: -63.13),
      serviceType: ServiceType.oneWay,
      scheduledAt: DateTime(2026, 10, 26, 12),
    );
    expect(bookingRouteRedirect(data), isNull);
  });

  test('la ruta /booking usa esa redirección', () {
    expect(
      File('lib/app/router/router.dart').readAsStringSync(),
      contains('redirect: (c, s) => bookingRouteRedirect(s.extra)'),
    );
  });
}
