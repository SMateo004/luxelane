import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';

/// E26: manifest con «A new Flutter project.» y «luxelane»; app del chófer
/// titulada «Luxelane Driver».
void main() {
  final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  final index = File('web/index.html').readAsStringSync();

  test('el título es el mismo en index.html, el manifest y las dos apps', () {
    expect(index, contains('<title>$kAppTitle</title>'));
    expect(manifest['name'], kAppTitle);
    expect(manifest['description'], kAppTitle);
    for (final f in ['lib/app/app.dart', 'lib/app/driver_app.dart']) {
      expect(File(f).readAsStringSync(), contains('title: kAppTitle'));
    }
  });

  test('colores del tema en el manifest', () {
    String hex(int argb) =>
        '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    expect(manifest['background_color'], hex(LuxColors.bg.toARGB32()));
    expect(manifest['theme_color'], hex(LuxColors.sapphire.toARGB32()));
  });

  test('sin textos de plantilla', () {
    expect(jsonEncode(manifest), isNot(contains('Flutter project')));
  });
}
