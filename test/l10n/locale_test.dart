import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/locale_controller.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/services/locale_sync.dart';
import 'package:luxelane/features/profile/presentation/widgets/language_selector.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas, A1, A3 y A7: resolución del idioma, cambio en caliente desde el
/// perfil y el panel de admin, que no cambia.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  group('LocaleSync', () {
    late List<List<String>> saved;
    late LocaleController controller;
    LocaleSync sync(
        {bool fail = false, List<Locale> device = const [Locale('pt', 'BR')]}) {
      saved = [];
      controller = LocaleController();
      return LocaleSync(
        controller: controller,
        deviceLocales: () => device,
        save: (l, s) async {
          if (fail) throw Exception('sin red');
          saved.add([l, s]);
          return null;
        },
      );
    }

    test('primer inicio de sesión: guarda el idioma del teléfono', () async {
      await sync().onSignedIn();
      expect(saved, [
        ['pt', 'system'],
      ]);
    });

    test('teléfono en un idioma no soportado: guarda español', () async {
      await sync(device: const [Locale('fr')]).onSignedIn();
      expect(saved, [
        ['es', 'system'],
      ]);
    });

    test('la cuenta tiene un idioma elegido: este dispositivo lo adopta',
        () async {
      final s = sync();
      await s.onSignedIn(serverLocale: 'en', serverSource: 'user');
      expect(controller.value, LocaleChoice.en);
      expect(saved, isEmpty);
    });

    test('nada que cambiar: no llama al servidor', () async {
      await sync().onSignedIn(serverLocale: 'pt', serverSource: 'system');
      expect(saved, isEmpty);
    });

    test('elegir en el perfil cambia ya y guarda; sin red, avisa con false',
        () async {
      final s = sync();
      expect(await s.choose(LocaleChoice.en, signedIn: true), isTrue);
      expect(controller.value, LocaleChoice.en);
      expect(saved.last, ['en', 'user']);
      final f = sync(fail: true);
      expect(await f.choose(LocaleChoice.es, signedIn: true), isFalse);
      expect(controller.value, LocaleChoice.es);
    });

    test('la elección se recuerda en el dispositivo', () async {
      await sync().choose(LocaleChoice.pt, signedIn: false);
      final again = LocaleController();
      await again.load();
      expect(again.value, LocaleChoice.pt);
    });
  });

  group('selector del perfil', () {
    Future<LocaleSync> pump(WidgetTester t, {bool fail = false}) async {
      // Teléfono en español.
      t.platformDispatcher.localesTestValue = const [Locale('es', 'BO')];
      addTearDown(t.platformDispatcher.clearLocalesTestValue);
      final controller = LocaleController();
      final sync = LocaleSync(
        controller: controller,
        deviceLocales: () => const [Locale('es')],
        save: (_, __) async {
          if (fail) throw Exception('sin red');
          return null;
        },
      );
      await t.pumpWidget(
        ValueListenableBuilder<LocaleChoice>(
          valueListenable: controller,
          builder: (_, choice, __) => MaterialApp(
            locale: choice == LocaleChoice.system ? null : Locale(choice.name),
            localeListResolutionCallback: LuxLocale.resolveList,
            supportedLocales: LuxLocale.supportedLocales,
            localizationsDelegates: LuxLocale.delegates,
            home: Scaffold(
              body: Builder(
                builder: (c) => Column(
                  children: [
                    Text(AppLocalizations.of(c).languageTitle),
                    LanguageSelector(sync: sync),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return sync;
    }

    testWidgets('cambio en caliente: la pantalla cambia de idioma al tocar',
        (t) async {
      await pump(t);
      expect(find.text('Sistema'), findsOneWidget);
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      await t.tap(find.text('Português'));
      await t.pumpAndSettle();
      expect(find.text('Sistema'), findsOneWidget);
      expect(find.textContaining('celular'), findsOneWidget);
      await t.tap(find.text('Español'));
      await t.pumpAndSettle();
      expect(find.textContaining('teléfono'), findsOneWidget);
    });

    testWidgets('si la cuenta no lo guarda, avisa en el idioma nuevo',
        (t) async {
      await pump(t, fail: true);
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      expect(find.textContaining('could not be saved'), findsOneWidget);
    });

    testWidgets('accesible: opciones con estado, en su idioma y de 48 px',
        (t) async {
      final h = t.ensureSemantics();
      await pump(t);
      final english = t.getSemantics(find.text('English'));
      expect(english.label, 'English');
      expect(english.hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup), isTrue);
      expect(english.hasFlag(SemanticsFlag.isChecked), isFalse);
      final system = t.getSemantics(find.text('Sistema'));
      expect(system.hasFlag(SemanticsFlag.isChecked), isTrue);
      for (final w in ['Sistema', 'Español', 'English', 'Português']) {
        final box = t.getSize(find
            .ancestor(of: find.text(w), matching: find.byType(InkWell))
            .first);
        expect(box.height, greaterThanOrEqualTo(48), reason: w);
      }
      h.dispose();
    });
  });

  group('panel de admin', () {
    tearDown(() => L10n.use(const Locale('es')));

    testWidgets('con la app en inglés, el panel sigue en español', (t) async {
      late String cancel;
      late String title;
      L10n.use(const Locale('en'));
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: LuxSpanishOnly(
            child: Builder(
              builder: (inner) {
                cancel = MaterialLocalizations.of(inner).cancelButtonLabel;
                title = inner.l10n.languageTitle;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(cancel.toLowerCase(), 'cancelar');
      expect(title, 'Idioma');
      // Los textos fuera de los widgets (enums, formatos) también.
      expect(L10n.current.languageSystem, 'Sistema');
    });

    test('la ruta del panel va dentro de LuxSpanishOnly', () {
      final src = File('lib/app/router/router.dart').readAsStringSync();
      expect(src, contains('LuxSpanishOnly(child: AdminDashboardPage())'));
    });
  });
}
