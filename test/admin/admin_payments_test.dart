import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/features/admin/data/repositories/admin_payments_repository_impl.dart';
import 'package:luxelane/features/admin/domain/admin_payments.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_payments_cubit.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_payments_tab.dart';
import 'package:mocktail/mocktail.dart';

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock implements HttpsCallableResult<Object?> {}

class _Repo extends Mock implements AdminPaymentsRepository {}

/// Referencias, importes y números de operación de PRUEBA, ficticios.
const _reported = {
  'bookingId': 'reserva-aviso',
  'paymentRef': 'LX7K2M',
  'paymentStatus': 'awaiting_payment',
  'paymentMethod': 'manual_qr',
  'amountDue': 8650,
  'amountPaid': 0,
  'riderReportedAt': 1793000000000,
  'riderOperationNumber': 'OP 77',
  'booking': {
    'status': 'pending',
    'scheduledAt': 1793003600000,
    'vehicleClass': 'business',
    'pickupArea': 'Zona de prueba',
  },
};

PaymentInboxItem _item([Map<String, dynamic> extra = const {}]) =>
    PaymentInboxItem.fromJson({..._reported, ...extra});

const _why = 'Ingreso visto en el extracto de prueba';

void main() {
  setUpAll(() => registerFallbackValue(PaymentInboxKind.reported));

  group('repositorio', () {
    late _Functions fn;
    late _Callable callable;
    late AdminPaymentsRepositoryImpl repo;

    setUp(() {
      fn = _Functions();
      callable = _Callable();
      repo = AdminPaymentsRepositoryImpl(functions: fn);
      when(() => fn.httpsCallable(any())).thenReturn(callable);
    });

    void answer(Object? data) {
      final r = _Result();
      when(() => r.data).thenReturn(data);
      when(() => callable.call<Object?>(any())).thenAnswer((_) async => r);
    }

    test('bandeja: lee los elementos y los asientos de devolución', () async {
      answer({
        'kind': 'refunds',
        'items': [
          {
            ..._reported,
            'paymentStatus': 'refund_pending',
            'refundDue': 6000,
            'pendingRefunds': [
              {'entryId': 'refund_final_x', 'amount': 6000, 'method': 'card'},
            ],
          },
        ],
      });
      final r = await repo.inbox(PaymentInboxKind.refunds);
      final items = r.getOrElse(() => throw StateError('falló'));
      expect(items.single.refundDue, 6000);
      expect(items.single.pendingRefunds.single.entryId, 'refund_final_x');
      expect(items.single.pendingRefunds.single.byCard, isTrue);
      expect(items.single.vehicleClass, 'business');
      verify(() => callable.call<Object?>({'kind': 'refunds'})).called(1);
    });

    test('confirmar, rechazar y devolver mandan solo lo que pide el servidor',
        () async {
      answer({'paymentStatus': 'paid'});
      await repo.confirm(
        bookingId: 'b1',
        amountReceived: 86.5,
        operationNumber: ' OP 77 ',
        reason: ' $_why ',
      );
      verify(() => fn.httpsCallable('adminConfirmPayment')).called(1);
      verify(
        () => callable.call<Object?>({
          'bookingId': 'b1',
          'amountReceived': 86.5,
          'operationNumber': 'OP 77',
          'reason': _why,
        }),
      ).called(1);
      await repo.reject(bookingId: 'b1', reason: _why);
      verify(
        () => callable.call<Object?>({'bookingId': 'b1', 'reason': _why}),
      ).called(1);
      await repo.recordRefund(
        bookingId: 'b1',
        entryId: 'refund_b1',
        reason: _why,
        externalRef: 'DEV 9',
      );
      verify(
        () => callable.call<Object?>({
          'bookingId': 'b1',
          'entryId': 'refund_b1',
          'reason': _why,
          'externalRef': 'DEV 9',
        }),
      ).called(1);
    });

    test('errores: sin texto técnico; reauth y 2FA con su mensaje', () {
      String m(String code, String reason) =>
          adminPaymentErrorMessage(code, {'reason': reason});
      expect(m('failed-precondition', 'amount_mismatch'), contains('exacto'));
      expect(m('failed-precondition', 'operation_already_used'),
          contains('ya confirmó'));
      expect(m('unauthenticated', 'reauth_required'), kReauthRequiredMessage);
      expect(m('permission-denied', 'mfa_required'), kMfaRequiredMessage);
      final internal = adminPaymentErrorMessage('internal', null);
      for (final w in ['internal', 'error', 'exception', 'stack']) {
        expect(internal.toLowerCase().contains(w), isFalse, reason: w);
      }
    });
  });

  group('cubit', () {
    late _Repo repo;
    setUp(() {
      repo = _Repo();
      when(() => repo.inbox(any())).thenAnswer((_) async => Right([_item()]));
    });

    test('confirmar recarga la bandeja y avisa', () async {
      when(
        () => repo.confirm(
          bookingId: any(named: 'bookingId'),
          amountReceived: any(named: 'amountReceived'),
          operationNumber: any(named: 'operationNumber'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => const Right(null));
      final c = AdminPaymentsCubit(repo);
      await c.load();
      final ok = await c.confirm(
        _item(),
        amountReceived: 86.5,
        operationNumber: 'OP 77',
        reason: _why,
      );
      expect(ok, isTrue);
      expect(c.state.message, contains('Pago confirmado'));
      verify(() => repo.inbox(PaymentInboxKind.reported)).called(2);
      await c.close();
    });

    test('un fallo queda visible y no recarga', () async {
      when(() => repo.reject(
            bookingId: any(named: 'bookingId'),
            reason: any(named: 'reason'),
          )).thenAnswer(
        (_) async => const Left(
            ServerFailure('Este pago ya no está pendiente; recarga.')),
      );
      final c = AdminPaymentsCubit(repo);
      await c.load();
      expect(await c.reject(_item(), reason: _why), isFalse);
      expect(c.state.error, contains('ya no está pendiente'));
      expect(c.state.items, isNotEmpty);
      await c.close();
    });
  });

  group('pantalla', () {
    late _Repo repo;
    setUp(() => repo = _Repo());

    Future<AdminPaymentsCubit> pump(
      WidgetTester t,
      Either<Failure, List<PaymentInboxItem>> answer, {
      PaymentInboxKind kind = PaymentInboxKind.reported,
    }) async {
      t.view.physicalSize = const Size(1200, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      when(() => repo.inbox(any())).thenAnswer((_) async => answer);
      final c = AdminPaymentsCubit(repo);
      addTearDown(c.close);
      await t.pumpWidget(
        MaterialApp(
          theme: luxTheme,
          home: Scaffold(
            body: BlocProvider.value(value: c, child: const PaymentsView()),
          ),
        ),
      );
      await c.load(kind);
      await t.pumpAndSettle();
      return c;
    }

    testWidgets(
        '«ya pagué»: confirmar exige importe exacto, operación y motivo',
        (t) async {
      when(
        () => repo.confirm(
          bookingId: any(named: 'bookingId'),
          amountReceived: any(named: 'amountReceived'),
          operationNumber: any(named: 'operationNumber'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => const Right(null));
      await pump(t, Right([_item()]));
      expect(find.text('LX7K2M'), findsOneWidget);
      expect(find.text('OP 77'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      await t.tap(find.text('Confirmar pago'));
      await t.pumpAndSettle();
      FilledButton ok() =>
          t.widget<FilledButton>(find.byKey(const Key('confirm-payment')));
      // Importe y operación vienen rellenos; falta el motivo.
      expect(ok().onPressed, isNull);
      await t.enterText(find.byKey(const Key('confirm-reason')), _why);
      await t.pump();
      expect(ok().onPressed, isNotNull);
      await t.enterText(find.byKey(const Key('confirm-amount')), '80');
      await t.pump();
      expect(find.textContaining('Debe ser exactamente'), findsOneWidget);
      expect(ok().onPressed, isNull);
      await t.enterText(find.byKey(const Key('confirm-amount')), '86,50');
      await t.pump();
      await t.tap(find.byKey(const Key('confirm-payment')));
      await t.pumpAndSettle();
      verify(
        () => repo.confirm(
          bookingId: 'reserva-aviso',
          amountReceived: 86.5,
          operationNumber: 'OP 77',
          reason: _why,
        ),
      ).called(1);
    });

    testWidgets('devolución manual: pide la referencia del banco', (t) async {
      await pump(
        t,
        Right([
          _item({
            'paymentStatus': 'refund_pending',
            'refundDue': 6000,
            'pendingRefunds': [
              {
                'entryId': 'refund_reserva-aviso',
                'amount': 6000,
                'method': 'manual_qr'
              },
            ],
          }),
        ]),
        kind: PaymentInboxKind.refunds,
      );
      await t.tap(find.textContaining('Registrar devolución'));
      await t.pumpAndSettle();
      FilledButton ok() =>
          t.widget<FilledButton>(find.byKey(const Key('refund-confirm')));
      await t.enterText(find.byKey(const Key('refund-reason')), _why);
      await t.pump();
      expect(ok().onPressed, isNull);
      await t.enterText(find.byKey(const Key('refund-ref')), 'DEV 9');
      await t.pump();
      expect(ok().onPressed, isNotNull);
    });

    testWidgets('saldos: solo consulta, sin acciones', (t) async {
      await pump(
        t,
        Right([
          _item({'paymentStatus': 'paid', 'balanceDue': 1250}),
        ]),
        kind: PaymentInboxKind.balances,
      );
      expect(find.text('Saldo pendiente'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('vacía y con error: lo dice y deja reintentar', (t) async {
      await pump(t, const Right([]));
      expect(find.text('Nada pendiente'), findsOneWidget);
      await pump(t, const Left(ServerFailure(kNoConnectionMessage)));
      expect(find.text(kNoConnectionMessage), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('a11y: botones de 48 px y con nombre', (t) async {
      final h = t.ensureSemantics();
      await pump(t, Right([_item()]));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });
  });
}
