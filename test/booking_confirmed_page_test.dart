import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:luxelane/app/theme/lux_tokens.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/booking/domain/booking_error_codes.dart';
import 'package:luxelane/features/booking/presentation/booking_error_l10n.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_confirmed_page.dart';
import 'package:luxelane/features/booking/presentation/pages/ride_type_page.dart';
import 'package:luxelane/l10n/gen/app_localizations_en.dart';
import 'package:luxelane/l10n/gen/app_localizations_es.dart';

import 'helpers/l10n.dart';

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
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
    await initializeDateFormatting('pt');
  });

  testWidgets('shows the fixed price, trip summary and countdown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    await tester.pumpWidget(localizedApp(
      BookingConfirmedPage(bookingId: 'abc12345xyz', booking: _booking()),
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
    expect(find.text('Código de reserva: ABC12345'), findsOneWidget);
    expect(find.text('60 min de espera gratuita desde el aterrizaje'), findsOneWidget);
  });

  testWidgets('renders in English', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    await tester.pumpWidget(localizedApp(
      BookingConfirmedPage(bookingId: 'abc12345xyz', booking: _booking()),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('BOOKING CONFIRMED'), findsOneWidget);
    expect(find.text('Your chauffeur will be waiting.'), findsOneWidget);
    expect(find.text('Fixed price · card authorized'), findsOneWidget);
    expect(find.text('Flight OB 760'), findsOneWidget);
    expect(find.text('2 passengers · 3 bags'), findsOneWidget);
    expect(find.textContaining('Pickup in 3 h'), findsOneWidget);
    expect(find.text('VIEW MY BOOKING'), findsOneWidget);
    expect(find.text('Booking reference: ABC12345'), findsOneWidget);
    expect(find.text(LuxMoney.format(1250)), findsOneWidget); // Bs 1,250
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Portuguese without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 1600));
    await tester.pumpWidget(localizedApp(
      BookingConfirmedPage(bookingId: 'abc12345xyz', booking: _booking()),
      locale: const Locale('pt'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Seu motorista estará à sua espera.'), findsOneWidget);
    expect(find.text('2 passageiros · 3 malas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ride type page shows localized services', (tester) async {
    await tester.pumpWidget(localizedApp(const RideTypePage(), locale: const Locale('en')));
    await tester.pump();

    expect(find.text('Choose a service'), findsOneWidget);
    expect(find.text('One way'), findsOneWidget);
    expect(find.text('By the hour'), findsOneWidget);
  });

  test('booking error codes are translated', () {
    final en = AppLocalizationsEn();
    final es = AppLocalizationsEs();
    expect(localizedBookingError(en, BookingErrorCodes.quoteExpired),
        'Your quote has expired. Confirm again to see the updated price.');
    expect(localizedBookingError(es, BookingErrorCodes.createFailed), 'No se pudo crear la reserva');
    expect(localizedBookingError(en, 'Network error'), 'Network error');
  });

  test('LuxMoney formats Bolivianos', () {
    Intl.withLocale('es', () {
      expect(LuxMoney.format(1250), 'Bs 1.250');
      expect(LuxMoney.format(99.5, cents: true), 'Bs 99,50');
    });
  });
}
