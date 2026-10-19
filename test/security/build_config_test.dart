// Configuración de build sensible: firma de release y claves de Google Maps.
// Leen los archivos del repositorio, así que fallan si alguien vuelve a
// firmar la release con la clave de debug o a embeber una clave de Maps.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/env.dart';
import 'package:luxelane/core/widgets/lux_map.dart';

final _googleApiKey = RegExp(r'AIza[0-9A-Za-z_\-]{35}');

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Firma de Android (D9)', () {
    final gradle = _read('android/app/build.gradle.kts');

    test('la release no se firma con la clave de debug', () {
      expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
      expect(gradle,
          contains('signingConfig = signingConfigs.getByName("release")'));
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
      expect(_read('android/app/build.gradle.kts'),
          contains('Release build without a Google Maps key'));
    });

    test('la release de iOS falla sin clave de Maps', () {
      expect(_read('ios/Runner.xcodeproj/project.pbxproj'),
          contains('Release build without a Google Maps key'));
    });

    test('los archivos locales de claves están en .gitignore', () {
      final ignore = _read('.gitignore');
      expect(ignore, contains('env.local.json'));
      expect(ignore, contains('ios/Flutter/Secrets.xcconfig'));
    });

    testWidgets('sin clave, el mapa muestra un aviso visible', (tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: LuxMap())));
      expect(find.byType(MapsKeyMissing), findsOneWidget);
      expect(find.text('Mapa no disponible'), findsOneWidget);
    });
  });
}
