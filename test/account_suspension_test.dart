import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/account_suspended_page.dart';
import 'package:luxelane/features/booking/domain/booking_error_codes.dart';
import 'package:luxelane/features/booking/presentation/booking_error_l10n.dart';
import 'package:luxelane/l10n/gen/app_localizations_es.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

User _user({UserRole role = UserRole.rider, bool active = true}) => User(
      id: 'u1',
      email: 'u@luxelane.bo',
      phone: '',
      displayName: 'Ana',
      role: role,
      createdAt: DateTime(2025),
      isVerified: true,
      isActive: active,
      fcmTokens: const [],
    );

void main() {
  group('accountSuspensionRedirect', () {
    final suspended = AuthAuthenticated(_user(active: false));
    final active = AuthAuthenticated(_user());

    test('keeps a suspended account on the notice, help stays open', () {
      expect(isAccountSuspended(suspended), isTrue);
      expect(accountSuspensionRedirect(suspended, '/booking', home: '/'), accountSuspendedPath);
      expect(accountSuspensionRedirect(suspended, '/driver/queue', home: '/driver'), accountSuspendedPath);
      expect(accountSuspensionRedirect(suspended, accountSuspendedPath, home: '/'), isNull);
      expect(accountSuspensionRedirect(suspended, '/ayuda', home: '/'), isNull);
    });

    test('a reactivated account leaves the notice; admins are never suspended', () {
      expect(accountSuspensionRedirect(active, accountSuspendedPath, home: '/driver'), '/driver');
      expect(accountSuspensionRedirect(active, '/booking', home: '/'), isNull);
      expect(isAccountSuspended(AuthAuthenticated(_user(role: UserRole.admin, active: false))), isFalse);
      expect(isAccountSuspended(const AuthUnauthenticated()), isFalse);
    });

    test('booking errors explain the suspension', () {
      expect(localizedBookingError(AppLocalizationsEs(), BookingErrorCodes.accountSuspended),
          'Tu cuenta está suspendida. Escríbenos desde Ayuda.');
    });
  });

  group('AuthBloc watches the account status', () {
    late _MockAuthRepository repo;
    late StreamController<bool> status;

    setUp(() {
      repo = _MockAuthRepository();
      status = StreamController<bool>();
      when(() => repo.isSignedIn).thenAnswer((_) => const Stream.empty());
    });
    // Not awaited: close() never completes on a stream nobody listened to.
    tearDown(() {
      status.close();
    });

    blocTest<AuthBloc, AuthState>(
      'a suspension while signed in updates the user',
      build: () {
        when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => Right(_user()));
        return AuthBloc(authRepository: repo, watchIsActive: (_) => status.stream);
      },
      act: (bloc) async {
        bloc.add(const LoginRequested(email: 'u@luxelane.bo', password: 'x'));
        await Future<void>.delayed(Duration.zero);
        status
          ..add(true)
          ..add(false);
        await Future<void>.delayed(Duration.zero);
        status.add(true);
      },
      wait: const Duration(milliseconds: 10),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(_user()),
        AuthAuthenticated(_user(active: false)),
        AuthAuthenticated(_user()),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'admins are not watched',
      build: () {
        when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => Right(_user(role: UserRole.admin)));
        return AuthBloc(authRepository: repo, watchIsActive: (_) => throw StateError('watched an admin'));
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'a@luxelane.bo', password: 'x')),
      expect: () => [const AuthLoading(), AuthAuthenticated(_user(role: UserRole.admin))],
    );
  });

  group('AccountSuspendedPage', () {
    for (final (width, locale, title) in const [
      (360.0, Locale('es'), 'Tu cuenta está suspendida'),
      (1280.0, Locale('en'), 'Your account is suspended'),
      (390.0, Locale('pt'), 'Sua conta está suspensa'),
    ]) {
      testWidgets('explains and offers help or sign-out (${width.toInt()}px, ${locale.languageCode})', (tester) async {
        tester.view
          ..physicalSize = Size(width, 800)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final auth = _MockAuthBloc();
        whenListen(auth, const Stream<AuthState>.empty(), initialState: AuthAuthenticated(_user(active: false)));
        var helpOpened = false;
        await tester.pumpWidget(BlocProvider<AuthBloc>.value(
          value: auth,
          child: MaterialApp.router(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: supportedAppLocales,
            routerConfig: GoRouter(routes: [
              GoRoute(path: '/', builder: (_, __) => const AccountSuspendedPage()),
              GoRoute(
                path: '/ayuda',
                builder: (_, __) {
                  helpOpened = true;
                  return const Scaffold();
                },
              ),
            ]),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (locale.languageCode == 'es') {
          await tester.tap(find.text('CERRAR SESIÓN'));
          verify(() => auth.add(const LogoutRequested())).called(1);
          await tester.tap(find.text('ESCRIBIR A SOPORTE'));
          await tester.pumpAndSettle();
          expect(helpOpened, isTrue);
        }
      });
    }
  });
}
