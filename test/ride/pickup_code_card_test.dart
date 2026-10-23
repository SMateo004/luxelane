import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/ride/data/repositories/trip_flow_repository_impl.dart';
import 'package:luxelane/features/ride/presentation/widgets/pickup_code_card.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Mock implements TripFlowRepository {}

final _code = PickupCode(code: '4207', expiresAt: DateTime(2026, 10, 20, 19));

Future<void> _pump(
  WidgetTester tester,
  Widget card, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: SingleChildScrollView(child: card)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _Repo repo;
  setUp(() {
    repo = _Repo();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('muestra los 4 dígitos con su etiqueta accesible', (
    tester,
  ) async {
    when(() => repo.getPickupCode('b1')).thenAnswer((_) async => Right(_code));
    await _pump(tester, PickupCodeCard(bookingId: 'b1', repository: repo));
    for (final d in ['4', '2', '0', '7']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Código de recogida 4 2 0 7'), findsOneWidget);
    // Sin invitado no se ofrece compartir.
    expect(find.text('Compartir código'), findsNothing);
  });

  testWidgets('reserva con invitado: «Compartir código» abre el menú', (
    tester,
  ) async {
    when(() => repo.getPickupCode('b1')).thenAnswer((_) async => Right(_code));
    String? shared;
    await _pump(
      tester,
      PickupCodeCard(
        bookingId: 'b1',
        guestName: 'Carla Tercero',
        repository: repo,
        onShare: (t) async => shared = t,
      ),
    );
    expect(find.textContaining('Compártelo con Carla Tercero'), findsOneWidget);
    await tester.tap(find.text('Compartir código'));
    expect(shared, pickupShareText('4207'));
    expect(shared, contains('4207'));
  });

  testWidgets('sin red: aviso y «Reintentar» vuelve a pedirlo', (tester) async {
    var calls = 0;
    when(() => repo.getPickupCode('b1')).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Left(TripFailure(TripIssue.network, 'Sin conexión.'))
          : Right(_code);
    });
    await _pump(tester, PickupCodeCard(bookingId: 'b1', repository: repo));
    expect(find.text('Sin conexión.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
    expect(calls, 2);
  });

  for (final f in [
    tripFailureFor('failed-precondition', {'reason': 'code_expired'}),
    tripFailureFor('failed-precondition', {'reason': 'pickup_locked'}),
  ]) {
    testWidgets('${(f as TripFailure).issue}: mensaje claro y sin reintento', (
      tester,
    ) async {
      when(() => repo.getPickupCode('b1')).thenAnswer((_) async => Left(f));
      await _pump(tester, PickupCodeCard(bookingId: 'b1', repository: repo));
      expect(find.text(f.message), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      expect(find.text('4'), findsNothing);
    });
  }

  testWidgets('con «reducir movimiento» aparece sin animar', (tester) async {
    when(() => repo.getPickupCode('b1')).thenAnswer((_) async => Right(_code));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: PickupCodeCard(bookingId: 'b1', repository: repo),
          ),
        ),
      ),
    );
    // Un solo fotograma tras la respuesta: ya visible y opaco.
    await tester.pump();
    await tester.pump();
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('4'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1);
  });

  testWidgets('el código no se guarda en el dispositivo', (tester) async {
    when(() => repo.getPickupCode('b1')).thenAnswer((_) async => Right(_code));
    await _pump(tester, PickupCodeCard(bookingId: 'b1', repository: repo));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  group('tripFailureFor', () {
    test('motivos del servidor', () {
      TripIssue issue(String r, [Map<String, dynamic> extra = const {}]) =>
          (tripFailureFor('failed-precondition', {'reason': r, ...extra})
                  as TripFailure)
              .issue;
      expect(issue('not_at_pickup'), TripIssue.notAtPickup);
      expect(issue('code_expired'), TripIssue.expired);
      expect(issue('pickup_locked'), TripIssue.locked);
      expect(issue('pickup_unavailable'), TripIssue.unavailable);
      expect(issue('not_your_booking'), TripIssue.notAllowed);
      expect(issue('invalid_transition'), TripIssue.invalidTransition);
    });

    test('código incorrecto con intentos restantes', () {
      final f = tripFailureFor('failed-precondition', {
        'reason': 'wrong_code',
        'attemptsLeft': 1,
      }) as TripFailure;
      expect(f.issue, TripIssue.wrongCode);
      expect(f.attemptsLeft, 1);
      expect(f.message, 'Código incorrecto. Te queda 1 intento.');
    });

    test('sin red', () {
      expect(
        (tripFailureFor('unavailable', null) as TripFailure).issue,
        TripIssue.network,
      );
    });
  });
}
