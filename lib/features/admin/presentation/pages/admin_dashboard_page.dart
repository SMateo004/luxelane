import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/admin_finance.dart';
import '../bloc/admin_bloc.dart';
import '../widgets/admin_finance_tab.dart';
import '../widgets/admin_pricing_tab.dart';
import '../widgets/admin_companies_tab.dart';
import '../widgets/admin_special_tab.dart';
import '../widgets/admin_sections.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminSection _section = AdminSection.dashboard;

  static const _labels = {
    AdminSection.dashboard: 'Panel',
    AdminSection.operations: 'Operaciones',
    AdminSection.finance: 'Finanzas',
    AdminSection.companies: 'Empresas',
    AdminSection.special: 'Especiales',
    AdminSection.pricing: 'Tarifas',
    AdminSection.drivers: 'Chóferes',
    AdminSection.vehicles: 'Vehículos',
    AdminSection.users: 'Usuarios',
    AdminSection.audit: 'Auditoría',
    AdminSection.settings: 'Configuración',
  };
  static const _icons = {
    AdminSection.dashboard: Icons.dashboard_outlined,
    AdminSection.operations: Icons.confirmation_number_outlined,
    AdminSection.finance: Icons.account_balance_outlined,
    AdminSection.companies: Icons.apartment_outlined,
    AdminSection.special: Icons.flight_outlined,
    AdminSection.pricing: Icons.sell_outlined,
    AdminSection.drivers: Icons.badge_outlined,
    AdminSection.vehicles: Icons.directions_car_outlined,
    AdminSection.users: Icons.people_outline,
    AdminSection.audit: Icons.history_rounded,
    AdminSection.settings: Icons.settings_outlined,
  };

  void _go(AdminSection s) => setState(() => _section = s);

  /// Elementos que requieren acción en cada sección.
  int? _badge(AdminSection s, AdminState state) => switch (s) {
        AdminSection.operations => state.pendingRidesCount,
        AdminSection.finance =>
          state.finance(FinancePeriod.all).receivablesCount,
        AdminSection.drivers =>
          state.drivers.where((d) => !d.documentsVerified).length,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final web = isWeb(context);
    return BlocProvider(
      create: (context) => sl<AdminBloc>()..add(AdminDataRequested()),
      child: BlocListener<AdminBloc, AdminState>(
        // Un único punto de avisos para todas las secciones.
        listenWhen: (a, b) =>
            (b.successMessage != null &&
                a.successMessage != b.successMessage) ||
            (b.error != null && a.error != b.error),
        listener: (context, state) {
          if (state.error != null) {
            showLuxSnackbar(context, state.error!, isError: true);
          } else if (state.successMessage != null) {
            showLuxSnackbar(context, state.successMessage!);
          }
        },
        child: Scaffold(
          backgroundColor: LuxColors.bg,
          body: web ? _webLayout() : _mobileLayout(),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.surfaceMuted,
        title: const Text('Cerrar sesión', style: LuxTypography.titleLarge),
        content: const Text(
          '¿Seguro que quieres cerrar sesión del panel de administración?',
          style: LuxTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                  color: LuxColors.error, fontWeight: FontWeight.w600),
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
          title: Text(_labels[_section]!),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: () => _confirmSignOut(context),
            ),
          ],
        ),
        body: Column(
          children: [
            BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(LuxSpacing.md),
                child: Row(
                  children: [
                    for (final s in AdminSection.values)
                      Padding(
                        padding: const EdgeInsets.only(right: LuxSpacing.sm),
                        child: SectionChip(
                          label: (_badge(s, state) ?? 0) > 0
                              ? '${_labels[s]} · ${_badge(s, state)}'
                              : _labels[s]!,
                          selected: _section == s,
                          onTap: () => _go(s),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: _sectionBody()),
          ],
        ),
      );

  Widget _webLayout() => Row(
        children: [
          SizedBox(
            width: 240,
            child: Container(
              color: LuxColors.surface,
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
                            'PANEL ADMIN',
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
                  Expanded(
                    child: BlocBuilder<AdminBloc, AdminState>(
                      builder: (context, state) => ListView(
                        children: [
                          for (final s in AdminSection.values)
                            AdminNavItem(
                              icon: _icons[s]!,
                              label: _labels[s]!,
                              badge: _badge(s, state),
                              selected: _section == s,
                              onTap: () => _go(s),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const LuxDivider(),
                  AdminNavItem(
                    icon: Icons.logout_rounded,
                    label: 'Cerrar sesión',
                    selected: false,
                    onTap: () => _confirmSignOut(context),
                  ),
                  const SizedBox(height: LuxSpacing.md),
                ],
              ),
            ),
          ),
          const LuxDivider(vertical: true),
          Expanded(child: _sectionBody()),
        ],
      );

  Widget _sectionBody() => switch (_section) {
        AdminSection.dashboard => DashboardTab(onNavigate: _go),
        AdminSection.operations => const BookingsTab(),
        AdminSection.finance => const FinanceTab(),
        AdminSection.companies => const CompaniesTab(),
        AdminSection.special => const SpecialRequestsTab(),
        AdminSection.pricing => const PricingTab(),
        AdminSection.drivers => const DriversTab(),
        AdminSection.vehicles => const VehiclesTab(),
        AdminSection.users => const UsersTab(),
        AdminSection.audit => const AuditTab(),
        AdminSection.settings => const SettingsTab(),
      };
}
