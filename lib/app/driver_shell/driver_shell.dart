import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/lux_motion.dart';

/// Contenedor de la app del chófer: cada pantalla pone su propia cabecera
/// (así no se apilan dos barras) y abajo una navegación con indicador.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static List<Widget> _items(AppLocalizations t) => [
        NavigationDestination(
          icon: const Icon(Icons.radio_button_unchecked_rounded),
          selectedIcon: const Icon(Icons.radio_button_checked_rounded),
          label: t.driverNavDrive,
        ),
        NavigationDestination(
          icon: const Icon(Icons.inbox_outlined),
          selectedIcon: const Icon(Icons.inbox_rounded),
          label: t.driverNavRequests,
        ),
        NavigationDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
          label: t.driverNavEarnings,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: t.driverNavProfile,
        ),
      ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: LuxColors.border)),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: LuxMotion.base,
            onDestinationSelected: (i) {
              if (i != navigationShell.currentIndex) LuxHaptics.tap();
              navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              );
            },
            destinations: _items(context.l10n),
          ),
        ),
      );
}
