import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/driver_trip.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/driver/data/driver_history_repository.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_active_ride_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _Bookings extends Mock implements BookingRepository {}

class _Users extends Mock implements UserRepository {}

class _Maps extends Mock implements MapsService {}

class _Vehicles extends Mock implements VehicleRepository {}

class _Trips extends Mock implements TripFlowRepository {}

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

/// Historial falso: devuelve el resumen que se le dé (o null).
class _History implements DriverHistoryRepository {
  _History(this.status);
  BookingStatus? status;
  int calls = 0;
  @override
  Future<DriverTripSummary?> getTrip(String driverId, String bookingId) async {
    calls++;
    final s = status;
    return s == null
        ? null
        : DriverTripSummary(bookingId: bookingId, status: s);
  }
}

final _now = DateTime(2026, 11, 20);
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

Booking _trip(BookingStatus status) => Booking(
      id: 'b1',
      riderId: 'ana',
      driverId: 'luis',
      origin: const Place(address: 'Origen (prueba)', lat: -17.6, lng: -63.1),
      destination:
          const Place(address: 'Destino (prueba)', lat: -17.7, lng: -63.2),
      scheduledAt: _now,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: 120,
      createdAt: _now,
      updatedAt: _now,
    );

DriverLoaded _loaded(List<Booking> bookings,
        {Map<String, BookingStatus?> closed = const {}}) =>
    DriverLoaded(
      user: _user,
      profile: _profile,
      isAvailable: true,
      bookings: bookings,
      isTracking: true,
      closedTrips: closed,
    );

/// Ventana del chófer, A4: cuando la reserva sale de la ventana del chófer
/// (la consulta acotada ya no la trae: las reglas no le dejan leerla), la
/// app lo trata como fin de viaje normal, no como error.
void main() {
  late _Bookings bookings;
  late _Trips trips;
  late _Maps maps;
  late StreamController<List<Booking>> list;

  setUpAll(() => registerFallbackValue(BookingStatus.confirmed));

  setUp(() {
    bookings = _Bookings();
    trips = _Trips();
    maps = _Maps();
    list = StreamController<List<Booking>>();
    when(() => bookings.watchDriverBookings(any()))
        .thenAnswer((_) => list.stream);
    when(() => maps.driverPositionStream())
        .thenAnswer((_) => const Stream.empty());
    when(() => trips.advance(
          bookingId: any(named: 'bookingId'),
          to: any(named: 'to'),
          location: any(named: 'location'),
        )).thenAnswer((_) async => const Right(null));
  });
  // Sin esperar: en las pruebas de pantalla nadie escucha el stream y
  // close() no terminaría nunca.
  tearDown(() {
    unawaited(list.close());
  });

  DriverBloc bloc(_History history) => DriverBloc(
        bookingRepository: bookings,
        tripFlowRepository: trips,
        userRepository: _Users(),
        vehicleRepository: _Vehicles(),
        mapsService: maps,
        historyRepository: history,
        historyRetryDelays: const [Duration(milliseconds: 1)],
      );

  group('consulta del chófer', () {
    test('la ventana de la app es la de firestore.rules (inDriverWindow)', () {
      final rules = File('firestore.rules').readAsStringSync();
      final m = RegExp(
              r'function inDriverWindow\(status\) \{\s*return status in\s*\[([^\]]*)\]')
          .firstMatch(rules);
      expect(m, isNotNull);
      final fromRules = RegExp("'([a-z_]+)'")
          .allMatches(m!.group(1)!)
          .map((x) => x.group(1))
          .toList();
      expect(fromRules, [for (final s in kDriverWindowStatuses) s.label]);
    });

    test('watchDriverBookings filtra por los estados de la ventana', () {
      final src = File(
              'lib/features/booking/data/repositories/booking_repository_impl.dart')
          .readAsStringSync();
      final i = src.indexOf('watchDriverBookings(String driverId)');
      final body = src.substring(i, src.indexOf('.snapshots()', i));
      expect(body, contains("where('driverId', isEqualTo: driverId)"));
      expect(
          body,
          contains(
              'whereIn: [for (final s in kDriverWindowStatuses) s.label]'));
    });
  });

  group('DriverBloc', () {
    blocTest<DriverBloc, DriverState>(
      'el chófer completa: la respuesta de advanceBooking marca el cierre y '
      'que la reserva salga de la lista no es un error',
      build: () => bloc(_History(null)),
      seed: () => _loaded([_trip(BookingStatus.inProgress)]),
      act: (b) async {
        b.add(const DriverBookingsWatched(driverId: 'luis'));
        list.add([_trip(BookingStatus.inProgress)]);
        await Future<void>.delayed(Duration.zero);
        b.add(const DriverTripCompleted(bookingId: 'b1'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        list.add(const []);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (b) {
        final s = b.state as DriverLoaded;
        expect(s.bookings, isEmpty);
        expect(s.closedTrips, {'b1': BookingStatus.completed});
        expect(s.notice, isNull);
      },
    );

    for (final final_ in [BookingStatus.cancelled, BookingStatus.noShow]) {
      blocTest<DriverBloc, DriverState>(
        'cerrada por otro (${final_.label}) con el chófer mirando: '
        'el estado final sale del resumen del historial',
        build: () => bloc(_History(final_)),
        seed: () => _loaded([_trip(BookingStatus.driverArriving)]),
        act: (b) async {
          b.add(const DriverBookingsWatched(driverId: 'luis'));
          list.add([_trip(BookingStatus.driverArriving)]);
          await Future<void>.delayed(Duration.zero);
          list.add(const []);
          await Future<void>.delayed(const Duration(milliseconds: 20));
        },
        verify: (b) {
          final s = b.state as DriverLoaded;
          expect(s.closedTrips, {'b1': final_});
          expect(s.notice, isNull);
        },
      );
    }

    blocTest<DriverBloc, DriverState>(
      'sin resumen (p. ej. reasignada a otro chófer): queda cerrada sin estado, '
      'tras los reintentos',
      build: () => bloc(_History(null)),
      seed: () => _loaded([_trip(BookingStatus.confirmed)]),
      act: (b) async {
        b.add(const DriverBookingsWatched(driverId: 'luis'));
        list.add([_trip(BookingStatus.confirmed)]);
        await Future<void>.delayed(Duration.zero);
        list.add(const []);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      verify: (b) {
        final s = b.state as DriverLoaded;
        expect(s.closedTrips.containsKey('b1'), isTrue);
        expect(s.closedTrips['b1'], isNull);
      },
    );
  });

  group('pantalla del viaje', () {
    Future<void> pump(WidgetTester t, DriverState state,
        {Locale locale = const Locale('es')}) async {
      L10n.use(locale);
      final b = _MockDriverBloc();
      when(() => b.state).thenReturn(state);
      await t.pumpWidget(MaterialApp(
        theme: luxTheme,
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: BlocProvider<DriverBloc>.value(
          value: b,
          child: const DriverActiveRideScreen(bookingId: 'b1'),
        ),
      ));
      await t.pump();
    }

    tearDown(() => L10n.use(const Locale('es')));

    for (final (status, title) in [
      (BookingStatus.completed, 'Viaje terminado'),
      (BookingStatus.cancelled, 'El viaje se canceló'),
      (BookingStatus.noShow, 'Marcaste que el pasajero no se presentó'),
      (null, 'Este viaje ya no está a tu cargo'),
    ]) {
      testWidgets(
          'cierre ${status?.label ?? 'sin estado'}: «$title», sin error',
          (t) async {
        await pump(t, _loaded(const [], closed: {'b1': status}));
        expect(find.text(title), findsOneWidget);
        expect(find.text('Volver a solicitudes'), findsOneWidget);
        expect(find.text(L10n.current.driverTripNotFound), findsNothing);
      });
    }

    testWidgets('en inglés y en portugués', (t) async {
      await pump(t, _loaded(const [], closed: {'b1': BookingStatus.completed}),
          locale: const Locale('en'));
      expect(find.text('Trip completed'), findsOneWidget);
      await pump(t, _loaded(const [], closed: {'b1': BookingStatus.cancelled}),
          locale: const Locale('pt'));
      expect(find.text('A viagem foi cancelada'), findsOneWidget);
    });

    testWidgets('una reserva que nunca tuvo: sigue siendo «no encontrado»',
        (t) async {
      await pump(t, _loaded(const []));
      expect(find.text(L10n.current.driverTripNotFound), findsOneWidget);
    });

    testWidgets('el botón de volver mide al menos 48 px y es un botón',
        (t) async {
      final h = t.ensureSemantics();
      await pump(t, _loaded(const [], closed: {'b1': BookingStatus.completed}));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });
  });
}
