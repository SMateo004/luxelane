// Configuración de build sensible: firma de release, claves de Google Maps y
// claves de Firebase de las apps nativas.
// Leen los archivos del repositorio, así que fallan si alguien vuelve a
// firmar la release con la clave de debug o a embeber una clave de Maps.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/env.dart';
import 'package:luxelane/core/widgets/lux_map.dart';
import 'package:luxelane/firebase_options.dart';

final _googleApiKey = RegExp(r'AIza[0-9A-Za-z_\-]{35}');

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Firma de Android (D9)', () {
    final gradle = _read('android/app/build.gradle.kts');

    test('la release no se firma con la clave de debug', () {
      expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
      expect(
        gradle,
        contains('signingConfig = signingConfigs.getByName("release")'),
      );
    });

    test('la release lee android/key.properties y falla sin él', () {
      expect(gradle, contains('rootProject.file("key.properties")'));
      expect(gradle, contains('Release build without android/key.properties'));
    });

    test('el keystore y key.properties no se versionan', () {
      final ignore = _read('android/.gitignore');
      expect(ignore, contains('key.properties'));
      expect(ignore, contains('*.jks'));
      expect(ignore, contains('*.keystore'));
    });
  });

  group('Claves de Google Maps (D12)', () {
    for (final path in [
      'lib/core/config/env.dart',
      'android/app/build.gradle.kts',
      'ios/Flutter/Luxelane.xcconfig',
    ]) {
      test('$path no contiene ninguna clave', () {
        expect(_googleApiKey.hasMatch(_read(path)), isFalse);
      });
    }

    test('sin --dart-define no hay clave', () {
      expect(AppConfig.googleMapsKey, isEmpty);
      expect(AppConfig.hasMapsKey, isFalse);
    });

    test('la release de Android falla sin clave de Maps', () {
      expect(
        _read('android/app/build.gradle.kts'),
        contains('Release build without a Google Maps key'),
      );
    });

    test('la release de iOS falla sin clave de Maps', () {
      expect(
        _read('ios/Runner.xcodeproj/project.pbxproj'),
        contains('Release build without a Google Maps key'),
      );
    });

    test('los archivos locales de claves están en .gitignore', () {
      final ignore = _read('.gitignore');
      expect(ignore, contains('env.local.json'));
      expect(ignore, contains('ios/Flutter/Secrets.xcconfig'));
    });

    testWidgets('sin clave, el mapa muestra un aviso visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LuxMap())),
      );
      expect(find.byType(MapsKeyMissing), findsOneWidget);
      expect(find.text('Mapa no disponible'), findsOneWidget);
    });
  });

  group('Claves de Firebase de las apps nativas (B8)', () {
    final options = _read('lib/firebase_options.dart');

    test('firebase_options.dart no trae claves nativas por defecto', () {
      for (final name in ['FIREBASE_ANDROID_API_KEY', 'FIREBASE_IOS_API_KEY']) {
        final decl = RegExp(
          "String\\.fromEnvironment\\(\\s*'$name'([^)]*)\\)",
        ).firstMatch(options);
        expect(decl, isNotNull, reason: '$name debe leerse de --dart-define');
        expect(decl!.group(1), isNot(contains('defaultValue')), reason: name);
      }
    });

    test('las opciones nativas usan la clave de su plataforma', () {
      expect(
        options,
        isNot(contains('apiKey: _stagingApiKey,\n    appId: _androidAppId')),
      );
      expect(
        options,
        isNot(contains('apiKey: _stagingApiKey,\n    appId: _iosAppId')),
      );
      expect(
        RegExp(
          r'apiKey: _androidApiKey,\s+appId: _androidAppId',
        ).allMatches(options).length,
        2,
      );
      expect(
        RegExp(
          r'apiKey: _iosApiKey,\s+appId: _iosAppId',
        ).allMatches(options).length,
        2,
      );
    });

    test(
      'sin --dart-define faltan el app ID y la clave de cada plataforma',
      () {
        expect(
          DefaultFirebaseOptions.missingNativeDefines(TargetPlatform.android),
          ['FIREBASE_ANDROID_APP_ID', 'FIREBASE_ANDROID_API_KEY'],
        );
        expect(
          DefaultFirebaseOptions.missingNativeDefines(TargetPlatform.iOS),
          ['FIREBASE_IOS_APP_ID', 'FIREBASE_IOS_API_KEY'],
        );
      },
    );

    test('la release de Android falla sin la configuración de Firebase', () {
      final gradle = _read('android/app/build.gradle.kts');
      expect(gradle, contains('Release build without Firebase Android config'));
      expect(
        gradle,
        contains('"FIREBASE_ANDROID_APP_ID", "FIREBASE_ANDROID_API_KEY"'),
      );
    });

    test('la release de iOS falla sin la configuración de Firebase', () {
      final pbx = _read('ios/Runner.xcodeproj/project.pbxproj');
      expect(pbx, contains('Release build without Firebase iOS config'));
      expect(pbx, contains('FIREBASE_IOS_APP_ID FIREBASE_IOS_API_KEY'));
    });

    test('el CI pasa cada clave desde su secreto, sin imprimirla', () {
      final ci = _read('.github/workflows/ci.yml');
      expect(
        RegExp(
          r'--dart-define=FIREBASE_ANDROID_API_KEY=\$\{\{ secrets\.FIREBASE_ANDROID_API_KEY \}\}',
        ).allMatches(ci).length,
        2,
        reason: 'builds de Android del pasajero y del chófer',
      );
      expect(
        ci,
        contains(
          r'--dart-define=FIREBASE_IOS_API_KEY=${{ secrets.FIREBASE_IOS_API_KEY }}',
        ),
      );
      expect(_googleApiKey.hasMatch(ci), isFalse);
    });
  });

  group('Orden de despliegue: reglas al final y a mano (D1/T8)', () {
    final ci = _read('.github/workflows/ci.yml');

    test('el despliegue de functions no lleva las reglas', () {
      expect(ci, isNot(contains('deploy --only functions,firestore:rules')));
      expect(ci, contains('args: deploy --only functions,firestore:indexes\n'));
      expect(
        ci,
        isNot(contains('functions,firestore:indexes,firestore:rules')),
      );
    });

    test(
      'las reglas solo se despliegan a mano, desde main y con aprobación',
      () {
        final job = ci.substring(ci.indexOf('  deploy_rules:'));
        expect(job, contains("github.event_name == 'workflow_dispatch'"));
        expect(job, contains('inputs.deploy_rules'));
        expect(job, contains("github.ref == 'refs/heads/main'"));
        expect(job, contains('environment: production'));
        expect(job, contains('args: deploy --only firestore:rules'));
      },
    );

    test('los índices compuestos de incidents se despliegan con functions', () {
      final indexes = _read('firestore.indexes.json');
      for (final f in ['status', 'reporterId', 'locationsPurged']) {
        expect(indexes, contains('"fieldPath": "$f"'));
      }
      expect(indexes, contains('"collectionGroup": "incidents"'));
    });

    test('no se despliega sin PICKUP_CODE_SECRET en Secret Manager', () {
      expect(ci, contains('functions:secrets:get PICKUP_CODE_SECRET'));
    });
  });
}
