// Experiencia, A5 y Parte B: «reducir movimiento» y animaciones
// interrumpidas. Antes estaban en tools/experiencia/pruebas (fallaban: E1,
// E3, E10); pasan al corregirse.
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/incidents/presentation/widgets/sos_button.dart';

Widget _app(Widget child, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  group('SOS (E1): 2 s de pulsación siempre', () {
    Future<int> hold(
      WidgetTester t,
      Duration d, {
      bool platform = false,
      double dilation = 1,
    }) async {
      var n = 0;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: platform);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      timeDilation = dilation;
      await t.pumpWidget(
        _app(SosButton(onActivated: () => n++), reduce: platform),
      );
      final g = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('sos-button'))),
      );
      await t.pump();
      await t.pump(d);
      await g.up();
      await t.pump();
      // El arnés exige restaurarla dentro del cuerpo del test.
      timeDilation = 1;
      return n;
    }

    testWidgets('normal: 1 s no envía, 2,1 s sí', (t) async {
      expect(await hold(t, const Duration(seconds: 1)), 0);
      expect(await hold(t, const Duration(milliseconds: 2100)), 1);
    });

    testWidgets('con «quitar animaciones» del sistema: 200 ms ni 1,9 s envían',
        (t) async {
      expect(
        await hold(t, const Duration(milliseconds: 200), platform: true),
        0,
      );
      expect(
        await hold(t, const Duration(milliseconds: 1900), platform: true),
        0,
      );
      expect(
        await hold(t, const Duration(milliseconds: 2100), platform: true),
        1,
      );
    });

    testWidgets('con timeDilation 5: envía a los 2 s, no a los 10', (t) async {
      expect(
        await hold(t, const Duration(milliseconds: 1900), dilation: 5),
        0,
      );
      expect(
        await hold(t, const Duration(milliseconds: 2100), dilation: 5),
        1,
      );
    });
  });
}
