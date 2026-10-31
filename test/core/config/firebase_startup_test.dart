import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/firebase_env.dart';
import 'package:luxelane/core/config/firebase_startup.dart';

void main() {
  final logs = <String>[];
  setUp(logs.clear);

  Future<void> failsWith(Object error) async => throw error;

  group('startFirebase en release', () {
    test('cualquier fallo detiene el arranque', () async {
      for (final error in [
        const StagingNotConfiguredError(),
        StateError('sin red'),
      ]) {
        final r = await startFirebase(
          () => failsWith(error),
          release: true,
          log: logs.add,
        );
        expect(r, isA<FirebaseFatal>());
      }
    });

    test('sin fallo, la app arranca normal', () async {
      final r = await startFirebase(() async {}, release: true, log: logs.add);
      expect(r, isA<FirebaseReady>());
      expect(logs, isEmpty);
    });

    testWidgets('muestra la pantalla de error en lugar de la app', (
      tester,
    ) async {
      final r = await startFirebase(
        () => failsWith(StateError('x')),
        release: true,
        log: logs.add,
      );
      // Sin Firebase no hay idioma del perfil: usa el del teléfono.
      tester.platformDispatcher.localesTestValue = const [Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(appForStartup(r, const Text('APP')));
      expect(find.text('APP'), findsNothing);
      expect(find.text('No pudimos iniciar la app'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [Locale('en')];
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(appForStartup(r, const Text('APP')));
      expect(find.text('We could not start the app'), findsOneWidget);
    });
  });

  // Los tests corren en debug: `release` toma kReleaseMode == false.
  group('startFirebase en debug con staging sin configurar', () {
    test('avisa en consola qué falta configurar', () async {
      final r = await startFirebase(
        () => failsWith(const StagingNotConfiguredError()),
        log: logs.add,
      );
      expect(r, isA<FirebaseDegraded>());
      expect(logs.single, contains('Falta configurar el proyecto de staging'));
    });

    testWidgets('muestra el aviso en pantalla sobre la app', (tester) async {
      final r = await startFirebase(
        () => failsWith(const StagingNotConfiguredError()),
        log: logs.add,
      );
      await tester.pumpWidget(
        appForStartup(
          r,
          const Directionality(
            textDirection: TextDirection.ltr,
            child: Text('APP'),
          ),
        ),
      );
      expect(find.text('APP'), findsOneWidget);
      expect(
        find.textContaining('Falta configurar el proyecto de staging'),
        findsOneWidget,
      );
    });
  });
}
