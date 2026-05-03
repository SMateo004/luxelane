import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/enums.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/booking/presentation/pages/booking_screen.dart';
import '../../features/booking/presentation/pages/ride_type_page.dart';
import '../../features/driver/presentation/pages/driver_active_ride_screen.dart';
import '../../features/driver/presentation/pages/driver_earnings_screen.dart';
import '../../features/driver/presentation/pages/driver_home_screen.dart';
import '../../features/driver/presentation/pages/driver_queue_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/payments/presentation/pages/add_card_screen.dart';
import '../../features/payments/presentation/pages/payment_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/ride/presentation/pages/ride_screen.dart';
import '../../features/trips/presentation/pages/trips_screen.dart';
import '../driver_shell/driver_shell.dart';
import '../shell/app_shell.dart';
import '../theme/app_theme.dart';

abstract class LuxRoutes {
  static const splash   = '/splash';
  static const login    = '/login';
  static const register = '/register';
  static const home     = '/';
  static const booking  = '/booking';
  static const rideType = '/ride-type';
  static const ride     = '/ride/:rideId';
  static const profile  = '/profile';
  static const trips    = '/trips';
  static const admin    = '/admin';
  static const payment  = '/payment';
  static const addCard  = '/payment/add';

  // Driver Routes
  static const driverHome     = '/driver';
  static const driverLogin    = '/driver/login';
  static const driverQueue    = '/driver/queue';
  static const driverEarnings = '/driver/earnings';
  static const driverProfile  = '/driver/profile';
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

        // 1. Initial State: Only show splash if we are NOT already trying to reach a specific driver path.
        if (authState is AuthInitial) {
          if (going.startsWith('/driver')) return null; 
          return going == LuxRoutes.splash ? null : LuxRoutes.splash;
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
          if (going == LuxRoutes.splash || going == LuxRoutes.login ||
              going == LuxRoutes.register || going == LuxRoutes.driverLogin) {
            return isDriver ? LuxRoutes.driverHome : LuxRoutes.home;
          }
        }

        // 4. Guest (Unauthenticated) logic
        if (!isAuth) {
          final isDriverPath = going.startsWith('/driver');
          
          if (kIsWeb) {
            const webGuestOk = {LuxRoutes.login, LuxRoutes.register, LuxRoutes.home, LuxRoutes.driverLogin};
            final guestOk = webGuestOk.contains(going) ||
                going.startsWith('/ride-type') ||
                going.startsWith('/booking');
            
            // If explicitly trying to enter via driver path, go to driver login.
            // But if on general pages, stay on general login.
            if (isDriverPath && going != LuxRoutes.driverLogin) {
              return LuxRoutes.driverLogin;
            }
            
            if (!guestOk) return LuxRoutes.login;
          } else {
            // Mobile rules...
            final mobileGuestOk = going == LuxRoutes.login ||
                going == LuxRoutes.register ||
                going == LuxRoutes.home ||
                going == LuxRoutes.driverLogin ||
                going.startsWith('/ride-type') ||
                going.startsWith('/booking');
            if (!mobileGuestOk) return LuxRoutes.login;
          }
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
          path: LuxRoutes.register,
          pageBuilder: (c, s) => _fade(const RegisterPage(), s),
        ),
        GoRoute(
          path: LuxRoutes.admin,
          pageBuilder: (c, s) => _fade(const AdminDashboardPage(), s),
        ),
        GoRoute(
          path: LuxRoutes.driverActiveRide,
          pageBuilder: (c, s) => _slide(
            DriverActiveRideScreen(bookingId: s.pathParameters['bookingId'] ?? ''),
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
          builder: (context, state, shell) => DriverShell(navigationShell: shell),
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
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );

CustomTransitionPage<void> _slide(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );

// ---------------------------------------------------------------------------

class _SplashPage extends StatelessWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LUXELANE',
                style: TextStyle(
                  color: LuxColors.sapphire,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 8,
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: LuxColors.sapphire,
                ),
              ),
            ],
          ),
        ),
      );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('404',
                  style: TextStyle(color: Colors.white, fontSize: 64)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
}
