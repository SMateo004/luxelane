import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/booking_payment.dart';
import 'package:luxelane/features/payments/presentation/widgets/payment_receipt.dart';
import 'package:luxelane/features/ride/presentation/pages/ride_screen.dart'
    show cancelledMessage, receiptBelowDriver;

/// Importes y referencia de PRUEBA, ficticios (céntimos de boliviano).
BookingPayment _p(String status, Map<String, dynamic> extra) =>
    BookingPayment.fromJson('b1', {
      'paymentStatus': status,
      'paymentMethod': 'manual_qr',
      'amountDue': 8000,
      'amountPaid': 8000,
      'paymentRef': 'LX7K2M',
      'paidAt': DateTime(2026, 10, 26, 9, 30).millisecondsSinceEpoch,
      ...extra,
    });

void main() {
  Future<void> pump(WidgetTester t, Widget w, {double scale = 1}) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: SingleChildScrollView(child: w)),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  group('comprobante', () {
    testWidgets('pagada: dice que no es una factura', (t) async {
      await pump(t, PaymentReceiptCard(payment: _p('paid', {})));
      expect(find.text('Comprobante de pago'), findsOneWidget);
      expect(find.text('Este comprobante no es una factura.'), findsOneWidget);
      expect(find.text('QR o transferencia'), findsOneWidget);
      expect(find.text('LX7K2M'), findsOneWidget);
      expect(find.textContaining('80'), findsWidgets);
    });

    testWidgets(
        'devolución pendiente: sin «te devolvemos» hasta que el servidor '
        'la registre (B4)', (t) async {
      await pump(
        t,
        PaymentReceiptCard(
          payment: _p('refund_pending', {
            'amountRetained': 2000,
            'refundDue': 6000,
          }),
        ),
      );
      expect(find.text('Retención por cancelación'), findsOneWidget);
      expect(find.text('Devolución pendiente'), findsOneWidget);
      expect(find.textContaining('Te devolvemos'), findsNothing);
    });

    testWidgets('devolución registrada: ahora sí, al método con que pagó',
        (t) async {
      await pump(
        t,
        PaymentReceiptCard(
          payment: _p('refunded', {'amountRefunded': 8000}),
        ),
      );
      expect(
        find.text('Te devolvemos el dinero al método con el que pagaste.'),
        findsOneWidget,
      );
      expect(find.text('Retención por cancelación'), findsNothing);
    });

    testWidgets('sin retención no aparece la línea (solo si > 0)', (t) async {
      await pump(
        t,
        PaymentReceiptCard(
          payment: _p('refund_pending', {'refundDue': 8000}),
        ),
      );
      expect(find.text('Retención por cancelación'), findsNothing);
    });

    testWidgets('texto al 200 %: nada se desborda', (t) async {
      await pump(
        t,
        PaymentReceiptCard(
          payment: _p('partially_refunded', {
            'amountRetained': 2000,
            'amountRefunded': 6000,
            'balanceDue': 1250,
          }),
        ),
        scale: 2,
      );
      expect(t.takeException(), isNull);
    });
  });

  group('E40: con el viaje en curso', () {
    test('el comprobante va debajo del chófer solo con el viaje en curso', () {
      for (final st in BookingStatus.values) {
        expect(
          receiptBelowDriver(st),
          {
            BookingStatus.driverArriving,
            BookingStatus.driverArrived,
            BookingStatus.verified,
            BookingStatus.inProgress,
          }.contains(st),
          reason: st.name,
        );
      }
    });

    testWidgets('plegado: título e importe; se despliega al tocar', (t) async {
      final h = t.ensureSemantics();
      await pump(
        t,
        PaymentReceiptCard(payment: _p('paid', {}), collapsed: true),
      );
      expect(find.text('Comprobante de pago'), findsOneWidget);
      expect(find.textContaining('120'), findsNothing);
      expect(find.textContaining('80'), findsOneWidget);
      expect(find.text('Referencia'), findsNothing);
      // Plegado ocupa una línea: no empuja al chófer.
      expect(
        t.getSize(find.byKey(const ValueKey('payment-receipt'))).height,
        lessThan(80),
      );
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await t.tap(find.byTooltip('Ver comprobante'));
      await t.pumpAndSettle();
      expect(find.text('Referencia'), findsOneWidget);
      expect(find.text('Este comprobante no es una factura.'), findsOneWidget);
      h.dispose();
    });
  });

  group('E43: titular de una reserva cancelada', () {
    test('si el comprobante muestra la retención, el titular no la repite', () {
      final p = _p('partially_refunded', {
        'amountRetained': 1200,
        'amountRefunded': 6800,
      });
      expect(p.hasReceipt, isTrue);
      expect(cancelledMessage(p, null), 'Esta reserva fue cancelada.');
    });

    test('reserva antigua (sin estado de pago): el recargo de la reserva', () {
      expect(
        cancelledMessage(null, 50),
        'Esta reserva fue cancelada. Retención por cancelación: Bs\u00A050.',
      );
      expect(cancelledMessage(null, 0), 'Esta reserva fue cancelada.');
    });
  });

  testWidgets('H3: el saldo pendiente, en texto neutro', (t) async {
    await pump(
      t,
      PaymentReceiptCard(payment: _p('paid', {'balanceDue': 1500})),
    );
    expect(find.text('Saldo pendiente'), findsOneWidget);
    expect(find.text('Bs\u00A015'), findsOneWidget);
    expect(
      find.text('El importe final del viaje fue mayor que lo pagado.'),
      findsOneWidget,
    );
    final texts = t
        .widgetList<Text>(find.byType(Text))
        .map((w) => (w.data ?? '').toLowerCase())
        .join(' ');
    for (final w in [
      'contact',
      'avisaremos',
      'llamar',
      'plazo',
      'días',
      'horas',
      'pronto',
      'en breve'
    ]) {
      expect(texts.contains(w), isFalse, reason: w);
    }
  });

  group('pago pendiente en el viaje', () {
    testWidgets('lleva a pagar; botón de 48 px con nombre', (t) async {
      var tapped = 0;
      final h = t.ensureSemantics();
      await pump(
        t,
        PaymentPendingCard(
          payment: _p('awaiting_payment', {'amountPaid': 0}),
          onPay: () => tapped++,
        ),
      );
      expect(find.text('Pago pendiente'), findsOneWidget);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await t.tap(find.text('Pagar ahora'));
      expect(tapped, 1);
      h.dispose();
    });

    testWidgets('ya avisó: esperando confirmación', (t) async {
      await pump(
        t,
        PaymentPendingCard(
          payment: _p('awaiting_payment', {
            'amountPaid': 0,
            'riderReportedAt': 1,
          }),
          onPay: () {},
        ),
      );
      expect(find.text('Esperando confirmación'), findsOneWidget);
      expect(find.text('Ver el pago'), findsOneWidget);
    });
  });
}
