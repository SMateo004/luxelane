import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El diálogo de invitado no debe prometer avisos al invitado mientras no
/// existan: solo dice que el chófer asignado recibe sus datos. Los textos
/// están en lib/l10n/src/booking.json (es, en y pt); la pantalla los usa
/// por su clave.
void main() {
  final source = File(
    'lib/features/booking/presentation/pages/booking_screen.dart',
  ).readAsStringSync();
  final texts = jsonDecode(
    File('lib/l10n/src/booking.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  String es(String key) => (texts[key] as Map<String, dynamic>)['es'] as String;
  final all = [
    source,
    for (final v in texts.values)
      for (final l in ['es', 'en', 'pt']) (v as Map<String, dynamic>)[l],
  ].join('\n');

  test('no promete notificaciones al invitado', () {
    expect(all, isNot(contains('recibirá las notificaciones')));
    expect(all, isNot(contains('Los mantendremos informados')));
    expect(all.toLowerCase(), isNot(contains('keep them informed')));
    expect(all.toLowerCase(), isNot(contains('receberá as notificações')));
  });

  test('dice con quién se comparten los datos del invitado', () {
    expect(source, contains('context.l10n.bookingGuestIntro'));
    expect(source, contains('context.l10n.bookingGuestPhoneNote'));
    expect(
      es('bookingGuestIntro'),
      contains('con el chófer asignado para coordinar la recogida'),
    );
    expect(
      es('bookingGuestPhoneNote'),
      'El chófer asignado usará este número para coordinar la recogida.',
    );
  });
}
