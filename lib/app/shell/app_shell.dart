import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notifications/presentation/widgets/notification_bell.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _Tab(icon: Icons.home_outlined,    activeIcon: Icons.home_rounded,    label: 'Home',    path: '/'),
    _Tab(icon: Icons.history_outlined, activeIcon: Icons.history_rounded,  label: 'Trips',   path: '/trips'),
    _Tab(icon: Icons.person_outline,   activeIcon: Icons.person_rounded,   label: 'Profile', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context) => isWeb(context)
      ? _WebShell(shell: navigationShell, tabs: _tabs)
      : _MobileShell(shell: navigationShell, tabs: _tabs);
}

// ---------------------------------------------------------------------------
// Mobile Shell
// ---------------------------------------------------------------------------

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.shell, required this.tabs});
  final StatefulNavigationShell shell;
  final List<_Tab> tabs;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: LuxColors.blackBorder)),
          ),
          child: BottomNavigationBar(
            currentIndex: shell.currentIndex,
            onTap: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            items: tabs
                .map((t) => BottomNavigationBarItem(
                      icon: Icon(t.icon),
                      activeIcon: Icon(t.activeIcon),
                      label: t.label,
                    ))
                .toList(),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Web Shell
// ---------------------------------------------------------------------------

class _WebShell extends StatelessWidget {
  const _WebShell({required this.shell, required this.tabs});
  final StatefulNavigationShell shell;
  final List<_Tab> tabs;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthBloc, AuthState>(builder: (context, auth) {
        final isAuth = auth is AuthAuthenticated;
        return Scaffold(
          drawer: isAuth
              ? Drawer(
                  backgroundColor: LuxColors.blackSurface,
                  width: 240,
                  child: _WebRail(shell: shell, tabs: tabs),
                )
              : null,
          // Home page (index 0) has its own full-bleed nav overlay —
          // don't add a second header above it.
          body: Column(
            children: [
              if (shell.currentIndex != 0)
                _WebNav(isAuth: isAuth, auth: auth, shell: shell),
              Expanded(child: shell),
            ],
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// Web Navigation Bar — Blacklane-style
// ---------------------------------------------------------------------------

class _WebNav extends StatelessWidget {
  const _WebNav(
      {required this.isAuth, required this.auth, required this.shell});
  final bool isAuth;
  final AuthState auth;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Container(
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE8E5DF))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (isAuth) {
                  Scaffold.of(context).openDrawer();
                } else {
                  context.go('/');
                }
              },
              child: const _WordmarkLogo(),
            ),
            if (!isAuth) ...[
              const Spacer(),
              _TextNavBtn('Services', () {}),
              const SizedBox(width: 32),
              _TextNavBtn('For Business', () {}),
              const SizedBox(width: 40),
              Container(width: 1, height: 18, color: const Color(0xFFDDDAD4)),
              const SizedBox(width: 40),
              _TextNavBtn('Sign In', () => context.go('/login')),
              const SizedBox(width: 20),
              _FilledNavBtn(label: 'Book a Ride', onTap: () => context.go('/')),
            ] else ...[
              const Spacer(),
              _TextNavBtn('Home', () => shell.goBranch(0)),
              const SizedBox(width: 32),
              _TextNavBtn('My Trips', () => shell.goBranch(1)),
              const SizedBox(width: 40),
              _FilledNavBtn(label: 'Book a Ride', onTap: () => context.go('/')),
              const SizedBox(width: 12),
              NotificationBell(color: const Color(0xFF111111)),
              const SizedBox(width: 8),
              _AvatarBtn(auth: auth),
            ],
          ],
        ),
      );
}

class _WordmarkLogo extends StatelessWidget {
  const _WordmarkLogo();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF111111)),
            ),
            child: const Center(
              child: Text(
                'L',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 15,
                  fontFamily: 'Cormorant',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'LUXELANE',
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 12,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
        ],
      );
}

class _TextNavBtn extends StatelessWidget {
  const _TextNavBtn(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF666666),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
        child: Text(label),
      );
}

class _FilledNavBtn extends StatelessWidget {
  const _FilledNavBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            elevation: 0,
            shape: const RoundedRectangleBorder(
              
            ),
            textStyle: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
          child: Text(label.toUpperCase()),
        ),
      );
}

class _AvatarBtn extends StatelessWidget {
  const _AvatarBtn({required this.auth});
  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    final initial = auth is AuthAuthenticated
        ? (auth as AuthAuthenticated).user.displayName.isNotEmpty
            ? (auth as AuthAuthenticated).user.displayName[0].toUpperCase()
            : 'U'
        : 'U';
    return GestureDetector(
      onTap: () => context.go('/profile'),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDDDAD4)),
          color: const Color(0xFFF5F4F0),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontWeight: FontWeight.w500,
              fontSize: 13,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Web Rail (authenticated)
// ---------------------------------------------------------------------------

class _WebRail extends StatelessWidget {
  const _WebRail({required this.shell, required this.tabs});
  final StatefulNavigationShell shell;
  final List<_Tab> tabs;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 240,
        child: NavigationRail(
          extended: true,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) {
            Navigator.of(context).pop(); // Close the drawer
            shell.goBranch(i, initialLocation: i == shell.currentIndex);
          },
          backgroundColor: LuxColors.blackSurface,
          destinations: tabs
              .map((t) => NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.activeIcon),
                    label: Text(t.label),
                  ))
              .toList(),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: TextButton.icon(
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const LogoutRequested()),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sign Out'),
                  style: TextButton.styleFrom(
                    foregroundColor: LuxColors.whiteTertiary,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _Tab {
  const _Tab(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.path});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}
