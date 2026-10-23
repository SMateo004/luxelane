import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

final _mockUser = User(
  id: 'uid-1',
  email: 'test@luxelane.com',
  phone: '+1555000000',
  displayName: 'Test User',
  role: UserRole.rider,
  createdAt: DateTime(2025),
  isVerified: false,
  isActive: true,
  fcmTokens: const [],
);

void main() {
  late MockAuthRepository repo;

  setUpAll(() {
    registerFallbackValue(UserRole.rider);
  });

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.authStateChanges).thenAnswer((_) => Stream.value(null));
    when(() => repo.isSignedIn).thenAnswer((_) => const Stream.empty());
    when(() => repo.watchUser(any())).thenAnswer((_) => const Stream.empty());
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'cierra la sesión si el admin bloquea la cuenta con la app abierta',
      build: () {
        when(
          () => repo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(_mockUser));
        when(() => repo.watchUser('uid-1')).thenAnswer(
          (_) => Stream.value(
            User.fromJson({..._mockUser.toJson(), 'isActive': false}),
          ),
        );
        when(() => repo.logout()).thenAnswer((_) async => const Right(null));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(
        const LoginRequested(
          email: 'test@luxelane.com',
          password: 'secret',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(_mockUser),
        const AuthError(kBlockedAccountMessage),
      ],
      verify: (_) => verify(() => repo.logout()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'al abrir la app con la cuenta bloqueada explica el motivo',
      build: () {
        when(() => repo.authStateChanges).thenAnswer(
          (_) => Stream.error(const AuthFailure(kBlockedAccountMessage)),
        );
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () =>
          [const AuthLoading(), const AuthError(kBlockedAccountMessage)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on LoginRequested success',
      build: () {
        when(
          () => repo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(_mockUser));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(
        const LoginRequested(
          email: 'test@luxelane.com',
          password: 'secret',
        ),
      ),
      expect: () => [const AuthLoading(), AuthAuthenticated(_mockUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on LoginRequested failure',
      build: () {
        when(
          () => repo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(AuthFailure('Wrong credentials')));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'x@x.com', password: 'wrong'),
      ),
      expect: () => [const AuthLoading(), const AuthError('Wrong credentials')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on GoogleSignInRequested success',
      build: () {
        when(
          () => repo.signInWithGoogle(),
        ).thenAnswer((_) async => Right(_mockUser));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [const AuthLoading(), AuthAuthenticated(_mockUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'returns to AuthUnauthenticated without error when Google is cancelled',
      build: () {
        when(
          () => repo.signInWithGoogle(),
        ).thenAnswer((_) async => const Left(AuthCancelledFailure()));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on GoogleSignInRequested failure',
      build: () {
        when(() => repo.signInWithGoogle()).thenAnswer(
          (_) async => const Left(AuthFailure('Google no disponible')),
        );
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () =>
          [const AuthLoading(), const AuthError('Google no disponible')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] on LogoutRequested',
      build: () {
        when(() => repo.logout()).thenAnswer((_) async => const Right(null));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on RegisterRequested success',
      build: () {
        when(
          () => repo.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            phone: any(named: 'phone'),
            displayName: any(named: 'displayName'),
            role: any(named: 'role'),
          ),
        ).thenAnswer((_) async => Right(_mockUser));
        return AuthBloc(authRepository: repo);
      },
      act: (bloc) => bloc.add(
        const RegisterRequested(
          email: 'test@luxelane.com',
          password: 'secret',
          phone: '+1555000000',
          displayName: 'Test User',
          role: UserRole.rider,
        ),
      ),
      expect: () => [const AuthLoading(), AuthAuthenticated(_mockUser)],
    );
  });
}
