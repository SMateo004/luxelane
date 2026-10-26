import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E28: trinquete de valores fuera del tema. Cuenta, por archivo de lib/,
/// colores literales, Colors.*, fontSize, TextStyle propios y SizedBox con
/// números en vez de LuxSpacing. Ningún archivo puede subir de lo anotado
/// en tema_trinquete.json (los nuevos empiezan en 0). Bajar sí se puede:
/// para fijar el nuevo mínimo, ACTUALIZAR_TRINQUETE=1 flutter test este
/// archivo. Mismos patrones que tools/experiencia/analisis_tema.py.
const _baseline = 'test/experiencia/tema_trinquete.json';

const _themeFiles = {
  'lib/app/theme/app_theme.dart',
  'lib/app/theme/lux_motion.dart',
  'lib/features/home/presentation/pages/home_design.dart',
};

final _patterns = <String, RegExp>{
  'colores': RegExp(r'\bColor\(0x[0-9A-Fa-f]{8}\)'),
  'colors_material': RegExp(r'\bColors\.(?!transparent\b)[a-z][A-Za-z0-9]*'),
  'font_size': RegExp(r'fontSize:\s*[0-9.]+'),
  'text_style': RegExp(r'(?<![A-Za-z])TextStyle\('),
  'sized_box_numero': RegExp(r'SizedBox\((?:height|width):\s*[0-9.]+\)'),
};

Map<String, Map<String, int>> _count() {
  final out = <String, Map<String, int>>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    final path = f.path.replaceAll(r'\', '/');
    if (_themeFiles.contains(path)) continue;
    final code = f.readAsStringSync().replaceAll(RegExp(r'//.*'), '');
    final row = <String, int>{
      for (final e in _patterns.entries)
        if (e.value.allMatches(code).isNotEmpty)
          e.key: e.value.allMatches(code).length,
    };
    if (row.isNotEmpty) out[path] = row;
  }
  return out;
}

void main() {
  test('los valores fuera del tema no aumentan', () {
    final now = _count();
    if (Platform.environment['ACTUALIZAR_TRINQUETE'] == '1') {
      File(_baseline).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(now)}\n',
      );
    }
    final base = (jsonDecode(File(_baseline).readAsStringSync()) as Map)
        .map((k, v) => MapEntry(k as String, Map<String, int>.from(v as Map)));
    final up = <String>[];
    now.forEach((file, row) {
      row.forEach((kind, n) {
        final before = base[file]?[kind] ?? 0;
        if (n > before) up.add('$file: $kind $before → $n');
      });
    });
    expect(up, isEmpty, reason: 'Usa LuxColors, LuxTypography y LuxSpacing');
  });
}
