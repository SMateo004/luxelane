import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E2/E24: la app no promete lo que el sistema no cumple. Si una de estas
/// frases vuelve a lib/, el responsable debe decidir antes si se respalda.
/// El texto legal (legal_page.dart) se revisa aparte con el abogado (E33).
const _prohibidas = <String, String>{
  'cancelación gratuita': r'cancelaci[oó]n\s+gratuita',
  'cancelar sin coste': r'sin\s+cos(te|to)',
  'modificar sin coste': r'modifica[r]?\s+sin',
  'espera gratuita':
      r'espera\s+(gratuita|gratis)|espera\s+gratis|min(utos)?\s+de\s+espera',
  'seguimiento de vuelo':
      r'seguimiento\s+de\s+(tu\s+)?vuelo|seguimos\s+tu\s+vuelo|sigue\s+tu\s+vuelo',
  'atención 24/7': r'24\s*/\s*7',
  'propina incluida': r'propina',
  'verificación de antecedentes':
      r'antecedentes|capacitaci[oó]n\s+en\s+servicio|formados\s+en',
  'te contactarán': r'te\s+contactar[aá]n?\b|te\s+llamar[aá]\b',
  'cobertura mundial':
      r'en\s+todo\s+el\s+mundo|cobertura\s+(mundial|global)|m[aá]s\s+de\s+50\s+ciudades',
};

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('legal_page.dart'));

  for (final entry in _prohibidas.entries) {
    test('nadie promete «${entry.key}»', () {
      final re = RegExp(entry.value, caseSensitive: false);
      final hits = <String>[
        for (final f in files)
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (!line.trimLeft().startsWith('//') && re.hasMatch(line))
              '${f.path}:${i + 1}: ${line.trim()}',
      ];
      expect(hits, isEmpty);
    });
  }
}
