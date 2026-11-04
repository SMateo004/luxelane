import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/notifications/push_permission.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Prompt 18, C4: permiso de avisos con explicación propia y configuración
/// nativa de los push (iOS y Android).
void main() {
  group('PushPermissionGate', () {
    Future<(bool, int, int)> run(AuthorizationStatus s,
        {bool answer = true}) async {
      var explained = 0, requested = 0;
      final asked = await PushPermissionGate(
        status: () async => s,
        request: () async => requested++,
        explain: () async {
          explained++;
          return answer;
        },
      ).run();
      return (asked, explained, requested);
    }

    test('sin pedir aún: explica y, si sigue, pide al sistema', () async {
      expect(await run(AuthorizationStatus.notDetermined), (true, 1, 1));
    });
    test('«Ahora no»: no se pide al sistema', () async {
      expect(await run(AuthorizationStatus.notDetermined, answer: false),
          (false, 1, 0));
    });
    test('ya concedido, provisional o negado: ni explica ni insiste', () async {
      for (final s in [
        AuthorizationStatus.authorized,
        AuthorizationStatus.provisional,
        AuthorizationStatus.denied
      ]) {
        expect(await run(s), (false, 0, 0));
      }
    });
  });

  group('explicación previa', () {
    Future<bool?> open(WidgetTester t, Locale locale,
        {bool tapContinue = true}) async {
      L10n.use(locale);
      bool? result;
      await t.pumpWidget(MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: Builder(
          builder: (c) => TextButton(
            onPressed: () async =>
                result = await showPushPermissionExplainer(c),
            child: const Text('abrir'),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      return result;
    }

    tearDown(() => L10n.use(const Locale('es')));

    for (final (locale, title, go, no) in [
      (const Locale('es'), 'Avisos de tus viajes', 'Continuar', 'Ahora no'),
      (
        const Locale('en'),
        'Notifications about your trips',
        'Continue',
        'Not now'
      ),
      (const Locale('pt'), 'Avisos das suas viagens', 'Continuar', 'Agora não'),
    ]) {
      testWidgets(
          'textos en ${locale.languageCode}; «Continuar» sigue y «Ahora no», no',
          (t) async {
        await open(t, locale);
        expect(find.text(title), findsOneWidget);
        await t.tap(find.text(go));
        await t.pumpAndSettle();
        await open(t, locale);
        await t.tap(find.text(no));
        await t.pumpAndSettle();
        expect(find.text(title), findsNothing);
      });
    }

    testWidgets('botones de 48 px y etiquetados; sin promesas', (t) async {
      final h = t.ensureSemantics();
      await open(t, const Locale('es'));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      expect(
          L10n.current.pushPermissionBody,
          isNot(matches(
              RegExp('garantiz|a tiempo|siempre', caseSensitive: false))));
      h.dispose();
    });
  });

  group('configuración nativa de los push', () {
    test('iOS: Runner.entitlements con aps-environment', () {
      final f = File('ios/Runner/Runner.entitlements').readAsStringSync();
      expect(f, contains('<key>aps-environment</key>'));
    });

    test(
        'iOS: el target Runner usa los entitlements en Debug, Release y Profile',
        () {
      final p = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      // Cada configuración del target Runner (la que usa Runner/Info.plist).
      final configs = RegExp(
              r'buildSettings = \{([^}]*INFOPLIST_FILE = Runner/Info\.plist;[^}]*)\};\s*name = (\w+);')
          .allMatches(p)
          .map((m) => (m.group(2)!, m.group(1)!))
          .toList();
      expect(configs.map((c) => c.$1).toList()..sort(),
          ['Debug', 'Profile', 'Release']);
      for (final (_, body) in configs) {
        expect(body,
            contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'));
      }
      expect(
          p, contains('/* Runner.entitlements */ = {isa = PBXFileReference;'));
    });

    test(
        'Android: canal por defecto declarado, creado y con nombre en es/en/pt',
        () {
      final m =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
          m,
          contains(
              'com.google.firebase.messaging.default_notification_channel_id'));
      final main =
          File('android/app/src/main/kotlin/com/luxelane/app/MainActivity.kt')
              .readAsStringSync();
      expect(main, contains('createNotificationChannel'));
      for (final dir in ['values', 'values-en', 'values-pt']) {
        final s = File('android/app/src/main/res/$dir/strings.xml')
            .readAsStringSync();
        expect(s, contains('name="notification_channel_trips_name"'),
            reason: dir);
      }
    });
  });
}
