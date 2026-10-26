import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pagos B4: lo que lee el pasajero al reservar, pagar, cancelar y en sus
/// viajes no promete devoluciones inmediatas ni plazos que no estén en
/// config/ops, no habla de monedero, saldo a favor ni crédito, y no promete
/// liberar retenciones de tarjeta (el flujo anterior).
void main() {
  test('textos del pasajero sin promesas ni monedero', () {
    final dirs = [
      'lib/features/payments',
      'lib/features/booking',
      'lib/features/ride',
      'lib/features/trips',
    ];
    final forbidden = RegExp(
      r'monedero|billetera|wallet|saldo a favor|cr[eé]dito|inmediat|'
      r'al instante|d[ií]as h[aá]biles|horas h[aá]biles|'
      r'en \d+ (d[ií]as|horas|minutos)|se liberar[aá]|reembolso',
      caseSensitive: false,
    );
    // Solo el texto entre comillas, sin comentarios ni nombres de iconos.
    final literal = RegExp(r"'([^'\\]|\\.)*'");
    final hits = <String>[];
    for (final d in dirs) {
      for (final f in Directory(d)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (line.startsWith('//') || line.startsWith('import ')) continue;
          for (final m in literal.allMatches(line)) {
            if (forbidden.hasMatch(m.group(0)!)) {
              hits.add('${f.path}:${i + 1} ${m.group(0)}');
            }
          }
        }
      }
    }
    expect(hits, isEmpty);
  });
}
