import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/waiting_policy.dart';
import 'package:luxelane/core/widgets/trip_widgets.dart';

Booking _b({
  String? flight,
  FlightInfo? flightInfo,
  DateTime? pickup,
  DateTime? arrivedAt,
  BookingStatus status = BookingStatus.driverArrived,
  String? name = 'Ana Gutiérrez',
  String? phone = '+591 70000000',
}) {
  final at = pickup ?? DateTime(2026, 10, 7, 14);
  return Booking(
    id: 'b1',
    riderId: 'r1',
    origin: const Place(address: 'Viru Viru', lat: -17.64, lng: -63.13),
    destination: const Place(address: 'Equipetrol', lat: -17.76, lng: -63.19),
    scheduledAt: at,
    vehicleClass: VehicleClass.business,
    serviceType: ServiceType.oneWay,
    status: status,
    estimatedPrice: 110,
    createdAt: at,
    updatedAt: at,
    flightNumber: flight,
    flight: flightInfo,
    driverArrivedAt: arrivedAt,
    passengerName: name,
    passengerPhone: phone,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('WaitingPolicy', () {
    test('city: 15 min from pickup', () {
      final b = _b();
      expect(WaitingPolicy.isAirport(b), isFalse);
      expect(WaitingPolicy.freeUntil(b), DateTime(2026, 10, 7, 14, 15));
    });

    test('city: clock starts when a late chauffeur arrives', () {
      final b = _b(arrivedAt: DateTime(2026, 10, 7, 14, 10));
      expect(WaitingPolicy.freeUntil(b), DateTime(2026, 10, 7, 14, 25));
    });

    test('airport: 60 min from landing', () {
      final b = _b(
        flight: 'OB760',
        flightInfo: FlightInfo(number: 'OB760', status: 'Arrived', estimatedArrival: DateTime(2026, 10, 7, 14, 30)),
      );
      expect(WaitingPolicy.freeUntil(b), DateTime(2026, 10, 7, 15, 30));
      expect(WaitingPolicy.summary(b), contains('aterrizaje'));
    });

    test('remaining is null once the free wait is over', () {
      final b = _b();
      expect(WaitingPolicy.remaining(b, now: DateTime(2026, 10, 7, 14, 5))!.inMinutes, 10);
      expect(WaitingPolicy.remaining(b, now: DateTime(2026, 10, 7, 14, 20)), isNull);
    });
  });

  testWidgets('FreeWaitBanner shows the countdown while waiting', (tester) async {
    final soon = DateTime.now();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FreeWaitBanner(booking: _b(pickup: soon)))));
    expect(find.textContaining('Espera gratuita:'), findsOneWidget);
    expect(find.textContaining('15 min de espera gratuita'), findsOneWidget);
  });

  testWidgets('PassengerCard offers call, WhatsApp and the name sign', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PassengerCard(booking: _b(flight: 'OB760')))));
    expect(find.text('Ana Gutiérrez'), findsOneWidget);
    expect(find.textContaining('Vuelo OB760'), findsOneWidget);
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);

    await tester.tap(find.text('Mostrar cartel'));
    await tester.pumpAndSettle();
    expect(find.byType(NameSignPage), findsOneWidget);
    expect(find.text('Ana Gutiérrez'), findsOneWidget);

    await tester.tap(find.byType(NameSignPage));
    await tester.pumpAndSettle();
    expect(find.byType(NameSignPage), findsNothing);
  });

  testWidgets('PassengerCard hides contact actions without a phone', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PassengerCard(booking: _b(phone: null, name: null)))));
    expect(find.text('Pasajero'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
    expect(find.text('Mostrar cartel'), findsNothing);
  });

  testWidgets('MeetAndGreetCard names the sign', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MeetAndGreetCard(booking: _b(flight: 'OB760')))));
    expect(find.textContaining('«Ana Gutiérrez»'), findsOneWidget);
    expect(find.textContaining('60 min de espera gratuita'), findsOneWidget);
  });
}
