import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/admin_finance.dart';
import '../bloc/admin_bloc.dart';
import '../widgets/admin_alerts_tab.dart';
import '../widgets/admin_finance_tab.dart';
import '../widgets/admin_incidents_strip.dart';
import '../widgets/admin_pricing_tab.dart';
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
    AdminSection.pricing: 'Tarifas',
    AdminSection.drivers: 'Chóferes',
    AdminSection.vehicles: 'Vehículos',
    AdminSection.users: 'Usuarios',
    AdminSection.business: 'Empresas',
    AdminSection.audit: 'Auditoría',
    AdminSection.alerts: 'Alertas',
    AdminSection.settings: 'Configuración',
  };
  static const _icons = {
    AdminSection.dashboard: Icons.dashboard_outlined,
    AdminSection.operations: Icons.confirmation_number_outlined,
    AdminSection.finance: Icons.account_balance_outlined,
    AdminSection.pricing: Icons.sell_outlined,
    AdminSection.drivers: Icons.badge_outlined,
    AdminSection.vehicles: Icons.directions_car_outlined,
    AdminSection.users: Icons.people_outline,
    AdminSection.business: Icons.business_outlined,
    AdminSection.audit: Icons.history_rounded,
    AdminSection.alerts: Icons.notification_important_outlined,
    AdminSection.settings: Icons.settings_outlined,
  };

  /// La barra lateral agrupa las secciones por tarea.
  static const _groups = [
    (
      'Operación',
      [
        AdminSection.dashboard,
        AdminSection.operations,
        AdminSection.drivers,
        AdminSection.vehicles,
      ]
    ),
    (
      'Negocio',
      [
        AdminSection.finance,
        AdminSection.pricing,
        AdminSection.business,
        AdminSection.users,
      ]
    ),
    (
      'Sistema',
      [AdminSection.alerts, AdminSection.audit, AdminSection.settings]
    ),
  ];

  /// Una línea de contexto bajo el título de cada sección.
  static const _subtitles = {
    AdminSection.dashboard: 'Lo que pasa hoy en Luxelane, de un vistazo.',
    AdminSection.operations: 'Reservas, asignaciones y estados en vivo.',
    AdminSection.finance: 'Facturación, cobros y liquidaciones.',
    AdminSection.pricing: 'Tarifas por clase de vehículo y servicio.',
    AdminSection.drivers: 'Verificación y disponibilidad de chóferes.',
    AdminSection.vehicles: 'La flota y su estado.',
    AdminSection.users: 'Cuentas, roles y accesos.',
    AdminSection.business: 'Solicitudes de empresas.',
    AdminSection.audit: 'Cada acción del panel, con su autor.',
    AdminSection.alerts: 'Avisos del servidor que piden revisión.',
    AdminSection.settings: 'Ajustes generales de la plataforma.',
  };

  void _go(AdminSection s) {
    if (s != _section) LuxHaptics.tap();
    setState(() => _section = s);
  }

  /// Elementos que requieren acción en cada sección.
  int? _badge(AdminSection s, AdminState state) => switch (s) {
        AdminSection.operations => state.pendingRidesCount,
        AdminSection.finance =>
          state.finance(FinancePeriod.all).receivablesCount,
        AdminSection.drivers =>
          state.drivers.where((d) => !d.documentsVerified).length,
        AdminSection.alerts => state.openAlertsCount,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final web = isWeb(context);
    return BlocProvider(
      create: (context) => sl<AdminBloc>()..add(AdminDataRequested()),
      child: BlocListener<AdminBloc, AdminState>(
        // Un único punto de avisos para todas las secciones.
        listenWhen: (a, b) => a.messageSeq != b.messageSeq,
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
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          '¿Seguro que quieres cerrar sesión del panel de administración?',
          style: LuxTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout() => Scaffold(
        appBar: AppBar(
          // El admin siempre vuelve al panel (router), así que no hay "atrás".
          automaticallyImplyLeading: false,
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
            Expanded(child: _withLoadError(_sectionBody())),
          ],
        ),
      );

  Widget _webLayout() => Row(
        children: [
          SizedBox(
            width: 252,
            child: Container(
              color: LuxColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: LuxelaneWordmark(size: 11),
                  ),
                  Expanded(
                    child: BlocBuilder<AdminBloc, AdminState>(
                      builder: (context, state) => ListView(
                        padding: const EdgeInsets.only(bottom: 12),
                        children: [
                          for (final (label, sections) in _groups) ...[
                            AdminNavGroup(label),
                            for (final s in sections)
                              AdminNavItem(
                                icon: _icons[s]!,
                                label: _labels[s]!,
                                badge: _badge(s, state),
                                selected: _section == s,
                                onTap: () => _go(s),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const LuxDivider(),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, auth) {
                      final name = auth is AuthAuthenticated
                          ? auth.user.displayName
                          : 'Administración';
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: LuxColors.sapphireTint,
                              child: Text(
                                name.isEmpty ? 'A' : name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Cormorant Garamond',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: LuxColors.sapphire,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: LuxTypography.titleMedium
                                          .copyWith(fontSize: 13)),
                                  const Text('Administración',
                                      style: LuxTypography.caption),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cerrar sesión',
                              onPressed: () => _confirmSignOut(context),
                              icon: const Icon(Icons.logout_rounded,
                                  size: 18, color: LuxColors.inkTertiary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const LuxDivider(vertical: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminPageHeader(
                  title: _labels[_section]!,
                  subtitle: _subtitles[_section],
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: LuxMotion.of(context, LuxMotion.base),
                    switchInCurve: LuxMotion.decelerate,
                    child: KeyedSubtree(
                      key: ValueKey(_section),
                      child: _withLoadError(_sectionBody()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  /// Si alguna lista no cargó, se dice arriba en vez de mostrar la sección
  /// como si estuviera vacía.
  Widget _withLoadError(Widget body) => BlocBuilder<AdminBloc, AdminState>(
        buildWhen: (a, b) => a.loadError != b.loadError,
        builder: (context, state) => Column(
          children: [
            // SOS: siempre arriba, en cualquier sección.
            const AdminIncidentsStrip(),
            if (state.loadError != null)
              MaterialBanner(
                backgroundColor: LuxColors.error.withValues(alpha: 0.08),
                leading:
                    const Icon(Icons.cloud_off_rounded, color: LuxColors.error),
                content: Text(
                    '${state.loadError} Los datos de esta pantalla pueden '
                    'estar incompletos.',
                    style: LuxTypography.bodyMedium),
                actions: [
                  TextButton(
                    onPressed: () =>
                        context.read<AdminBloc>().add(AdminDataRequested()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            Expanded(child: body),
          ],
        ),
      );

  Widget _sectionBody() => switch (_section) {
        AdminSection.dashboard => DashboardTab(onNavigate: _go),
        AdminSection.operations => const BookingsTab(),
        AdminSection.finance => const FinanceTab(),
        AdminSection.pricing => const PricingTab(),
        AdminSection.drivers => const DriversTab(),
        AdminSection.vehicles => const VehiclesTab(),
        AdminSection.business => const BusinessLeadsTab(),
        AdminSection.users => const UsersTab(),
        AdminSection.audit => const AuditTab(),
        AdminSection.alerts => const AlertsTab(),
        AdminSection.settings => const SettingsTab(),
      };
}
