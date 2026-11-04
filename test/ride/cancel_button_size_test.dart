import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/utils/service_area.dart';
import 'package:luxelane/features/ride/presentation/pages/ride_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Bookings extends Mock implements BookingRepository {}

class _Trips extends Mock implements TripFlowRepository {}

class _Incidents extends Mock implements IncidentRepository {}

class _Prefs extends Mock implements PreferencesRepository {}

class _NoRoute extends MapsService {
  @override
  Future<RouteInfo?> getRoute({
    required Place origin,
    required Place destination,
  }) async =>
      null;
}

// Lugares y vuelo de PRUEBA, ficticios.
const _origin =
    Place(name: 'Aeropuerto (prueba)', address: 'A', lat: -17.64, lng: -63.13);
const _dest =
    Place(name: 'Centro (prueba)', address: 'B', lat: -17.78, lng: -63.18);

/// Vuelos, revisión de la Parte B: la auditoría de las capturas marcó
/// «Cancelar reserva» con 27 px de alto, pero era el botón cortado por el
/// borde de la ventana. Mide 48 px (LuxButton.ghost); este test lo fija a
/// 390 y 1280 px y con el texto al 200 %.
void main() {
  tearDown(() async {
    L10n.use(const Locale('es'));
    await sl.reset();
  });

  group('viaje del pasajero: botón «Cancelar reserva»', () {
    late DateTime ready;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      final now = DateTime.now();
      ready = now.add(const Duration(hours: 3));
      final ride = Booking(
        id: 'b1',
        riderId: 'ana',
        origin: _origin,
        destination: _dest,
        scheduledAt: ready,
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        status: BookingStatus.confirmed,
        estimatedPrice: 120,
        createdAt: now,
        updatedAt: now,
        flight: FlightInfo(
          airportCode: 'VVI',
          flightType: FlightType.domestic,
          flightNumber: 'ZZ1',
          flightDate: '2026-11-20',
          scheduledArrival: now.add(const Duration(hours: 1)),
          estimatedArrival: now.add(const Duration(hours: 2, minutes: 30)),
          status: FlightStatus.delayed,
          dataQuality: FlightDataQuality.ok,
          readyAt: ready,
        ),
      );
      final bookings = _Bookings();
      when(() => bookings.watchBooking(any()))
          .thenAnswer((_) => Stream.value(ride));
      when(() => bookings.watchDriverPhone(any()))
          .thenAnswer((_) => const Stream.empty());
      when(() => bookings.watchDriverLocation(any()))
          .thenAnswer((_) => const Stream.empty());
      sl.registerSingleton<BookingRepository>(bookings);
      sl.registerSingleton<MapsService>(_NoRoute());
      final trips = _Trips();
      when(() => trips.getPickupCode(any())).thenAnswer(
        (_) async => Right(PickupCode(code: '4207', expiresAt: now)),
      );
      sl.registerSingleton<TripFlowRepository>(trips);
      final incidents = _Incidents();
      when(() => incidents.watchMine(any(), any()))
          .thenAnswer((_) => Stream.value(null));
      sl.registerSingleton<IncidentRepository>(incidents);
      final prefs = _Prefs();
      when(() => prefs.watchBookingPreferences(any()))
          .thenAnswer((_) => Stream.value(null));
      sl.registerSingleton<PreferencesRepository>(prefs);
    });

    for (final (width, scale) in [(390.0, 1.0), (390.0, 2.0), (1280.0, 1.0)]) {
      testWidgets(
          '«Cancelar reserva» mide al menos 48 px ($width px, texto x$scale)',
          (t) async {
        final h = t.ensureSemantics();
        t.view.physicalSize = Size(width, 2400);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(
          theme: luxTheme,
          locale: const Locale('es'),
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 2400),
                  textScaler: TextScaler.linear(scale)),
              child: const RideScreen(rideId: 'b1')),
        ));
        await t.pump(const Duration(seconds: 2));
        await t.pump(const Duration(seconds: 2));
        final b = find.bySemanticsLabel(RegExp('Cancelar reserva'));
        expect(b, findsOneWidget);
        expect(t.getSize(b).height, greaterThanOrEqualTo(48));
        expect(t.getSemantics(b), containsSemantics(isButton: true));
        h.dispose();
      });
    }
  });
}
