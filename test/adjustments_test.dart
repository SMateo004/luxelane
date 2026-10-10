import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/adjustments/domain/adjustments.dart';
import 'package:luxelane/features/adjustments/presentation/adjust_price_dialog.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:luxelane/features/trips/presentation/pages/receipt_page.dart';

import 'helpers/l10n.dart';

class _MockAdminBloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

final _at = DateTime(2026, 10, 9, 9);

Booking _b({
  BookingStatus status = BookingStatus.completed,
  double? finalPrice,
  double refunded = 0,
  List<PriceAdjustment> adjustments = const [],
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
      estimatedPrice: 250,
      finalPrice: finalPrice,
      createdAt: _at,
      updatedAt: _at,
      refundedAmount: refunded,
      adjustments: adjustments,
      paymentMethod: method,
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  group('Adjustments', () {
    test('parses stored adjustments, skipping unknown ones', () {
      final a = [
        {'type': 'toll', 'amount': 15, 'note': null},
        {'type': 'tip', 'amount': 5},
        {'type': 'correction', 'amount': -10.5, 'note': 'Ruta más corta'},
      ].map(PriceAdjustment.fromJson).whereType<PriceAdjustment>().toList();
      expect(a.map((x) => (x.type, x.amount)), [(AdjustmentType.toll, 15.0), (AdjustmentType.correction, -10.5)]);
    });

    test('when it can be adjusted', () {
      expect(Adjustments.canAdjust(_b()), isTrue);
      expect(Adjustments.canAdjust(_b(status: BookingStatus.driverArrived)), isTrue);
      expect(Adjustments.canAdjust(_b(status: BookingStatus.confirmed)), isFalse);
      expect(Adjustments.canAdjust(_b(method: 'card')), isFalse);
    });

    test('validation mirrors the server', () {
      final b = _b(finalPrice: 265, refunded: 200);
      expect(Adjustments.validate(b, AdjustmentType.toll, 15, ''), isNull);
      expect(Adjustments.validate(b, null, 15, ''), 'adjust/type');
      expect(Adjustments.validate(b, AdjustmentType.toll, -5, ''), 'adjust/amount');
      expect(Adjustments.validate(b, AdjustmentType.toll, 2500, ''), 'adjust/amount');
      expect(Adjustments.validate(b, AdjustmentType.correction, -5, ''), 'adjust/note');
      expect(Adjustments.validate(b, AdjustmentType.correction, -70, 'Error de cobro'), 'adjust/below-zero');
      expect(Adjustments.totalWith(b, 15), 280);
    });
  });

  group('AdjustPriceDialog', () {
    for (final width in const [390.0, 1280.0]) {
      testWidgets('adds a toll and previews the new total (${width.toInt()}px)', (tester) async {
        tester.view
          ..physicalSize = Size(width, 1000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final calls = <(AdjustmentType, double, String)>[];
        final b = _b(finalPrice: 280, adjustments: const [PriceAdjustment(type: AdjustmentType.waiting, amount: 30)]);
        await tester.pumpWidget(localizedApp(Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => AdjustPriceDialog(
                  booking: b,
                  onSubmit: (t, a, n) async {
                    calls.add((t, a, n));
                    return null;
                  },
                ),
              ),
              child: const Text('open'),
            ),
          ),
        )));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Total actual: Bs 280,00'), findsOneWidget);
        expect(find.text('Espera adicional: +Bs 30,00'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Guardar ajuste'));
        await tester.pumpAndSettle();
        expect(find.text('Elige qué se agrega.'), findsOneWidget);

        await tester.tap(find.text('Peaje'));
        await tester.enterText(find.widgetWithText(TextField, 'Monto en Bs'), '15');
        await tester.pumpAndSettle();
        expect(find.text('Nuevo total: Bs 295,00'), findsOneWidget);
        await tester.tap(find.text('Guardar ajuste'));
        await tester.pumpAndSettle();
        expect(calls.single, (AdjustmentType.toll, 15.0, ''));
        expect(find.byType(AdjustPriceDialog), findsNothing);
      });
    }

    testWidgets('a correction needs a reason; server errors show (en)', (tester) async {
      await tester.pumpWidget(localizedApp(
        Scaffold(
          body: AdjustPriceDialog(booking: _b(), onSubmit: (_, __, ___) async => 'adjust/status'),
        ),
        locale: const Locale('en'),
      ));
      await tester.tap(find.text('Correction'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Amount in Bs (negative to lower the price)'), '-20');
      await tester.tap(find.text('Save adjustment'));
      await tester.pumpAndSettle();
      expect(find.text('Write the reason for the correction.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Reason for the correction'), 'Shorter route');
      await tester.tap(find.text('Save adjustment'));
      await tester.pumpAndSettle();
      expect(find.text("Prices can only be adjusted from the chauffeur's arrival until the ride ends."), findsOneWidget);
    });
  });

  testWidgets('admin bookings show the adjusted total and offer an adjustment', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = _MockAdminBloc();
    whenListen(bloc, const Stream<AdminState>.empty(),
        initialState: AdminState(bookings: [_b(status: BookingStatus.inProgress, finalPrice: 265)]));
    await tester.pumpWidget(BlocProvider<AdminBloc>.value(
      value: bloc,
      child: localizedApp(const Scaffold(body: BookingsTab())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Bs 265'), findsOneWidget);
    await tester.tap(find.byTooltip('Acciones'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustar precio'), findsOneWidget);
  });

  testWidgets('receipt itemizes the adjustments', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(localizedApp(ReceiptPage(
      bookingId: 'x',
      booking: _b(finalPrice: 275, adjustments: const [
        PriceAdjustment(type: AdjustmentType.toll, amount: 35),
        PriceAdjustment(type: AdjustmentType.correction, amount: -10, note: 'Ruta más corta'),
      ]),
    )));
    expect(find.text('Peaje'), findsOneWidget);
    expect(find.text('+Bs 35,00'), findsOneWidget);
    expect(find.text('Corrección'), findsOneWidget);
    expect(find.text('−Bs 10,00'), findsOneWidget);
    expect(find.text('Bs 275,00'), findsWidgets);
  });
}
