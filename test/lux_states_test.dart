import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/widgets/lux_states.dart';
import 'package:luxelane/features/trips/presentation/pages/receipt_page.dart';

import 'helpers/l10n.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('es')}) =>
    localizedApp(Scaffold(body: child), locale: locale);

Booking _booking({BookingStatus status = BookingStatus.completed}) {
  final at = DateTime(2026, 10, 7, 9, 30);
  return Booking(
    id: 'rcpt1234abcd',
    riderId: 'rider-1',
    origin: const Place(address: 'Hotel Los Tajibos', lat: -17.76, lng: -63.18),
    destination: const Place(address: 'Aeropuerto Viru Viru', lat: -17.64, lng: -63.13),
    scheduledAt: at,
    vehicleClass: VehicleClass.business,
    serviceType: ServiceType.oneWay,
    status: status,
    estimatedPrice: 110,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
  });

  group('PriceBreakdown', () {
    testWidgets('one-way: base + distance, rounded total', (tester) async {
      await tester.pumpWidget(_wrap(const PriceBreakdown(
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        km: 20,
      )));
      expect(find.text('Tarifa base'), findsOneWidget);
      expect(find.textContaining('20,0 km'), findsOneWidget);
      // 50 + 20 × 3 = 110
      expect(find.text('Bs 110'), findsOneWidget);
      expect(find.text('Ajuste a tarifa mínima'), findsNothing);
    });

    testWidgets('shows the minimum-fare adjustment when it applies', (tester) async {
      await tester.pumpWidget(_wrap(const PriceBreakdown(
        vehicleClass: VehicleClass.firstClass,
        serviceType: ServiceType.oneWay,
      )));
      // base 80 + 0 km == minimum 80 → no adjustment
      expect(find.text('Bs 80'), findsOneWidget);

      await tester.pumpWidget(_wrap(const PriceBreakdown(
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.byTheHour,
        hours: 1,
      )));
      // 1 h × 80 = 80, minimum 160
      expect(find.text('Ajuste a tarifa mínima'), findsOneWidget);
      expect(find.text('Bs 160'), findsOneWidget);
    });
  });

  testWidgets('LuxErrorState calls retry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_wrap(LuxErrorState(message: 'Sin conexión', onRetry: () => retried++)));
    await tester.tap(find.text('Reintentar'));
    expect(retried, 1);
  });

  testWidgets('LuxSkeletonList renders without animation errors', (tester) async {
    await tester.pumpWidget(_wrap(const LuxSkeletonList(count: 2)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
  });

  group('ReceiptPage', () {
    testWidgets('completed trip shows total and payment method', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      await tester.pumpWidget(localizedApp(ReceiptPage(bookingId: 'x', booking: _booking())));
      expect(find.text('VIAJE COMPLETADO'), findsOneWidget);
      expect(find.text('Bs 110,00'), findsWidgets);
      expect(find.text('Pago al chófer'), findsOneWidget);
      expect(find.text('Nº RCPT1234'), findsOneWidget);
    });

    testWidgets('cancelled booking shows no charge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      await tester.pumpWidget(localizedApp(
        ReceiptPage(bookingId: 'x', booking: _booking(status: BookingStatus.cancelled)),
      ));
      expect(find.text('RESERVA CANCELADA'), findsOneWidget);
      expect(find.text('Sin cargo'), findsOneWidget);
      expect(find.text('Forma de pago'), findsNothing);
    });
  });

  group('English', () {
    testWidgets('PriceBreakdown uses English labels and number format', (tester) async {
      await tester.pumpWidget(_wrap(
        const PriceBreakdown(vehicleClass: VehicleClass.business, serviceType: ServiceType.oneWay, km: 20),
        locale: const Locale('en'),
      ));
      expect(find.text('Base fare'), findsOneWidget);
      expect(find.textContaining('20.0 km'), findsOneWidget);
      expect(find.text('Estimated total'), findsOneWidget);
    });

    testWidgets('LuxErrorState defaults are translated', (tester) async {
      await tester.pumpWidget(_wrap(LuxErrorState(message: 'x', onRetry: () {}), locale: const Locale('en')));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('ReceiptPage is fully translated at 360 px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(localizedApp(
        ReceiptPage(bookingId: 'x', booking: _booking()),
        locale: const Locale('en'),
      ));
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('TRIP COMPLETED'), findsOneWidget);
      expect(find.text('Bs 110.00'), findsWidgets);
      expect(find.text('Paid to chauffeur'), findsOneWidget);
      expect(find.text('Payment method'), findsOneWidget);
      expect(find.text('No. RCPT1234'), findsOneWidget);
      expect(find.text('Wednesday, October 7, 2026 · 9:30 AM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
