import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/driver/presentation/widgets/flight_info_card.dart';

Booking _booking({String? flight, String? type, String? airport}) {
  final ts = Timestamp.fromDate(DateTime(2026, 10, 10, 12));
  return Booking.fromJson({
    'id': 'b1',
    'riderId': 'r1',
    'origin': {
      'name': 'Aeropuerto Internacional Viru Viru',
      'address': 'Warnes, Santa Cruz',
      'coordinates': const GeoPoint(-17.6447, -63.1353),
    },
    'destination': {
      'address': 'Equipetrol',
      'coordinates': const GeoPoint(-17.7650, -63.1960),
    },
    'scheduledAt': ts,
    'createdAt': ts,
    'updatedAt': ts,
    'status': 'confirmed',
    'estimatedPrice': 120.0,
    'flightNumber': flight,
    'flightType': type,
    'pickupAirport': airport,
  });
}

Widget _wrap(Booking b) => MaterialApp(
      home: Scaffold(body: FlightInfoCard(booking: b)),
    );

void main() {
  testWidgets('renders nothing without a flight', (tester) async {
    await tester.pumpWidget(_wrap(_booking()));
    expect(find.textContaining('Vuelo'), findsNothing);
  });

  testWidgets('shows the arrivals exit for the flight type', (tester) async {
    await tester.pumpWidget(_wrap(
        _booking(flight: 'OB760', type: 'international', airport: 'VVI')));
    expect(find.text('Aeropuerto Internacional Viru Viru'), findsOneWidget);
    expect(find.text('INTERNACIONAL'), findsOneWidget);
    expect(find.text('Salida de llegadas internacionales'), findsOneWidget);
    expect(find.text('Vuelo OB760'), findsOneWidget);
  });

  testWidgets('tapping the flight warns to switch airport first',
      (tester) async {
    await tester.pumpWidget(
        _wrap(_booking(flight: 'OB760', type: 'domestic', airport: 'VVI')));
    await tester.tap(find.text('Vuelo OB760'));
    await tester.pumpAndSettle();

    expect(find.text('Primero cambia de aeropuerto'), findsOneWidget);
    expect(
        find.textContaining(
            'Aeropuerto Internacional Viru Viru (Santa Cruz de la Sierra)'),
        findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Primero cambia de aeropuerto'), findsNothing);
  });
}
