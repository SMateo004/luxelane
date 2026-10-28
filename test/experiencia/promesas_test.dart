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
  // F2: quitadas sin sustituir.
  'puntualidad garantizada': r'puntualidad\s+garantizada',
  'gerente de cuenta': r'gerente\s+de\s+cuenta',
  'cumplimiento de política de viajes':
      r'cumplimiento\s+de\s+(la\s+)?pol[ií]tica',
  'monitoreo de viajes': r'monitoreo\s+de\s+viajes',
  'discreción y privacidad': r'discreci[oó]n',
  // F2: quitadas por ahora; la lista para reponer está en
  // docs/EXPERIENCIA_LUXLANE.md (decisión del responsable).
  'cartel con tu nombre': r'cartel',
  'recibimiento personalizado': r'recibimiento\s+personalizado',
  'agua de cortesía': r'\bagua\b',
  'cargadores a bordo': r'cargador',
  'pañuelos': r'pa[ñn]uelo|toallita',
  'chóferes multilingües': r'multiling',
  // G1 (pagos): el chófer se busca cuando el pago está confirmado; nada de
  // asignación inmediata. Quitadas sin sustituir.
  'chófer de inmediato':
      r'(ch[oó]fer|asign\w*)[^\n]{0,60}(de\s+inmediato|al\s+instante|en\s+cuanto\s+confirmas)',
  // (\\n: saltos de línea escritos dentro de las cadenas, como en títulos.)
  'en minutos': r'(\b|\\n)en\s+minutos\b',
};

void main() {
  // lib/ (app y web Flutter) y web/ (index.html y manifest).
  final files = [
    for (final dir in ['lib', 'web'])
      ...Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => RegExp(r'\.(dart|html|json)$').hasMatch(f.path))
          .where((f) => !f.path.endsWith('legal_page.dart')),
  ];

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
