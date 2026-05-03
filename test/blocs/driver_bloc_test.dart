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

Booking _makeBooking(BookingStatus status) => Booking(
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
    );

void main() {
  late MockBookingRepository bookingRepo;
  late MockUserRepository userRepo;
  late MockMapsService mapsService;

  setUpAll(() {
    registerFallbackValue(_makeBooking(BookingStatus.pending));
    registerFallbackValue(BookingStatus.confirmed);
    registerFallbackValue(_driverProfile);
  });

  setUp(() {
    bookingRepo = MockBookingRepository();
    userRepo = MockUserRepository();
    mapsService = MockMapsService();

    when(() => bookingRepo.watchDriverBookings(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => userRepo.getDriverProfile(any()))
        .thenAnswer((_) async => Right(_driverProfile));
  });

  DriverBloc bloc() => DriverBloc(
        bookingRepository: bookingRepo,
        userRepository: userRepo,
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
          ..emit(const DriverLoaded(isAvailable: false, bookings: []));
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
      final state = DriverLoaded(isAvailable: true, bookings: bookings);
      expect(state.activeBooking?.status, BookingStatus.inProgress);
    });

    test('activeBooking returns null when no active ride', () {
      final bookings = [_makeBooking(BookingStatus.completed)];
      final state = DriverLoaded(isAvailable: true, bookings: bookings);
      expect(state.activeBooking, isNull);
    });

    test('totalEarnings sums completed booking prices', () {
      final bookings = [
        _makeBooking(BookingStatus.completed),
        _makeBooking(BookingStatus.completed),
        _makeBooking(BookingStatus.inProgress),
      ];
      final state = DriverLoaded(isAvailable: true, bookings: bookings);
      expect(state.totalEarnings, 150.0); // 75 + 75
    });
  });
}
