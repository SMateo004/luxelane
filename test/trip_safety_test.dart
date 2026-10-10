import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luxelane/features/support/data/support_repository.dart';
import 'package:luxelane/features/support/domain/support_ticket.dart';
import 'package:luxelane/features/support/presentation/pages/new_ticket_page.dart';
import 'package:luxelane/features/support/presentation/widgets/trip_safety.dart';
import 'package:luxelane/l10n/l10n.dart';

class _NoopRepo implements SupportRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late List<Uri> launched;
  late String? openedHelp;
  late bool launchOk;

  Widget app(Locale locale) => MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        routerConfig: GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: TripSafetyButton(
                bookingId: 'b42',
                repository: _NoopRepo(),
                launcher: (u) async {
                  launched.add(u);
                  return launchOk;
                },
              ),
            ),
          ),
          GoRoute(
            path: '/ayuda',
            builder: (_, s) {
              openedHelp = s.uri.queryParameters['booking'];
              return const Scaffold();
            },
          ),
        ]),
      );

  setUp(() {
    launched = [];
    openedHelp = null;
    launchOk = true;
  });

  testWidgets('calls the police', (tester) async {
    await tester.pumpWidget(app(const Locale('es')));
    await tester.tap(find.text('Seguridad'));
    await tester.pumpAndSettle();
    expect(find.text('Seguridad en el viaje'), findsOneWidget);
    await tester.tap(find.text('Llamar al 110 (Policía)'));
    await tester.pumpAndSettle();
    expect(launched.single.toString(), 'tel:110');
  });

  testWidgets('says the number when the phone cannot open', (tester) async {
    launchOk = false;
    await tester.pumpWidget(app(const Locale('en')));
    await tester.tap(find.text('Safety'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Call 110 (Police)'));
    await tester.pumpAndSettle();
    expect(find.text("We couldn't open the phone. Dial 110."), findsOneWidget);
  });

  testWidgets('reports a safety problem about this trip', (tester) async {
    await tester.pumpWidget(app(const Locale('es')));
    await tester.tap(find.text('Seguridad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reportar un problema de seguridad'));
    await tester.pumpAndSettle();
    final page = tester.widget<NewTicketPage>(find.byType(NewTicketPage));
    expect(page.bookingId, 'b42');
    expect(page.initialCategory, TicketCategory.safety);
    expect(find.text('Problema de seguridad en mi viaje'), findsOneWidget);
  });

  testWidgets('opens help for this trip (pt)', (tester) async {
    await tester.pumpWidget(app(const Locale('pt')));
    await tester.tap(find.text('Segurança'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajuda com esta viagem'));
    await tester.pumpAndSettle();
    expect(openedHelp, 'b42');
  });
}
