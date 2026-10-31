import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'textos_fijos.dart';

/// Idiomas, A5: trinquete de textos fijos. Ninguna carpeta puede tener más
/// textos literales que en textos_fijos_trinquete.json; al migrar textos a
/// los .arb la cuenta baja y hay que fijar el nuevo mínimo con
/// ACTUALIZAR_TRINQUETE=1 flutter test este archivo (si no, también falla:
/// lo migrado no puede volver). Meta: «trinquete» en cero (apps del pasajero
/// y del chófer); el panel de admin y las páginas legales no cuentan.
const _baseline = 'test/l10n/textos_fijos_trinquete.json';

void main() {
  test('los textos fijos no aumentan (y la línea base está al día)', () {
    final now = countLib();
    if (Platform.environment['ACTUALIZAR_TRINQUETE'] == '1') {
      File(_baseline).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(now)}\n',
      );
    }
    final base = (jsonDecode(File(_baseline).readAsStringSync()) as Map).map(
      (k, v) => MapEntry(k as String, Map<String, int>.from(v as Map)),
    );
    final problems = <String>[];
    for (final group in now.keys) {
      final b = base[group] ?? {};
      final n = now[group]!;
      for (final k in {...b.keys, ...n.keys}) {
        final before = b[k] ?? 0;
        final after = n[k] ?? 0;
        if (after > before) problems.add('$group $k: $before → $after (sube)');
        if (after < before) {
          problems.add(
              '$group $k: $before → $after (baja: actualiza la línea base)');
        }
      }
    }
    expect(problems, isEmpty,
        reason:
            'Los textos nuevos van a lib/l10n/app_es.arb, app_en.arb y app_pt.arb');
  });

  group('criterio', () {
    test('cuenta lenguaje natural', () {
      expect(countFile("Text('Reservar'); Text('¿Cancelar?'); x('SOS');"), 3);
      expect(countFile("const t = 'Tu chófer llegó';"), 1);
      expect(countFile('a(title: "Hola mundo")'), 1);
    });

    test('no cuenta claves, rutas, logs ni comentarios', () {
      expect(
        countFile(
          "x['riderId']; go('/ride/\$id'); import 'package:a/b.dart';\n"
          "debugPrint('Hola mundo');\n// Text('Hola mundo')\n"
          "const k = ValueKey('Boton guardar');\nfinal s = '\${a.b}';",
        ),
        0,
      );
    });

    test('una línea marcada i18n-ignore no cuenta', () {
      expect(
        countFile("x('Business Class'); // i18n-ignore: nombre de producto"),
        0,
      );
    });

    test('un texto nuevo en una pantalla haría fallar el trinquete', () {
      final before = countFile('Text(l10n.languageTitle)');
      final after = countFile("Text(l10n.languageTitle); Text('Idioma nuevo')");
      expect(after, before + 1);
    });
  });
}
