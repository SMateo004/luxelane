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

// Lugares de PRUEBA, ficticios.
const _origin =
    Place(name: 'Origen (prueba)', address: 'A', lat: -16.5, lng: -68.1);
const _dest =
    Place(name: 'Destino (prueba)', address: 'B', lat: -16.51, lng: -68.19);

/// Preferencias, B1: en el viaje, el pasajero lee una frase sobria («Tu
/// chófer verá estas preferencias.») con el resumen, sin promesas.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    final now = DateTime.now();
    final ride = Booking(
      id: 'b1',
      riderId: 'ana',
      origin: _origin,
      destination: _dest,
      scheduledAt: now.add(const Duration(minutes: 40)),
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: BookingStatus.confirmed,
      estimatedPrice: 120,
      createdAt: now,
      updatedAt: now,
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
    when(() => prefs.watchBookingPreferences('b1')).thenAnswer(
      (_) => Stream.value(const TripPreferences(
        conversation: ConversationPref.quiet,
        music: MusicStyle.jazz,
      )),
    );
    sl.registerSingleton<PreferencesRepository>(prefs);
  });

  tearDown(() async {
    L10n.use(const Locale('es'));
    await sl.reset();
  });

  for (final (locale, phrase, promise) in [
    (
      const Locale('es'),
      'Tu chófer verá estas preferencias. Prefiero silencio · Jazz',
      'conoce tu estilo',
    ),
    (
      const Locale('en'),
      'Your chauffeur will see these preferences. I prefer quiet · Jazz',
      'knows your style',
    ),
    (
      const Locale('pt'),
      'Seu motorista verá estas preferências. Prefiro silêncio · Jazz',
      'conhece seu estilo',
    ),
  ]) {
    testWidgets('frase sobria en ${locale.languageCode}', (t) async {
      L10n.use(locale);
      t.view.physicalSize = const Size(420, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        theme: luxTheme,
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: const RideScreen(rideId: 'b1'),
      ));
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 2));
      expect(find.text(phrase), findsOneWidget);
      expect(find.textContaining(promise), findsNothing);
    });
  }
}
