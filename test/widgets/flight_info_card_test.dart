import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/utils/lux_format.dart';
import 'package:luxelane/core/utils/service_area.dart';
import 'package:luxelane/features/booking/data/airport_repository.dart';
import 'package:luxelane/features/driver/presentation/widgets/flight_info_card.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Tarjeta «Vuelo» del chófer (Parte B de vuelos). Datos FICTICIOS.
class _Flights implements DriverFlightSource {
  _Flights(this.value);
  final FlightInfo? value;
  @override
  Stream<FlightInfo?> watch(String bookingId) => Stream.value(value);
}

class _Airports implements AirportRepository {
  _Airports(this.value);
  final Airport? value;
  @override
  Stream<Airport?> watch(String code) => Stream.value(value);
}

final _ready = DateTime(2026, 11, 20, 14, 25);
final _sched = DateTime(2026, 11, 20, 14);

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

FlightInfo _flight({
  FlightStatus status = FlightStatus.delayed,
  FlightDataQuality quality = FlightDataQuality.ok,
  DateTime? estimated,
}) =>
    FlightInfo(
      airportCode: 'VVI',
      flightType: FlightType.domestic,
      airline: 'Aerolínea de prueba',
      flightNumber: 'ZZ123',
      flightDate: '2026-11-20',
      scheduledArrival: _sched,
      estimatedArrival: estimated,
      status: status,
      dataQuality: quality,
      readyAt: _ready,
    );

const _point = PickupPoint(
  name: 'Salida nacional (ficticia)',
  instructions: 'Frente a la puerta 1 (prueba)',
  lat: -17.64,
  lng: -63.13,
);

Future<void> _pump(
  WidgetTester t,
  Booking b, {
  FlightInfo? flight,
  Airport? airport,
  Locale locale = const Locale('es'),
}) {
  L10n.use(locale);
  return t.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: LuxLocale.supportedLocales,
    localizationsDelegates: LuxLocale.delegates,
    home: Scaffold(
      body: FlightInfoCard(
        booking: b,
        flights: _Flights(flight),
        airports: _Airports(airport),
      ),
    ),
  ));
}

void main() {
  testWidgets('nada sin vuelo', (t) async {
    await _pump(t, _booking());
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('driver-flight-card')), findsNothing);
  });

  testWidgets(
      'aerolínea, número, estado, hora estimada, «Debes estar a las» y el punto nacional',
      (t) async {
    await _pump(
      t,
      _booking(flight: 'ZZ123', type: 'domestic', airport: 'VVI'),
      flight: _flight(estimated: _sched.add(const Duration(minutes: 40))),
      airport: const Airport(
          code: 'VVI',
          name: 'Aeropuerto (prueba)',
          city: 'Santa Cruz',
          domestic: _point),
    );
    await t.pumpAndSettle();
    final l = L10n.current;
    expect(find.text('Vuelo · Aerolínea de prueba · ZZ123'), findsOneWidget);
    expect(
        find.text(l.driverFlightStatus(l.flightStatusDelayed)), findsOneWidget);
    expect(
        find.text(l.flightEstimatedArrival(
            LuxFormat.time(_sched.add(const Duration(minutes: 40))))),
        findsOneWidget);
    expect(
        find.text(l.flightBeAtPointAt(LuxFormat.time(_ready))), findsOneWidget);
    expect(find.text('Salida nacional (ficticia)'), findsOneWidget);
    expect(find.text('Frente a la puerta 1 (prueba)'), findsOneWidget);
    expect(find.textContaining('Sin datos de vuelo'), findsNothing);
  });

  testWidgets('sin datos en vivo lo dice con la hora programada', (t) async {
    await _pump(
      t,
      _booking(flight: 'ZZ123', type: 'domestic', airport: 'VVI'),
      flight: _flight(
          status: FlightStatus.scheduled, quality: FlightDataQuality.none),
    );
    await t.pumpAndSettle();
    expect(find.text(L10n.current.flightNoLiveData(LuxFormat.time(_sched))),
        findsOneWidget);
  });

  testWidgets(
      'sin punto definido para el tipo: «Punto por confirmar con central» (no se inventa una salida)',
      (t) async {
    await _pump(
      t,
      _booking(flight: 'ZZ123', type: 'international', airport: 'VVI'),
      airport: const Airport(
          code: 'VVI',
          name: 'Aeropuerto (prueba)',
          city: 'x',
          domestic: _point),
    );
    await t.pumpAndSettle();
    expect(find.text(L10n.current.flightPickupPointPending), findsOneWidget);
    expect(find.text('Salida nacional (ficticia)'), findsNothing);
    expect(find.text('Salida de llegadas internacionales'), findsNothing);
  });

  testWidgets('en inglés y portugués, sin textos en español', (t) async {
    for (final loc in const [Locale('en'), Locale('pt')]) {
      await _pump(
        t,
        _booking(flight: 'ZZ123', type: 'domestic', airport: 'VVI'),
        flight: _flight(),
        locale: loc,
      );
      await t.pumpAndSettle();
      expect(find.text(L10n.current.flightPickupPointPending), findsOneWidget);
      expect(find.textContaining('Debes estar'), findsNothing);
    }
  });

  testWidgets('el enlace para ver el vuelo avisa antes de abrir', (t) async {
    await _pump(t, _booking(flight: 'OB760', type: 'domestic', airport: 'VVI'));
    await t.pumpAndSettle();
    await t.tap(find.text(L10n.current.driverFlightCheckStatus));
    await t.pumpAndSettle();
    expect(find.text('Primero cambia de aeropuerto'), findsOneWidget);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
  });
}
