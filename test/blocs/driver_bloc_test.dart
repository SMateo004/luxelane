import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockMapsService extends Mock implements MapsService {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

final _now = DateTime(2025, 6);

final _driverProfile = DriverProfile(
  userId: 'driver-1',
  licenseNumber: 'DL-001',
  licenseExpiry: DateTime(2027),
  vehicleId: 'vehicle-1',
  documentsVerified: true,
  rating: 4.9,
  totalRides: 42,
  isAvailable: false,
);

final _driverUser = User(
  id: 'driver-1',
  email: 'driver@luxelane.com',
  phone: '+59170000000',
  displayName: 'Driver One',
  role: UserRole.driver,
  createdAt: _now,
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

const _vehicle = Vehicle(
  id: 'vehicle-1',
  driverId: 'driver-1',
  make: 'Toyota',
  model: 'Camry',
  year: 2024,
  plate: '1234ABC',
  vehicleClass: VehicleClass.business,
  color: 'Negro',
  capacity: 3,
  isActive: true,
);

Booking _makeBooking(BookingStatus status,
        {BookingSettlement? settlement, bool refunded = false}) =>
    Booking(
      id: 'booking-1',
      riderId: 'rider-1',
      driverId: 'driver-1',
      origin: const Place(address: 'Origin', lat: 0, lng: 0),
      destination: const Place(address: 'Dest', lat: 1, lng: 1),
      scheduledAt: _now,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: 75,
      createdAt: _now,
      updatedAt: _now,
      settlement: settlement,
      refunded: refunded,
    );

OpenRequest _request(String id,
        {VehicleClass vehicleClass = VehicleClass.business}) =>
    OpenRequest(
      id: id,
      vehicleClass: vehicleClass,
      serviceType: ServiceType.oneWay,
      scheduledAt: _now,
      estimatedPrice: 75,
    );

void main() {
  late MockBookingRepository bookingRepo;
  late MockUserRepository userRepo;
  late MockMapsService mapsService;
  late MockVehicleRepository vehicleRepo;

  setUpAll(() {
    registerFallbackValue(_makeBooking(BookingStatus.pending));
    registerFallbackValue(BookingStatus.confirmed);
    registerFallbackValue(_driverProfile);
  });

  setUp(() {
    bookingRepo = MockBookingRepository();
    userRepo = MockUserRepository();
    mapsService = MockMapsService();
    vehicleRepo = MockVehicleRepository();

    when(() => bookingRepo.watchDriverBookings(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => bookingRepo.streamOpenRequests())
        .thenAnswer((_) => Stream.value([]));
    when(() => userRepo.getUserById(any()))
        .thenAnswer((_) async => Right(_driverUser));
    when(() => userRepo.getDriverProfile(any()))
        .thenAnswer((_) async => Right(_driverProfile));
    when(() => userRepo.watchDriverProfile(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => vehicleRepo.getVehicleByDriver(any()))
        .thenAnswer((_) async => const Right(_vehicle));
    when(() => mapsService.driverPositionStream())
        .thenAnswer((_) => const Stream.empty());
  });

  DriverBloc bloc() => DriverBloc(
        bookingRepository: bookingRepo,
        userRepository: userRepo,
        vehicleRepository: vehicleRepo,
        mapsService: mapsService,
      );

  group('DriverBloc', () {
    blocTest<DriverBloc, DriverState>(
      'emits DriverLoaded on DriverStarted',
      build: bloc,
      act: (bloc) => bloc.add(const DriverStarted(userId: 'driver-1')),
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.isAvailable, 'isAvailable', false)
            .having(
                (s) => s.vehicleClass, 'vehicleClass', VehicleClass.business),
      ],
      verify: (_) {
        verify(() => userRepo.getDriverProfile('driver-1')).called(1);
      },
    );

    blocTest<DriverBloc, DriverState>(
      'toggles availability and calls setDriverAvailability',
      build: () {
        when(() => userRepo.setDriverAvailability(
              userId: any(named: 'userId'),
              isAvailable: any(named: 'isAvailable'),
            )).thenAnswer((_) async => const Right(null));
        return bloc()
          ..emit(DriverLoaded(
            user: _driverUser,
            profile: _driverProfile,
            isAvailable: false,
            bookings: const [],
          ));
      },
      act: (bloc) => bloc.add(const DriverAvailabilityToggled(
        userId: 'driver-1',
        isAvailable: true,
      )),
      expect: () => [
        isA<DriverLoaded>().having((s) => s.isAvailable, 'isAvailable', true),
        isA<DriverLoaded>().having((s) => s.isTracking, 'isTracking', true),
      ],
      verify: (_) {
        verify(() => userRepo.setDriverAvailability(
              userId: 'driver-1',
              isAvailable: true,
            )).called(1);
      },
    );

    blocTest<DriverBloc, DriverState>(
      'calls updateBookingStatus on DriverBookingAccepted',
      build: () {
        when(() => bookingRepo.updateBookingStatus(
              bookingId: any(named: 'bookingId'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => const Right(null));
        return bloc();
      },
      act: (bloc) =>
          bloc.add(const DriverBookingAccepted(bookingId: 'booking-1')),
      verify: (_) {
        verify(() => bookingRepo.updateBookingStatus(
              bookingId: 'booking-1',
              status: BookingStatus.driverArriving,
            )).called(1);
      },
    );

    blocTest<DriverBloc, DriverState>(
      'calls updateBookingStatus on DriverTripCompleted',
      build: () {
        when(() => bookingRepo.updateBookingStatus(
              bookingId: any(named: 'bookingId'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => const Right(null));
        return bloc();
      },
      act: (bloc) =>
          bloc.add(const DriverTripCompleted(bookingId: 'booking-1')),
      verify: (_) {
        verify(() => bookingRepo.updateBookingStatus(
              bookingId: 'booking-1',
              status: BookingStatus.completed,
            )).called(1);
      },
    );

    test('activeBooking returns correct booking from state', () {
      final bookings = [
        _makeBooking(BookingStatus.completed),
        _makeBooking(BookingStatus.inProgress),
      ];
      final state = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: bookings,
      );
      expect(state.activeBooking?.status, BookingStatus.inProgress);
    });

    test('activeBooking returns null when no active ride', () {
      final bookings = [_makeBooking(BookingStatus.completed)];
      final state = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: bookings,
      );
      expect(state.activeBooking, isNull);
    });

    test('totalEarnings descuenta la comisión de los viajes completados', () {
      final bookings = [
        _makeBooking(BookingStatus.completed),
        _makeBooking(BookingStatus.completed),
        _makeBooking(BookingStatus.inProgress),
      ];
      final state = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: bookings,
      );
      // Sin reparto del servidor: comisión por defecto del 20 %.
      expect(state.grossEarnings, 150.0); // 75 + 75
      expect(state.totalCommission, 30.0);
      expect(state.totalEarnings, 120.0);
      expect(state.hasProvisionalEarnings, isTrue);
    });

    test('totalEarnings usa el reparto fijado por el servidor', () {
      const settled = BookingSettlement(
        amount: 75,
        commissionPct: 10,
        platformCommission: 7.5,
        driverPayout: 67.5,
      );
      final state = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: [
          _makeBooking(BookingStatus.completed, settlement: settled),
          _makeBooking(BookingStatus.completed, settlement: settled),
        ],
      );
      expect(state.totalEarnings, 135.0);
      expect(state.totalCommission, 15.0);
      expect(state.hasProvisionalEarnings, isFalse);
    });

    blocTest<DriverBloc, DriverState>(
      'si otro chófer ganó la reserva avisa y la descarta',
      build: () {
        when(() => bookingRepo.assignDriver(
                  bookingId: any(named: 'bookingId'),
                  driverId: any(named: 'driverId'),
                ))
            .thenAnswer((_) async => const Left(
                ValidationFailure('Otro chófer ya aceptó este viaje.')));
        return bloc()
          ..emit(DriverLoaded(
            user: _driverUser,
            profile: _driverProfile,
            isAvailable: true,
            bookings: const [],
          ));
      },
      act: (bloc) => bloc.add(const DriverRequestAccepted(
          bookingId: 'booking-1', driverId: 'driver-1')),
      expect: () => [
        isA<DriverLoaded>()
            .having(
                (s) => s.notice, 'notice', 'Otro chófer ya aceptó este viaje.')
            .having((s) => s.declinedIds, 'declinedIds', ['booking-1']),
      ],
      verify: (_) => verifyNever(() => bookingRepo.updateBookingStatus(
            bookingId: any(named: 'bookingId'),
            status: any(named: 'status'),
          )),
    );

    test('solo ofrece solicitudes de su clase y si puede aceptarlas', () {
      final van = _request('van', vehicleClass: VehicleClass.businessVan);
      final sedan = _request('sedan');
      final base = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: const [],
        pendingRequests: [van, sedan],
        vehicleClass: VehicleClass.business,
      );
      expect(base.currentRequest?.id, 'sedan');
      expect(base.matchingRequests.map((b) => b.id), ['sedan']);
      // Desconectado o con un viaje en curso: no se le ofrece nada.
      expect(base.copyWith(isAvailable: false).currentRequest, isNull);
      expect(
          base.copyWith(bookings: [
            _makeBooking(BookingStatus.inProgress)
          ]).currentRequest,
          isNull);
    });

    test('una reserva confirmada para otro día no ocupa al chófer', () {
      final future = Booking.fromJson({
        ..._makeBooking(BookingStatus.confirmed).toJson(),
        'scheduledAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      });
      final soon = Booking.fromJson({
        ..._makeBooking(BookingStatus.confirmed).toJson(),
        'scheduledAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 20))),
      });
      final base = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: [future],
      );
      expect(base.activeBooking, isNull);
      expect(base.canAccept, isTrue);
      expect(base.copyWith(bookings: [soon]).activeBooking, isNotNull);
    });

    test('un viaje reembolsado no suma ganancias ni queda provisional', () {
      final state = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: [
          _makeBooking(BookingStatus.completed),
          _makeBooking(BookingStatus.completed, refunded: true),
        ],
      );
      expect(state.grossEarnings, 75.0);
      expect(state.totalEarnings, 60.0);
      expect(state.totalCommission, 15.0);
    });

    test('solo comparte ubicación en la reserva mientras el viaje está activo',
        () {
      DriverLoaded withStatus(BookingStatus s) => DriverLoaded(
            user: _driverUser,
            profile: _driverProfile,
            isAvailable: true,
            bookings: [_makeBooking(s)],
          );
      for (final s in [
        BookingStatus.driverArriving,
        BookingStatus.driverArrived,
        BookingStatus.inProgress,
      ]) {
        expect(withStatus(s).liveBooking?.id, 'booking-1');
      }
      for (final s in [
        BookingStatus.confirmed,
        BookingStatus.completed,
        BookingStatus.cancelled,
      ]) {
        expect(withStatus(s).liveBooking, isNull);
      }
    });

    test('una solicitud que ya aceptó no se le vuelve a ofrecer', () {
      final state = DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: [_makeBooking(BookingStatus.confirmed)],
        pendingRequests: [_request('booking-1'), _request('otra')],
        vehicleClass: VehicleClass.business,
      );
      expect(state.matchingRequests.map((r) => r.id), ['otra']);
    });

    blocTest<DriverBloc, DriverState>(
      'un chófer verificado escucha las solicitudes abiertas',
      build: bloc,
      act: (bloc) => bloc.add(const DriverStarted(userId: 'driver-1')),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => bookingRepo.streamOpenRequests()).called(1);
      },
    );

    blocTest<DriverBloc, DriverState>(
      'un chófer sin verificar no pide las solicitudes (las reglas lo '
      'rechazarían)',
      build: () {
        when(() => userRepo.getDriverProfile(any()))
            .thenAnswer((_) async => Right(DriverProfile.fromJson({
                  ..._driverProfile.toJson(),
                  'documentsVerified': false,
                })));
        return bloc();
      },
      act: (bloc) => bloc.add(const DriverStarted(userId: 'driver-1')),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verifyNever(() => bookingRepo.streamOpenRequests());
      },
    );

    blocTest<DriverBloc, DriverState>(
      'un chófer bloqueado (isActive == false) no pide las solicitudes '
      'aunque esté verificado',
      build: () {
        when(() => userRepo.getUserById(any())).thenAnswer(
            (_) async => Right(_driverUser.copyWith(isActive: false)));
        return bloc();
      },
      act: (bloc) => bloc.add(const DriverStarted(userId: 'driver-1')),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verifyNever(() => bookingRepo.streamOpenRequests());
      },
    );
  });
}
