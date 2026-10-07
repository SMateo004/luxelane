import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/widgets/lux_states.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_confirmed_page.dart';
import 'package:luxelane/features/trips/presentation/pages/receipt_page.dart';

import 'helpers/l10n.dart';

Booking _hourly({int days = 3, int hours = 8}) {
  final at = DateTime(2026, 10, 7, 9, 30);
  return Booking(
    id: 'RCPT1234XYZ',
    riderId: 'r',
    origin: const Place(address: 'Hotel Los Tajibos', lat: 0, lng: 0),
    destination: const Place(address: 'Hotel Los Tajibos', lat: 0, lng: 0),
    scheduledAt: at,
    vehicleClass: VehicleClass.business,
    serviceType: ServiceType.byTheHour,
    status: BookingStatus.completed,
    estimatedPrice: 1920,
    createdAt: at,
    updatedAt: at,
    hours: hours,
    days: days,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('chauffeur by the day', () {
    test('estimate multiplies the daily price and caps at 7 days', () {
      expect(DefaultPricing.estimate(VehicleClass.business, ServiceType.byTheHour, hours: 8), 640);
      expect(DefaultPricing.estimate(VehicleClass.business, ServiceType.byTheHour, hours: 8, days: 3), 1920);
      // Minimum applies per day (2 h × Bs 80 = 160).
      expect(DefaultPricing.estimate(VehicleClass.business, ServiceType.byTheHour, hours: 1, days: 2), 320);
      expect(DefaultPricing.estimate(VehicleClass.business, ServiceType.byTheHour, hours: 8, days: 30), 640 * 7);
      // Days never change one-way prices.
      expect(DefaultPricing.estimate(VehicleClass.business, ServiceType.oneWay, km: 10, days: 3), 80);
    });

    test('quote and booking read days (default 1)', () {
      expect(Quote.fromJson({'quoteId': 'q', 'amount': 1920, 'expiresAt': 0, 'days': 3}).days, 3);
      expect(Quote.fromJson({'quoteId': 'q', 'amount': 100, 'expiresAt': 0}).days, 1);
    });

    testWidgets('price breakdown shows days × hours × rate', (tester) async {
      await tester.pumpWidget(localizedApp(const Scaffold(
        body: PriceBreakdown(vehicleClass: VehicleClass.business, serviceType: ServiceType.byTheHour, hours: 8, days: 3),
      )));
      expect(find.text('3 días × 8 h × Bs 80'), findsOneWidget);
      expect(find.text('Bs 1.920'), findsOneWidget);
    });

    testWidgets('receipt shows the days (en)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(localizedApp(ReceiptPage(bookingId: 'x', booking: _hourly()), locale: const Locale('en')));
      expect(find.text('3 days · 8 h per day'), findsOneWidget);
    });
  });

  group('return trip', () {
    test('suggested time is 4 h later on a quarter hour', () {
      expect(suggestedReturnTime(DateTime(2026, 10, 7, 9, 30)), DateTime(2026, 10, 7, 13, 30));
      expect(suggestedReturnTime(DateTime(2026, 10, 7, 9, 31)), DateTime(2026, 10, 7, 13, 45));
      expect(suggestedReturnTime(DateTime(2026, 10, 7, 22, 50)), DateTime(2026, 10, 8, 3));
    });

    test('booking keeps the quoted distance for the reverse route', () {
      final place = {'address': 'A', 'coordinates': const GeoPoint(-17.7, -63.1)};
      final b = Booking.fromJson({'id': 'b', 'distanceKm': 18.4, 'status': 'pending', 'origin': place, 'destination': place});
      expect(b.distanceKm, 18.4);
      expect(b.days, 1);
    });
  });
}
