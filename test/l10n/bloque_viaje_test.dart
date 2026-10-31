import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/ride/data/repositories/trip_flow_repository_impl.dart';
import 'package:luxelane/features/ride/presentation/widgets/cancel_booking_dialog.dart';
import 'package:luxelane/features/ride/presentation/widgets/pickup_code_card.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TripRepo extends Mock implements TripFlowRepository {}

final _code = PickupCode(code: '4207', expiresAt: DateTime(2026, 10, 20, 19));

/// Bloque viaje (B1): código de recogida, cancelación y errores del viaje
/// en inglés y en portugués, sin restos del español.
void main() {
  Future<void> pump(WidgetTester t, Locale locale, Widget child) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: Scaffold(body: SingleChildScrollView(child: child)),
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
