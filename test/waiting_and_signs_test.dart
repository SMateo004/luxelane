import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/waiting_policy.dart';
import 'package:luxelane/core/widgets/trip_widgets.dart';
import 'package:luxelane/l10n/l10n.dart';

import 'helpers/l10n.dart';

Booking _b({
  String? flight,
  FlightInfo? flightInfo,
  DateTime? pickup,
  DateTime? arrivedAt,
  BookingStatus status = BookingStatus.driverArrived,
  String? name = 'Ana Gutiérrez',
  String? phone = '+591 70000000',
  int luggage = 0,
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
    luggageCount: luggage,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
    await initializeDateFormatting('pt');
  });

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
      expect(WaitingPolicy.localizedSummary(lookupAppLocalizations(const Locale('es')), b), contains('aterrizaje'));
      expect(WaitingPolicy.localizedSummary(lookupAppLocalizations(const Locale('en')), b), contains('landing'));
    });

    test('remaining is null once the free wait is over', () {
      final b = _b();
      expect(WaitingPolicy.remaining(b, now: DateTime(2026, 10, 7, 14, 5))!.inMinutes, 10);
      expect(WaitingPolicy.remaining(b, now: DateTime(2026, 10, 7, 14, 20)), isNull);
    });
  });

  testWidgets('FreeWaitBanner shows the countdown while waiting', (tester) async {
    final soon = DateTime.now();
    await tester.pumpWidget(localizedApp(Scaffold(body: FreeWaitBanner(booking: _b(pickup: soon)))));
    expect(find.textContaining('Espera gratuita:'), findsOneWidget);
    expect(find.textContaining('15 min de espera gratuita'), findsOneWidget);
  });

  testWidgets('PassengerCard offers call, WhatsApp and the name sign', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(localizedApp(Scaffold(body: PassengerCard(booking: _b(flight: 'OB760')))));
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
    await tester.pumpWidget(localizedApp(Scaffold(body: PassengerCard(booking: _b(phone: null, name: null)))));
    expect(find.text('Pasajero'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
    expect(find.text('Mostrar cartel'), findsNothing);
  });

  testWidgets('MeetAndGreetCard names the sign', (tester) async {
    await tester.pumpWidget(localizedApp(Scaffold(body: MeetAndGreetCard(booking: _b(flight: 'OB760')))));
    expect(find.textContaining('«Ana Gutiérrez»'), findsOneWidget);
    expect(find.textContaining('60 min de espera gratuita'), findsOneWidget);
  });

  group('English', () {
    testWidgets('FreeWaitBanner is translated', (tester) async {
      await tester.pumpWidget(localizedApp(
        Scaffold(body: FreeWaitBanner(booking: _b(pickup: DateTime.now()))),
        locale: const Locale('en'),
      ));
      expect(find.textContaining('Free waiting:'), findsOneWidget);
      expect(find.textContaining('15 min free waiting'), findsOneWidget);
      expect(find.textContaining('Espera'), findsNothing);
    });

    testWidgets('FreeWaitBanner tells the rider the chauffeur is still waiting', (tester) async {
      await tester.pumpWidget(localizedApp(
        Scaffold(body: FreeWaitBanner(booking: _b(pickup: DateTime.now().subtract(const Duration(hours: 1))))),
        locale: const Locale('en'),
      ));
      expect(find.textContaining('Free waiting ended at'), findsOneWidget);
      expect(find.textContaining('Your chauffeur is still waiting'), findsOneWidget);
    });

    testWidgets('PassengerCard and name sign chrome are translated', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(localizedApp(
        Scaffold(body: PassengerCard(booking: _b(flight: 'OB760', luggage: 1))),
        locale: const Locale('en'),
      ));
      expect(find.text('1 passenger · 1 bag · Flight OB760'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      await tester.tap(find.text('Show name sign'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Gutiérrez'), findsOneWidget); // data stays as is
      expect(find.text('Tap the screen to close'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Name sign for Ana Gutiérrez. Tap to close.')), findsOneWidget);
    });

    testWidgets('MeetAndGreetCard in Portuguese', (tester) async {
      await tester.pumpWidget(localizedApp(
        Scaffold(body: MeetAndGreetCard(booking: _b(flight: 'OB760'))),
        locale: const Locale('pt'),
      ));
      expect(find.text('Recepção no desembarque'), findsOneWidget);
      expect(find.textContaining('“Ana Gutiérrez”'), findsOneWidget);
      expect(find.textContaining('60 min de espera grátis'), findsOneWidget);
    });
  });
}
