import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../company/presentation/widgets/companies_admin_tab.dart';
import '../bloc/admin_bloc.dart';
import '../widgets/admin_sections.dart';
import '../widgets/admin_shared_widgets.dart';
import '../widgets/reports_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _section = 0;

  List<String> _sections(AppLocalizations l) => [
        l.adminSectionDashboard,
        l.adminSectionBookings,
        l.adminSectionReports,
        l.adminSectionCompanies,
        l.adminSectionDrivers,
        l.adminSectionVehicles,
        l.adminSectionUsers,
        l.adminSectionPricing,
        l.adminSectionAudit,
        l.adminSectionSettings,
      ];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.confirmation_number_outlined,
    Icons.insights_outlined,
    Icons.business_outlined,
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
        title: Text(context.l10n.profileSignOut, style: LuxTypography.titleLarge),
        content: Text(
          context.l10n.adminSignOutConfirm,
          style: LuxTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: Text(
              context.l10n.profileSignOut,
              style: const TextStyle(color: LuxColors.error, fontWeight: FontWeight.w600),
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
            tooltip: context.l10n.commonBack,
            onPressed: () => context.go('/'),
          ),
          title: Text(context.l10n.adminTitle),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: LuxSpacing.md),
              padding: const EdgeInsets.symmetric(
                  horizontal: LuxSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: LuxColors.accentSubtle,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                border: Border.all(color: LuxColors.accent.withOpacity(0.4)),
              ),
              child: Text(context.l10n.coreRoleAdmin.toUpperCase(),
                  style: LuxTypography.caption.copyWith(
                      color: LuxColors.accent, fontWeight: FontWeight.w700)),
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
                  _sections(context.l10n).length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: LuxSpacing.sm),
                    child: SectionChip(
                      label: _sections(context.l10n)[i],
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
                            color: LuxColors.accentSubtle,
                            borderRadius: BorderRadius.circular(LuxRadius.sm),
                          ),
                          child: Text(
                            context.l10n.adminPanelBadge.toUpperCase(),
                            style: LuxTypography.caption.copyWith(
                                color: LuxColors.accent,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const LuxDivider(),
                  const SizedBox(height: LuxSpacing.sm),
                  ...List.generate(
                    _sections(context.l10n).length,
                    (i) => AdminNavItem(
                      icon: _icons[i],
                      label: _sections(context.l10n)[i],
                      selected: _section == i,
                      onTap: () => setState(() => _section = i),
                    ),
                  ),
                  const Spacer(),
                  const LuxDivider(),
                  AdminNavItem(
                    icon: Icons.logout_rounded,
                    label: context.l10n.profileSignOut,
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
      case 2: return const ReportsTab();
      case 3: return const CompaniesAdminTab();
      case 4: return const DriversTab();
      case 5: return const VehiclesTab();
      case 6: return const UsersTab();
      case 7: return const PricingTab();
      case 8: return const AuditTab();
      case 9: return const SettingsTab();
      default: return const SizedBox();
    }
  }
}
