import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
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
  });
}
