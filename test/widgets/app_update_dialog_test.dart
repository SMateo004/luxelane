import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/widgets/app_update_dialog.dart';

void main() {
  const failure = AppUpdateRequiredFailure(
    androidStoreUrl: 'https://play.example/luxelane',
  );

  test('elige el enlace de la tienda de la plataforma', () {
    expect(
      storeUrlFor(failure, TargetPlatform.android, web: false),
      'https://play.example/luxelane',
    );
    expect(storeUrlFor(failure, TargetPlatform.iOS, web: false), isNull);
    expect(storeUrlFor(failure, TargetPlatform.android, web: true), isNull);
  });

  testWidgets('pide actualizar con un mensaje sobrio', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppUpdateDialog(failure: failure, web: false)),
      ),
    );
    expect(find.text('Actualiza la app para reservar'), findsOneWidget);
    expect(
      find.textContaining('Actualízala para seguir reservando'),
      findsOneWidget,
    );
  });

  testWidgets('en la web pide recargar la página', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppUpdateDialog(failure: failure, web: true)),
      ),
    );
    expect(find.textContaining('Recarga la página'), findsOneWidget);
    expect(find.text('Entendido'), findsOneWidget);
  });
}
