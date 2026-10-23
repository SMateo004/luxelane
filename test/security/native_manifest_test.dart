// Manifiesto de Android (T5): sin copia de seguridad de los datos de la app.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('allowBackup desactivado', () {
    expect(manifest, contains('android:allowBackup="false"'));
  });

  test('Android 12+: sin copia en la nube ni transferencia entre equipos', () {
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    final rules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
    expect(rules, contains('domain="sharedpref"'));
  });

  test('sin tráfico en claro ni depuración forzada', () {
    expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
    expect(manifest, isNot(contains('android:debuggable="true"')));
  });
}
