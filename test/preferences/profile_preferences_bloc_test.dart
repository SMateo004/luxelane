import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _Users extends Mock implements UserRepository {}

class _Bookings extends Mock implements BookingRepository {}

class _Prefs extends Mock implements PreferencesRepository {}

final _user = User(
  id: 'uid-1',
  email: 'ana@luxelane.com',
  phone: '',
  displayName: 'Ana',
  role: UserRole.rider,
  createdAt: DateTime(2026),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

/// Preferencias, B0: el perfil guarda las preferencias con updatePreferences
/// (PreferencesRepository), nunca con updateUser.
void main() {
  late _Users users;
  late _Bookings bookings;
  late _Prefs prefs;
  const wanted =
      TripPreferences(conversation: ConversationPref.quiet, note: '  Hola ');
  const saved =
      TripPreferences(conversation: ConversationPref.quiet, note: 'Hola');

  setUpAll(() {
    registerFallbackValue(TripPreferences.empty);
    registerFallbackValue(_user);
  });

  setUp(() {
    users = _Users();
    bookings = _Bookings();
    prefs = _Prefs();
    when(() => users.getUserById('uid-1'))
        .thenAnswer((_) async => Right(_user));
    when(() => bookings.getBookingsByRider('uid-1'))
        .thenAnswer((_) async => const Right([]));
  });

  ProfileBloc build() => ProfileBloc(
        userRepository: users,
        bookingRepository: bookings,
        preferencesRepository: prefs,
      );

  blocTest<ProfileBloc, ProfileState>(
    'guardar: la copia saneada del servidor y un aviso sobrio',
    build: () {
      when(() => prefs.save(any())).thenAnswer((_) async => const Right(saved));
      return build();
    },
    act: (b) async {
      b.add(const ProfileLoadRequested(userId: 'uid-1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ProfilePreferencesSaved(wanted));
    },
    skip: 2,
    expect: () => [
      isA<ProfileLoaded>()
          .having((s) => s.user.tripPreferences, 'prefs', saved)
          .having((s) => s.message, 'message', 'Preferencias guardadas.')
          .having((s) => s.isError, 'isError', false),
    ],
    verify: (_) {
      verify(() => prefs.save(wanted)).called(1);
      verifyNever(() => users.updateUser(any()));
    },
  );

  blocTest<ProfileBloc, ProfileState>(
    'si falla, siguen las anteriores y se avisa con el motivo',
    build: () {
      when(() => prefs.save(any())).thenAnswer((_) async => const Left(
          ServerFailure(
              'Revisa la nota: hasta 200 caracteres y sin enlaces.')));
      return build();
    },
    act: (b) async {
      b.add(const ProfileLoadRequested(userId: 'uid-1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ProfilePreferencesSaved(wanted));
    },
    skip: 2,
    expect: () => [
      isA<ProfileLoaded>()
          .having((s) => s.user.tripPreferences, 'prefs', TripPreferences.empty)
          .having((s) => s.isError, 'isError', true)
          .having((s) => s.message, 'message', contains('sin enlaces')),
    ],
  );
}
