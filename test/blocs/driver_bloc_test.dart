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
  id: 'v_driver-1',
  driverId: 'driver-1',
  make: 'Toyota',
  model: 'Camry',
  year: 2024,
  plate: '123ABC',
  vehicleClass: VehicleClass.business,
  color: 'Negro',
  capacity: 3,
  isActive: true,
);

Booking _makeBooking(
  BookingStatus status, {
  BookingSettlement? settlement,
  String id = 'booking-1',
  String? driverId = 'driver-1',
  VehicleClass vehicleClass = VehicleClass.business,
}) =>
    Booking(
      id: id,
      riderId: 'rider-1',
      driverId: driverId,
      origin: const Place(address: 'Origin', lat: 0, lng: 0),
      destination: const Place(address: 'Dest', lat: 1, lng: 1),
      scheduledAt: _now,
      vehicleClass: vehicleClass,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: 75,
      createdAt: _now,
      updatedAt: _now,
      settlement: settlement,
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
    when(() => bookingRepo.streamPendingBookings())
        .thenAnswer((_) => Stream.value([]));
    when(() => userRepo.getUserById(any()))
        .thenAnswer((_) async => Right(_driverUser));
    when(() => userRepo.getDriverProfile(any()))
        .thenAnswer((_) async => Right(_driverProfile));
    when(() => userRepo.watchDriverProfile(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => vehicleRepo.getVehicleByDriver(any()))
        .thenAnswer((_) async => const Right(_vehicle));
    when(() => mapsService.getCurrentPosition()).thenAnswer((_) async => null);
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
        isA<DriverLoaded>().having((s) => s.isAvailable, 'isAvailable', false),
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

    DriverLoaded loaded({
      bool available = true,
      List<Booking> bookings = const [],
      List<Booking> pending = const [],
      DriverProfile? profile,
    }) =>
        DriverLoaded(
          user: _driverUser,
          profile: profile ?? _driverProfile,
          vehicle: _vehicle,
          isAvailable: available,
          bookings: bookings,
          pendingRequests: pending,
        );

    test('solo ofrece solicitudes de su clase y cuando está libre', () {
      final pending = [
        _makeBooking(BookingStatus.pending,
            id: 'suv', driverId: null, vehicleClass: VehicleClass.businessSuv),
        _makeBooking(BookingStatus.pending, id: 'biz', driverId: null),
      ];
      expect(loaded(pending: pending).currentRequest?.id, 'biz');
      expect(loaded(pending: pending, available: false).currentRequest, isNull);
      expect(
          loaded(
            pending: pending,
            bookings: [_makeBooking(BookingStatus.inProgress)],
          ).currentRequest,
          isNull);
    });

    test('un chófer sin verificar no ve solicitudes', () {
      final unverified = DriverProfile(
        userId: 'driver-1',
        licenseNumber: 'DL-001',
        licenseExpiry: DateTime(2027),
        vehicleId: 'v_driver-1',
        documentsVerified: false,
        rating: 0,
        totalRides: 0,
        isAvailable: false,
      );
      final s = loaded(
        profile: unverified,
        pending: [_makeBooking(BookingStatus.pending, driverId: null)],
      );
      expect(s.canWork, isFalse);
      expect(s.currentRequest, isNull);
    });

    blocTest<DriverBloc, DriverState>(
      'no deja desconectarse con un viaje en curso',
      build: () => bloc()
        ..emit(loaded(bookings: [_makeBooking(BookingStatus.inProgress)])),
      act: (b) => b.add(const DriverAvailabilityToggled(
          userId: 'driver-1', isAvailable: false)),
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.isAvailable, 'isAvailable', true)
            .having((s) => s.notice, 'notice', contains('Termina el viaje')),
      ],
      verify: (_) => verifyNever(() => userRepo.setDriverAvailability(
            userId: any(named: 'userId'),
            isAvailable: any(named: 'isAvailable'),
          )),
    );

    blocTest<DriverBloc, DriverState>(
      'acepta por el servidor y avisa si otro chófer se adelantó',
      build: () {
        when(() => bookingRepo.acceptBooking('b1'))
            .thenAnswer((_) async => const Right(AcceptOutcome.alreadyTaken));
        return bloc()
          ..emit(loaded(pending: [
            _makeBooking(BookingStatus.pending, id: 'b1', driverId: null),
          ]));
      },
      act: (b) => b.add(
          const DriverRequestAccepted(bookingId: 'b1', driverId: 'driver-1')),
      expect: () => [
        isA<DriverLoaded>().having((s) => s.accepting, 'accepting', true),
        isA<DriverLoaded>()
            .having((s) => s.accepting, 'accepting', false)
            .having((s) => s.declinedIds, 'declinedIds', ['b1'])
            .having((s) => s.currentRequest, 'currentRequest', isNull)
            .having((s) => s.notice, 'notice', contains('Otro chófer')),
      ],
      verify: (_) {
        verify(() => bookingRepo.acceptBooking('b1')).called(1);
        verifyNever(() => bookingRepo.assignDriver(
              bookingId: any(named: 'bookingId'),
              driverId: any(named: 'driverId'),
            ));
      },
    );

    blocTest<DriverBloc, DriverState>(
      'no acepta otra solicitud durante un viaje',
      build: () => bloc()
        ..emit(loaded(bookings: [_makeBooking(BookingStatus.confirmed)])),
      act: (b) => b.add(
          const DriverRequestAccepted(bookingId: 'b2', driverId: 'driver-1')),
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.notice, 'notice', contains('viaje en curso')),
      ],
      verify: (_) => verifyNever(() => bookingRepo.acceptBooking(any())),
    );

    blocTest<DriverBloc, DriverState>(
      'avisa si no se pudo avanzar el viaje',
      build: () {
        when(() => bookingRepo.updateBookingStatus(
              bookingId: any(named: 'bookingId'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => const Left(ServerFailure('x')));
        return bloc()
          ..emit(loaded(bookings: [_makeBooking(BookingStatus.driverArrived)]));
      },
      act: (b) => b.add(const DriverTripStarted(bookingId: 'booking-1')),
      expect: () => [
        isA<DriverLoaded>()
            .having((s) => s.notice, 'notice', contains('No pudimos iniciar')),
      ],
    );

    blocTest<DriverBloc, DriverState>(
      'al cerrar sesión se desconecta y vuelve al estado inicial',
      build: () {
        when(() => userRepo.setDriverAvailability(
              userId: any(named: 'userId'),
              isAvailable: any(named: 'isAvailable'),
            )).thenAnswer((_) async => const Right(null));
        return bloc();
      },
      act: (b) async {
        b.add(const DriverStarted(userId: 'driver-1'));
        await Future<void>.delayed(Duration.zero);
        b.add(const DriverAvailabilityToggled(
            userId: 'driver-1', isAvailable: true));
        await Future<void>.delayed(Duration.zero);
        b.add(const DriverSignedOut());
      },
      skip: 3,
      expect: () => [isA<DriverInitial>()],
      verify: (_) => verify(() => userRepo.setDriverAvailability(
            userId: 'driver-1',
            isAvailable: false,
          )).called(1),
    );

    blocTest<DriverBloc, DriverState>(
      'bloquea a un usuario que no es chófer',
      build: () {
        when(() => userRepo.getUserById(any())).thenAnswer((_) async => Right(
              User(
                id: 'r',
                email: 'r@x.com',
                phone: '',
                displayName: 'R',
                role: UserRole.rider,
                createdAt: _now,
                isVerified: true,
                isActive: true,
                fcmTokens: const [],
              ),
            ));
        return bloc();
      },
      act: (b) => b.add(const DriverStarted(userId: 'r')),
      expect: () => [
        isA<DriverError>().having(
            (s) => s.message, 'message', contains('solo para chóferes')),
      ],
    );
  });
}
