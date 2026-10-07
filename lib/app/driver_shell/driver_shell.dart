import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/components.dart';
import '../../features/notifications/presentation/widgets/notification_bell.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static List<BottomNavigationBarItem> _items(AppLocalizations l) => [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home_rounded),
          label: l.driverTabHome,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list_alt_outlined),
          activeIcon: const Icon(Icons.list_alt_rounded),
          label: l.driverTabJobs,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.attach_money_outlined),
          activeIcon: const Icon(Icons.attach_money_rounded),
          label: l.driverStatEarnings,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline_rounded),
          activeIcon: const Icon(Icons.person_rounded),
          label: l.driverTabProfile,
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
          selectedItemColor: LuxColors.accent,
          unselectedItemColor: LuxColors.whiteTertiary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: LuxTypography.caption
              .copyWith(color: LuxColors.accent, fontSize: 10),
          unselectedLabelStyle:
              LuxTypography.caption.copyWith(fontSize: 10),
          items: _items(context.l10n),
        ),
      );
}
