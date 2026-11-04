import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/driver_trip.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_earnings_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

final _now = DateTime(2026, 10, 10, 12);

final _user = User(
  id: 'd',
  email: 'd@example.com',
  phone: '',
  displayName: 'Luis',
  role: UserRole.driver,
  createdAt: _now,
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);
final _profile = DriverProfile(
  userId: 'd',
  licenseNumber: 'LP-1',
  licenseExpiry: _now,
  vehicleId: 'v',
  documentsVerified: true,
  rating: 5,
  totalRides: 2,
  isAvailable: true,
);

/// Resumen FICTICIO del historial: solo zona, sin dirección exacta.
DriverTripSummary _t(String id, {BookingSettlement? settlement}) =>
    DriverTripSummary(
      bookingId: id,
      status: BookingStatus.completed,
      endedAt: _now,
      serviceType: ServiceType.oneWay,
      pickupArea: 'Aeropuerto',
      dropoffArea: 'La Paz',
      estimatedPrice: 100,
      settlement: settlement,
    );

/// Una reserva completada con dirección exacta: la pantalla ya no la usa.
Booking _booking() => Booking(
      id: 'vieja',
      riderId: 'r',
      driverId: 'd',
      origin: const Place(address: 'Aeropuerto El Alto', lat: 0, lng: 0),
      destination:
          const Place(address: 'Av. Ballivián, Calacoto', lat: 0, lng: 0),
      scheduledAt: _now,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: BookingStatus.completed,
      estimatedPrice: 100,
      createdAt: _now,
      updatedAt: _now,
    );

DriverLoaded _state({
  List<DriverTripSummary>? history,
  bool failed = false,
  List<Booking> bookings = const [],
}) =>
    DriverLoaded(
      user: _user,
      profile: _profile,
      isAvailable: true,
      bookings: bookings,
      history: history,
      historyFailed: failed,
    );

/// Ventana del chófer, B1: la pantalla de ganancias lee el historial
/// (driverHistory), con estados de carga, error y vacío.
void main() {
  late _MockDriverBloc bloc;

  Future<void> pump(WidgetTester tester, DriverState state,
      {Locale locale = const Locale('es')}) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    L10n.use(locale);
    bloc = _MockDriverBloc();
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: BlocProvider<DriverBloc>.value(
          value: bloc,
          child: const DriverEarningsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  tearDown(() => L10n.use(const Locale('es')));

  testWidgets('muestra ganancias netas, comisión y viajes provisionales',
      (tester) async {
    await pump(
      tester,
      _state(history: [
        _t(
          'a',
          settlement: const BookingSettlement(
            amount: 100,
            commissionPct: 10,
            platformCommission: 10,
            driverPayout: 90,
          ),
        ),
        _t('b'),
      ]),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Bs 170'), findsOneWidget); // 90 + 80
    expect(find.text('Bs 200'), findsOneWidget); // tarifas
    expect(find.text('− Bs 30'), findsOneWidget); // 10 + 20
    expect(find.text('Bs 90'), findsOneWidget);
    expect(find.text('Bs 80'), findsOneWidget);
    expect(find.text('Provisional'), findsOneWidget);
  });

  testWidgets('cada viaje muestra la zona, no la dirección exacta',
      (tester) async {
    await pump(tester, _state(history: [_t('a')]));
    expect(find.text('La Paz'), findsOneWidget);
    expect(find.textContaining('Ballivián'), findsNothing);
  });

  testWidgets('ya no usa las reservas: con historial vacío, estado vacío',
      (tester) async {
    await pump(tester, _state(history: const [], bookings: [_booking()]));
    expect(find.text(L10n.current.driverEarningsEmpty), findsOneWidget);
    expect(find.textContaining('Ballivián'), findsNothing);
  });

  testWidgets('cargando: esqueleto con etiqueta para el lector de pantalla',
      (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, _state());
    expect(find.bySemanticsLabel(L10n.current.driverHistoryLoading),
        findsOneWidget);
    expect(find.text(L10n.current.driverEarningsEmpty), findsNothing);
    h.dispose();
  });

  testWidgets('error sin datos: mensaje y «Reintentar» vuelve a escuchar',
      (tester) async {
    await pump(tester, _state(failed: true));
    expect(find.text(L10n.current.driverHistoryLoadFailed), findsOneWidget);
    await tester.tap(find.text(L10n.current.driverRetry));
    verify(() => bloc.add(const DriverHistoryWatched(driverId: 'd'))).called(1);
  });

  testWidgets('error con datos ya cargados: aviso sin tapar la lista',
      (tester) async {
    await pump(tester, _state(history: [_t('a')], failed: true));
    expect(find.text(L10n.current.driverHistoryLoadFailed), findsOneWidget);
    expect(find.text('La Paz'), findsOneWidget);
  });

  testWidgets('textos en inglés y portugués', (tester) async {
    await pump(tester, _state(failed: true), locale: const Locale('en'));
    expect(find.text("We couldn't load your completed trips."), findsOneWidget);
    await pump(tester, _state(failed: true), locale: const Locale('pt'));
    expect(find.text('Não foi possível carregar suas viagens concluídas.'),
        findsOneWidget);
  });

  testWidgets('botones de 48 px y etiquetados', (tester) async {
    final h = tester.ensureSemantics();
    await pump(tester, _state(failed: true));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });
}
