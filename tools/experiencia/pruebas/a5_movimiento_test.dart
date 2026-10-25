// A5: «reducir movimiento» y animaciones interrumpidas, en tests de widget.
// Afirman el comportamiento DESEADO: hoy algunos fallan y eso documenta el
// hallazgo (ver docs/EXPERIENCIA_LUXLANE.md). No está en test/ para no
// romper la suite; se ejecuta con:
//   flutter test tools/experiencia/pruebas/a5_movimiento_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/widgets/lux_feedback.dart';
import 'package:luxelane/core/widgets/lux_raised.dart';

Widget _app(Widget child, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  testWidgets('deslizar para confirmar: si el paso falla, se puede repetir',
      (t) async {
    var calls = 0;
    await t.pumpWidget(_app(SizedBox(
      width: 320,
      child: LuxSlideToConfirm(label: 'He llegado', onConfirmed: () => calls++),
    )));
    Future<void> slide() async {
      await t.drag(find.byType(LuxSlideToConfirm), const Offset(400, 0));
      await t.pumpAndSettle();
    }
    await slide();
    expect(calls, 1);
    // El servidor rechazó el paso: el estado (y la etiqueta) no cambian.
    await t.pumpWidget(_app(SizedBox(
      width: 320,
      child: LuxSlideToConfirm(label: 'He llegado', onConfirmed: () => calls++),
    )));
    await slide();
    expect(calls, 2, reason: 'el control quedó en «hecho» y no deja reintentar');
  });

  for (final reduce in [false, true]) {
    testWidgets('puntos de carga con reducir movimiento=$reduce: '
        '${reduce ? 'quietos' : 'animados'}', (t) async {
      await t.pumpWidget(_app(const LuxLoadingDots(color: Colors.black), reduce: reduce));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.binding.hasScheduledFrame, !reduce,
          reason: reduce ? 'sigue repitiéndose con reducir movimiento' : '');
    });
  }

  testWidgets('barra de progreso del viaje: con reducir movimiento no pulsa',
      (t) async {
    await t.pumpWidget(_app(const RideProgressBar(status: BookingStatus.driverArriving), reduce: true));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'el pulso sigue corriendo');
  });

  testWidgets('esqueleto de carga: con reducir movimiento queda quieto', (t) async {
    await t.pumpWidget(_app(const SizedBox(height: 400, child: LuxSkeletonList()), reduce: true));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'el brillo sigue corriendo');
  });
}
