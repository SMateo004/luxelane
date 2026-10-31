import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/l10n/build_arb.dart';

/// Los .arb salen de lib/l10n/src/*.json (tool/l10n/build.sh): nadie los
/// edita a mano y siempre están al día.
void main() {
  test('lib/l10n/app_*.arb son los de los fragmentos', () {
    final built = buildArbs('lib/l10n/src');
    for (final l in locales) {
      expect(File('lib/l10n/app_$l.arb').readAsStringSync(), built[l],
          reason: 'Ejecuta tool/l10n/build.sh');
    }
  });

  test('una clave repetida entre fragmentos o sin un idioma falla', () {
    final dir = Directory.systemTemp.createTempSync('l10n');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a.json')
        .writeAsStringSync('{"k": {"es": "a", "en": "b", "pt": "c"}}');
    File('${dir.path}/b.json')
        .writeAsStringSync('{"k": {"es": "a", "en": "b", "pt": "c"}}');
    expect(() => buildArbs(dir.path), throwsStateError);
    File('${dir.path}/b.json')
        .writeAsStringSync('{"j": {"es": "a", "en": "b"}}');
    expect(() => buildArbs(dir.path), throwsStateError);
  });
}
