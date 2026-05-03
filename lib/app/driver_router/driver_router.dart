import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/driver/presentation/pages/driver_active_ride_screen.dart';
import '../../features/driver/presentation/pages/driver_earnings_screen.dart';
import '../../features/driver/presentation/pages/driver_home_screen.dart';
import '../../features/driver/presentation/pages/driver_queue_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../driver_shell/driver_shell.dart';

abstract class DriverRoutes {
  static const login        = '/driver/login';
  static const home         = '/driver';
  static const queue        = '/driver/queue';
  static const earnings     = '/driver/earnings';
  static const profile      = '/driver/profile';
  static const activeRide   = '/driver/active-ride/:bookingId';
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildDriverRouter(AuthBloc authBloc) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: DriverRoutes.home,
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuth = authState is AuthAuthenticated;
        final going = state.matchedLocation;

        // While checking initial auth (splash), hold on
        if (authState is AuthInitial) return null;

        // If not authenticated, force them to the driver login page
        // (unless they are already going there)
        if (!isAuth && going != DriverRoutes.login) {
          return DriverRoutes.login;
        }

        // If authenticated and hitting login, go to driver home
        if (isAuth && going == DriverRoutes.login) {
          return DriverRoutes.home;
        }

        return null;
      },
      refreshListenable: _DriverBlocListenable(authBloc),
      routes: [
        GoRoute(
          path: DriverRoutes.login,
          pageBuilder: (c, s) => _fade(const LoginPage(), s),
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
  _DriverBlocListenable(this._bloc) {
    _bloc.stream.listen((_) => notifyListeners());
  }
  final AuthBloc _bloc;
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
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Text('404', style: TextStyle(color: Colors.white, fontSize: 64)),
        ),
      );
}
