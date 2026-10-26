import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E5: los assets se empaquetan en la web y en las apps nativas. Antes:
/// 122 MB de vídeo y 48 imágenes que sumaban 50,7 MB.
void main() {
  final assets = Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => !f.path.endsWith('.md'))
      .toList();

  test('ningún asset pesa más de 600 KB', () {
    final big = [
      for (final f in assets)
        if (f.lengthSync() > 600 * 1024)
          '${f.path}: ${f.lengthSync() ~/ 1024} KB',
    ];
    expect(big, isEmpty);
  });

  test('los assets suman menos de 10 MB', () {
    final total = assets.fold<int>(0, (s, f) => s + f.lengthSync());
    expect(total, lessThan(10 * 1024 * 1024));
  });

  test('sin vídeos de fondo ni video_player', () {
    expect(assets.where((f) => f.path.endsWith('.mp4')), isEmpty);
    expect(File('pubspec.yaml').readAsStringSync(),
        isNot(contains('video_player')));
  });
}
