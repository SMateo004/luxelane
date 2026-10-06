import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/app/theme/lux_tokens.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_confirmed_page.dart';

Booking _booking() {
  final now = DateTime.now();
  return Booking(
    id: 'abc12345xyz',
    riderId: 'rider-1',
    origin: const Place(address: 'Plaza 24 de Septiembre', lat: -17.78, lng: -63.18),
    destination: const Place(address: 'Aeropuerto Viru Viru', lat: -17.64, lng: -63.13),
    scheduledAt: now.add(const Duration(hours: 3, minutes: 5)),
    vehicleClass: VehicleClass.firstClass,
    serviceType: ServiceType.oneWay,
    status: BookingStatus.pending,
    estimatedPrice: 1250,
    createdAt: now,
    updatedAt: now,
    flightNumber: 'OB 760',
    passengerCount: 2,
    luggageCount: 3,
    stripePaymentIntentId: 'pi_123',
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('shows the fixed price, trip summary and countdown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    await tester.pumpWidget(MaterialApp(
      home: BookingConfirmedPage(bookingId: 'abc12345xyz', booking: _booking()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('RESERVA CONFIRMADA'), findsOneWidget);
    expect(find.text(LuxMoney.format(1250)), findsOneWidget);
    expect(find.textContaining('tarjeta autorizada'), findsOneWidget);
    expect(find.text('Aeropuerto Viru Viru'), findsOneWidget);
    expect(find.text('Vuelo OB 760'), findsOneWidget);
    expect(find.text('2 pasajeros · 3 maletas'), findsOneWidget);
    expect(find.textContaining('Recogida en 3 h'), findsOneWidget);
    expect(find.text('VER MI RESERVA'), findsOneWidget);
  });

  test('LuxMoney formats Bolivianos', () {
    expect(LuxMoney.format(1250), 'Bs 1.250');
    expect(LuxMoney.format(99.5, cents: true), 'Bs 99,50');
  });
}
