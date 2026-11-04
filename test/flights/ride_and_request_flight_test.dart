import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/flight.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/utils/lux_format.dart';
import 'package:luxelane/core/utils/service_area.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/booking/presentation/widgets/flight_step_fields.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_queue_screen.dart';
import 'package:luxelane/features/ride/presentation/pages/ride_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Bookings extends Mock implements BookingRepository {}

class _Trips extends Mock implements TripFlowRepository {}

class _Incidents extends Mock implements IncidentRepository {}

class _Prefs extends Mock implements PreferencesRepository {}

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

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

/// Vuelos, B4 y B5 (hallazgos de las capturas): la nota del vuelo se ve
/// también en el diseño ancho del viaje, y la solicitud abierta dice el
/// aeropuerto y el tipo de vuelo (nunca el número).
void main() {
  tearDown(() async {
    L10n.use(const Locale('es'));
    await sl.reset();
  });

  group('viaje del pasajero', () {
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

    for (final width in [390.0, 768.0, 1280.0]) {
      testWidgets('retrasado: la nota se ve a $width px', (t) async {
        t.view.physicalSize = Size(width, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(
          theme: luxTheme,
          locale: const Locale('es'),
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: const RideScreen(rideId: 'b1'),
        ));
        await t.pump(const Duration(seconds: 2));
        await t.pump(const Duration(seconds: 2));
        expect(find.byType(RiderFlightStatusNote), findsOneWidget);
        expect(find.text(L10n.current.rideFlightDelayed(LuxFormat.time(ready))),
            findsOneWidget);
      });
    }
  });

  group('solicitud abierta del chófer', () {
    Future<void> pump(WidgetTester t, Locale locale, OpenRequest request) {
      L10n.use(locale);
      final driver = _MockDriverBloc();
      when(() => driver.state).thenReturn(DriverLoaded(
        user: User(
          id: 'd',
          email: 'd@example.com',
          phone: '',
          displayName: 'Luis',
          role: UserRole.driver,
          createdAt: DateTime(2026),
          isVerified: true,
          isActive: true,
          fcmTokens: const [],
        ),
        profile: DriverProfile(
          userId: 'd',
          licenseNumber: 'LP-1',
          licenseExpiry: DateTime(2030),
          vehicleId: 'v',
          documentsVerified: true,
          rating: 4.9,
          totalRides: 12,
          isAvailable: true,
        ),
        isAvailable: true,
        bookings: const [],
        pendingRequests: [request],
        vehicleClass: VehicleClass.business,
      ));
      final auth = _MockAuthBloc();
      when(() => auth.state).thenReturn(const AuthUnauthenticated());
      t.view.physicalSize = const Size(390, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      return t.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<DriverBloc>.value(value: driver),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: const DriverQueueScreen(),
        ),
      ));
    }

    OpenRequest request({String? airport, String? type}) => OpenRequest(
          id: 'q1',
          vehicleClass: VehicleClass.business,
          serviceType: ServiceType.oneWay,
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
          estimatedPrice: 150,
          pickupArea: 'Aeropuerto',
          dropoffArea: 'Centro',
          pickupAirport: airport,
          flightType: type,
        );

    for (final (locale, line) in [
      (const Locale('es'), 'Aeropuerto VVI · Nacional'),
      (const Locale('en'), 'Airport VVI · Domestic'),
      (const Locale('pt'), 'Aeroporto VVI · Nacional'),
    ]) {
      testWidgets('aeropuerto y tipo de vuelo en ${locale.languageCode}',
          (t) async {
        await pump(t, locale, request(airport: 'VVI', type: 'domestic'));
        await t.pump(const Duration(milliseconds: 600));
        expect(find.text(line), findsOneWidget);
      });
    }

    testWidgets('sin tipo de vuelo o sin aeropuerto: no hay línea de vuelo',
        (t) async {
      await pump(t, const Locale('es'), request(airport: 'VVI'));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('Aeropuerto VVI'), findsNothing);
      await pump(t, const Locale('es'), request(type: 'domestic'));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('· Nacional'), findsNothing);
    });
  });
}
