import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/utils/service_area.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_screen.dart';

/// Vuelos, B4 (hallazgo de las capturas): «Nacional» e «Internacional»
/// miden al menos 48 px de alto y el lector de pantalla los lee como
/// botones, con el elegido marcado.
void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('48 px y botón seleccionado (texto x$scale)', (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(MaterialApp(
        locale: const Locale('es'),
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: FlightTypeSelector(
              value: FlightType.domestic,
              onChanged: (_) {},
            ),
          ),
        ),
      ));
      for (final type in FlightType.values) {
        final node = find.bySemanticsLabel(type.label);
        expect(node, findsOneWidget);
        expect(t.getSize(node).height, greaterThanOrEqualTo(48));
        expect(
          t.getSemantics(node),
          containsSemantics(
            label: type.label,
            isButton: true,
            isSelected: type == FlightType.domestic,
            hasTapAction: true,
          ),
        );
      }
      handle.dispose();
    });
  }
}
