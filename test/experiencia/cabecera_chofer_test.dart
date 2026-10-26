import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_home_screen.dart';

/// E17: con viaje, «Pide al pasajero su código…» quedaba pegado al SOS y a
/// la campana.
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('el título deja 16 px antes del SOS (letra ×$scale)', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              textScaler: TextScaler.linear(scale),
            ),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(20),
                child: DriverTripHeader(
                  message: 'Pide al pasajero su código de recogida.',
                  actions: [
                    SizedBox.square(key: Key('sos'), dimension: 52),
                    SizedBox.square(key: Key('campana'), dimension: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final title =
          t.getRect(find.text('Pide al pasajero su código de recogida.'));
      final sos = t.getRect(find.byKey(const Key('sos')));
      final bell = t.getRect(find.byKey(const Key('campana')));
      expect(sos.left - title.right, greaterThanOrEqualTo(16));
      expect(bell.left - sos.right, greaterThanOrEqualTo(8));
    });
  }
}
