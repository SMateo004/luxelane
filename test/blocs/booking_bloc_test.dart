import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

final _now = DateTime(2025, 6, 1, 12);

const _origin = Place(
  address: '123 Main St',
  lat: 40.7128,
  lng: -74.0060,
);
const _destination = Place(
  address: 'JFK Airport',
  lat: 40.6413,
  lng: -73.7781,
);

Booking _makeBooking({BookingStatus status = BookingStatus.pending}) => Booking(
      id: 'booking-1',
      riderId: 'rider-1',
      origin: _origin,
      destination: _destination,
      scheduledAt: _now,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: 75.0,
      createdAt: _now,
      updatedAt: _now,
    );

void main() {
  late MockBookingRepository repo;

  setUpAll(() {
    registerFallbackValue(_makeBooking());
    registerFallbackValue(BookingStatus.pending);
  });

  setUp(() {
    repo = MockBookingRepository();
  });

  group('BookingBloc', () {
    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingCreated] on BookingCreateRequested success',
      build: () {
        when(() => repo.createBooking(any(),
                quotedPrice: any(named: 'quotedPrice')))
            .thenAnswer((_) async => Right(_makeBooking()));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) => bloc.add(BookingCreateRequested(
        origin: _origin,
        destination: _destination,
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        scheduledAt: _now,
        riderId: 'rider-1',
        estimatedPrice: 75.0,
      )),
      expect: () => [
        const BookingLoading(),
        isA<BookingCreated>(),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingError] on BookingCreateRequested failure',
      build: () {
        when(() => repo.createBooking(any(),
                quotedPrice: any(named: 'quotedPrice')))
            .thenAnswer(
                (_) async => const Left(ServerFailure('Network error')));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) => bloc.add(BookingCreateRequested(
        origin: _origin,
        destination: _destination,
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        scheduledAt: _now,
        riderId: 'rider-1',
        estimatedPrice: 75.0,
      )),
      expect: () => [
        const BookingLoading(),
        const BookingError('Network error'),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingLoading, BookingCancelled] on BookingCancelRequested success',
      build: () {
        when(() => repo.cancelBooking(any()))
            .thenAnswer((_) async => const Right(null));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) =>
          bloc.add(const BookingCancelRequested(bookingId: 'booking-1')),
      expect: () => [
        const BookingLoading(),
        const BookingCancelled(),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'la lista de viajes se actualiza en vivo al llegar una reserva nueva',
      build: () {
        when(() => repo.watchBookingsByRider('rider-1'))
            .thenAnswer((_) => Stream.fromIterable([
                  [_makeBooking()],
                  [
                    _makeBooking(),
                    _makeBooking(status: BookingStatus.confirmed)
                  ],
                ]));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) =>
          bloc.add(const BookingRiderTripsWatched(riderId: 'rider-1')),
      expect: () => [
        const BookingLoading(),
        isA<BookingTripsLoaded>().having((s) => s.bookings.length, 'length', 1),
        isA<BookingTripsLoaded>().having((s) => s.bookings.length, 'length', 2),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingTripsLoaded] on BookingRiderTripsRequested success',
      build: () {
        when(() => repo.getBookingsByRider(any()))
            .thenAnswer((_) async => Right([_makeBooking()]));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) =>
          bloc.add(const BookingRiderTripsRequested(riderId: 'rider-1')),
      expect: () => [
        const BookingLoading(),
        isA<BookingTripsLoaded>().having((s) => s.bookings.length, 'length', 1),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits BookingStatusUpdated on BookingStatusChanged',
      build: () => BookingBloc(bookingRepository: repo),
      act: (bloc) => bloc.add(
        BookingStatusChanged(
            booking: _makeBooking(status: BookingStatus.confirmed)),
      ),
      expect: () => [
        isA<BookingStatusUpdated>()
            .having((s) => s.booking.status, 'status', BookingStatus.confirmed),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'calls updateBookingStatus on BookingUpdateStatusRequested',
      build: () {
        when(() => repo.updateBookingStatus(
              bookingId: any(named: 'bookingId'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => const Right(null));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) => bloc.add(const BookingUpdateStatusRequested(
        bookingId: 'booking-1',
        status: BookingStatus.driverArriving,
      )),
      verify: (_) {
        verify(() => repo.updateBookingStatus(
              bookingId: 'booking-1',
              status: BookingStatus.driverArriving,
            )).called(1);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'una reserva para otra persona guarda el invitado aparte de las notas',
      build: () {
        when(() => repo.createBooking(any(),
                quotedPrice: any(named: 'quotedPrice')))
            .thenAnswer((_) async => Right(_makeBooking()));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) => bloc.add(BookingCreateRequested(
        origin: _origin,
        destination: _destination,
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        scheduledAt: _now,
        riderId: 'rider-1',
        estimatedPrice: 75.0,
        notes: 'Llevar agua',
        guest: const BookingGuest(
            title: 'Sra.', firstName: 'Carla', phone: '+59170000001'),
      )),
      verify: (_) {
        final sent = verify(() => repo.createBooking(captureAny(),
            quotedPrice: any(named: 'quotedPrice'))).captured.single as Booking;
        expect(sent.notes, 'Llevar agua');
        expect(sent.guest?.fullName, 'Sra. Carla');
        expect(sent.guest?.phone, '+59170000001');
      },
    );

    blocTest<BookingBloc, BookingState>(
      'si el servidor cotiza más que lo mostrado, pide confirmar el precio nuevo',
      build: () {
        when(() => repo.createBooking(any(),
                quotedPrice: any(named: 'quotedPrice')))
            .thenAnswer((_) async => const Left(PriceChangedFailure(120)));
        return BookingBloc(bookingRepository: repo);
      },
      act: (bloc) => bloc.add(BookingCreateRequested(
        origin: _origin,
        destination: _destination,
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        scheduledAt: _now,
        riderId: 'rider-1',
        estimatedPrice: 90,
        quotedPrice: 90,
      )),
      expect: () => [
        const BookingLoading(),
        isA<BookingPriceChanged>()
            .having((s) => s.previousPrice, 'previousPrice', 90)
            .having((s) => s.newPrice, 'newPrice', 120)
            .having((s) => s.request.withQuotedPrice(120).quotedPrice,
                'reenvío', 120),
      ],
      verify: (_) =>
          verify(() => repo.createBooking(any(), quotedPrice: 90)).called(1),
    );
  });
}
