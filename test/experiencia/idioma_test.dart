import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';

/// E11: el calendario de la reserva salía en inglés («Sun, Oct 25»,
/// «October 2026», «S M T W T F S»). Con los idiomas (es, en, pt), en
/// español sigue saliendo en español.
void main() {
  testWidgets('el calendario sale en español', (t) async {
    await t.pumpWidget(
      MaterialApp(
        locale: LuxLocale.fallback,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () => showDatePicker(
              context: c,
              initialDate: DateTime(2026, 10, 25),
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    expect(find.textContaining('octubre'), findsWidgets);
    expect(find.textContaining('October'), findsNothing);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  test('las dos apps usan los delegados y la elección de idioma', () {
    for (final f in ['lib/app/app.dart', 'lib/app/driver_app.dart']) {
      final src = File(f).readAsStringSync();
      expect(src, contains('localizationsDelegates: LuxLocale.delegates'),
          reason: f);
      expect(src, contains('ValueListenableBuilder<LocaleChoice>'), reason: f);
      expect(
          src, contains('localeListResolutionCallback: LuxLocale.resolveList'),
          reason: f);
    }
  });
}
