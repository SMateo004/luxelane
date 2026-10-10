import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/ops_report.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:luxelane/features/refunds/domain/refund.dart';
import 'package:luxelane/features/refunds/presentation/refund_dialog.dart';
import 'package:luxelane/features/trips/presentation/pages/receipt_page.dart';

import 'helpers/l10n.dart';

class _MockAdminBloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

final _at = DateTime(2026, 10, 9, 9);

Booking _b({
  BookingStatus status = BookingStatus.completed,
  double price = 250,
  double? finalPrice,
  double refunded = 0,
  String? companyId,
  String? method,
}) =>
    Booking(
      id: 'booking123',
      riderId: 'r1',
      driverId: 'd1',
      origin: const Place(address: 'Hotel Los Tajibos', lat: 0, lng: 0),
      destination: const Place(address: 'Viru Viru', lat: 0, lng: 0),
      scheduledAt: _at,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: price,
      finalPrice: finalPrice,
      createdAt: _at,
      updatedAt: _at,
      refundedAmount: refunded,
      companyId: companyId,
      companyName: companyId == null ? null : 'Acme',
      paymentMethod: method,
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  group('Refunds', () {
    test('what is left to refund', () {
      expect(Refunds.refundable(_b()), 250);
      expect(Refunds.refundable(_b(finalPrice: 280, refunded: 30.5)), 249.5);
      expect(Refunds.canRefund(_b(refunded: 250)), isFalse);
      expect(Refunds.canRefund(_b(status: BookingStatus.cancelled)), isFalse);
      // Card charges go back through Stripe instead.
      expect(Refunds.canRefund(_b(method: 'card')), isFalse);
    });

    test('validation mirrors the server', () {
      final b = _b(refunded: 200);
      expect(Refunds.validate(b, 50, RefundMethod.qr, 'Llegó tarde'), isNull);
      expect(Refunds.validate(b, 51, RefundMethod.qr, 'Llegó tarde'), 'refund/too-much');
      expect(Refunds.validate(b, 0, RefundMethod.qr, 'Llegó tarde'), 'refund/amount');
      expect(Refunds.validate(b, 10.555, RefundMethod.qr, 'Llegó tarde'), 'refund/amount');
      expect(Refunds.validate(b, 19.99, RefundMethod.qr, 'Llegó tarde'), isNull);
      expect(Refunds.validate(b, 4.35, RefundMethod.qr, 'Llegó tarde'), isNull);
      expect(Refunds.validate(b, 10, RefundMethod.invoiceCredit, 'Llegó tarde'), 'refund/method');
      expect(Refunds.validate(b, 10, RefundMethod.qr, ' '), 'refund/reason');
      expect(Refunds.methodsFor(_b(companyId: 'acme')), [RefundMethod.invoiceCredit]);
    });

    test('reports count refunds on completed rides', () {
      final r = OpsReport.lastDays([_b(refunded: 40), _b(), _b(refunded: 10)], 7, now: _at);
      expect(r.revenue, 750);
      expect(r.refunded, 50);
      expect(r.refundedTrips, 2);
    });
  });

  group('RefundDialog', () {
    Future<List<(double, RefundMethod, String)>> open(WidgetTester tester, Booking b,
        {String? serverError, Locale locale = const Locale('es'), double width = 390}) async {
      tester.view
        ..physicalSize = Size(width, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final calls = <(double, RefundMethod, String)>[];
      await tester.pumpWidget(localizedApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => RefundDialog(
                  booking: b,
                  onSubmit: (a, m, r) async {
                    calls.add((a, m, r));
                    return serverError;
                  },
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        locale: locale,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return calls;
    }

    for (final width in const [390.0, 1280.0]) {
      testWidgets('records a partial refund (${width.toInt()}px)', (tester) async {
        final calls = await open(tester, _b(refunded: 50), width: width);
        expect(find.text('El pasajero pagó Bs 250,00; ya se le devolvieron Bs 50,00.'), findsOneWidget);
        expect(find.text('200'), findsOneWidget); // prefilled with what's left
        expect(tester.takeException(), isNull);

        await tester.enterText(find.widgetWithText(TextField, 'Monto (máximo Bs 200,00)'), '250');
        await tester.tap(find.text('Registrar'));
        await tester.pumpAndSettle();
        expect(find.text('El monto supera lo que queda por devolver.'), findsOneWidget);

        await tester.enterText(find.widgetWithText(TextField, 'Monto (máximo Bs 200,00)'), '35,50');
        await tester.tap(find.text('QR'));
        await tester.enterText(find.widgetWithText(TextField, 'Motivo'), 'Llegó 25 min tarde');
        await tester.tap(find.text('Registrar'));
        await tester.pumpAndSettle();
        expect(calls.single, (35.5, RefundMethod.qr, 'Llegó 25 min tarde'));
        expect(find.byType(RefundDialog), findsNothing);
      });
    }

    testWidgets('company rides are credited on the invoice; server errors show (en)', (tester) async {
      final calls = await open(tester, _b(companyId: 'acme'), serverError: 'refund/too-much', locale: const Locale('en'));
      expect(find.text('Credit on the company invoice'), findsOneWidget);
      expect(find.text('QR'), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, 'Reason'), 'Wrong vehicle class');
      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();
      expect(calls.single.$2, RefundMethod.invoiceCredit);
      expect(find.text("The amount is more than what's left to refund."), findsOneWidget);
    });
  });

  testWidgets('admin bookings offer a refund on completed rides and show what was refunded', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = _MockAdminBloc();
    whenListen(bloc, const Stream<AdminState>.empty(), initialState: AdminState(bookings: [_b(refunded: 50)]));
    await tester.pumpWidget(BlocProvider<AdminBloc>.value(
      value: bloc,
      child: localizedApp(const Scaffold(body: BookingsTab())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Reembolsado Bs 50,00'), findsOneWidget);
    await tester.tap(find.byTooltip('Acciones'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar reembolso'), findsOneWidget);
  });

  testWidgets('receipt shows the refund and the net total', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(localizedApp(ReceiptPage(bookingId: 'x', booking: _b(refunded: 50))));
    expect(find.text('Reembolsado'), findsOneWidget);
    expect(find.text('−Bs 50,00'), findsOneWidget);
    expect(find.text('Total neto'), findsOneWidget);
    expect(find.text('Bs 200,00'), findsOneWidget);
  });
}
