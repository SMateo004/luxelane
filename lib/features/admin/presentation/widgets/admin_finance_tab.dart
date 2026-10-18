import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../domain/admin_finance.dart';
import '../../domain/admin_operations.dart';
import '../bloc/admin_bloc.dart';
import 'admin_shared_widgets.dart';

Color chargeStatusColor(ChargeStatus s) {
  switch (s) {
    case ChargeStatus.collected:
      return LuxColors.success;
    case ChargeStatus.pendingCollection:
      return LuxColors.warning;
    case ChargeStatus.refunded:
      return LuxColors.inkTertiary;
    case ChargeStatus.failed:
      return LuxColors.error;
  }
}

class FinanceTab extends StatefulWidget {
  const FinanceTab({super.key});

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  FinancePeriod _period = FinancePeriod.thisMonth;
  ChargeStatus? _filter;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        if (state.isLoading && state.bookings.isEmpty) {
          return const LuxSkeletonList();
        }
        final f = state.finance(_period);
        final rows = _filter == null
            ? f.entries
            : f.entries.where((e) => e.status == _filter).toList();

        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            Row(
              children: [
                const Expanded(child: SectionHeader(title: 'Finanzas')),
                TextButton.icon(
                  onPressed: f.entries.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(
                              ClipboardData(text: f.toCsv(state.userName)));
                          showLuxSnackbar(context,
                              'Libro de ${_period.label.toLowerCase()} copiado como CSV');
                        },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Exportar CSV'),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.sm),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [
                for (final p in FinancePeriod.values)
                  AdminFilterChip(
                    label: p.label,
                    selected: _period == p,
                    onTap: () => setState(() => _period = p),
                  ),
              ],
            ),
            if (state.bookingsTruncated) ...[
              const SizedBox(height: LuxSpacing.md),
              _Notice(
                'Se cargaron las ${state.bookingsLimit} reservas más recientes. '
                'Los totales de periodos largos pueden estar incompletos.',
              ),
            ],
            const SizedBox(height: LuxSpacing.lg),
            FinanceKpis(summary: f),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Facturación diaria'),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              padding: const EdgeInsets.all(LuxSpacing.lg),
              child: SizedBox(height: 220, child: DailyRevenueChart(f.daily)),
            ),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Conciliación de cobros'),
            const SizedBox(height: LuxSpacing.sm),
            const Text(
              'Viajes completados y su estado de cobro. Registra cobros en '
              'efectivo/QR/transferencia, ajusta precios antes de cobrar o '
              'reembolsa pagos capturados.',
              style: LuxTypography.caption,
            ),
            const SizedBox(height: LuxSpacing.md),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [
                AdminFilterChip(
                  label: 'Todos',
                  count: f.entries.length,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final s in ChargeStatus.values)
                  AdminFilterChip(
                    label: s.label,
                    count: f.entries.where((e) => e.status == s).length,
                    selected: _filter == s,
                    onTap: () =>
                        setState(() => _filter = _filter == s ? null : s),
                  ),
              ],
            ),
            const SizedBox(height: LuxSpacing.md),
            if (rows.isEmpty)
              const AdminEmpty(
                icon: Icons.receipt_long_outlined,
                title: 'Sin movimientos en este periodo',
              )
            else
              LuxCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: LuxSpacing.md, vertical: LuxSpacing.xs),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const LuxDivider(),
                      _LedgerTile(entry: rows[i], state: state),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Liquidación a chóferes'),
            const SizedBox(height: LuxSpacing.sm),
            Text(
              'Cada viaje se reparte con la comisión vigente al completarse '
              '(ahora ${f.commissionPct.toStringAsFixed(f.commissionPct % 1 == 0 ? 0 : 1)} %); '
              'el chófer ve las mismas cifras en su app. "Liquidable" es su '
              'parte en viajes ya cobrados.',
              style: LuxTypography.caption,
            ),
            const SizedBox(height: LuxSpacing.md),
            _DriverPayouts(summary: f, state: state),
            const SizedBox(height: LuxSpacing.xl),
            const SectionHeader(title: 'Por clase y servicio'),
            const SizedBox(height: LuxSpacing.md),
            _Segments(summary: f),
          ],
        );
      });
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: LuxColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(LuxRadius.sm),
          border: Border.all(color: LuxColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: LuxColors.warning, size: 18),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(
                child: Text(text,
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.warning))),
          ],
        ),
      );
}

/// KPIs financieros. También los usa el panel de inicio, para que las cifras
/// sean idénticas en ambas pantallas.
class FinanceKpis extends StatelessWidget {
  const FinanceKpis({super.key, required this.summary, this.compact = false});
  final FinancialSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final f = summary;
    final tiles = [
      AdminKpiTile(
        label: 'Facturado neto',
        value: bs(f.netRevenue, short: true),
        icon: Icons.payments_outlined,
        sub:
            '${f.completedCount} viajes · bruto ${bs(f.grossBilled, short: true)}',
      ),
      AdminKpiTile(
        label: 'Cobrado',
        value: bs(f.collected, short: true),
        icon: Icons.account_balance_wallet_outlined,
        sub: '${f.collectionRate.toStringAsFixed(0)} % de lo facturado',
        color: LuxColors.success,
      ),
      AdminKpiTile(
        label: 'Por cobrar',
        value: bs(f.receivables, short: true),
        icon: Icons.pending_actions_outlined,
        sub: '${f.receivablesCount} viajes sin cobro'
            '${f.failed > 0 ? ' · ${bs(f.failed, short: true)} fallidos' : ''}',
        color: f.receivables > 0 ? LuxColors.warning : LuxColors.inkSecondary,
      ),
      AdminKpiTile(
        label: 'Ingresos plataforma',
        value: bs(f.platformRevenue, short: true),
        icon: Icons.trending_up_rounded,
        sub: 'Comisión ${f.commissionPct.toStringAsFixed(0)} %',
      ),
      if (!compact) ...[
        AdminKpiTile(
          label: 'A pagar a chóferes',
          value: bs(f.driverPayouts, short: true),
          icon: Icons.badge_outlined,
          sub: '${f.byDriver.length} chóferes con viajes',
          color: LuxColors.inkSecondary,
        ),
        AdminKpiTile(
          label: 'Reembolsado',
          value: bs(f.refunded, short: true),
          icon: Icons.undo_rounded,
          sub: '${f.refundedCount} reembolsos',
          color: f.refunded > 0 ? LuxColors.error : LuxColors.inkSecondary,
        ),
        AdminKpiTile(
          label: 'Ticket medio',
          value: bs(f.averageTicket, short: true),
          icon: Icons.receipt_outlined,
          sub: 'Por viaje facturado',
          color: LuxColors.inkSecondary,
        ),
        AdminKpiTile(
          label: 'Ingresos en curso',
          value: bs(f.pipelineValue, short: true),
          icon: Icons.hourglass_top_rounded,
          sub: '${f.pipelineCount} activas · ${f.pendingCount} pendientes',
          color: LuxColors.inkSecondary,
        ),
      ],
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 920
          ? 4
          : c.maxWidth >= 300
              ? 2
              : 1;
      final w = (c.maxWidth - (cols - 1) * LuxSpacing.md) / cols;
      return Wrap(
        spacing: LuxSpacing.md,
        runSpacing: LuxSpacing.md,
        children: [
          for (final t in tiles)
            AdminKpiTile(
              label: t.label,
              value: t.value,
              icon: t.icon,
              sub: t.sub,
              color: t.color,
              width: w,
            ),
        ],
      );
    });
  }
}

class DailyRevenueChart extends StatelessWidget {
  const DailyRevenueChart(this.daily, {super.key});
  final Map<DateTime, double> daily;

  static const _days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final days = daily.keys.toList();
    final values = daily.values.toList();
    final maxY = values.fold(0.0, (m, v) => v > m ? v : m);
    final step = (days.length / 7).ceil();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 100 : maxY * 1.15,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: LuxColors.ink.withOpacity(0.05), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => LuxColors.surfaceMuted,
            getTooltipItem: (group, _, rod, __) {
              final d = days[group.x];
              return BarTooltipItem(
                '${d.day}/${d.month}\n${bs(rod.toY)}',
                LuxTypography.caption.copyWith(color: LuxColors.ink),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) => value == meta.max
                  ? const SizedBox.shrink()
                  : Text(bs(value, short: true),
                      style: LuxTypography.caption.copyWith(fontSize: 9)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= days.length || i % step != 0) {
                  return const SizedBox.shrink();
                }
                final d = days[i];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      days.length <= 7
                          ? '${_days[d.weekday - 1]} ${d.day}'
                          : '${d.day}/${d.month}',
                      style: LuxTypography.caption.copyWith(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i],
                width: days.length <= 7 ? 18 : 6,
                color: LuxColors.sapphire,
                borderRadius: BorderRadius.circular(3),
              ),
            ]),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry, required this.state});
  final LedgerEntry entry;
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final b = entry.booking;
    final color = chargeStatusColor(entry.status);
    final canCollect = entry.status == ChargeStatus.pendingCollection ||
        entry.status == ChargeStatus.failed;
    final canRefund =
        entry.status == ChargeStatus.collected && entry.payment != null;
    final canAdjust = AdminOperations.canAdjustFinalPrice(b, entry.payment);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${shortId(b.id)} · ${state.userName(b.riderId)}',
                    style: LuxTypography.titleMedium),
                Text(
                  '${adminDate(entry.date)} · ${b.vehicleClass.label} · '
                  '${b.serviceType.label}'
                  '${b.driverId != null ? ' · ${state.userName(b.driverId!)}' : ''}',
                  style: LuxTypography.caption,
                ),
                if (b.finalPrice != null && b.finalPrice != b.estimatedPrice)
                  Text('Estimado ${bs(b.estimatedPrice)}',
                      style: LuxTypography.caption
                          .copyWith(color: LuxColors.inkTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bs(entry.amount),
                  style: LuxTypography.titleMedium.copyWith(
                    color: entry.status == ChargeStatus.refunded
                        ? LuxColors.inkTertiary
                        : LuxColors.ink,
                    decoration: entry.status == ChargeStatus.refunded
                        ? TextDecoration.lineThrough
                        : null,
                  )),
              const SizedBox(height: 4),
              AdminTag(entry.status.label, color: color),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            color: LuxColors.surfaceMuted,
            icon: const Icon(Icons.more_vert_rounded,
                color: LuxColors.inkTertiary),
            enabled: canCollect || canRefund || canAdjust,
            onSelected: (v) {
              switch (v) {
                case 'collect':
                  recordPaymentDialog(context, b);
                case 'adjust':
                  adjustPriceDialog(context, b);
                case 'refund':
                  _refund(context, entry);
              }
            },
            itemBuilder: (_) => [
              if (canCollect)
                const PopupMenuItem(
                    value: 'collect', child: Text('Registrar cobro')),
              if (canAdjust)
                const PopupMenuItem(
                    value: 'adjust', child: Text('Ajustar precio final')),
              if (canRefund)
                const PopupMenuItem(
                    value: 'refund',
                    child: Text('Reembolsar',
                        style: TextStyle(color: LuxColors.error))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refund(BuildContext context, LedgerEntry e) async {
    final reason = await confirmAdminAction(
      context,
      title: 'Reembolsar ${bs(e.amount)}',
      message: 'Se devolverá el pago de la reserva #${shortId(e.booking.id)} '
          'al pasajero. Esta acción no se puede deshacer.',
      confirmLabel: 'Reembolsar',
      reasonLabel: 'Motivo del reembolso',
      destructive: true,
    );
    if (reason == null || !context.mounted) return;
    context
        .read<AdminBloc>()
        .add(AdminRefundPaymentRequested(e.payment!, reason));
  }
}

/// Registrar un cobro hecho fuera de la app (efectivo, QR, transferencia…).
Future<void> recordPaymentDialog(BuildContext context, Booking b) async {
  const methods = {
    'cash': 'Efectivo',
    'qr': 'QR',
    'transfer': 'Transferencia',
    'card_terminal': 'Tarjeta (POS)',
  };
  var method = 'cash';
  final ref = TextEditingController();
  final bloc = context.read<AdminBloc>();
  final amount = b.finalPrice ?? b.estimatedPrice;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: LuxColors.surfaceMuted,
        title: Text('Registrar cobro de ${bs(amount)}',
            style: LuxTypography.titleLarge),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reserva #${shortId(b.id)}', style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.md),
              Wrap(
                spacing: LuxSpacing.sm,
                runSpacing: LuxSpacing.sm,
                children: [
                  for (final m in methods.entries)
                    AdminFilterChip(
                      label: m.value,
                      selected: method == m.key,
                      onTap: () => setState(() => method = m.key),
                    ),
                ],
              ),
              const SizedBox(height: LuxSpacing.md),
              TextField(
                controller: ref,
                style: LuxTypography.bodyMedium,
                decoration: adminInputDecoration(
                    hint: 'Referencia / nº de comprobante (opcional)'),
              ),
              const SizedBox(height: LuxSpacing.sm),
              const Text(
                  'Si el importe no es correcto, ajusta primero el precio final.',
                  style: LuxTypography.caption),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Registrar cobro',
                style: TextStyle(
                    color: LuxColors.success, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
  final reference = ref.text.trim();
  ref.dispose();
  if (ok == true) {
    bloc.add(AdminRecordPaymentRequested(b, methods[method]!, reference));
  }
}

Future<void> adjustPriceDialog(BuildContext context, Booking b) async {
  final ctrl = TextEditingController(
      text: (b.finalPrice ?? b.estimatedPrice).toStringAsFixed(2));
  final reason = TextEditingController();
  final bloc = context.read<AdminBloc>();
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final value = double.tryParse(ctrl.text.replaceAll(',', '.'));
      final valid =
          value != null && value >= 0 && reason.text.trim().length >= 3;
      return AlertDialog(
        backgroundColor: LuxColors.surfaceMuted,
        title:
            const Text('Ajustar precio final', style: LuxTypography.titleLarge),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Reserva #${shortId(b.id)} · estimado ${bs(b.estimatedPrice)}',
                  style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.md),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: LuxTypography.bodyMedium,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(prefixText: 'Bs '),
              ),
              const SizedBox(height: LuxSpacing.sm),
              TextField(
                controller: reason,
                style: LuxTypography.bodyMedium,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(
                    hint: 'Motivo (peajes, espera, descuento…)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: valid ? () => Navigator.pop(ctx, value) : null,
            child: const Text('Guardar'),
          ),
        ],
      );
    }),
  );
  final why = reason.text.trim();
  ctrl.dispose();
  reason.dispose();
  if (result != null) {
    bloc.add(AdminAdjustFinalPriceRequested(b, result, why));
  }
}

class _DriverPayouts extends StatelessWidget {
  const _DriverPayouts({required this.summary, required this.state});
  final FinancialSummary summary;
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final rows = summary.byDriver.values.toList()
      ..sort((a, b) => b.billed.compareTo(a.billed));
    if (rows.isEmpty) {
      return const AdminEmpty(
          icon: Icons.badge_outlined, title: 'Sin viajes de chóferes');
    }
    return LuxCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle:
              LuxTypography.caption.copyWith(color: LuxColors.inkSecondary),
          dataTextStyle: LuxTypography.bodyMedium,
          columnSpacing: LuxSpacing.lg,
          columns: const [
            DataColumn(label: Text('Chófer')),
            DataColumn(label: Text('Viajes'), numeric: true),
            DataColumn(label: Text('Facturado'), numeric: true),
            DataColumn(label: Text('Comisión'), numeric: true),
            DataColumn(label: Text('Parte chófer'), numeric: true),
            DataColumn(label: Text('Liquidable'), numeric: true),
          ],
          rows: [
            for (final d in rows)
              DataRow(cells: [
                DataCell(Text(state.userName(d.driverId))),
                DataCell(Text('${d.rides}')),
                DataCell(Text(bs(d.billed))),
                DataCell(Text(bs(d.commission))),
                DataCell(Text(bs(d.payout))),
                DataCell(Text(bs(d.collectedPayout),
                    style: const TextStyle(color: LuxColors.success))),
              ]),
          ],
        ),
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.summary});
  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget block(String title, Map<String, SegmentFinance> data) {
      final total = data.values.fold(0.0, (s, e) => s + e.billed);
      return LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: LuxTypography.titleMedium),
            const SizedBox(height: LuxSpacing.sm),
            if (data.isEmpty)
              const Text('Sin datos', style: LuxTypography.caption),
            for (final e in data.entries) ...[
              const SizedBox(height: LuxSpacing.sm),
              Row(
                children: [
                  Expanded(
                      child: Text('${e.key} · ${e.value.rides}',
                          style: LuxTypography.bodyMedium)),
                  Text(bs(e.value.billed), style: LuxTypography.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : e.value.billed / total,
                  minHeight: 4,
                  backgroundColor: LuxColors.border,
                  color: LuxColors.sapphire,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final byClass = {
      for (final e in summary.byClass.entries) e.key.label: e.value,
    };
    final byService = {
      for (final e in summary.byService.entries) e.key.label: e.value,
    };
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 640;
      final a = block('Por clase de vehículo', byClass);
      final b = block('Por tipo de servicio', byService);
      return wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: a),
                const SizedBox(width: LuxSpacing.md),
                Expanded(child: b),
              ],
            )
          : Column(children: [a, const SizedBox(height: LuxSpacing.md), b]);
    });
  }
}
