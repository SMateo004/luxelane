import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../widgets/admin_sections.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _section = 0;

  static const _sections = [
    'Dashboard',
    'Bookings',
    'Drivers',
    'Vehicles',
    'Users',
    'Pricing',
    'Audit',
    'Settings'
  ];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.confirmation_number_outlined,
    Icons.directions_car_outlined,
    Icons.car_crash_outlined,
    Icons.people_outline,
    Icons.attach_money_rounded,
    Icons.history_rounded,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final web = isWeb(context);
    return BlocProvider(
      create: (context) => sl<AdminBloc>()..add(AdminDataRequested()),
      child: Scaffold(
        backgroundColor: LuxColors.black,
        body: web ? _webLayout() : _mobileLayout(),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.blackElevated,
        title: const Text('Sign Out', style: LuxTypography.titleLarge),
        content: const Text(
          'Are you sure you want to sign out of the admin panel?',
          style: LuxTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: LuxColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout() => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Admin'),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: LuxSpacing.md),
              padding: const EdgeInsets.symmetric(
                  horizontal: LuxSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: LuxColors.sapphireSubtle,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                border: Border.all(color: LuxColors.sapphire.withOpacity(0.4)),
              ),
              child: Text('ADMIN',
                  style: LuxTypography.caption.copyWith(
                      color: LuxColors.sapphire, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(LuxSpacing.md),
              child: Row(
                children: List.generate(
                  _sections.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: LuxSpacing.sm),
                    child: SectionChip(
                      label: _sections[i],
                      selected: _section == i,
                      onTap: () => setState(() => _section = i),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _sectionBody()),
          ],
        ),
      );

  Widget _webLayout() => Row(
        children: [
          // Admin sidebar
          SizedBox(
            width: 240,
            child: Container(
              color: LuxColors.blackSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(LuxSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LuxelaneWordmark(),
                        const SizedBox(height: LuxSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: LuxSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: LuxColors.sapphireSubtle,
                            borderRadius: BorderRadius.circular(LuxRadius.sm),
                          ),
                          child: Text(
                            'ADMIN PANEL',
                            style: LuxTypography.caption.copyWith(
                                color: LuxColors.sapphire,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const LuxDivider(),
                  const SizedBox(height: LuxSpacing.sm),
                  ...List.generate(
                    _sections.length,
                    (i) => AdminNavItem(
                      icon: _icons[i],
                      label: _sections[i],
                      selected: _section == i,
                      onTap: () => setState(() => _section = i),
                    ),
                  ),
                  const Spacer(),
                  const LuxDivider(),
                  AdminNavItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    selected: false,
                    onTap: () => _confirmSignOut(context),
                  ),
                  const SizedBox(height: LuxSpacing.md),
                ],
              ),
            ),
          ),
          const LuxDivider(vertical: true),
          // Main content
          Expanded(child: _sectionBody()),
        ],
      );

  Widget _sectionBody() {
    switch (_section) {
      case 0: return const DashboardTab();
      case 1: return const BookingsTab();
      case 2: return const DriversTab();
      case 3: return const VehiclesTab();
      case 4: return const UsersTab();
      case 5: return const PricingTab();
      case 6: return const AuditTab();
      case 7: return const SettingsTab();
      default: return const SizedBox();
    }
  }
}
