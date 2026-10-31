import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/booking_payment.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/payments/data/repositories/booking_payment_repository_impl.dart';
import 'package:luxelane/features/payments/presentation/bloc/booking_payment_cubit.dart';
import 'package:luxelane/features/payments/presentation/pages/booking_payment_screen.dart';
import 'package:luxelane/features/payments/presentation/pages/payment_screen.dart';
import 'package:luxelane/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Idiomas, bloque de pagos: la pantalla de pago y el comprobante salen en
/// inglés y en portugués, sin restos en español. Los datos de cobro que
/// escribe el admin (titular, banco, cuenta, nota) se muestran tal cual.
/// Importes y referencia de PRUEBA, ficticios (céntimos de boliviano).
const _instructions = ManualInstructions(
  holderName: 'Titular ficticio',
  bankName: 'Banco ficticio',
  accountNumber: '000-ficticia',
  note: 'Nota ficticia del admin',
);

class _FakeRepo implements BookingPaymentRepository {
  final ctrl = StreamController<BookingPayment?>.broadcast();

  Future<void> dispose() => ctrl.close();

  @override
  Stream<BookingPayment?> watch(String bookingId) => ctrl.stream;

  @override
  Future<Either<Failure, PaymentStart>> start(
    String bookingId,
    String method,
  ) async =>
      const Right(
        PaymentStart(
          method: PayMethod.manualQr,
          amountDue: 123450,
          paymentRef: 'LX7K2M',
          instructions: _instructions,
        ),
      );

  @override
  Future<Either<Failure, void>> markSent(
    String bookingId, {
    String? operationNumber,
  }) async =>
      const Right(null);
}

BookingPayment _payment(String status,
        [Map<String, dynamic> extra = const {}]) =>
    BookingPayment.fromJson('b1', {
      'paymentStatus': status,
      'paymentMethod': 'manual_qr',
      'amountDue': 123450,
      'amountPaid': status == 'awaiting_payment' ? 0 : 123450,
      'paymentRef': 'LX7K2M',
      'methodsOffered': ['manual_qr'],
      'paidAt': DateTime(2026, 10, 26, 9, 30).millisecondsSinceEpoch,
      ...extra,
    });

Widget _app(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      supportedLocales: LuxLocale.supportedLocales,
      localizationsDelegates: LuxLocale.delegates,
      home: child,
    );

void main() {
  late _FakeRepo repo;

  Future<void> pumpPayment(WidgetTester t, Locale locale) async {
    t.view.physicalSize = const Size(390, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final c = BookingPaymentCubit(
      repository: repo,
      bookingId: 'b1',
      isWeb: false,
    );
    addTearDown(c.close);
    await t.pumpWidget(
      _app(
        locale,
        BlocProvider.value(
          value: c,
          child: const BookingPaymentView(bookingId: 'b1'),
        ),
      ),
    );
    repo.ctrl.add(
      _payment('awaiting_payment', {
        'paymentDeadline': DateTime.now()
            .add(const Duration(minutes: 30))
            .millisecondsSinceEpoch,
      }),
    );
    await t.pumpAndSettle();
  }

  Future<void> pumpReceipt(WidgetTester t, Locale locale) async {
    t.view.physicalSize = const Size(390, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _app(
        locale,
        Scaffold(
          body: SingleChildScrollView(
            child: PaymentReceiptCard(
              payment: _payment('refund_pending', {
                'amountRetained': 20000,
                'refundDue': 103450,
              }),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  setUp(() => repo = _FakeRepo());
  tearDown(() async {
    await repo.dispose();
    L10n.use(const Locale('es'));
  });

  group('inglés', () {
    setUp(() => L10n.use(const Locale('en')));

    testWidgets('pantalla de pago', (t) async {
      await pumpPayment(t, const Locale('en'));
      expect(find.text('Booking payment'), findsOneWidget);
      expect(find.text('AMOUNT DUE'), findsOneWidget);
      expect(find.text('Bs\u00A01,234.50'), findsOneWidget);
      expect(find.text('PAY BY QR OR TRANSFER'), findsOneWidget);
      expect(find.text('Account holder'), findsOneWidget);
      expect(find.textContaining('left to pay (until'), findsOneWidget);
      expect(
        find.text(
          'Pay exactly Bs\u00A01,234.50 and enter the reference LX7K2M in the '
          'payment description.',
        ),
        findsOneWidget,
      );
      expect(find.text('Transaction number (optional)'), findsOneWidget);
      expect(find.text('I have paid'), findsOneWidget);
      expect(
        find.text('We look for a chauffeur once the payment is confirmed.'),
        findsOneWidget,
      );
      // Datos que escribe el admin: no se traducen.
      expect(find.text('Titular ficticio'), findsOneWidget);
      expect(find.text('Banco ficticio'), findsOneWidget);
      expect(find.text('Nota ficticia del admin'), findsOneWidget);
      // Nada en español.
      expect(find.text('Pago de tu reserva'), findsNothing);
      expect(find.text('IMPORTE A PAGAR'), findsNothing);
      expect(find.text('Ya pagué'), findsNothing);
      expect(find.textContaining('Quedan'), findsNothing);
      expect(find.textContaining('Bs\u00A01.234,50'), findsNothing);
    });

    testWidgets('comprobante: importe «Bs 1,234.50»', (t) async {
      await pumpReceipt(t, const Locale('en'));
      expect(find.text('Payment receipt'), findsOneWidget);
      expect(find.text('This receipt is not an invoice.'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Bs\u00A01,234.50'), findsOneWidget);
      expect(find.text('Bs\u00A01,034.50'), findsOneWidget);
      expect(find.text('QR or transfer'), findsOneWidget);
      expect(find.text('Cancellation fee'), findsOneWidget);
      expect(find.text('Refund pending'), findsOneWidget);
      expect(find.text('Reference'), findsOneWidget);
      expect(find.text('Comprobante de pago'), findsNothing);
      expect(find.text('Devolución pendiente'), findsNothing);
      expect(find.textContaining('Bs\u00A01.234,50'), findsNothing);
    });

    testWidgets('métodos de pago sin tarjetas', (t) async {
      await t.pumpWidget(
        _app(const Locale('en'), const PaymentScreen(cardsEnabled: false)),
      );
      expect(find.text('Payment methods'), findsOneWidget);
      expect(
        find.text('Each booking is paid in its own payment step.'),
        findsOneWidget,
      );
      expect(find.text('Métodos de pago'), findsNothing);
    });

    test('mensajes de error del servidor', () {
      expect(paymentFailureFor('internal', null), startsWith('We could not'));
      expect(
        paymentFailureFor(
          'failed-precondition',
          {'reason': 'not_awaiting_payment'},
        ),
        'This booking no longer accepts payments. Check its status in My '
        'trips.',
      );
      expect(
          paymentTimeLeft(
              DateTime(2026, 1, 1, 15, 5), DateTime(2026, 1, 1, 14)),
          '1 h 5 min left to pay (until 3:05 PM).');
    });
  });

  group('portugués', () {
    setUp(() => L10n.use(const Locale('pt')));

    testWidgets('pantalla de pago', (t) async {
      await pumpPayment(t, const Locale('pt'));
      expect(find.text('Pagamento da sua reserva'), findsOneWidget);
      expect(find.text('VALOR A PAGAR'), findsOneWidget);
      expect(find.text('Bs\u00A01.234,50'), findsOneWidget);
      expect(find.text('PAGUE POR QR OU TRANSFERÊNCIA'), findsOneWidget);
      expect(find.text('Conta'), findsOneWidget);
      expect(find.textContaining('Restam'), findsOneWidget);
      expect(find.text('Já paguei'), findsOneWidget);
      expect(find.text('Titular ficticio'), findsOneWidget);
      expect(find.text('Pago de tu reserva'), findsNothing);
      expect(find.text('Ya pagué'), findsNothing);
      expect(find.text('Cuenta'), findsNothing);
      expect(find.textContaining('Quedan'), findsNothing);
    });

    testWidgets('comprobante', (t) async {
      await pumpReceipt(t, const Locale('pt'));
      expect(find.text('Comprovante de pagamento'), findsOneWidget);
      expect(
          find.text('Este comprovante não é uma nota fiscal.'), findsOneWidget);
      expect(find.text('Bs\u00A01.234,50'), findsOneWidget);
      expect(find.text('Taxa de cancelamento'), findsOneWidget);
      expect(find.text('Reembolso pendente'), findsOneWidget);
      expect(find.text('Referência'), findsOneWidget);
      expect(find.text('Comprobante de pago'), findsNothing);
      expect(find.text('Este comprobante no es una factura.'), findsNothing);
    });
  });
}
