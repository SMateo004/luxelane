import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../domain/admin_finance.dart';
import '../../domain/admin_operations.dart';
import '../bloc/admin_bloc.dart';
import 'admin_finance_tab.dart';
import 'admin_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Panel  (estado del negocio y lo que requiere atención)
// ─────────────────────────────────────────────────────────────────────────────

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, this.onNavigate});

  /// Abre otra sección del panel (índice de AdminDashboardPage).
  final ValueChanged<AdminSection>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading && state.bookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final month = state.finance(FinancePeriod.thisMonth);
        final week = state.finance(FinancePeriod.last7);
        final unassigned = state.bookings
            .where((b) => b.status == BookingStatus.pending)
            .length;
        final unverified =
            state.drivers.where((d) => !d.documentsVerified).length;
        final priceReviews = state.bookings
            .where((b) =>
                b.pricingReviewReason != null &&
                !AdminOperations.isClosed(b.status))
            .length;
        final alerts = <Widget>[
          if (state.isMaintenanceMode)
            _AlertRow(
              icon: Icons.construction_rounded,
              color: LuxColors.error,
              text: 'Modo mantenimiento activo: los pasajeros no pueden '
                  'reservar.',
              action: 'Reanudar',
              onTap: () => context
                  .read<AdminBloc>()
                  .add(const AdminToggleMaintenanceModeRequested(false)),
            ),
          if (unassigned > 0)
            _AlertRow(
              icon: Icons.hourglass_top_rounded,
              color: LuxColors.warning,
              text: '$unassigned reservas pendientes sin chófer',
              action: 'Ver',
              onTap: () => onNavigate?.call(AdminSection.operations),
            ),
          if (priceReviews > 0)
            _AlertRow(
              icon: Icons.sell_outlined,
              color: LuxColors.warning,
              text: '$priceReviews reservas activas con precio fuera de tarifa',
              action: 'Ver',
              onTap: () => onNavigate?.call(AdminSection.operations),
            ),
          if (month.receivablesCount > 0)
            _AlertRow(
              icon: Icons.pending_actions_outlined,
              color: LuxColors.warning,
              text: '${month.receivablesCount} viajes de este mes sin cobrar '
                  '(${bs(month.receivables)})',
              action: 'Conciliar',
              onTap: () => onNavigate?.call(AdminSection.finance),
            ),
          if (unverified > 0)
            _AlertRow(
              icon: Icons.badge_outlined,
              color: LuxColors.warning,
              text: '$unverified chóferes sin verificar',
              action: 'Revisar',
              onTap: () => onNavigate?.call(AdminSection.drivers),
            ),
        ];

        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            const SectionHeader(title: 'Requiere atención'),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              child: alerts.isEmpty
                  ? const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: LuxColors.success),
                        SizedBox(width: LuxSpacing.md),
                        Text('Todo en orden', style: LuxTypography.bodyMedium),
                      ],
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < alerts.length; i++) ...[
                          if (i > 0) const LuxDivider(),
                          alerts[i],
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Este mes'),
            const SizedBox(height: LuxSpacing.md),
            FinanceKpis(summary: month, compact: true),
            const SizedBox(height: LuxSpacing.md),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 920
                  ? 4
                  : c.maxWidth >= 460
                      ? 2
                      : 1;
              final w = (c.maxWidth - (cols - 1) * LuxSpacing.md) / cols;
              return Wrap(
                spacing: LuxSpacing.md,
                runSpacing: LuxSpacing.md,
                children: [
                  AdminKpiTile(
                    width: w,
                    label: 'En curso ahora',
                    value: '${state.activeRidesCount}',
                    icon: Icons.route_outlined,
                    sub: '${month.pipelineCount} reservas activas',
                    color: LuxColors.success,
                  ),
                  AdminKpiTile(
                    width: w,
                    label: 'Pendientes',
                    value: '${state.pendingRidesCount}',
                    icon: Icons.hourglass_top_rounded,
                    sub: 'Esperando chófer',
                    color: state.pendingRidesCount > 0
                        ? LuxColors.warning
                        : LuxColors.whiteSecondary,
                  ),
                  AdminKpiTile(
                    width: w,
                    label: 'Canceladas (mes)',
                    value: '${month.cancelledCount}',
                    icon: Icons.cancel_outlined,
                    sub:
                        '${bs(month.cancelledValue, short: true)} no facturados',
                    color: LuxColors.whiteSecondary,
                  ),
                  AdminKpiTile(
                    width: w,
                    label: 'Usuarios',
                    value: '${state.users.length}',
                    icon: Icons.people_outline,
                    sub: '${state.drivers.where((d) => d.isAvailable).length}'
                        ' de ${state.drivers.length} chóferes en línea',
                    color: LuxColors.whiteSecondary,
                  ),
                ],
              );
            }),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Facturación últimos 7 días'),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              padding: const EdgeInsets.all(LuxSpacing.lg),
              child:
                  SizedBox(height: 200, child: DailyRevenueChart(week.daily)),
            ),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Actividad reciente'),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.md),
              child: Column(
                children: [
                  for (final b in state.bookings.take(6)) ...[
                    if (b != state.bookings.first) const LuxDivider(),
                    _AdminBookingTile(booking: b, state: state),
                  ],
                  if (state.bookings.isEmpty)
                    const AdminEmpty(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Aún no hay reservas'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Secciones del panel, en el orden del menú.
enum AdminSection {
  dashboard,
  operations,
  finance,
  pricing,
  drivers,
  vehicles,
  users,
  audit,
  settings,
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String text, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: LuxSpacing.md),
            Expanded(child: Text(text, style: LuxTypography.bodyMedium)),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Operaciones  (reservas: estado, chófer, cobro)
// ─────────────────────────────────────────────────────────────────────────────

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  BookingStatus? _filter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.isLoading && state.bookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = _search.trim().toLowerCase();
        final rows = state.bookings.where((b) {
          if (_filter != null && b.status != _filter) return false;
          if (q.isEmpty) return true;
          return b.id.toLowerCase().contains(q) ||
              state.userName(b.riderId).toLowerCase().contains(q) ||
              (b.driverId != null &&
                  state.userName(b.driverId!).toLowerCase().contains(q)) ||
              b.origin.address.toLowerCase().contains(q) ||
              b.destination.address.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  LuxSpacing.lg, LuxSpacing.md, LuxSpacing.lg, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: LuxTypography.bodyMedium,
                decoration: adminInputDecoration(
                  hint: 'Buscar por código, pasajero, chófer o dirección…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: LuxColors.whiteTertiary, size: 20),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: LuxSpacing.lg, vertical: LuxSpacing.sm),
              child: Row(
                children: [
                  AdminFilterChip(
                    label: 'Todas',
                    count: state.bookings.length,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final s in BookingStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(left: LuxSpacing.sm),
                      child: AdminFilterChip(
                        label: s.displayLabel,
                        count:
                            state.bookings.where((b) => b.status == s).length,
                        selected: _filter == s,
                        onTap: () =>
                            setState(() => _filter = _filter == s ? null : s),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const AdminEmpty(
                      icon: Icons.confirmation_number_outlined,
                      title: 'No se encontraron reservas')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: LuxSpacing.lg, vertical: LuxSpacing.sm),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const LuxDivider(),
                      itemBuilder: (_, i) =>
                          _AdminBookingTile(booking: rows[i], state: state),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminBookingTile extends StatelessWidget {
  const _AdminBookingTile({required this.booking, required this.state});
  final Booking booking;
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final payment = state.paymentFor(b);
    final charge = b.status == BookingStatus.completed
        ? FinancialSummary.chargeStatusOf(payment)
        : null;
    return InkWell(
      onTap: () => showBookingDetail(context, b.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: LuxColors.sapphireSubtle,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: Text(shortId(b.id),
                  style: LuxTypography.caption
                      .copyWith(color: LuxColors.sapphireBright)),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.userName(b.riderId),
                      style: LuxTypography.titleMedium),
                  Text(
                    '${b.origin.address} → ${b.destination.address}',
                    style: LuxTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${adminDate(b.scheduledAt)} · ${b.vehicleClass.label} · '
                    '${b.driverId != null ? state.userName(b.driverId!) : 'Sin chófer'}',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.whiteTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: LuxSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(bs(b.finalPrice ?? b.estimatedPrice),
                    style: LuxTypography.titleMedium),
                const SizedBox(height: 4),
                BookingStatusChip(status: b.status),
                if (charge != null) ...[
                  const SizedBox(height: 4),
                  AdminTag(charge.label, color: chargeStatusColor(charge)),
                ],
                if (b.pricingReviewReason != null) ...[
                  const SizedBox(height: 4),
                  const AdminTag('Revisar precio', color: LuxColors.warning),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ficha de una reserva con todas las acciones del admin. Se reconstruye con
/// el estado en vivo, así refleja el resultado de cada acción.
Future<void> showBookingDetail(BuildContext context, String bookingId) {
  final bloc = context.read<AdminBloc>();
  return showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: Dialog(
        backgroundColor: LuxColors.blackSurface,
        insetPadding: const EdgeInsets.all(LuxSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: _BookingDetail(bookingId: bookingId),
        ),
      ),
    ),
  );
}

class _BookingDetail extends StatelessWidget {
  const _BookingDetail({required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        Booking? b;
        for (final x in state.bookings) {
          if (x.id == bookingId) b = x;
        }
        if (b == null) {
          return const Padding(
            padding: EdgeInsets.all(LuxSpacing.xl),
            child: Text('La reserva ya no está disponible'),
          );
        }
        final booking = b;
        final payment = state.paymentFor(booking);
        final charge = booking.status == BookingStatus.completed
            ? FinancialSummary.chargeStatusOf(payment)
            : null;
        final next = AdminOperations.nextStatuses(booking.status)
            .where((s) => s != BookingStatus.cancelled)
            .toList();
        final canCancel = AdminOperations.canTransition(
            booking.status, BookingStatus.cancelled);
        final amount = booking.finalPrice ?? booking.estimatedPrice;
        final commission = amount * state.commissionPct / 100;

        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Reserva #${shortId(booking.id)}',
                      style: LuxTypography.titleLarge),
                ),
                BookingStatusChip(status: booking.status),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.sm),
            AdminInfoRow(
                label: 'Pasajero', value: state.userName(booking.riderId)),
            AdminInfoRow(
                label: 'Chófer',
                value: booking.driverId == null
                    ? 'Sin asignar'
                    : state.userName(booking.driverId!)),
            AdminInfoRow(label: 'Origen', value: booking.origin.address),
            AdminInfoRow(label: 'Destino', value: booking.destination.address),
            AdminInfoRow(
                label: 'Fecha del servicio',
                value: adminDate(booking.scheduledAt)),
            AdminInfoRow(
                label: 'Servicio',
                value: '${booking.serviceType.label} · '
                    '${booking.vehicleClass.label}'
                    '${booking.hours != null ? ' · ${booking.hours} h' : ''}'),
            if (booking.notes?.isNotEmpty == true)
              AdminInfoRow(label: 'Notas', value: booking.notes!),
            AdminInfoRow(label: 'Creada', value: adminDate(booking.createdAt)),
            const SizedBox(height: LuxSpacing.sm),
            const LuxDivider(),
            const SizedBox(height: LuxSpacing.sm),
            const Text('Finanzas', style: LuxTypography.titleMedium),
            AdminInfoRow(
                label: 'Precio estimado', value: bs(booking.estimatedPrice)),
            if (pricingReviewLabel(booking) != null)
              AdminInfoRow(
                  label: 'Control de tarifa',
                  value: pricingReviewLabel(booking)!,
                  valueColor: LuxColors.warning),
            AdminInfoRow(
                label: 'Precio final',
                value:
                    booking.finalPrice == null ? '—' : bs(booking.finalPrice!)),
            if (booking.status == BookingStatus.completed) ...[
              AdminInfoRow(
                  label:
                      'Comisión (${state.commissionPct.toStringAsFixed(0)} %)',
                  value: bs(commission)),
              AdminInfoRow(
                  label: 'Parte chófer', value: bs(amount - commission)),
            ],
            AdminInfoRow(
              label: 'Cobro',
              value: charge?.label ??
                  (payment == null
                      ? 'Se cobra al completar'
                      : payment.status.label),
              valueColor: charge == null ? null : chargeStatusColor(charge),
            ),
            if (payment != null)
              AdminInfoRow(label: 'Id de pago', value: payment.id),
            const SizedBox(height: LuxSpacing.md),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [
                if (AdminOperations.canAssignDriver(booking))
                  AdminActionButton(
                    icon: Icons.person_add_alt_1_outlined,
                    label: booking.driverId == null
                        ? 'Asignar chófer'
                        : 'Reasignar chófer',
                    onTap: () => _assignDriver(context, state, booking),
                  ),
                for (final s in next)
                  AdminActionButton(
                    icon: Icons.arrow_forward_rounded,
                    label: 'Marcar "${s.displayLabel}"',
                    onTap: () => _changeStatus(context, booking, s),
                  ),
                if (charge == ChargeStatus.pendingCollection ||
                    charge == ChargeStatus.failed)
                  AdminActionButton(
                    icon: Icons.point_of_sale_outlined,
                    label: 'Registrar cobro',
                    onTap: () => recordPaymentDialog(context, booking),
                  ),
                if (AdminOperations.canAdjustFinalPrice(booking, payment))
                  AdminActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Ajustar precio final',
                    onTap: () => adjustPriceDialog(context, booking),
                  ),
                if (canCancel)
                  AdminActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancelar reserva',
                    color: LuxColors.error,
                    onTap: () => _cancel(context, booking),
                  ),
              ],
            ),
          ],
        );
      });

  Future<void> _changeStatus(
      BuildContext context, Booking b, BookingStatus s) async {
    final ok = await confirmAdminAction(
      context,
      title: 'Cambiar estado',
      message: 'La reserva #${shortId(b.id)} pasará de '
          '"${b.status.displayLabel}" a "${s.displayLabel}".'
          '${s == BookingStatus.completed ? '\n\nQuedará facturada por ${bs(b.finalPrice ?? b.estimatedPrice)} y el chófer volverá a estar disponible.' : ''}',
      confirmLabel: 'Confirmar',
    );
    if (ok == null || !context.mounted) return;
    context.read<AdminBloc>().add(AdminChangeBookingStatusRequested(b, s));
  }

  Future<void> _cancel(BuildContext context, Booking b) async {
    final reason = await confirmAdminAction(
      context,
      title: 'Cancelar reserva',
      message: 'La reserva #${shortId(b.id)} quedará cancelada y se '
          'conservará en el historial. El chófer asignado quedará libre.',
      confirmLabel: 'Cancelar reserva',
      reasonLabel: 'Motivo de la cancelación',
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    context.read<AdminBloc>().add(AdminChangeBookingStatusRequested(
        b, BookingStatus.cancelled,
        reason: reason));
  }

  Future<void> _assignDriver(
      BuildContext context, AdminState state, Booking b) async {
    final candidates = state.drivers
        .where((d) => d.documentsVerified && d.userId != b.driverId)
        .toList()
      ..sort((a, c) => (c.isAvailable ? 1 : 0) - (a.isAvailable ? 1 : 0));
    final bloc = context.read<AdminBloc>();
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.blackElevated,
        title: const Text('Asignar chófer', style: LuxTypography.titleLarge),
        content: SizedBox(
          width: 420,
          child: candidates.isEmpty
              ? const Text('No hay chóferes verificados disponibles.',
                  style: LuxTypography.bodyMedium)
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final d in candidates)
                      ListTile(
                        onTap: () => Navigator.pop(ctx, d.userId),
                        leading: Icon(Icons.circle,
                            size: 10,
                            color: d.isAvailable
                                ? LuxColors.success
                                : LuxColors.whiteTertiary),
                        title: Text(state.userName(d.userId),
                            style: LuxTypography.bodyMedium),
                        subtitle: Text(
                            '${d.isAvailable ? 'Disponible' : 'Ocupado / fuera de línea'}'
                            ' · ★ ${d.rating.toStringAsFixed(1)}'
                            ' · ${d.totalRides} viajes',
                            style: LuxTypography.caption),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
        ],
      ),
    );
    if (chosen != null) bloc.add(AdminAssignDriverRequested(b, chosen));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Chóferes
// ─────────────────────────────────────────────────────────────────────────────

class DriversTab extends StatelessWidget {
  const DriversTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.drivers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.drivers.isEmpty) {
          return const AdminEmpty(
              icon: Icons.badge_outlined, title: 'No se encontraron chóferes');
        }
        final month = state.finance(FinancePeriod.thisMonth);
        final drivers = [...state.drivers]..sort((a, b) =>
            (a.documentsVerified ? 1 : 0) - (b.documentsVerified ? 1 : 0));
        return ListView.separated(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          itemCount: drivers.length,
          separatorBuilder: (_, __) => const LuxDivider(),
          itemBuilder: (_, i) {
            final driver = drivers[i];
            return _DriverTile(
              driver: driver,
              user: state.userById(driver.userId),
              monthPayout: month.byDriver[driver.userId]?.payout ?? 0,
            );
          },
        );
      });
}

class _DriverTile extends StatelessWidget {
  const _DriverTile(
      {required this.driver, required this.monthPayout, this.user});
  final DriverProfile driver;
  final User? user;
  final double monthPayout;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ??
        (driver.userId.length > 8
            ? driver.userId.substring(0, 8)
            : driver.userId);
    final licenseExpired = driver.licenseExpiry.isBefore(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: LuxColors.blackElevated,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: LuxTypography.titleLarge
                    .copyWith(color: LuxColors.sapphireBright)),
          ),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: LuxTypography.titleMedium),
                Text(user?.email ?? '', style: LuxTypography.caption),
                Text(
                  'Licencia ${driver.licenseNumber.isEmpty ? '—' : driver.licenseNumber}'
                  ' · vence ${DateFormat('dd/MM/yyyy').format(driver.licenseExpiry)}',
                  style: LuxTypography.caption.copyWith(
                      color: licenseExpired
                          ? LuxColors.error
                          : LuxColors.whiteTertiary),
                ),
                Text(
                  '★ ${driver.rating.toStringAsFixed(1)} · '
                  '${driver.totalRides} viajes · ${bs(monthPayout, short: true)} este mes',
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: LuxSpacing.md),
          if (!driver.documentsVerified)
            AdminActionButton(
              label: 'Verificar',
              icon: Icons.verified_outlined,
              onTap: () async {
                final ok = await confirmAdminAction(
                  context,
                  title: 'Verificar chófer',
                  message: 'Confirma que revisaste la licencia y los '
                      'documentos de $name. Podrá recibir reservas.',
                  confirmLabel: 'Verificar',
                );
                if (ok == null || !context.mounted) return;
                context
                    .read<AdminBloc>()
                    .add(AdminVerifyDriverRequested(driver.userId));
              },
            )
          else
            const Tooltip(
              message: 'Documentos verificados',
              child: Icon(Icons.verified_rounded,
                  color: LuxColors.success, size: 20),
            ),
          const SizedBox(width: LuxSpacing.md),
          Tooltip(
            message: driver.isAvailable ? 'En línea' : 'Fuera de línea',
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: driver.isAvailable
                    ? LuxColors.success
                    : LuxColors.whiteTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Vehículos
// ─────────────────────────────────────────────────────────────────────────────

class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.vehicles.isEmpty) {
          return const AdminEmpty(
            icon: Icons.directions_car_outlined,
            title: 'Aún no hay vehículos registrados',
            subtitle: 'Los vehículos vinculados a chóferes aparecen aquí',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          itemCount: state.vehicles.length,
          separatorBuilder: (_, __) => const LuxDivider(),
          itemBuilder: (_, i) => _VehicleTile(
              vehicle: state.vehicles[i],
              owner: state.userName(state.vehicles[i].driverId)),
        );
      });
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.owner});
  final Vehicle vehicle;
  final String owner;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LuxColors.blackElevated,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: const Icon(Icons.directions_car_filled_rounded,
                  color: LuxColors.sapphireBright, size: 24),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vehicle.make} ${vehicle.model} (${vehicle.year})',
                      style: LuxTypography.titleMedium),
                  Text(
                    'Placa ${vehicle.plate} · ${vehicle.vehicleClass.label} · $owner',
                    style: LuxTypography.caption,
                  ),
                ],
              ),
            ),
            AdminTag(vehicle.isActive ? 'Activo' : 'Inactivo',
                color: vehicle.isActive ? LuxColors.success : LuxColors.error),
            const SizedBox(width: LuxSpacing.sm),
            Switch.adaptive(
              value: vehicle.isActive,
              activeColor: LuxColors.sapphireBright,
              onChanged: (val) => context
                  .read<AdminBloc>()
                  .add(AdminToggleVehicleStatusRequested(vehicle.id, val)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Usuarios
// ─────────────────────────────────────────────────────────────────────────────

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _search = '';
  UserRole? _role;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = _search.toLowerCase();
        final filtered = state.users
            .where((u) =>
                (_role == null || u.role == _role) &&
                (q.isEmpty ||
                    u.displayName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q) ||
                    u.phone.contains(q)))
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  LuxSpacing.lg, LuxSpacing.md, LuxSpacing.lg, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: LuxTypography.bodyMedium,
                decoration: adminInputDecoration(
                  hint: 'Buscar por nombre, email o teléfono…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: LuxColors.whiteTertiary, size: 20),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: LuxSpacing.lg, vertical: LuxSpacing.sm),
              child: Row(
                children: [
                  AdminFilterChip(
                    label: 'Todos',
                    count: state.users.length,
                    selected: _role == null,
                    onTap: () => setState(() => _role = null),
                  ),
                  for (final r in UserRole.values)
                    Padding(
                      padding: const EdgeInsets.only(left: LuxSpacing.sm),
                      child: AdminFilterChip(
                        label: r.displayLabel,
                        count: state.users.where((u) => u.role == r).length,
                        selected: _role == r,
                        onTap: () =>
                            setState(() => _role = _role == r ? null : r),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const AdminEmpty(
                      icon: Icons.person_search_outlined,
                      title: 'Ningún usuario coincide con la búsqueda')
                  : ListView.separated(
                      padding: const EdgeInsets.all(LuxSpacing.lg),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const LuxDivider(),
                      itemBuilder: (_, i) => _UserTile(user: filtered[i]),
                    ),
            ),
          ],
        );
      });
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final User user;

  Color get _roleColor => switch (user.role) {
        UserRole.admin => LuxColors.sapphireBright,
        UserRole.driver => LuxColors.success,
        UserRole.rider => LuxColors.whiteTertiary,
      };

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: LuxColors.blackElevated,
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0] : '?',
                style: LuxTypography.bodyLarge
                    .copyWith(color: LuxColors.sapphireBright),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: LuxTypography.titleMedium),
                  Text(user.email, style: LuxTypography.caption),
                  Text(
                    'Miembro desde ${DateFormat('MM/yyyy').format(user.createdAt)}'
                    '${user.isActive ? '' : ' · BLOQUEADO'}',
                    style: LuxTypography.caption.copyWith(
                        color: user.isActive
                            ? LuxColors.whiteTertiary
                            : LuxColors.error),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => _showRoleDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminTag(user.role.displayLabel, color: _roleColor),
                  const Icon(Icons.arrow_drop_down_rounded,
                      size: 18, color: LuxColors.whiteTertiary),
                ],
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Tooltip(
              message: user.isActive ? 'Bloquear' : 'Reactivar',
              child: Switch.adaptive(
                value: user.isActive,
                activeColor: LuxColors.sapphireBright,
                onChanged: (val) async {
                  if (!val) {
                    final ok = await confirmAdminAction(
                      context,
                      title: 'Bloquear usuario',
                      message: '${user.displayName} no podrá usar la app '
                          'hasta que lo reactives.',
                      confirmLabel: 'Bloquear',
                      destructive: true,
                    );
                    if (ok == null || !context.mounted) return;
                  }
                  context
                      .read<AdminBloc>()
                      .add(AdminToggleUserStatusRequested(user.id, val));
                },
              ),
            ),
          ],
        ),
      );

  void _showRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.blackElevated,
        title: Text('Cambiar rol de ${user.displayName}',
            style: LuxTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values
              .map((role) => RadioListTile<UserRole>(
                    value: role,
                    groupValue: user.role,
                    title: Text(role.displayLabel,
                        style: LuxTypography.bodyMedium),
                    subtitle: role == UserRole.admin
                        ? const Text('Acceso total al panel y a las finanzas',
                            style: LuxTypography.caption)
                        : null,
                    activeColor: LuxColors.sapphireBright,
                    onChanged: (r) async {
                      Navigator.pop(ctx);
                      if (r == null || r == user.role) return;
                      final ok = await confirmAdminAction(
                        context,
                        title: 'Confirmar cambio de rol',
                        message: '${user.displayName}: '
                            '${user.role.displayLabel} → ${r.displayLabel}',
                        confirmLabel: 'Cambiar rol',
                        destructive: r == UserRole.admin,
                      );
                      if (ok == null || !context.mounted) return;
                      context
                          .read<AdminBloc>()
                          .add(AdminUpdateUserRoleRequested(user.id, r));
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Auditoría
// ─────────────────────────────────────────────────────────────────────────────

const _auditLabels = {
  'update_pricing': 'Tarifa modificada',
  'reset_pricing': 'Tarifa restablecida',
  'update_status': 'Estado de reserva',
  'cancel_booking': 'Reserva cancelada',
  'assign_driver': 'Chófer asignado',
  'reassign_driver': 'Chófer reasignado',
  'adjust_price': 'Precio ajustado',
  'record_payment': 'Cobro registrado',
  'refund_payment': 'Reembolso',
  'update_finance_settings': 'Config. financiera',
  'verify_driver': 'Chófer verificado',
  'block_user': 'Usuario bloqueado',
  'unblock_user': 'Usuario reactivado',
  'update_role': 'Cambio de rol',
  'enable_vehicle': 'Vehículo activado',
  'disable_vehicle': 'Vehículo desactivado',
  'enable_maintenance': 'Mantenimiento ON',
  'disable_maintenance': 'Mantenimiento OFF',
  'update_settings': 'Configuración',
  'delete_booking': 'Reserva eliminada',
};

class AuditTab extends StatefulWidget {
  const AuditTab({super.key});

  @override
  State<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<AuditTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.auditLogs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = _search.toLowerCase();
        final logs = state.auditLogs.where((l) {
          if (q.isEmpty) return true;
          return (_auditLabels[l.action] ?? l.action)
                  .toLowerCase()
                  .contains(q) ||
              l.details.toLowerCase().contains(q) ||
              l.targetId.toLowerCase().contains(q) ||
              _actor(state, l).toLowerCase().contains(q);
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  LuxSpacing.lg, LuxSpacing.md, LuxSpacing.lg, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: LuxTypography.bodyMedium,
                decoration: adminInputDecoration(
                  hint: 'Filtrar por acción, admin, detalle o código…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: LuxColors.whiteTertiary, size: 20),
                ),
              ),
            ),
            Expanded(
              child: logs.isEmpty
                  ? const AdminEmpty(
                      icon: Icons.history_rounded,
                      title: 'Sin registros de auditoría',
                      subtitle: 'Cada acción administrativa queda registrada '
                          'aquí con su autor y fecha.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(LuxSpacing.lg),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const LuxDivider(),
                      itemBuilder: (_, i) => _AuditTile(
                          log: logs[i], actor: _actor(state, logs[i])),
                    ),
            ),
          ],
        );
      });

  static String _actor(AdminState s, AuditLog l) {
    final u = s.userById(l.adminId);
    return u?.displayName ?? l.adminEmail ?? l.adminId;
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.log, required this.actor});
  final AuditLog log;
  final String actor;

  @override
  Widget build(BuildContext context) {
    final color = _color(log.action);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(LuxSpacing.xs),
            decoration: BoxDecoration(
              color: LuxColors.blackElevated,
              borderRadius: BorderRadius.circular(LuxRadius.sm),
            ),
            child: Icon(_icon(log.action), color: color, size: 16),
          ),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(
                  style: LuxTypography.bodyMedium,
                  children: [
                    TextSpan(
                      text: _auditLabels[log.action] ?? log.action,
                      style:
                          TextStyle(fontWeight: FontWeight.w700, color: color),
                    ),
                    TextSpan(
                        text: '  #${shortId(log.targetId)}',
                        style: LuxTypography.caption),
                  ],
                )),
                if (log.details.isNotEmpty)
                  Text(log.details, style: LuxTypography.caption),
                Text('por $actor',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.whiteTertiary)),
              ],
            ),
          ),
          Text(DateFormat('dd/MM HH:mm').format(log.createdAt),
              style: LuxTypography.caption),
        ],
      ),
    );
  }

  IconData _icon(String a) {
    if (a.contains('pricing')) return Icons.sell_outlined;
    if (a.contains('payment') || a.contains('price')) {
      return Icons.payments_outlined;
    }
    if (a.contains('finance')) return Icons.account_balance_outlined;
    if (a.contains('booking') || a.contains('status')) {
      return Icons.confirmation_number_outlined;
    }
    if (a.contains('driver')) return Icons.badge_outlined;
    if (a.contains('block')) return Icons.block_flipped;
    if (a.contains('vehicle')) return Icons.directions_car_rounded;
    if (a.contains('maintenance')) return Icons.construction_rounded;
    if (a.contains('role')) return Icons.manage_accounts_rounded;
    return Icons.settings_outlined;
  }

  Color _color(String a) {
    if (a == 'block_user' ||
        a.contains('delete') ||
        a.contains('cancel') ||
        a.contains('refund') ||
        a == 'enable_maintenance') {
      return LuxColors.error;
    }
    if (a.contains('verify') ||
        a == 'unblock_user' ||
        a == 'record_payment' ||
        a == 'disable_maintenance') {
      return LuxColors.success;
    }
    if (a.contains('pricing') || a.contains('price')) {
      return LuxColors.warning;
    }
    return LuxColors.sapphireBright;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Configuración
// ─────────────────────────────────────────────────────────────────────────────

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        final all = state.finance(FinancePeriod.all);
        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            const SectionHeader(title: 'Operación'),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.construction_rounded,
                    title: 'Modo mantenimiento',
                    subtitle: 'Pausa todas las reservas nuevas en la web y la '
                        'app. Los viajes en curso no se ven afectados.',
                    value: state.isMaintenanceMode,
                    onChanged: (val) async {
                      if (val) {
                        final ok = await confirmAdminAction(
                          context,
                          title: 'Activar mantenimiento',
                          message: 'Los pasajeros no podrán reservar hasta '
                              'que lo desactives.',
                          confirmLabel: 'Activar',
                          destructive: true,
                        );
                        if (ok == null || !context.mounted) return;
                      }
                      context
                          .read<AdminBloc>()
                          .add(AdminToggleMaintenanceModeRequested(val));
                    },
                  ),
                  const LuxDivider(),
                  _SettingTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notificaciones push',
                    subtitle: 'Avisos del sistema por nuevas reservas.',
                    value: state.pushNotificationsEnabled,
                    onChanged: (val) => context.read<AdminBloc>().add(
                          AdminUpdateGlobalSettingsRequested(
                              {'pushNotificationsEnabled': val}),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Clases de vehículo'),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              child: _SettingTile(
                icon: Icons.workspace_premium_outlined,
                title: 'First Class disponible',
                subtitle: state.firstClassEnabled
                    ? 'Visible para los clientes en la web y la app.'
                    : 'Oculta: los clientes no ven ni pueden reservar First Class.',
                value: state.firstClassEnabled,
                onChanged: (val) => context.read<AdminBloc>().add(
                      AdminUpdateGlobalSettingsRequested(
                          {'firstClassEnabled': val}),
                    ),
              ),
            ),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Finanzas'),
            const SizedBox(height: LuxSpacing.md),
            _CommissionCard(current: state.commissionPct),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Totales históricos'),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              child: Column(
                children: [
                  AdminInfoRow(
                      label: 'Reservas cargadas',
                      value: '${state.bookings.length}'
                          '${state.bookingsTruncated ? ' (límite)' : ''}'),
                  AdminInfoRow(
                      label: 'Viajes completados',
                      value: '${all.completedCount}'),
                  AdminInfoRow(
                      label: 'Facturado neto', value: bs(all.netRevenue)),
                  AdminInfoRow(label: 'Cobrado', value: bs(all.collected)),
                  AdminInfoRow(
                      label: 'Por cobrar',
                      value: bs(all.receivables),
                      valueColor:
                          all.receivables > 0 ? LuxColors.warning : null),
                  AdminInfoRow(
                      label: 'Ingresos plataforma',
                      value: bs(all.platformRevenue)),
                  AdminInfoRow(
                      label: 'Usuarios / chóferes / vehículos',
                      value: '${state.users.length} / '
                          '${state.drivers.length} / ${state.vehicles.length}'),
                ],
              ),
            ),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Sistema'),
            const SizedBox(height: LuxSpacing.md),
            const LuxCard(
              child: Column(
                children: [
                  AdminInfoRow(label: 'Moneda', value: 'Bolivianos (Bs)'),
                  AdminInfoRow(label: 'Backend', value: 'Firebase / Firestore'),
                  AdminInfoRow(
                      label: 'Plataforma', value: 'Flutter Web + Mobile'),
                ],
              ),
            ),
          ],
        );
      });
}

class _CommissionCard extends StatefulWidget {
  const _CommissionCard({required this.current});
  final double current;

  @override
  State<_CommissionCard> createState() => _CommissionCardState();
}

class _CommissionCardState extends State<_CommissionCard> {
  late final _ctrl = TextEditingController(text: _fmt(widget.current));

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  void didUpdateWidget(covariant _CommissionCard old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current &&
        double.tryParse(_ctrl.text) == old.current) {
      _ctrl.text = _fmt(widget.current);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    final valid = value != null && value >= 0 && value <= 100;
    final dirty = valid && value != widget.current;
    return LuxCard(
      child: Row(
        children: [
          const Icon(Icons.percent_rounded, color: LuxColors.sapphireBright),
          const SizedBox(width: LuxSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comisión de la plataforma',
                    style: LuxTypography.titleMedium),
                Text(
                    'Porcentaje de cada viaje que retiene Luxelane; el resto '
                    'se liquida al chófer.',
                    style: LuxTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: LuxSpacing.md),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _ctrl,
              onChanged: (_) => setState(() {}),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: LuxTypography.bodyMedium,
              decoration: adminInputDecoration(suffixText: '%'),
            ),
          ),
          const SizedBox(width: LuxSpacing.sm),
          TextButton(
            onPressed: dirty
                ? () async {
                    final ok = await confirmAdminAction(
                      context,
                      title: 'Cambiar comisión',
                      message: '${_fmt(widget.current)} % → ${_fmt(value)} %. '
                          'Afecta al reparto mostrado de todos los viajes.',
                      confirmLabel: 'Guardar',
                    );
                    if (ok == null || !context.mounted) return;
                    context.read<AdminBloc>().add(
                        AdminUpdateFinanceSettingsRequested(
                            {'platformCommissionPct': value}));
                  }
                : null,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: LuxColors.sapphireBright, size: 24),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: LuxTypography.titleMedium),
                  Text(subtitle, style: LuxTypography.caption),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeColor: LuxColors.sapphireBright,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
