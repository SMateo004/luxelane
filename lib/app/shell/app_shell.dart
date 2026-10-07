import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/components.dart';
import '../../core/widgets/lux_site_chrome.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notifications/presentation/widgets/notification_bell.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _Tab(
        icon: Icons.near_me_outlined,
        activeIcon: Icons.near_me_rounded,
        label: 'Reservar'),
    _Tab(
        icon: Icons.event_note_outlined,
        activeIcon: Icons.event_note_rounded,
        label: 'Mis viajes'),
    _Tab(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: 'Perfil'),
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
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: LuxColors.blackSurface,
            border: Border(top: BorderSide(color: LuxColors.blackBorder)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _MobileTabItem(
                        tab: tabs[i],
                        active: shell.currentIndex == i,
                        onTap: () => shell.goBranch(i,
                            initialLocation: i == shell.currentIndex),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _MobileTabItem extends StatelessWidget {
  const _MobileTabItem(
      {required this.tab, required this.active, required this.onTap});
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: active,
        button: true,
        label: tab.label,
        child: InkResponse(
          onTap: onTap,
          radius: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hairline indicator: quiet, precise — no loud pills.
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: active ? 18 : 0,
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 8),
                color: LuxColors.sapphireBright,
              ),
              Icon(active ? tab.activeIcon : tab.icon,
                  size: 22,
                  color: active ? LuxColors.white : LuxColors.whiteTertiary),
              const SizedBox(height: 4),
              Text(
                tab.label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? LuxColors.white : LuxColors.whiteTertiary,
                ),
              ),
            ],
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
        return Scaffold(
          // Home page (index 0) has its own full-bleed nav overlay —
          // don't add a second header above it.
          body: Column(
            children: [
              if (shell.currentIndex != 0)
                _WebNav(auth: auth, shell: shell, tabs: tabs),
              Expanded(child: shell),
            ],
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// Web Navigation Bar — same midnight bar as the public site, so moving from
// the landing page into the account area feels like one product.
// ---------------------------------------------------------------------------

class _WebNav extends StatelessWidget {
  const _WebNav({required this.auth, required this.shell, required this.tabs});
  final AuthState auth;
  final StatefulNavigationShell shell;
  final List<_Tab> tabs;

  @override
  Widget build(BuildContext context) {
    final isAuth = auth is AuthAuthenticated;
    final narrow = MediaQuery.sizeOf(context).width < 900;
    return Container(
      height: kSiteNavHeight,
      decoration: const BoxDecoration(
        color: LuxColors.black,
        border: Border(bottom: BorderSide(color: LuxColors.blackBorder)),
      ),
      padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 56),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: const LuxelaneWordmark(),
            ),
          ),
          const Spacer(),
          if (isAuth) ...[
            if (!narrow)
              for (var i = 1; i < tabs.length; i++) ...[
                _ShellLink(
                  label: tabs[i].label,
                  active: shell.currentIndex == i,
                  onTap: () => shell.goBranch(i),
                ),
                const SizedBox(width: 32),
              ],
            if (!narrow) ...[
              LuxNavCta(onTap: () => context.go('/')),
              const SizedBox(width: 16),
            ],
            const NotificationBell(color: Colors.white),
            const SizedBox(width: 8),
            _AvatarBtn(auth: auth, onTap: () => shell.goBranch(2)),
          ] else ...[
            const LuxServicesMenu(),
            const SizedBox(width: 32),
            LuxNavLink('Iniciar sesión', onTap: () => context.go('/login')),
            const SizedBox(width: 24),
            LuxNavCta(onTap: () => context.go('/'), compact: narrow),
          ],
        ],
      ),
    );
  }
}

class _ShellLink extends StatelessWidget {
  const _ShellLink(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: active ? Colors.white : Colors.white.withAlpha(150),
                ),
              ),
              Positioned(
                left: 0,
                bottom: -6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 1,
                  width: active ? 18 : 0,
                  color: LuxColors.sapphireBright,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AvatarBtn extends StatelessWidget {
  const _AvatarBtn({required this.auth, required this.onTap});
  final AuthState auth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = auth;
    final name = a is AuthAuthenticated ? a.user.displayName : '';
    return Semantics(
      button: true,
      label: 'Mi perfil',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(90)),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'L',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFamily: 'Cormorant Garamond',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(
      {required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
