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
    // Preferencias (B4): un deseo, no un compromiso.
    'cumplir preferencias':
        r'(lo|las|los)\s+cumpliremos|nos\s+aseguramos|te\s+aseguramos|respetar[aá]\s+(siempre\s+)?tus',
    // promesas_test.dart no las ve: «\b» tras «á» no es límite en Dart.
    'te contactarán': r'te\s+(contactamos|contactaremos|llamar[aá]|llamaremos)',
    // Registro de chóferes (B4): la foto en vivo no es una prueba de vida
    // ni una comparación de rostro; nada de identidad «verificada».
    'verificación de identidad':
        r'verificaci[oó]n\s+de\s+(la\s+)?identidad|identidad\s+verificada|verificamos\s+(tu\s+)?identidad',
    'biometría':
        r'biom[eé]tric|prueba\s+de\s+vida|reconocimiento\s+facial|comparaci[oó]n\s+(de\s+)?(rostro|cara)',
    // Vuelos (Prompt 15, B6): la hora sale de un dato que puede faltar o
    // estar viejo; nada de llegar «a tiempo» ni de esperar sin límite.
    'llegaremos a tiempo':
        r'(llegaremos|llegar|recogerte|buscarte)\s+a\s+tiempo|nunca\s+llegamos\s+tarde|sin\s+retrasos|puntual(es|idad)?\b',
    'vuelo en tiempo real':
        r'vuelo[^\n]{0,40}tiempo\s+real|tiempo\s+real[^\n]{0,40}vuelo|monitoreamos\s+tu\s+vuelo|vigilamos\s+tu\s+vuelo|rastreamos\s+tu\s+vuelo',
    'espera sin límite':
        r'esperar[aá]\s+(lo\s+que|el\s+tiempo\s+que)|espera\s+ilimitada|sin\s+l[ií]mite\s+de\s+espera|te\s+esperar[aá]\s+siempre',
    'ajuste automático':
        r'(ajustamos|adaptamos|actualizamos)\s+(autom[aá]ticamente\s+)?(la\s+hora|tu\s+recogida)|se\s+ajusta\s+(sola|autom[aá]ticamente)',
    'el chófer estará a la hora':
        r'tu\s+ch[oó]fer\s+(te\s+esperar[aá]|estar[aá])\s+en\s+el\s+punto',
    // Avisos y viaje compartido (Prompt 18, C6): ni seguridad prometida ni
    // hora de llegada prometida. «Por seguridad…» o «Seguro del vehículo»
    // no son promesas y siguen permitidos.
    'seguridad prometida':
        r'(viaje|trayecto|llegada|traslado)\s+(100\s*%\s*)?segur[oa]|est(á|ás|ará|arás|amos)\s+(totalmente\s+)?segur[oa]|100\s*%\s*segur|totalmente\s+segur|siempre\s+segur',
    'llegará a las':
        r'llegar[áa]\s+a\s+las|te\s+recoger[áa]\s+a\s+las|estar[áa]\s+(all[íi]|ah[íi])\s+a\s+las',
  },
  'en': {
    'garantías': r'guarantee',
    'cumplir preferencias':
        r'we\s+will\s+(honou?r|fulfil|respect)|we\s+(make|will\s+make)\s+sure|we\s+ensure',
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
    'te contactarán': r'will\s+(contact|call)\s+you|get\s+back\s+to\s+you',
    'cobertura mundial':
        r'worldwide|all\s+over\s+the\s+world|global\s+coverage',
    'puntualidad garantizada': r'punctuality',
    'gerente de cuenta': r'account\s+manager',
    'discreción': r'discretion',
    'cartel con tu nombre': r'name\s+sign|\bsign\s+with\s+your\s+name',
    'agua de cortesía': r'\bwater\b',
    'cargadores': r'charger',
    'chóferes multilingües': r'multilingual',
    'verificación de identidad':
        r'identity\s+verification|verif\w*\s+(your\s+)?identity|identity\s+(is\s+)?verified',
    'biometría':
        r'biometric|liveness|proof\s+of\s+life|facial\s+recognition|face\s+(match|comparison)',
    'llegaremos a tiempo':
        r"\bon[\s-]+time\b|we('ll|\s+will)\s+be\s+there|never\s+late|no\s+delays|punctual",
    'vuelo en tiempo real':
        r'flight[^\n]{0,40}real[\s-]time|real[\s-]time[^\n]{0,40}flight|live\s+flight\s+tracking|we\s+(monitor|track|watch)\s+your\s+flight',
    'espera sin límite':
        r'wait\s+as\s+long\s+as|unlimited\s+wait|no\s+waiting\s+limit|will\s+always\s+wait',
    'ajuste automático':
        r'(adjust|update)s?\s+(your\s+pickup|the\s+time)\s+automatically|automatically\s+(adjust|update)',
    'el chófer estará a la hora':
        r'your\s+chauffeur\s+will\s+(wait\s+for\s+you|be)\s+at\s+the\s+pickup',
    'seguridad prometida':
        r"\b(safe|secure)\s+(trip|ride|journey|transfer)|(you|we)('ll|\s+will|\s+are|'re)\s+(be\s+)?(completely\s+)?safe|100\s*%\s*safe|completely\s+safe|always\s+safe",
    'llegará a las': r'will\s+(arrive|pick\s+you\s+up|be\s+there)\s+at',
  },
  'pt': {
    'garantías': r'garanti',
    'cumplir preferencias':
        r'vamos\s+cumprir|cumpriremos|n[oó]s\s+asseguramos|asseguramos\s+que',
    'chófer inmediato':
        r'(motorista|designa\w*)[^\n]{0,60}(imediatamente|na\s+hora|em\s+minutos|instantaneamente)',
    'en minutos': r'\bem\s+minutos\b',
    'cancelación gratuita':
        r'cancelamento\s+gr[aá]tis|cancelamento\s+gratuito|sem\s+custo',
    'espera gratuita': r'espera\s+(gr[aá]tis|gratuita)|minutos\s+de\s+espera',
    'seguimiento de vuelo':
        r'(acompanhamento|monitoramento)\s+(do\s+|de\s+)?voo|acompanhamos\s+seu\s+voo',
    'atención 24/7': r'24\s*/\s*7|24\s+horas\s+por\s+dia|dia\s+e\s+noite',
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
    'verificación de identidad':
        r'verifica[cç][aã]o\s+de\s+identidade|identidade\s+verificada|verificamos\s+(a\s+sua\s+|sua\s+)?identidade',
    'biometría':
        r'biom[eé]tric|prova\s+de\s+vida|reconhecimento\s+facial|compara[cç][aã]o\s+(de\s+)?rosto',
    'llegaremos a tiempo':
        r'(chegaremos|chegar|busc\w*\s+voc[eê])\s+a\s+tempo|nunca\s+atras|sem\s+atrasos|pontua(l|is)\b',
    'vuelo en tiempo real':
        r'voo[^\n]{0,40}tempo\s+real|tempo\s+real[^\n]{0,40}voo|monitoramos\s+seu\s+voo|acompanhamos\s+seu\s+voo\s+ao\s+vivo|rastreamos\s+seu\s+voo',
    'espera sin límite':
        r'esperar[aá]\s+o\s+tempo\s+que|espera\s+ilimitada|sem\s+limite\s+de\s+espera|sempre\s+esperar[aá]',
    'ajuste automático':
        r'(ajustamos|atualizamos)\s+(automaticamente\s+)?(o\s+hor[aá]rio|sua\s+busca)|ajusta\s+automaticamente',
    'el chófer estará a la hora':
        r'seu\s+motorista\s+(vai\s+esperar|estar[aá])\s+(voc[eê]\s+)?no\s+ponto',
    'seguridad prometida':
        r'viagem\s+(100\s*%\s*)?segura|(est[áa]|estar[áa]|estamos)\s+(totalmente\s+)?segur[oa]|100\s*%\s*segur|totalmente\s+segur|sempre\s+segur',
    'llegará a las':
        r'chegar[áa]\s+[àa]s|vai\s+(te\s+)?buscar\s+[àa]s|vai\s+buscar\s+voc[êe]\s+[àa]s|estar[áa]\s+l[áa]\s+[àa]s',
  },
};

/// Compromisos que ya estaban en español y que decide el responsable (no se
/// cambian al traducir): se excluyen aquí, con su motivo, y un test fija la
/// lista para que no crezca sin querer.
const _pendientesDeDecision = <String, String>{
  'incidentCancelRequestedBody':
      'tras cancelar un SOS, «Central te llamará»: depende de quién atiende (D23)',
  'businessLead': '«te contactamos en menos de un día hábil» a empresas',
};

/// Clave del nombre del documento de antecedentes (registro de chóferes):
/// la única que puede decir «antecedentes».
const _antecedentesKey = 'regDocTypeCriminalRecord';

/// Textos de un idioma: los valores del .arb y los del catálogo del servidor.
List<String> _texts(String locale) {
  final arb = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
      as Map<String, dynamic>;
  final out = [
    for (final e in arb.entries)
      if (!e.key.startsWith('@') && !_pendientesDeDecision.containsKey(e.key))
        '${e.key}: ${e.value}',
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
        // Única excepción, por clave: el nombre del documento del registro
        // de chóferes («Certidão de antecedentes criminais»).
        final allowed = entry.key == 'verificación de antecedentes'
            ? '$_antecedentesKey: '
            : null;
        expect(
            texts
                .where((t) => allowed == null || !t.startsWith(allowed))
                .where(re.hasMatch)
                .toList(),
            isEmpty);
      });
    }
  }

  test('compromisos pendientes de decisión: solo estos', () {
    expect(_pendientesDeDecision.keys.toList()..sort(),
        ['businessLead', 'incidentCancelRequestedBody']);
  });

  test('preferencias: la frase sobria, igual en los tres idiomas', () {
    for (final (l, want) in [
      ('es', 'Tu chófer verá estas preferencias.'),
      ('en', 'Your chauffeur will see these preferences.'),
      ('pt', 'Seu motorista verá estas preferências.'),
    ]) {
      final arb = jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync())
          as Map<String, dynamic>;
      expect(arb['prefsDriverWillSee'], want);
    }
    expect(
      RegExp(_porIdioma['es']!['cumplir preferencias']!, caseSensitive: false)
          .hasMatch('Tus preferencias: lo cumpliremos'),
      isTrue,
    );
  });

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

  test(
      'vuelos: la comprobación detecta las promesas de hora en los tres idiomas',
      () {
    for (final (l, k, bad) in [
      ('es', 'llegaremos a tiempo', 'Tranquilo, llegaremos a tiempo'),
      ('es', 'garantías', 'Garantizamos tu recogida'),
      ('es', 'vuelo en tiempo real', 'Vemos tu vuelo en tiempo real'),
      ('es', 'llegaremos a tiempo', 'Indica tu vuelo para recogerte a tiempo'),
      ('es', 'espera sin límite', 'Tu chófer esperará lo que haga falta'),
      ('en', 'llegaremos a tiempo', 'Your chauffeur will be on time'),
      ('en', 'garantías', 'On-time guarantee'),
      ('en', 'vuelo en tiempo real', 'Real-time flight tracking'),
      ('pt', 'llegaremos a tiempo', 'Chegaremos a tempo'),
      ('pt', 'garantías', 'Garantimos sua busca'),
      ('pt', 'espera sin límite', 'O motorista esperará o tempo que for'),
    ]) {
      expect(RegExp(_porIdioma[l]![k]!, caseSensitive: false).hasMatch(bad),
          isTrue,
          reason: '$l/$k: $bad');
    }
  });

  test(
      'avisos y viaje compartido: detecta seguridad y hora prometidas en los tres idiomas',
      () {
    for (final (l, k, bad) in [
      ('es', 'seguridad prometida', 'Disfruta de un viaje seguro'),
      ('es', 'seguridad prometida', 'Con nosotros estarás totalmente seguro'),
      ('es', 'garantías', 'Llegada garantizada'),
      ('es', 'llegará a las', 'Tu chófer llegará a las 14:00'),
      ('es', 'llegará a las', 'Te recogerá a las 9:30'),
      ('en', 'seguridad prometida', 'Enjoy a safe ride'),
      ('en', 'llegará a las', 'Your chauffeur will arrive at 2:00 PM'),
      ('pt', 'seguridad prometida', 'Uma viagem segura'),
      ('pt', 'llegará a las', 'O motorista chegará às 14:00'),
    ]) {
      expect(RegExp(_porIdioma[l]![k]!, caseSensitive: false).hasMatch(bad),
          isTrue,
          reason: '$l/$k: $bad');
    }
    // Lo que no es una promesa sigue permitido.
    for (final ok in [
      'Por seguridad, escribe tu contraseña',
      'Seguro del vehículo',
      'Hora de recogida prevista: 14:00'
    ]) {
      expect(
          RegExp(_porIdioma['es']!['seguridad prometida']!,
                  caseSensitive: false)
              .hasMatch(ok),
          isFalse,
          reason: ok);
      expect(
          RegExp(_porIdioma['es']!['llegará a las']!, caseSensitive: false)
              .hasMatch(ok),
          isFalse,
          reason: ok);
    }
  });

  test('pt: «antecedentes» sigue vetado fuera de esa clave', () {
    final re = RegExp(_porIdioma['pt']!['verificación de antecedentes']!,
        caseSensitive: false);
    expect(re.hasMatch('motoristas com antecedentes verificados'), isTrue);
    final otros = _texts('pt')
        .where((t) => !t.startsWith('$_antecedentesKey: '))
        .where(re.hasMatch)
        .toList();
    expect(otros, isEmpty);
    expect(_texts('pt'),
        contains('$_antecedentesKey: Certidão de antecedentes criminais'));
  });
}
