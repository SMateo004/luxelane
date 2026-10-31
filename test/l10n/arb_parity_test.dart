import 'package:flutter_test/flutter_test.dart';

import 'arb_check.dart';

/// Idiomas, A7: los tres .arb tienen las mismas claves y los mismos
/// marcadores que la plantilla en español.
void main() {
  test('es, en y pt tienen las mismas claves y marcadores', () {
    expect(arbProblems(readArbs()), isEmpty);
  });

  test('detecta una clave que falta en un idioma', () {
    final arbs = {
      'es': <String, dynamic>{'a': 'Hola', 'b': 'Adiós'},
      'en': <String, dynamic>{'a': 'Hello', 'b': 'Goodbye'},
      'pt': <String, dynamic>{'a': 'Olá'},
    };
    expect(arbProblems(arbs), ['pt: falta b']);
  });

  test('detecta un marcador distinto entre idiomas', () {
    final arbs = {
      'es': <String, dynamic>{
        'a': 'Hola, {name}',
        '@a': {
          'placeholders': {'name': <String, dynamic>{}},
        },
      },
      'en': <String, dynamic>{'a': 'Hello, {nombre}'},
      'pt': <String, dynamic>{'a': 'Olá'},
    };
    expect(arbProblems(arbs), [
      'en: a tiene marcadores {nombre} y la plantilla {name}',
      'pt: a tiene marcadores {} y la plantilla {name}',
    ]);
  });

  test('detecta una clave que sobra y una traducción vacía', () {
    final arbs = {
      'es': <String, dynamic>{'a': 'Hola'},
      'en': <String, dynamic>{'a': ' ', 'x': 'Extra'},
      'pt': <String, dynamic>{'a': 'Olá'},
    };
    expect(arbProblems(arbs), ['en: a vacío', 'en: sobra x']);
  });
}
