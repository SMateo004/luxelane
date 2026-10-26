import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F5: los lugares y rutas ficticios del entorno de capturas
/// (tools/experiencia/fake_maps_service.dart) no pueden llegar a la app real.
/// Ningún archivo de lib/ los importa ni los nombra, y las entradas de las
/// builds (lib/main*.dart) tampoco.
void main() {
  final banned = RegExp(
    r'fake_maps_service|main_capturas|FakeMapsService|kLugaresFicticios|'
    r'fakeRoute|tools/experiencia',
  );

  test('ningún archivo de lib/ importa ni nombra el MapsService ficticio', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (banned.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });

  test('las entradas de las builds son de lib/, no del entorno de capturas',
      () {
    final entries = Directory('lib')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'main\w*\.dart$').hasMatch(f.path))
        .toList();
    expect(entries, isNotEmpty);
    for (final f in entries) {
      expect(banned.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test('el ficticio marca cada lugar como ficticio', () {
    final src =
        File('tools/experiencia/fake_maps_service.dart').readAsStringSync();
    final names = RegExp(r"name: '([^']+)'").allMatches(src).toList();
    expect(names, isNotEmpty);
    for (final m in names) {
      expect(m.group(1), contains(r'$kFicticio'));
    }
  });
}
