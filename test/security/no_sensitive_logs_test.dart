// Privacidad (T6): las pantallas y repositorios que manejan el código de
// recogida y las ubicaciones del SOS no escriben nada en la consola.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final files = [
    'lib/features/ride/data/repositories/trip_flow_repository_impl.dart',
    'lib/features/ride/presentation/widgets/pickup_code_card.dart',
    'lib/features/driver/presentation/widgets/pickup_code_entry.dart',
    ...Directory('lib/features/incidents')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.path),
    'lib/features/admin/presentation/widgets/admin_incidents_strip.dart',
  ];
  final logging = RegExp(r'\b(print|debugPrint|log)\(|developer\.log');

  for (final path in files) {
    test('$path no escribe en la consola', () {
      final lines = File(path).readAsLinesSync();
      final hits = [
        for (var i = 0; i < lines.length; i++)
          if (logging.hasMatch(lines[i]) && !lines[i].trim().startsWith('//'))
            '${i + 1}: ${lines[i].trim()}',
      ];
      expect(hits, isEmpty);
    });
  }

  test('la lista incluye los archivos del SOS', () {
    expect(files.where((f) => f.contains('incidents')).length,
        greaterThanOrEqualTo(5));
  });
}
