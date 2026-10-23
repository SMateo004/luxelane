import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El diálogo de invitado no debe prometer avisos al invitado mientras no
/// existan: solo dice que el chófer asignado recibe sus datos.
void main() {
  final source =
      File(
        'lib/features/booking/presentation/pages/booking_screen.dart',
      ).readAsStringSync();

  test('no promete notificaciones al invitado', () {
    expect(source, isNot(contains('recibirá las notificaciones')));
    expect(source, isNot(contains('Los mantendremos informados')));
  });

  test('dice con quién se comparten los datos del invitado', () {
    expect(
      source,
      contains('con el chófer asignado para coordinar la recogida'),
    );
    expect(
      source,
      contains(
        'El chófer asignado usará este número para coordinar la recogida.',
      ),
    );
  });
}
