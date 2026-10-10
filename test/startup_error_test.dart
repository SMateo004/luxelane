import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/widgets/startup_error_app.dart';

void main() {
  testWidgets('explains that the app could not start, in the device language', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const StartupErrorApp());
    await tester.pumpAndSettle();
    expect(find.text('No pudimos iniciar Luxelane'), findsOneWidget);
  });
}
