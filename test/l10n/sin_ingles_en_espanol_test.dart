import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/failures.dart';

/// La versión en español no lleva textos en inglés («Server error»,
/// «Resource not found», «OUR SIGNATURE EXPERIENCE»…): se tradujeron a los
/// tres idiomas con el tono del glosario.
final _englishWord = RegExp(
  r'^(the|of|and|your|our|not|found|server|scroll|signature|experience|sign|'
  r'resource|authentication|validation|payment|permission|denied|cancelled|'
  r'canceled|please|we|you|with|for|are|is|sorry|failed|unknown|user|profile)$',
  caseSensitive: false,
);

/// Nombres propios y de producto que no se traducen.
const _allowed = {
  'Business',
  'Class',
  'First',
  'Van',
  'SUV',
  'SOS',
  'Luxelane'
};

List<String> englishInSpanish(Map<String, Map<String, dynamic>> fragments) {
  final hits = <String>[];
  for (final f in fragments.entries) {
    for (final e in f.value.entries) {
      final v = e.value as Map<String, dynamic>;
      final es = (v['es'] as String).replaceAll(RegExp(r'\{[^}]*\}'), ' ');
      final words = RegExp(r'\p{L}+', unicode: true)
          .allMatches(es)
          .map((m) => m.group(0)!)
          .where((w) => !_allowed.contains(w));
      final english = words.where(_englishWord.hasMatch).toList();
      if (english.isNotEmpty) {
        hits.add('${f.key}: ${e.key} «${v['es']}»');
      }
    }
  }
  return hits;
}

void main() {
  test('ningún texto en español está en inglés', () {
    final fragments = {
      for (final f in Directory('lib/l10n/src').listSync().whereType<File>())
        f.uri.pathSegments.last:
            jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
    }.map((k, v) => MapEntry(k, v.cast<String, dynamic>()));
    expect(
      englishInSpanish(
        fragments
            .map((k, v) => MapEntry(k, v.cast<String, Map<String, dynamic>>())),
      ),
      isEmpty,
    );
  });

  test('la comprobación detecta inglés en la versión en español', () {
    final hits = englishInSpanish({
      'x.json': {
        'a': {'es': 'Server error', 'en': 'Server error', 'pt': 'Erro'},
        'b': {'es': 'OUR SIGNATURE EXPERIENCE', 'en': 'OUR', 'pt': 'NOSSA'},
        'c': {
          'es': 'Business Class',
          'en': 'Business Class',
          'pt': 'Business Class'
        },
        'd': {
          'es': 'Desliza cuando estéis listos.',
          'en': 'Swipe',
          'pt': 'Deslize'
        },
      },
    });
    expect(hits.length, 2);
  });

  test('los fallos sin texto dicen qué pasó en español', () {
    expect(const ServerFailure().message,
        'No se pudo completar la operación. Inténtalo de nuevo.');
    expect(const NotFoundFailure().message, 'No encontramos lo que buscabas.');
    expect(const AuthFailure().message,
        'No se pudo iniciar sesión. Inténtalo de nuevo.');
  });
}
