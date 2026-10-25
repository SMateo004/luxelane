// Los stubs nombran los argumentos que la app manda explícitamente, aunque
// coincidan con el valor por defecto (si no, mocktail no los empareja).
// ignore_for_file: avoid_redundant_argument_values

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_step_action.dart';
import 'package:luxelane/features/ride/data/repositories/trip_flow_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

class _Booking extends Mock implements BookingRepository {}

class _Users extends Mock implements UserRepository {}

class _Maps extends Mock implements MapsService {}

class _Vehicles extends Mock implements VehicleRepository {}

class _Trip extends Mock implements TripFlowRepository {}

final _now = DateTime(2026, 10, 25, 12);

Booking _b(BookingStatus status, {DateTime? noShowAt}) => Booking(
      id: 'b1',
      riderId: 'ana',
      driverId: 'd1',
      origin: const Place(address: 'Aeropuerto', lat: 0, lng: 0),
      destination: const Place(address: 'Centro', lat: 0, lng: 0),
      scheduledAt: _now,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: 100,
      createdAt: _now,
      updatedAt: _now,
      noShowAvailableAt: noShowAt,
    );

final _user = User(
  id: 'd1',
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
  userId: 'd1',
  licenseNumber: 'L',
  vehicleId: 'v1',
  rating: 5,
  totalRides: 0,
  licenseExpiry: DateTime(2030),
  documentsVerified: true,
  isAvailable: false,
);

Position _pos() => Position(
      latitude: -17.64,
      longitude: -63.13,
      timestamp: _now,
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// B4–B6 en la app del chófer: «el pasajero no aparece» y liberar el viaje.
void main() {
  setUpAll(() {
    registerFallbackValue(BookingStatus.pending);
    registerFallbackValue(const DriverRiderNoShow(bookingId: 'x'));
  });

  group('DriverBloc', () {
    late _Trip trip;
    late _Users users;
    late _Maps maps;

    setUp(() {
      trip = _Trip();
      users = _Users();
      maps = _Maps();
      when(
        () => trip.advance(
          bookingId: any(named: 'bookingId'),
          to: any(named: 'to'),
          location: any(named: 'location'),
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => trip.release(
          bookingId: any(named: 'bookingId'),
          reason: any(named: 'reason'),
          location: any(named: 'location'),
        ),
      ).thenAnswer((_) async => const Right(null));
      when(() => maps.driverPositionStream())
          .thenAnswer((_) => Stream.value(_pos()));
      when(
        () => users.updateDriverLocation(
          userId: any(named: 'userId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Right(null));
    });

    DriverBloc bloc() => DriverBloc(
          bookingRepository: _Booking(),
          tripFlowRepository: trip,
          userRepository: users,
          vehicleRepository: _Vehicles(),
          mapsService: maps,
        )..emit(
            DriverLoaded(
              user: _user,
              profile: _profile,
              isAvailable: false,
              bookings: const [],
            ),
          );

    blocTest<DriverBloc, DriverState>(
      'no aparece sin ubicación: lo pide y no llama al servidor',
      build: bloc,
      act: (b) => b.add(const DriverRiderNoShow(bookingId: 'b1')),
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.notice, 'notice', contains('Activa la ubicación')),
      ],
      verify: (_) => verifyNever(
        () => trip.advance(
          bookingId: any(named: 'bookingId'),
          to: any(named: 'to'),
          location: any(named: 'location'),
        ),
      ),
    );

    blocTest<DriverBloc, DriverState>(
      'no aparece con ubicación: advanceBooking a no_show con la ubicación',
      build: bloc,
      act: (b) async {
        b.add(const DriverLocationTrackingStarted(userId: 'd1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        b.add(const DriverRiderNoShow(bookingId: 'b1'));
      },
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.notice, 'notice', contains('Avisamos a central')),
      ],
      verify: (_) => verify(
        () => trip.advance(
          bookingId: 'b1',
          to: BookingStatus.noShow,
          location: (lat: -17.64, lng: -63.13),
        ),
      ).called(1),
    );

    blocTest<DriverBloc, DriverState>(
      'liberar: releaseBooking con el motivo',
      build: bloc,
      act: (b) => b.add(
        const DriverBookingReleased(bookingId: 'b1', reason: 'vehicle_issue'),
      ),
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.notice, 'notice', contains('Liberaste el viaje'))
            // No vuelve a ofrecérsele (el servidor tampoco la deja aceptar).
            .having((s) => s.declinedIds, 'declinedIds', contains('b1')),
      ],
      verify: (_) => verify(
        () => trip.release(
          bookingId: 'b1',
          reason: 'vehicle_issue',
          location: null,
        ),
      ).called(1),
    );

    blocTest<DriverBloc, DriverState>(
      'liberar sin red: lo dice',
      build: () {
        when(
          () => trip.release(
            bookingId: any(named: 'bookingId'),
            reason: any(named: 'reason'),
            location: any(named: 'location'),
          ),
        ).thenAnswer(
          (_) async => const Left(TripFailure(TripIssue.network, 'x')),
        );
        return bloc();
      },
      act: (b) => b.add(
        const DriverBookingReleased(bookingId: 'b1', reason: 'other'),
      ),
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.notice, 'notice', contains('no se liberó')),
      ],
    );
  });

  group('DriverStepAction', () {
    late _MockDriverBloc bloc;

    setUp(() {
      bloc = _MockDriverBloc();
      when(() => bloc.state).thenReturn(const DriverInitial());
    });

    Future<void> pump(WidgetTester t, Booking b, {DateTime? now}) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<DriverBloc>.value(
              value: bloc,
              child: SingleChildScrollView(
                child: DriverStepAction(
                  booking: b,
                  clock: () => now ?? _now,
                  openCodeEntry: (_, __) async {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('sin política no hay «no aparece»', (t) async {
      await pump(t, _b(BookingStatus.driverArrived));
      expect(find.text('Ingresar código del pasajero'), findsOneWidget);
      expect(find.byKey(const Key('no-show')), findsNothing);
    });

    testWidgets('antes de la espera: desactivado y dice desde qué hora',
        (t) async {
      await pump(
        t,
        _b(
          BookingStatus.driverArrived,
          noShowAt: _now.add(const Duration(minutes: 5)),
        ),
      );
      final button = t.widget<ButtonStyleButton>(
        find.byKey(const Key('no-show')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Disponible a partir de las 12:05.'), findsOneWidget);
      // El temporizador no deja nada pendiente al salir.
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('pasada la espera: confirma y avisa a central', (t) async {
      await pump(
        t,
        _b(
          BookingStatus.driverArrived,
          noShowAt: _now.subtract(const Duration(minutes: 1)),
        ),
      );
      expect(find.textContaining('Disponible a partir'), findsNothing);
      await t.tap(find.byKey(const Key('no-show')));
      await t.pumpAndSettle();
      expect(find.text('¿El pasajero no aparece?'), findsOneWidget);
      await t.tap(find.text('Seguir esperando'));
      await t.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
      await t.tap(find.byKey(const Key('no-show')));
      await t.pumpAndSettle();
      await t.tap(find.text('Avisar a central'));
      await t.pumpAndSettle();
      verify(() => bloc.add(const DriverRiderNoShow(bookingId: 'b1')))
          .called(1);
    });

    testWidgets('liberar: exige motivo de la lista y lo manda', (t) async {
      await pump(t, _b(BookingStatus.driverArriving));
      await t.tap(find.byKey(const Key('release-booking')));
      await t.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, 'Liberar viaje');
      expect(t.widget<FilledButton>(confirm).onPressed, isNull);
      await t.tap(find.text('Problema con el vehículo'));
      await t.pump();
      await t.tap(confirm);
      await t.pumpAndSettle();
      verify(
        () => bloc.add(
          const DriverBookingReleased(bookingId: 'b1', reason: 'vehicle_issue'),
        ),
      ).called(1);
    });

    testWidgets('ya en la recogida no se ofrece liberar', (t) async {
      await pump(t, _b(BookingStatus.driverArrived));
      expect(find.byKey(const Key('release-booking')), findsNothing);
      await pump(t, _b(BookingStatus.inProgress));
      expect(find.byKey(const Key('release-booking')), findsNothing);
    });
  });

  test('errores del servidor del «no aparece» y liberar, sin texto técnico',
      () {
    TripFailure f(String reason) =>
        tripFailureFor('failed-precondition', {'reason': reason})
            as TripFailure;
    expect(f('no_show_too_early').issue, TripIssue.tooEarly);
    expect(f('no_show_disabled').issue, TripIssue.notAllowed);
    expect(f('location_required').issue, TripIssue.locationRequired);
    expect(f('not_releasable').message, contains('Ya no puedes liberar'));
  });
}
