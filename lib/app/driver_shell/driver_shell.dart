import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/components.dart';
import '../../features/notifications/presentation/widgets/notification_bell.dart';
import '../theme/app_theme.dart';

class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_outlined),
      activeIcon: Icon(Icons.list_alt_rounded),
      label: 'Jobs',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.attach_money_outlined),
      activeIcon: Icon(Icons.attach_money_rounded),
      label: 'Earnings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const LuxelaneWordmark(),
          actions: const [
            NotificationBell(),
            SizedBox(width: 8),
          ],
        ),
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
          type: BottomNavigationBarType.fixed,
          backgroundColor: LuxColors.blackSurface,
          selectedItemColor: LuxColors.sapphire,
          unselectedItemColor: LuxColors.whiteTertiary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: LuxTypography.caption
              .copyWith(color: LuxColors.sapphire, fontSize: 10),
          unselectedLabelStyle:
              LuxTypography.caption.copyWith(fontSize: 10),
          items: _items,
        ),
      );
}
