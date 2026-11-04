import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/brand_fonts.dart';

void main() {
  group('preloadBrandFonts', () {
    test('el límite por defecto es de 8 segundos', () {
      expect(kBrandFontsTimeout, const Duration(seconds: 8));
    });

    testWidgets('si las fuentes no llegan, el arranque sigue a los 8 s',
        (tester) async {
      final logs = <String>[];
      var done = false;
      unawaited(preloadBrandFonts(
        load: () => Completer<void>().future, // nunca termina
        log: logs.add,
      ).then((_) => done = true));

      await tester.pump(const Duration(milliseconds: 7999));
      expect(done, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(done, isTrue);
      expect(logs.single, contains('fuentes de marca no disponibles'));
    });

    test('un error al cargar no tumba el arranque', () async {
      final logs = <String>[];
      await preloadBrandFonts(
        load: () async => throw Exception('sin red'),
        log: logs.add,
      );
      expect(logs.single, contains('sin red'));
    });

    test('si llegan a tiempo, termina sin avisar', () async {
      final logs = <String>[];
      await preloadBrandFonts(load: () async {}, log: logs.add);
      expect(logs, isEmpty);
    });
  });
}
