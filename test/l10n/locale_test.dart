import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';

/// Idiomas, A1: resolución del idioma y el panel de admin, que no cambia.
void main() {
  group('idioma del sistema', () {
    test('es, en o pt del teléfono se usan; pt-PT y pt-BR dan pt', () {
      expect(
          LuxLocale.fromDevice([const Locale('en', 'US')]), const Locale('en'));
      expect(
          LuxLocale.fromDevice([const Locale('pt', 'PT')]), const Locale('pt'));
      expect(
          LuxLocale.fromDevice([const Locale('pt', 'BR')]), const Locale('pt'));
      expect(
          LuxLocale.fromDevice([const Locale('es', 'BO')]), const Locale('es'));
    });

    test('un idioma no soportado cae en español, o en el siguiente soportado',
        () {
      expect(
          LuxLocale.fromDevice([const Locale('fr', 'FR')]), const Locale('es'));
      expect(LuxLocale.fromDevice([const Locale('de'), const Locale('en')]),
          const Locale('en'));
      expect(LuxLocale.fromDevice(const []), const Locale('es'));
      expect(LuxLocale.fromDevice(null), const Locale('es'));
    });

    test('la elección del perfil manda sobre el teléfono', () {
      final fr = [const Locale('fr')];
      expect(LuxLocale.resolve(LocaleChoice.system, fr), const Locale('es'));
      expect(LuxLocale.resolve(LocaleChoice.pt, fr), const Locale('pt'));
      expect(LuxLocale.choiceOf('en'), LocaleChoice.en);
      expect(LuxLocale.choiceOf('fr'), LocaleChoice.system);
      expect(LuxLocale.choiceOf(null), LocaleChoice.system);
    });
  });

  group('panel de admin', () {
    testWidgets('con la app en inglés, el panel sigue en español', (t) async {
      late String cancel;
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: Builder(
            builder: (c) => Localizations.override(
              context: c,
              locale: LuxLocale.fallback,
              child: Builder(
                builder: (inner) {
                  cancel = MaterialLocalizations.of(inner).cancelButtonLabel;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(cancel.toLowerCase(), 'cancelar');
    });

    test('la ruta del panel fuerza el español', () {
      final src = File('lib/app/router/router.dart').readAsStringSync();
      expect(
        src,
        matches(RegExp(
          r'Localizations\.override\(\s*context: c,\s*locale: LuxLocale\.fallback,\s*child: const AdminDashboardPage\(\)',
        )),
      );
    });
  });
}
