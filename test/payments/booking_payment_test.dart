import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/booking_payment.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/payments/data/repositories/booking_payment_repository_impl.dart';
import 'package:luxelane/features/payments/domain/card_payment_presenter.dart';
import 'package:luxelane/features/payments/presentation/bloc/booking_payment_cubit.dart';
import 'package:luxelane/features/payments/presentation/pages/booking_payment_screen.dart';

/// Datos de cobro y referencia de PRUEBA, ficticios.
const _instructions = ManualInstructions(
  holderName: 'Titular ficticio',
  bankName: 'Banco ficticio',
  accountNumber: '000-ficticia',
  note: 'Nota ficticia',
);

class _FakeRepo implements BookingPaymentRepository {
  final ctrl = StreamController<BookingPayment?>.broadcast();
  final started = <String>[];
  final sent = <String?>[];
  Failure? startFailure;
  Failure? sentFailure;

  @override
  Stream<BookingPayment?> watch(String bookingId) => ctrl.stream;

  @override
  Future<Either<Failure, PaymentStart>> start(
    String bookingId,
    String method,
  ) async {
    started.add(method);
    if (startFailure != null) return Left(startFailure!);
    return Right(
      PaymentStart(
        method: method,
        amountDue: 8650,
        paymentRef: 'LX7K2M',
        instructions: method == PayMethod.manualQr ? _instructions : null,
        clientSecret: method == PayMethod.card ? 'secreto-ficticio' : null,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> markSent(
    String bookingId, {
    String? operationNumber,
  }) async {
    sent.add(operationNumber);
    if (sentFailure != null) return Left(sentFailure!);
    return const Right(null);
  }
}

class _Card implements CardPaymentPresenter {
  _Card(this.outcome);
  CardSheetOutcome outcome;
  int calls = 0;

  @override
  Future<CardSheetResult> present(String clientSecret) async {
    calls++;
    return CardSheetResult(outcome);
  }
}

BookingPayment _payment({
  String status = 'awaiting_payment',
  List<String> methods = const ['manual_qr'],
  Map<String, dynamic> extra = const {},
}) =>
    BookingPayment.fromJson('b1', {
      'paymentStatus': status,
      'amountDue': 8650,
      'amountPaid': 0,
      'paymentRef': 'LX7K2M',
      'methodsOffered': methods,
      ...extra,
    });

void main() {
  late _FakeRepo repo;

  BookingPaymentCubit cubit({bool web = false, CardPaymentPresenter? card}) =>
      BookingPaymentCubit(
        repository: repo,
        bookingId: 'b1',
        isWeb: web,
        cardPresenter: card,
      );

  setUp(() => repo = _FakeRepo());
  tearDown(() => repo.ctrl.close());

  group('BookingPaymentCubit', () {
    test('con solo el pago manual, pide sus datos sin preguntar', () async {
      final c = cubit();
      repo.ctrl.add(_payment());
      await pumpEventQueue();
      expect(repo.started, [PayMethod.manualQr]);
      expect(c.state.start?.instructions?.holderName, 'Titular ficticio');
      await c.close();
    });

    test('E38: en la web la tarjeta no se ofrece aunque esté activa', () {
      final p = _payment(methods: ['manual_qr', 'card']);
      expect(
          cubit(web: true, card: _Card(CardSheetOutcome.completed))
              .usableMethods(p),
          ['manual_qr']);
      expect(cubit(card: _Card(CardSheetOutcome.completed)).usableMethods(p),
          ['manual_qr', 'card']);
      // Sin formulario de proveedor registrado, tampoco en la app.
      expect(cubit().usableMethods(p), ['manual_qr']);
    });

    test('con dos métodos espera a que elija', () async {
      final c = cubit(card: _Card(CardSheetOutcome.completed));
      repo.ctrl.add(_payment(methods: ['manual_qr', 'card']));
      await pumpEventQueue();
      expect(repo.started, isEmpty);
      await c.close();
    });

    test('«Ya pagué» manda el número de operación', () async {
      final c = cubit();
      repo.ctrl.add(_payment());
      await pumpEventQueue();
      await c.reportPaid(operationNumber: 'OP 123');
      expect(repo.sent, ['OP 123']);
      expect(c.state.error, isNull);
      await c.close();
    });

    test('tarjeta: fallo con reintento; el reintento vuelve a startPayment',
        () async {
      final card = _Card(CardSheetOutcome.failed);
      final c = cubit(card: card);
      repo.ctrl.add(_payment(methods: ['card']));
      await pumpEventQueue();
      await c.choose(PayMethod.card);
      expect(c.state.error, BookingPaymentCubit.kCardFailed);
      card.outcome = CardSheetOutcome.completed;
      await c.choose(PayMethod.card);
      expect(c.state.error, isNull);
      expect(c.state.cardSubmitted, isTrue);
      // El importe y la clave del cobro los pone el servidor en cada intento.
      expect(repo.started, [PayMethod.card, PayMethod.card]);
      expect(card.calls, 2);
      await c.close();
    });

    test('rechazado con la pantalla abierta: vuelve a mostrar los datos',
        () async {
      final c = cubit();
      repo.ctrl.add(
        _payment(extra: {'riderReportedAt': 1}),
      );
      await pumpEventQueue();
      expect(repo.started, isEmpty);
      repo.ctrl.add(_payment(status: 'failed', extra: {'rejectedAt': 2}));
      await pumpEventQueue();
      expect(repo.started, [PayMethod.manualQr]);
      await c.close();
    });
  });

  group('paymentFailureFor', () {
    test('un fallo del servidor no culpa a la persona (E37)', () {
      expect(paymentFailureFor('internal', null), kPaymentOurFault);
      expect(
        paymentFailureFor('failed-precondition', {'reason': 'method_disabled'}),
        contains('no está disponible'),
      );
    });
  });

  test('tiempo para pagar: solo con el plazo del servidor', () {
    final now = DateTime(2026, 10, 26, 14);
    expect(
      paymentTimeLeft(DateTime(2026, 10, 26, 14, 24), now),
      'Quedan 24 min para pagar (hasta las 14:24).',
    );
    expect(
      paymentTimeLeft(DateTime(2026, 10, 26, 15, 30), now),
      'Quedan 1 h 30 min para pagar (hasta las 15:30).',
    );
    expect(
      paymentTimeLeft(DateTime(2026, 10, 26, 13, 59), now),
      'El plazo para pagar terminó a las 13:59.',
    );
  });

  group('pantalla de pago', () {
    Future<BookingPaymentCubit> pump(
      WidgetTester t,
      BookingPayment? p, {
      double scale = 1,
      CardPaymentPresenter? card,
    }) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = cubit(card: card);
      addTearDown(c.close);
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              textScaler: TextScaler.linear(scale),
            ),
            child: BlocProvider.value(
              value: c,
              child: const BookingPaymentView(bookingId: 'b1'),
            ),
          ),
        ),
      );
      repo.ctrl.add(p);
      await t.pumpAndSettle();
      return c;
    }

    testWidgets('manual: importe exacto, referencia, datos y «Ya pagué»',
        (t) async {
      await pump(
        t,
        _payment(
          extra: {
            'paymentDeadline': DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
          },
        ),
      );
      expect(find.textContaining('86,50'), findsWidgets);
      expect(find.text('LX7K2M'), findsOneWidget);
      expect(find.text('Titular ficticio'), findsOneWidget);
      expect(find.text('000-ficticia'), findsOneWidget);
      expect(find.textContaining('Quedan'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'OP 9');
      await t.ensureVisible(find.text('Ya pagué'));
      await t.tap(find.text('Ya pagué'));
      await t.pumpAndSettle();
      expect(repo.sent, ['OP 9']);
    });

    testWidgets('esperando confirmación tras «Ya pagué»', (t) async {
      await pump(
        t,
        _payment(extra: {'riderReportedAt': 1, 'riderOperationNumber': 'OP 9'}),
      );
      expect(find.text('Esperando confirmación'), findsOneWidget);
      expect(find.text('Ya pagué'), findsNothing);
      expect(find.textContaining('OP 9'), findsOneWidget);
    });

    testWidgets('confirmado', (t) async {
      await pump(t, _payment(status: 'paid'));
      expect(find.text('Pago confirmado'), findsOneWidget);
    });

    testWidgets('vencido: explicación sobria con la referencia', (t) async {
      await pump(t, _payment(status: 'expired'));
      expect(find.text('El plazo para pagar terminó'), findsOneWidget);
      expect(find.textContaining('LX7K2M'), findsWidgets);
    });

    testWidgets('rechazado: aviso y los datos otra vez', (t) async {
      await pump(t, _payment(status: 'failed', extra: {'rejectedAt': 2}));
      expect(
          find.textContaining('No pudimos confirmar tu pago'), findsOneWidget);
      expect(find.text('Ya pagué'), findsOneWidget);
    });

    testWidgets('error del servidor visible y sin culpar a la persona',
        (t) async {
      repo.startFailure = const PaymentFailure(kPaymentOurFault);
      await pump(t, _payment());
      expect(find.text(kPaymentOurFault), findsOneWidget);
    });

    testWidgets('dos métodos: elige; con tarjeta muestra «Pagar con tarjeta»',
        (t) async {
      await pump(
        t,
        _payment(methods: ['manual_qr', 'card']),
        card: _Card(CardSheetOutcome.cancelled),
      );
      expect(find.text('¿CÓMO QUIERES PAGAR?'), findsOneWidget);
      await t.tap(find.text('Tarjeta'));
      await t.pumpAndSettle();
      expect(find.text('Pagar con tarjeta'), findsOneWidget);
      expect(find.text('Cambiar método de pago'), findsOneWidget);
    });

    testWidgets('a11y: botones de 48 px y con nombre', (t) async {
      final h = t.ensureSemantics();
      await pump(t, _payment());
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('texto al 200 %: nada se desborda', (t) async {
      await pump(t, _payment(), scale: 2);
      expect(t.takeException(), isNull);
      await pump(t, _payment(extra: {'riderReportedAt': 1}), scale: 2);
      expect(t.takeException(), isNull);
      await pump(t, _payment(status: 'expired'), scale: 2);
      expect(t.takeException(), isNull);
    });
  });

  test('B4: los textos no prometen plazos ni hablan de saldo o monedero', () {
    final all = [
      kPaymentOurFault,
      BookingPaymentCubit.kCardFailed,
      BookingPaymentCubit.kCardUnavailable,
      BookingPaymentCubit.kPaymentLoadError,
      paymentFailureFor('failed-precondition', {'reason': 'method_disabled'}),
      paymentFailureFor(
          'failed-precondition', {'reason': 'not_awaiting_payment'}),
    ].join(' ').toLowerCase();
    for (final w in [
      'monedero',
      'billetera',
      'saldo a favor',
      'crédito',
      'inmediat',
      'al instante',
      'horas hábiles',
      'días hábiles'
    ]) {
      expect(all.contains(w), isFalse, reason: w);
    }
  });
}
