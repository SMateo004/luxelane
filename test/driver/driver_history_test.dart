import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/driver_trip.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/driver/data/driver_history_repository.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_home_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _Bookings extends Mock implements BookingRepository {}

class _Users extends Mock implements UserRepository {}

class _Maps extends Mock implements MapsService {}

class _Vehicles extends Mock implements VehicleRepository {}

class _Trips extends Mock implements TripFlowRepository {}

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Historial falso: un stream que controla el test.
class _History implements DriverHistoryRepository {
  final controllers = <StreamController<List<DriverTripSummary>>>[];
  @override
  Future<DriverTripSummary?> getTrip(String driverId, String bookingId) async =>
      null;
  @override
  Stream<List<DriverTripSummary>> watchCompletedTrips(String driverId) {
    final c = StreamController<List<DriverTripSummary>>();
    controllers.add(c);
    return c.stream;
  }
}

final _now = DateTime.now();
final _user = User(
  id: 'luis',
  email: 'luis@prueba.test',
  phone: '',
  displayName: 'Luis (prueba)',
  role: UserRole.driver,
  createdAt: _now,
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);
final _profile = DriverProfile(
  userId: 'luis',
  licenseNumber: 'L-1',
  licenseExpiry: DateTime(2030),
  vehicleId: 'v',
  documentsVerified: true,
  rating: 4.9,
  totalRides: 3,
  isAvailable: true,
);

/// Viaje completado FICTICIO de 100 Bs con 20 % de comisión.
DriverTripSummary _trip(String id, DateTime endedAt) => DriverTripSummary(
      bookingId: id,
      status: BookingStatus.completed,
      endedAt: endedAt,
      estimatedPrice: 100,
      settlement: const BookingSettlement(
        amount: 100,
        commissionPct: 20,
        platformCommission: 20,
        driverPayout: 80,
      ),
    );

DriverLoaded _loaded({List<DriverTripSummary>? history, bool failed = false}) =>
    DriverLoaded(
      user: _user,
      profile: _profile,
      isAvailable: true,
      bookings: const [],
      history: history,
      historyFailed: failed,
      vehicleClass: VehicleClass.business,
    );

/// Ventana del chófer, B1: el historial (driverHistory) alimenta las
/// ganancias; carga, error y reintento.
void main() {
  group('DriverBloc y el historial', () {
    late _History history;
    DriverBloc bloc() => DriverBloc(
          bookingRepository: _Bookings(),
          tripFlowRepository: _Trips(),
          userRepository: _Users(),
          vehicleRepository: _Vehicles(),
          mapsService: _Maps(),
          historyRepository: history,
        );
    setUp(() => history = _History());

    blocTest<DriverBloc, DriverState>(
      'los datos del historial llegan al estado; hoy suma solo lo de hoy',
      build: bloc,
      seed: _loaded,
      act: (b) async {
        b.add(const DriverHistoryWatched(driverId: 'luis'));
        await Future<void>.delayed(Duration.zero);
        history.controllers.single.add([
          _trip('hoy', _now),
          _trip('ayer', _now.subtract(const Duration(days: 1))),
        ]);
        await Future<void>.delayed(Duration.zero);
      },
      verify: (b) {
        final s = b.state as DriverLoaded;
        expect(s.history, hasLength(2));
        expect(s.historyFailed, isFalse);
        expect(s.completedToday.map((t) => t.bookingId), ['hoy']);
        expect(s.todayEarnings, 80);
        expect(s.totalEarnings, 160);
      },
    );

    blocTest<DriverBloc, DriverState>(
      'un error del historial se marca; reintentar vuelve a escuchar y lo limpia',
      build: bloc,
      seed: _loaded,
      act: (b) async {
        b.add(const DriverHistoryWatched(driverId: 'luis'));
        await Future<void>.delayed(Duration.zero);
        history.controllers.single.addError(Exception('permission-denied'));
        await Future<void>.delayed(Duration.zero);
        expect((b.state as DriverLoaded).historyFailed, isTrue);
        b.add(const DriverHistoryWatched(driverId: 'luis'));
        await Future<void>.delayed(Duration.zero);
        history.controllers.last.add([_trip('a', _now)]);
        await Future<void>.delayed(Duration.zero);
      },
      verify: (b) {
        final s = b.state as DriverLoaded;
        expect(history.controllers, hasLength(2));
        expect(s.historyFailed, isFalse);
        expect(s.history, hasLength(1));
      },
    );
  });

  group('«Ganancias de hoy» del inicio', () {
    Future<void> pump(WidgetTester t, DriverLoaded s, {Locale? locale}) async {
      if (locale != null) L10n.use(locale);
      final driver = _MockDriverBloc();
      when(() => driver.state).thenReturn(s);
      final auth = _MockAuthBloc();
      when(() => auth.state).thenReturn(const AuthUnauthenticated());
      t.view.physicalSize = const Size(390, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<DriverBloc>.value(value: driver),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: MaterialApp(
          locale: locale ?? const Locale('es'),
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: const DriverHomeScreen(),
        ),
      ));
      await t.pump(const Duration(milliseconds: 600));
    }

    tearDown(() => L10n.use(const Locale('es')));

    testWidgets('con historial: lo neto de hoy y los viajes de hoy', (t) async {
      await pump(
          t,
          _loaded(history: [
            _trip('hoy', _now),
            _trip('ayer', _now.subtract(const Duration(days: 1))),
          ]));
      expect(find.text('Bs 80'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('vacío: cero, sin error', (t) async {
      await pump(t, _loaded(history: const []));
      expect(find.text('Bs 0'), findsOneWidget);
      expect(find.text(L10n.current.driverHistoryLoadFailed), findsNothing);
    });

    testWidgets('cargando: «—» (no un cero) y el lector dice que carga',
        (t) async {
      final h = t.ensureSemantics();
      await pump(t, _loaded());
      // La entrada del inicio se anima: sin terminarla no hay semántica.
      await t.pump(const Duration(seconds: 2));
      expect(find.text('Bs 0'), findsNothing);
      expect(find.text('—'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp(L10n.current.driverHistoryLoading)),
          findsOneWidget);
      h.dispose();
    });

    testWidgets('error: aviso con «Reintentar» (48 px)', (t) async {
      final h = t.ensureSemantics();
      await pump(t, _loaded(failed: true));
      expect(find.text(L10n.current.driverHistoryLoadFailed), findsOneWidget);
      expect(find.text(L10n.current.driverRetry), findsOneWidget);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });

    testWidgets('error en inglés y portugués', (t) async {
      await pump(t, _loaded(failed: true), locale: const Locale('en'));
      expect(
          find.text("We couldn't load your completed trips."), findsOneWidget);
      await pump(t, _loaded(failed: true), locale: const Locale('pt'));
      expect(find.text('Não foi possível carregar suas viagens concluídas.'),
          findsOneWidget);
    });
  });
}
