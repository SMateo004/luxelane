import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/driver/presentation/bloc/driver_bloc.dart';
import '../../features/driver/presentation/pages/driver_active_ride_screen.dart';
import '../../features/driver/presentation/pages/driver_earnings_screen.dart';
import '../../features/driver/presentation/pages/driver_home_screen.dart';
import '../../features/driver/presentation/pages/driver_documents_screen.dart';
import '../../features/driver/presentation/pages/driver_onboarding_screen.dart';
import '../../features/driver/presentation/pages/driver_queue_screen.dart';
import '../../features/legal/presentation/pages/legal_pages.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../l10n/l10n.dart';
import '../driver_shell/driver_shell.dart';

abstract class DriverRoutes {
  static const login        = '/driver/login';
  static const home         = '/driver';
  static const onboarding   = '/driver/onboarding';
  static const documents    = '/driver/documents';
  static const queue        = '/driver/queue';
  static const earnings     = '/driver/earnings';
  static const profile      = '/driver/profile';
  static const activeRide   = '/driver/active-ride/:bookingId';
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildDriverRouter(AuthBloc authBloc, DriverBloc driverBloc) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: DriverRoutes.home,
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuth = authState is AuthAuthenticated;
        final going = state.matchedLocation;

        // Legal, contact and account deletion are public.
        if (const {'/terminos', '/privacidad', '/contacto', '/eliminar-cuenta'}.contains(going)) {
          return null;
        }

        // While checking initial auth, hold on
        if (authState is AuthInitial || authState is AuthLoading) return null;

        // If not authenticated, go to login
        if (!isAuth && going != DriverRoutes.login) {
          return DriverRoutes.login;
        }

        // If authenticated and on login page, go to home
        if (isAuth && going == DriverRoutes.login) {
          return DriverRoutes.home;
        }

        // If driver hasn't completed onboarding, redirect there
        if (isAuth &&
            driverBloc.state is DriverOnboardingRequired &&
            going != DriverRoutes.onboarding) {
          return DriverRoutes.onboarding;
        }

        // Once onboarding is done, don't let them revisit it
        if (isAuth &&
            driverBloc.state is! DriverOnboardingRequired &&
            going == DriverRoutes.onboarding) {
          return DriverRoutes.home;
        }

        return null;
      },
      refreshListenable: _DriverBlocListenable(authBloc, driverBloc),
      routes: [
        GoRoute(
          path: DriverRoutes.login,
          pageBuilder: (c, s) => _fade(const LoginPage(), s),
        ),
        GoRoute(path: '/terminos', pageBuilder: (c, s) => _fade(LegalPage.terms(), s)),
        GoRoute(path: '/privacidad', pageBuilder: (c, s) => _fade(LegalPage.privacy(), s)),
        GoRoute(path: '/contacto', pageBuilder: (c, s) => _fade(const ContactPage(), s)),
        GoRoute(path: '/eliminar-cuenta', pageBuilder: (c, s) => _fade(const DeleteAccountPage(), s)),
        GoRoute(
          path: DriverRoutes.onboarding,
          pageBuilder: (c, s) => _fade(const DriverOnboardingScreen(), s),
        ),
        GoRoute(
          path: DriverRoutes.documents,
          pageBuilder: (c, s) => _slide(const DriverDocumentsScreen(), s),
        ),
        GoRoute(
          path: '/driver/active-ride/:bookingId',
          pageBuilder: (c, s) => _slide(
            DriverActiveRideScreen(
              bookingId: s.pathParameters['bookingId'] ?? '',
            ),
            s,
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              DriverShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: DriverRoutes.home,
                  pageBuilder: (c, s) =>
                      _fade(const DriverHomeScreen(), s),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: DriverRoutes.queue,
                  pageBuilder: (c, s) =>
                      _fade(const DriverQueueScreen(), s),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: DriverRoutes.earnings,
                  pageBuilder: (c, s) =>
                      _fade(const DriverEarningsScreen(), s),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: DriverRoutes.profile,
                  pageBuilder: (c, s) =>
                      _fade(const ProfileScreen(), s),
                ),
              ],
            ),
          ],
        ),
      ],
      errorPageBuilder: (context, state) => _fade(
        const _NotFoundPage(),
        state,
      ),
    );

class _DriverBlocListenable extends ChangeNotifier {
  _DriverBlocListenable(this._authBloc, this._driverBloc) {
    _authBloc.stream.listen((_) => notifyListeners());
    _driverBloc.stream.listen((_) => notifyListeners());
  }
  final AuthBloc _authBloc;
  final DriverBloc _driverBloc;
}

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
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('404', style: TextStyle(color: Colors.white, fontSize: 64)),
              const SizedBox(height: 8),
              Text(context.l10n.routerNotFoundTitle,
                  style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(DriverRoutes.home),
                child: Text(context.l10n.routerGoHome),
              ),
            ],
          ),
        ),
      );
}
