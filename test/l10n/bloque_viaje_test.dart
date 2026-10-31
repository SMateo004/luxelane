import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/incidents/data/incident_repository_impl.dart';
import 'package:luxelane/features/incidents/presentation/help_contacts.dart';
import 'package:luxelane/features/incidents/presentation/widgets/sos_button.dart';
import 'package:luxelane/features/ride/data/repositories/trip_flow_repository_impl.dart';
import 'package:luxelane/features/ride/presentation/widgets/cancel_booking_dialog.dart';
import 'package:luxelane/features/ride/presentation/widgets/pickup_code_card.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TripRepo extends Mock implements TripFlowRepository {}

final _code = PickupCode(code: '4207', expiresAt: DateTime(2026, 10, 20, 19));

/// Bloque viaje (B1): código de recogida, cancelación, errores del viaje y
/// botón SOS con su diálogo en inglés y en portugués, sin restos del
/// español. «SOS» no se traduce.
void main() {
  Future<void> pump(
    WidgetTester t,
    Locale locale,
    Widget child, {
    bool screenReader = false,
  }) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              accessibleNavigation: screenReader,
            ),
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => L10n.use(const Locale('es')));

  final cases = {
    'en': (
      title: 'PICKUP CODE',
      semantics: 'Pickup code 4 2 0 7',
      guest: 'Share it with Carla Tercero',
      share: 'Share code',
      shareText: 'Your pickup code is 4207.',
      cancel: 'Cancel booking',
      reason: 'My plans changed',
      fee: '1,234.50 of what you paid',
      wrongCode: 'Incorrect code. You have 2 attempts left.',
      sosLabel: 'Help SOS',
      sosHint: 'Press and hold for two seconds',
      sosTitle: 'Notify our operations team?',
      sosSend: 'Notify operations team',
      sosCancel: 'Cancel',
      sms: 'SOS. Reserva #ABC123. Ubicación no disponible.',
      sosError: 'The help button works during the trip.',
    ),
    'pt': (
      title: 'CÓDIGO DE EMBARQUE',
      semantics: 'Código de embarque 4 2 0 7',
      guest: 'Compartilhe-o com Carla Tercero',
      share: 'Compartilhar código',
      shareText: 'Seu código de embarque é 4207.',
      cancel: 'Cancelar reserva',
      reason: 'Mudei de planos',
      fee: '1.234,50 do valor pago',
      wrongCode: 'Código incorreto. Restam 2 tentativas.',
      sosLabel: 'Ajuda SOS',
      sosHint: 'Mantenha pressionado por dois segundos',
      sosTitle: 'Avisar a central?',
      sosSend: 'Avisar a central',
      sosCancel: 'Cancelar',
      sms: 'SOS. Reserva #ABC123. Ubicación no disponible.',
      sosError: 'O botão de ajuda funciona durante a viagem.',
    ),
  };

  for (final MapEntry(key: code, value: c) in cases.entries) {
    final locale = Locale(code);
    group('viaje en $code', () {
      setUp(() => L10n.use(locale));

      testWidgets('código de recogida', (t) async {
        final repo = _TripRepo();
        when(() => repo.getPickupCode('b1'))
            .thenAnswer((_) async => Right(_code));
        String? shared;
        await pump(
          t,
          locale,
          PickupCodeCard(
            bookingId: 'b1',
            guestName: 'Carla Tercero',
            repository: repo,
            onShare: (s) async => shared = s,
          ),
        );
        expect(find.text(c.title), findsOneWidget);
        expect(find.text('CÓDIGO DE RECOGIDA'), findsNothing);
        expect(find.bySemanticsLabel(c.semantics), findsOneWidget);
        expect(find.textContaining(c.guest), findsOneWidget);
        expect(find.textContaining('Compártelo'), findsNothing);
        await t.tap(find.text(c.share));
        expect(shared, startsWith(c.shareText));
      });

      testWidgets('diálogo de cancelación con retención', (t) async {
        await pump(
          t,
          locale,
          const CancelBookingDialog(fee: 1234.5, refund: 100),
        );
        expect(find.text(c.cancel), findsOneWidget);
        expect(find.textContaining(c.fee), findsOneWidget);
        expect(find.text(c.reason), findsOneWidget);
        expect(find.text('Cambié de planes'), findsNothing);
        expect(find.textContaining('Según la política'), findsNothing);
        expect(
            find.text('Motivo'), code == 'pt' ? findsOneWidget : findsNothing);
      });

      testWidgets('botón SOS y su diálogo de confirmación', (t) async {
        var hits = 0;
        await pump(
          t,
          locale,
          Center(child: SosButton(onActivated: () => hits++)),
          screenReader: true,
        );
        // «SOS» se ve igual en todos los idiomas.
        expect(find.text('SOS'), findsOneWidget);
        final node = t.getSemantics(find.byKey(const ValueKey('sos-button')));
        expect(node.label, c.sosLabel);
        expect(node.hint, startsWith(c.sosHint));
        expect(node.label, isNot(contains('Ayuda SOS')));
        await t.tap(find.byKey(const ValueKey('sos-button')));
        await t.pumpAndSettle();
        expect(find.text(c.sosTitle), findsOneWidget);
        expect(find.text('¿Avisar a central?'), findsNothing);
        expect(find.text(c.sosCancel), findsOneWidget);
        await t.tap(find.text(c.sosSend));
        await t.pumpAndSettle();
        expect(hits, 1);
      });

      test('SMS (a central, siempre en español) y errores del SOS', () {
        expect(incidentSmsBody('ABC123'), c.sms);
        final f = incidentFailureFor('failed-precondition', {
          'reason': 'outside_window',
        }) as IncidentFailure;
        expect(f.message, c.sosError);
      });

      test('errores del viaje', () {
        final f = tripFailureFor('failed-precondition', {
          'reason': 'wrong_code',
          'attemptsLeft': 2,
        }) as TripFailure;
        expect(f.message, c.wrongCode);
        final net = tripFailureFor('unavailable', null) as TripFailure;
        expect(net.message, isNot(contains('Sin conexión')));
      });
    });
  }

  test('en español no cambia nada', () {
    L10n.use(const Locale('es'));
    expect(
        pickupShareText('4207'), startsWith('Tu código de recogida es 4207'));
  });
}
