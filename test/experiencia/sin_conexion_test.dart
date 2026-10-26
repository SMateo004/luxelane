import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/widgets/lux_connection_banner.dart';

/// E12: sin red, las pantallas mostraban datos en caché sin avisarlo.
void main() {
  const aviso = 'Sin conexión. Lo que ves puede no estar al día.';

  Future<StreamController<bool>> pump(WidgetTester t) async {
    final c = StreamController<bool>();
    addTearDown(c.close);
    await t.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            LuxConnectionBanner(online: c.stream, child: child!),
        home: const Scaffold(body: Text('Mis viajes')),
      ),
    );
    return c;
  }

  testWidgets('sin conexión 2 s: aparece el aviso; al volver, se va', (
    t,
  ) async {
    // Se cierra en addTearDown dentro de pump.
    // ignore: close_sinks
    final c = await pump(t);
    c.add(false);
    await t.pump(const Duration(seconds: 1));
    expect(find.text(aviso), findsNothing);
    await t.pump(const Duration(seconds: 2));
    expect(find.text(aviso), findsOneWidget);
    expect(find.text('Mis viajes'), findsOneWidget);
    c.add(true);
    await t.pump();
    await t.pump();
    expect(find.text(aviso), findsNothing);
  });

  testWidgets('un corte de menos de 2 s no avisa', (t) async {
    // Se cierra en addTearDown dentro de pump.
    // ignore: close_sinks
    final c = await pump(t);
    c.add(false);
    await t.pump(const Duration(milliseconds: 800));
    c.add(true);
    await t.pump(const Duration(seconds: 3));
    expect(find.text(aviso), findsNothing);
  });

  test('las dos apps ponen el aviso sobre todas las pantallas', () {
    for (final f in ['lib/app/app.dart', 'lib/app/driver_app.dart']) {
      expect(
        File(f).readAsStringSync(),
        contains('LuxConnectionBanner('),
        reason: f,
      );
    }
  });
}
