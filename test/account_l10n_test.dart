import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/widgets/components.dart';
import 'package:luxelane/core/widgets/error_boundary.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:luxelane/features/auth/presentation/auth_error_messages.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/login_page.dart';
import 'package:luxelane/features/auth/presentation/pages/register_page.dart';
import 'package:luxelane/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:luxelane/features/payments/presentation/pages/payment_screen.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxelane/features/profile/presentation/pages/profile_screen.dart';
import 'package:luxelane/l10n/l10n.dart';

import 'helpers/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState> implements ProfileBloc {}

class _MockPaymentBloc extends MockBloc<PaymentEvent, PaymentState> implements PaymentBloc {}

class _MockAdminBloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

final _user = User(
  id: 'uid-1',
  email: 'ana@example.com',
  phone: '+59170000000',
  displayName: 'Ana Gutiérrez',
  role: UserRole.rider,
  createdAt: DateTime(2025, 3, 15),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

Booking _booking(BookingStatus status) {
  final at = DateTime(2026, 10, 7, 9, 30);
  return Booking(
    id: 'bk12345678',
    riderId: 'uid-1',
    origin: const Place(address: 'Hotel Los Tajibos', lat: -17.76, lng: -63.18),
    destination: const Place(address: 'Aeropuerto Viru Viru', lat: -17.64, lng: -63.13),
    scheduledAt: at,
    vehicleClass: VehicleClass.businessVan,
    serviceType: ServiceType.oneWay,
    status: status,
    estimatedPrice: 1250,
    createdAt: at,
    updatedAt: at,
  );
}

Widget _admin(Widget tab, AdminState state, Locale locale) {
  final bloc = _MockAdminBloc();
  whenListen(bloc, const Stream<AdminState>.empty(), initialState: state);
  return BlocProvider<AdminBloc>.value(
    value: bloc,
    child: localizedApp(Scaffold(body: tab), locale: locale),
  );
}

Widget _auth(Widget page, {required Locale locale, AuthState? initial, Stream<AuthState>? states}) {
  final bloc = _MockAuthBloc();
  whenListen(bloc, states ?? const Stream<AuthState>.empty(),
      initialState: initial ?? const AuthUnauthenticated());
  return BlocProvider<AuthBloc>.value(value: bloc, child: localizedApp(page, locale: locale));
}

/// Phone-sized surface (360 px wide) so overflow shows up as test failures.
Future<void> _phone(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('Login', () {
    testWidgets('shows English labels', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_auth(const LoginPage(), locale: const Locale('en')));
      expect(find.text('Welcome\nback.'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
    });

    testWidgets('validators are translated', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_auth(const LoginPage(), locale: const Locale('pt')));
      await tester.tap(find.text('ENTRAR'));
      await tester.pump();
      expect(find.text('Digite um e-mail válido'), findsOneWidget);
      expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);
    });

    testWidgets('Firebase errors are shown translated, never raw', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_auth(
        const LoginPage(),
        locale: const Locale('en'),
        states: Stream.value(const AuthError(
          'The supplied auth credential is incorrect, malformed or has expired.',
          code: 'invalid-credential',
        )),
      ));
      await tester.pump();
      expect(find.text('Incorrect email or password'), findsOneWidget);
      expect(find.textContaining('malformed'), findsNothing);
    });
  });

  group('Register', () {
    testWidgets('shows English labels and the consent sentence with links', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_auth(const RegisterPage(), locale: const Locale('en')));
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('I accept the Terms and Conditions and the Privacy Policy', findRichText: true),
          findsOneWidget);

      await tester.tap(find.text('CREATE ACCOUNT'));
      await tester.pump();
      expect(find.text('You need to accept the terms and the privacy policy'), findsOneWidget);
      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('Portuguese consent sentence reads naturally', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_auth(const RegisterPage(), locale: const Locale('pt')));
      expect(find.text('Aceito os Termos e Condições e a Política de Privacidade', findRichText: true),
          findsOneWidget);
    });

    testWidgets('tapping the consent text ticks the checkbox', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_auth(const RegisterPage(), locale: const Locale('es')));
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      final consent =
          find.text('Acepto los Términos y condiciones y la Política de privacidad', findRichText: true);
      await tester.ensureVisible(consent);
      await tester.tapAt(tester.getTopLeft(consent) + const Offset(8, 8));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });
  });

  group('authErrorMessage', () {
    final l = lookupAppLocalizations(const Locale('en'));
    test('maps Firebase codes', () {
      expect(authErrorMessage(l, 'wrong-password'), 'Incorrect email or password');
      expect(authErrorMessage(l, 'user-not-found'), "There's no account with this email");
      expect(authErrorMessage(l, 'email-already-in-use'), 'An account with this email already exists');
      expect(authErrorMessage(l, 'weak-password'), contains('too weak'));
      expect(authErrorMessage(l, 'network-request-failed'), l.commonConnectionError);
      expect(authErrorMessage(l, 'too-many-requests'), contains('Too many attempts'));
    });
    test('unknown or missing codes fall back to a generic message', () {
      expect(authErrorMessage(l, 'something-new'), l.authErrorGeneric);
      expect(authErrorMessage(l, null), l.authErrorGeneric);
    });
  });

  group('Core widgets', () {
    testWidgets('error screen and role labels follow the language', (tester) async {
      await tester.pumpWidget(localizedApp(LuxErrorScreen(onRetry: () {}), locale: const Locale('en')));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      final pt = lookupAppLocalizations(const Locale('pt'));
      expect(UserRole.driver.localizedLabel(pt), 'Motorista');
      expect(UserRole.rider.localizedLabel(pt), 'Passageiro');
    });
  });

  group('360 px layouts', () {
    for (final locale in supportedAppLocales) {
      testWidgets('profile (${locale.languageCode})', (tester) async {
        await _phone(tester);
        final auth = _MockAuthBloc();
        whenListen(auth, const Stream<AuthState>.empty(), initialState: AuthAuthenticated(_user));
        final profile = _MockProfileBloc();
        whenListen(profile, const Stream<ProfileState>.empty(),
            initialState: ProfileLoaded(user: _user, totalRides: 12, rating: 4.8));
        await tester.pumpWidget(MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<ProfileBloc>.value(value: profile),
          ],
          child: localizedApp(const ProfileScreen(), locale: locale),
        ));
        await tester.pump();
        if (locale.languageCode == 'en') {
          expect(find.text('Profile'), findsOneWidget);
          expect(find.text('PASSENGER'), findsOneWidget);
          expect(find.text('4.8'), findsOneWidget);
        }
        if (locale.languageCode == 'es') expect(find.text('4,8'), findsOneWidget);
      });

      testWidgets('payment methods (${locale.languageCode})', (tester) async {
        await _phone(tester);
        final auth = _MockAuthBloc();
        whenListen(auth, const Stream<AuthState>.empty(), initialState: AuthAuthenticated(_user));
        final payments = _MockPaymentBloc();
        whenListen(payments, const Stream<PaymentState>.empty(),
            initialState: const CardsLoaded([
              {'id': 'pm_1', 'brand': 'visa', 'last4': '4242', 'expMonth': 4, 'expYear': 2029},
              {'id': 'pm_2', 'last4': '0005', 'expMonth': 12, 'expYear': 2030},
            ]));
        await tester.pumpWidget(MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<PaymentBloc>.value(value: payments),
          ],
          child: localizedApp(const PaymentScreen(), locale: locale),
        ));
        await tester.pump();
        if (locale.languageCode == 'en') {
          expect(find.text('Payment methods'), findsOneWidget);
          expect(find.text('Expires 04/2029'), findsOneWidget);
          expect(find.text('Card •••• 0005'), findsOneWidget);
          expect(find.text('SET DEFAULT'), findsNWidgets(2));
        }
      });

      testWidgets('admin dashboard, pricing and settings (${locale.languageCode})', (tester) async {
        await _phone(tester);
        final state = AdminState(
          users: [_user],
          bookings: [_booking(BookingStatus.completed), _booking(BookingStatus.pending)],
          globalSettings: const {'isMaintenanceMode': true},
        );
        await tester.pumpWidget(_admin(const DashboardTab(), state, locale));
        await tester.pump();
        if (locale.languageCode == 'en') {
          expect(find.text('Overview'), findsOneWidget);
          expect(find.text('Total revenue'), findsOneWidget);
          expect(find.text('0 chauffeurs'), findsOneWidget);
          expect(find.text('COMPLETED'), findsOneWidget);
        }

        await tester.pumpWidget(_admin(const PricingTab(), state, locale));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.expand_more_rounded).first);
        await tester.pump();

        await tester.pumpWidget(_admin(const SettingsTab(), state, locale));
        await tester.pump();
        if (locale.languageCode == 'pt') {
          expect(find.text('Modo de manutenção'), findsOneWidget);
        }
      });
    }
  });
}
