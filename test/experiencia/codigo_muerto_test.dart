import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F4: código muerto borrado (DriveCanvasAnim, que además lanzaba al
/// pintarse, y /ride-type, sin enlaces internos). Que no vuelva.
void main() {
  test('no quedan ni los archivos ni referencias en lib/', () {
    expect(
      File('lib/features/home/presentation/pages/drive_canvas_painter.dart')
          .existsSync(),
      isFalse,
    );
    expect(
      File('lib/features/booking/presentation/pages/ride_type_page.dart')
          .existsSync(),
      isFalse,
    );
    final re = RegExp('DriveCanvasAnim|RideTypePage|ride-type');
    final hits = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            re.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(hits, isEmpty);
  });
}
