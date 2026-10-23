import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

final _now = DateTime(2026, 1, 1);

final _user = User(
  id: 'uid-1',
  email: 'ana@luxelane.com',
  phone: '+59170000000',
  displayName: 'Ana',
  role: UserRole.rider,
  createdAt: _now,
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

void main() {
  late MockUserRepository users;
  late MockBookingRepository bookings;

  setUpAll(() => registerFallbackValue(_user));

  setUp(() {
    users = MockUserRepository();
    bookings = MockBookingRepository();
    when(
      () => users.getUserById('uid-1'),
    ).thenAnswer((_) async => Right(_user));
    when(
      () => bookings.getBookingsByRider('uid-1'),
    ).thenAnswer((_) async => const Right([]));
  });

  ProfileBloc build() =>
      ProfileBloc(userRepository: users, bookingRepository: bookings);

  blocTest<ProfileBloc, ProfileState>(
    'al guardar se ve el nombre nuevo y el aviso de guardado',
    build: () {
      when(
        () => users.updateUser(any()),
      ).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (bloc) async {
      bloc.add(const ProfileLoadRequested(userId: 'uid-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        ProfileUpdateRequested(user: _user.copyWith(displayName: 'Ana María')),
      );
    },
    skip: 2,
    expect:
        () => [
          isA<ProfileLoaded>()
              .having((s) => s.user.displayName, 'nombre', 'Ana María')
              .having((s) => s.isError, 'error', false)
              .having((s) => s.messageSeq, 'seq', 1),
        ],
  );

  blocTest<ProfileBloc, ProfileState>(
    'si el guardado falla el perfil sigue a la vista con un aviso de error',
    build: () {
      when(
        () => users.updateUser(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('x')));
      return build();
    },
    act: (bloc) async {
      bloc.add(const ProfileLoadRequested(userId: 'uid-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        ProfileUpdateRequested(user: _user.copyWith(displayName: 'Ana María')),
      );
    },
    skip: 2,
    expect:
        () => [
          isA<ProfileLoaded>()
              .having((s) => s.user.displayName, 'nombre', 'Ana')
              .having((s) => s.isError, 'error', true),
        ],
  );
}
