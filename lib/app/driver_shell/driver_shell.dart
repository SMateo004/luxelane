import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/lux_motion.dart';

/// Contenedor de la app del chófer: cada pantalla pone su propia cabecera
/// (así no se apilan dos barras) y abajo una navegación con indicador.
class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _items = [
    NavigationDestination(
      icon: Icon(Icons.radio_button_unchecked_rounded),
      selectedIcon: Icon(Icons.radio_button_checked_rounded),
      label: 'Conducir',
    ),
    NavigationDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox_rounded),
      label: 'Solicitudes',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Ganancias',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
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
            destinations: _items,
          ),
        ),
      );
}
