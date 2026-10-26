import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/enums.dart';
import '../../core/models/booking_form_data.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/booking/presentation/pages/booking_screen.dart';
import '../../features/booking/presentation/pages/ride_type_page.dart';
import '../../features/driver/presentation/pages/driver_active_ride_screen.dart';
import '../../features/driver/presentation/pages/driver_earnings_screen.dart';
import '../../features/driver/presentation/pages/driver_home_screen.dart';
import '../../features/driver/presentation/pages/driver_onboarding_screen.dart';
import '../../features/driver/presentation/pages/driver_queue_screen.dart';
import '../../features/services/presentation/pages/airport_transfer_page.dart';
import '../../features/services/presentation/pages/hourly_charter_page.dart';
import '../../features/services/presentation/pages/immediate_pickup_page.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/payments/presentation/pages/add_card_screen.dart';
import '../../features/payments/presentation/pages/payment_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/ride/presentation/pages/ride_screen.dart';
import '../../features/trips/presentation/pages/trips_screen.dart';
import '../../features/business/presentation/pages/business_page.dart';
import '../../features/legal/presentation/pages/legal_page.dart';
import '../../core/widgets/components.dart';
import '../driver_shell/driver_shell.dart';
import '../shell/app_shell.dart';
import '../theme/app_theme.dart';
import 'lux_transitions.dart';

/// /booking solo tiene sentido con el viaje elegido en Inicio (extra).
/// Abierta directamente (enlace, recarga) mostraba «PRECIO FINAL Bs 20» sin
/// recorrido (E23): se vuelve al inicio.
String? bookingRouteRedirect(Object? extra) =>
    extra is BookingFormData ? null : LuxRoutes.home;

abstract class LuxRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const home = '/';
  static const booking = '/booking';
  static const rideType = '/ride-type';
  static const ride = '/ride/:rideId';
  static const profile = '/profile';
  static const trips = '/trips';
  static const admin = '/admin';
  static const payment = '/payment';
  static const addCard = '/payment/add';

  // Driver Routes
  static const driverHome = '/driver';
  static const driverLogin = '/driver/login';
  static const driverQueue = '/driver/queue';
  static const driverEarnings = '/driver/earnings';
  static const driverProfile = '/driver/profile';
  static const driverActiveRide = '/driver/active-ride/:bookingId';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthBloc authBloc) => GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: LuxRoutes.home,
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuth = authState is AuthAuthenticated;
        final going = state.matchedLocation;
        // Enlace al que quería ir (p. ej. /ride/abc) antes de pasar por el
        // splash o el login, para volver a él después.
        final from = state.uri.queryParameters['from'];
        final target = from ?? state.uri.toString();
        String keep(String route) {
          final t = target;
          final isEntry = t == '/' ||
              t.startsWith(LuxRoutes.splash) ||
              t.startsWith(LuxRoutes.login) ||
              t.startsWith(LuxRoutes.register);
          return isEntry ? route : '$route?from=${Uri.encodeComponent(t)}';
        }

        // 1. Initial State: Only show splash if we are NOT already trying to reach a specific driver path.
        if (authState is AuthInitial) {
          if (going.startsWith('/driver')) return null;
          return going == LuxRoutes.splash ? null : keep(LuxRoutes.splash);
        }

        // 2. Loading State: Don't block navigation to driver paths while auth is resolving.
        if (authState is AuthLoading) {
          return null;
        }

        // 3. User is Authenticated: Role-based destination rules
        if (isAuth) {
          final user = (authState).user;
          final isAdmin = user.role == UserRole.admin;
          final isDriver = user.role == UserRole.driver;
          final isDriverPath = going.startsWith('/driver');

          // ── Admin: always send to /admin, never block them ───────────────
          if (isAdmin) {
            // If already at admin panel, let them stay
            if (going == LuxRoutes.admin) return null;
            // Otherwise always redirect to admin
            return LuxRoutes.admin;
          }

          // ── Driver: force to driver pages ────────────────────────────────
          if (isDriver && !isDriverPath && going != LuxRoutes.profile) {
            return LuxRoutes.driverHome;
          }

          // ── Traveler: block driver pages ──────────────────────────────────
          if (!isDriver && isDriverPath) {
            return LuxRoutes.home;
          }

          // If landing on splash/auth while authed, send to correct home
          if (going == LuxRoutes.splash ||
              going == LuxRoutes.login ||
              going == LuxRoutes.register ||
              going == LuxRoutes.driverLogin) {
            if (from != null && from.startsWith('/') && !isDriver) return from;
            return isDriver ? LuxRoutes.driverHome : LuxRoutes.home;
          }
        }

        // 4. Guest (Unauthenticated) logic
        if (!isAuth) {
          bool guestOk(String path) {
            final common = path == LuxRoutes.login ||
                path == LuxRoutes.register ||
                path == LuxRoutes.home ||
                path == LuxRoutes.driverLogin ||
                path.startsWith('/ride-type') ||
                path.startsWith('/booking') ||
                path.startsWith('/legal') ||
                path == '/empresas';
            return common || (kIsWeb && path.startsWith('/servicios'));
          }

          // Al resolverse la sesión sin usuario, el splash lleva al enlace
          // público pedido (privacidad, empresas…) en vez de al login.
          if (going == LuxRoutes.splash) {
            final wanted = from != null ? Uri.tryParse(from)?.path : null;
            if (wanted != null && wanted.startsWith('/')) {
              // Un enlace privado (p. ej. /trips) pasa por el login y vuelve.
              return guestOk(wanted) ? from : keep(LuxRoutes.login);
            }
            return kIsWeb ? LuxRoutes.home : LuxRoutes.login;
          }

          final isDriverPath = going.startsWith('/driver');
          // If explicitly trying to enter via driver path, go to driver login.
          if (kIsWeb && isDriverPath && going != LuxRoutes.driverLogin) {
            return LuxRoutes.driverLogin;
          }
          if (!guestOk(going)) return keep(LuxRoutes.login);
        }

        // 5. Admin guard
        if (going == LuxRoutes.admin) {
          final isAdmin = isAuth && (authState).user.role == UserRole.admin;
          if (!isAdmin) return LuxRoutes.home;
        }

        return null;
      },
      refreshListenable: _BlocListenable(authBloc),
      routes: [
        GoRoute(
          path: LuxRoutes.splash,
          pageBuilder: (c, s) => _fade(const _SplashPage(), s),
        ),
        GoRoute(
          path: LuxRoutes.login,
          pageBuilder: (c, s) => _fade(const LoginPage(), s),
        ),
        GoRoute(
          path: LuxRoutes.driverLogin,
          pageBuilder: (c, s) => _fade(const LoginPage(), s),
        ),
        GoRoute(
          path: '/driver/onboarding',
          pageBuilder: (c, s) => _fade(const DriverOnboardingScreen(), s),
        ),
        GoRoute(
          path: '/empresas',
          pageBuilder: (c, s) => _fade(const BusinessPage(), s),
        ),
        GoRoute(
          path: '/legal/terminos',
          pageBuilder: (c, s) => _fade(const LegalPage(doc: LegalDoc.terms), s),
        ),
        GoRoute(
          path: '/legal/privacidad',
          pageBuilder: (c, s) =>
              _fade(const LegalPage(doc: LegalDoc.privacy), s),
        ),
        GoRoute(
          path: '/servicios/recogida-inmediata',
          pageBuilder: (c, s) => _fade(const ImmediatePickupPage(), s),
        ),
        GoRoute(
          path: '/servicios/traslado-aeropuerto',
          pageBuilder: (c, s) => _fade(const AirportTransferPage(), s),
        ),
        GoRoute(
          path: '/servicios/contratacion-por-horas',
          pageBuilder: (c, s) => _fade(const HourlyCharterPage(), s),
        ),
        GoRoute(
          path: LuxRoutes.register,
          pageBuilder: (c, s) => _fade(const RegisterPage(), s),
        ),
        GoRoute(
          path: LuxRoutes.verifyEmail,
          pageBuilder: (c, s) {
            final st = authBloc.state;
            return _slide(
              VerifyEmailPage(
                email: st is AuthAuthenticated ? st.user.email : null,
              ),
              s,
            );
          },
        ),
        GoRoute(
          path: LuxRoutes.admin,
          pageBuilder: (c, s) => _fade(const AdminDashboardPage(), s),
        ),
        GoRoute(
          path: LuxRoutes.driverActiveRide,
          pageBuilder: (c, s) => _slide(
            DriverActiveRideScreen(
              bookingId: s.pathParameters['bookingId'] ?? '',
            ),
            s,
          ),
        ),
        GoRoute(
          path: LuxRoutes.payment,
          pageBuilder: (c, s) => _slide(const PaymentScreen(), s),
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (c, s) => _slide(const AddCardScreen(), s),
            ),
          ],
        ),

        // Driver Shell
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              DriverShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: LuxRoutes.driverHome,
                  pageBuilder: (c, s) => _fade(const DriverHomeScreen(), s),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: LuxRoutes.driverQueue,
                  pageBuilder: (c, s) => _fade(const DriverQueueScreen(), s),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: LuxRoutes.driverEarnings,
                  pageBuilder: (c, s) => _fade(const DriverEarningsScreen(), s),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: LuxRoutes.driverProfile,
                  pageBuilder: (c, s) => _fade(const ProfileScreen(), s),
                ),
              ],
            ),
          ],
        ),

        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: LuxRoutes.home,
                  pageBuilder: (c, s) => _fade(const HomeScreen(), s),
                  routes: [
                    GoRoute(
                      path: 'ride-type',
                      pageBuilder: (c, s) => _slide(const RideTypePage(), s),
                    ),
                    GoRoute(
                      path: 'booking',
                      redirect: (c, s) => bookingRouteRedirect(s.extra),
                      pageBuilder: (c, s) => _slide(const BookingScreen(), s),
                    ),
                    GoRoute(
                      path: 'ride/:rideId',
                      pageBuilder: (c, s) => _fade(
                        RideScreen(rideId: s.pathParameters['rideId'] ?? ''),
                        s,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: LuxRoutes.trips,
                  pageBuilder: (c, s) => _fade(const TripsScreen(), s),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: LuxRoutes.profile,
                  pageBuilder: (c, s) => _fade(const ProfileScreen(), s),
                ),
              ],
            ),
          ],
        ),
      ],
      errorPageBuilder: (context, state) => _fade(const _NotFoundPage(), state),
    );

// ---------------------------------------------------------------------------
// Listenable bridge for BLoC → GoRouter redirect
// ---------------------------------------------------------------------------

class _BlocListenable extends ChangeNotifier {
  _BlocListenable(this._bloc) {
    _bloc.stream.listen((_) => notifyListeners());
  }
  final AuthBloc _bloc;
}

// ---------------------------------------------------------------------------
// Transitions
// ---------------------------------------------------------------------------

CustomTransitionPage<void> _fade(Widget child, GoRouterState state) =>
    luxFadeThroughPage(child, state);

CustomTransitionPage<void> _slide(Widget child, GoRouterState state) =>
    luxPushPage(child, state);

// ---------------------------------------------------------------------------

class _SplashPage extends StatelessWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: LuxColors.bg,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - t)),
                child: child,
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LuxelaneWordmark(size: 14),
                SizedBox(height: 36),
                SizedBox(
                  width: 72,
                  child: LinearProgressIndicator(
                    minHeight: 1,
                    backgroundColor: LuxColors.border,
                    color: LuxColors.sapphire,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: LuxColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LuxelaneWordmark(),
                const SizedBox(height: 48),
                Text(
                  'Este camino no existe.',
                  textAlign: TextAlign.center,
                  style: LuxTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Te llevamos de vuelta al inicio.',
                  textAlign: TextAlign.center,
                  style: LuxTypography.bodyMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 240,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('VOLVER AL INICIO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
