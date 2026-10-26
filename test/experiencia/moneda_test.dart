import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/utils/lux_format.dart';

/// E21: importes con formatos distintos («Bs96.00», «Bs 120», «Bs120.00»,
/// «Bs 50.00», «Bs 120,00»). Uno solo, en bolivianos como siempre.
void main() {
  test('Bs, espacio, miles con punto y céntimos con coma solo si los hay', () {
    expect(LuxFormat.money(120), 'Bs\u00A0120');
    expect(LuxFormat.money(96.5), 'Bs\u00A096,50');
    expect(LuxFormat.money(1234.05), 'Bs\u00A01.234,05');
    expect(LuxFormat.money(1000000), 'Bs\u00A01.000.000');
    expect(LuxFormat.money(0), 'Bs\u00A00');
    expect(LuxFormat.money(-15.2), '-Bs\u00A015,20');
    expect(LuxFormat.money(49.999), 'Bs\u00A050');
  });

  test('ningún importe se formatea a mano en lib/', () {
    final mano = RegExp(
        r'''Bs ?\$\{[^}]*toStringAsFixed|toStringAsFixed\([^)]*\)\} ?Bs''');
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (mano.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}
