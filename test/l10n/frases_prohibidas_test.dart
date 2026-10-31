import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Idiomas, B4: las promesas que la app no hace en español
/// (test/experiencia/promesas_test.dart) tampoco aparecen en inglés ni en
/// portugués: ni en los .arb ni en los avisos del servidor
/// (functions/src/i18n.ts). Además, ninguna garantía en los tres idiomas.
const _porIdioma = <String, Map<String, String>>{
  'es': {
    'garantías': r'garantiz',
  },
  'en': {
    'garantías': r'guarantee',
    'chófer inmediato':
        r'(chauffeur|driver|assign\w*)[^\n]{0,60}(immediately|instantly|right away|in minutes|within minutes)',
    'en minutos': r'\b(with)?in\s+minutes\b',
    'cancelación gratuita':
        r'free\s+(of\s+charge\s+)?cancell?ation|cancel\s+for\s+free|at\s+no\s+cost',
    'espera gratuita':
        r'free\s+waiting|waiting\s+time\s+included|minutes\s+of\s+waiting',
    'seguimiento de vuelo':
        r'flight\s+(tracking|monitoring)|track(s|ing)?\s+your\s+flight',
    'atención 24/7': r'24\s*/\s*7|around\s+the\s+clock',
    'propina incluida': r'\btips?\b|gratuity',
    'verificación de antecedentes': r'background\s+check|trained\s+in',
    'te contactarán': r'will\s+(contact|call)\s+you',
    'cobertura mundial':
        r'worldwide|all\s+over\s+the\s+world|global\s+coverage',
    'puntualidad garantizada': r'punctuality',
    'gerente de cuenta': r'account\s+manager',
    'discreción': r'discretion',
    'cartel con tu nombre': r'name\s+sign|\bsign\s+with\s+your\s+name',
    'agua de cortesía': r'\bwater\b',
    'cargadores': r'charger',
    'chóferes multilingües': r'multilingual',
  },
  'pt': {
    'garantías': r'garanti',
    'chófer inmediato':
        r'(motorista|designa\w*)[^\n]{0,60}(imediatamente|na\s+hora|em\s+minutos|instantaneamente)',
    'en minutos': r'\bem\s+minutos\b',
    'cancelación gratuita':
        r'cancelamento\s+gr[aá]tis|cancelamento\s+gratuito|sem\s+custo',
    'espera gratuita': r'espera\s+(gr[aá]tis|gratuita)|minutos\s+de\s+espera',
    'seguimiento de vuelo':
        r'(acompanhamento|monitoramento)\s+(do\s+|de\s+)?voo|acompanhamos\s+seu\s+voo',
    'atención 24/7': r'24\s*/\s*7|24\s+horas',
    'propina incluida': r'gorjeta',
    'verificación de antecedentes': r'antecedentes|treinados\s+em',
    'te contactarán':
        r'(vamos|iremos)\s+(te\s+)?(ligar|contatar)|entraremos\s+em\s+contato',
    'cobertura mundial':
        r'mundo\s+todo|todo\s+o\s+mundo|cobertura\s+(mundial|global)',
    'puntualidad garantizada': r'pontualidade',
    'gerente de cuenta': r'gerente\s+de\s+conta',
    'discreción': r'discri[cç][aã]o',
    'cartel con tu nombre': r'placa\s+com\s+(o\s+)?(seu\s+)?nome',
    'agua de cortesía': r'\b[aá]gua\b',
    'cargadores': r'carregador',
    'chóferes multilingües': r'multil[ií]ngue',
  },
};

/// Textos de un idioma: los valores del .arb y los del catálogo del servidor.
List<String> _texts(String locale) {
  final arb = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
      as Map<String, dynamic>;
  final out = [
    for (final e in arb.entries)
      if (!e.key.startsWith('@')) '${e.key}: ${e.value}',
  ];
  final server = File('../functions/src/i18n.ts').existsSync()
      ? File('../functions/src/i18n.ts')
      : File('functions/src/i18n.ts');
  final line = RegExp("\\b$locale:\\s*'((?:\\\\.|[^'\\\\])*)'");
  for (final m in line.allMatches(server.readAsStringSync())) {
    out.add('i18n.ts: ${m.group(1)}');
  }
  return out;
}

void main() {
  for (final locale in _porIdioma.keys) {
    final texts = _texts(locale);
    test('$locale: hay textos que revisar', () {
      expect(texts, isNotEmpty);
    });
    for (final entry in _porIdioma[locale]!.entries) {
      test('$locale: nadie promete «${entry.key}»', () {
        final re = RegExp(entry.value, caseSensitive: false);
        expect(texts.where(re.hasMatch).toList(), isEmpty);
      });
    }
  }

  test('la comprobación detecta una promesa en inglés y en portugués', () {
    expect(
        RegExp(_porIdioma['en']!['chófer inmediato']!, caseSensitive: false)
            .hasMatch('Your chauffeur will be assigned immediately'),
        isTrue);
    expect(
        RegExp(_porIdioma['pt']!['garantías']!, caseSensitive: false)
            .hasMatch('Pontualidade garantida'),
        isTrue);
  });
}
