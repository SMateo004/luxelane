import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/ops_report.dart';
import '../bloc/admin_bloc.dart';
import 'admin_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Reportes — operations metrics over the bookings already streamed into
// AdminState. Every chart is a single series in champagne (identity comes from
// the axis/row labels, never from color); status colors are not used here.
// ─────────────────────────────────────────────────────────────────────────────

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key, this.now});

  /// Injected clock for tests.
  final DateTime? now;

  static const periods = [7, 30, 90];

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final l = context.l10n;
        final report = OpsReport.lastDays(state.bookings, _days,
            now: widget.now, driverName: state.userName);
        final prev = report.previous(state.bookings);
        final lastDay = report.to.subtract(const Duration(days: 1));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l.adminReportsTitle),
              const SizedBox(height: LuxSpacing.md),
              // Filters live in one row above every chart.
              Wrap(
                spacing: LuxSpacing.sm,
                runSpacing: LuxSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final d in ReportsTab.periods)
                    SectionChip(
                      label: l.adminReportsDays(d),
                      selected: _days == d,
                      onTap: () => setState(() => _days = d),
                    ),
                ],
              ),
              const SizedBox(height: LuxSpacing.sm),
              Text(
                l.adminReportsRange(DateFormat.yMMMd().format(report.from),
                    DateFormat.yMMMd().format(lastDay)),
                style: LuxTypography.caption,
              ),
              const SizedBox(height: LuxSpacing.lg),
              if (report.total == 0)
                EmptyState(
                  icon: Icons.insights_outlined,
                  message: l.adminReportsEmpty,
                )
              else ...[
                _Kpis(report: report, prev: prev),
                const SizedBox(height: LuxSpacing.xl),
                _ChartGrid(children: [
                  _ChartCard(
                    title: l.adminReportsTripsPerDay,
                    child: _DailyBars(
                      days: report.days,
                      value: (d) => d.trips.toDouble(),
                      axisLabel: (v) => NumberFormat.decimalPattern().format(v),
                      tooltip: (d) => l.adminReportsTooltipTrips(d.trips),
                    ),
                  ),
                  _ChartCard(
                    title: l.adminReportsRevenuePerDay,
                    child: _DailyBars(
                      days: report.days,
                      value: (d) => d.revenue,
                      axisLabel: (v) => NumberFormat.compact().format(v),
                      tooltip: (d) => LuxMoney.format(d.revenue),
                    ),
                  ),
                ]),
                const SizedBox(height: LuxSpacing.md),
                _DailyTable(report: report),
                const SizedBox(height: LuxSpacing.lg),
                _ChartCard(
                  title: l.adminReportsPeakHours,
                  subtitle: _peakLabel(context, report),
                  child: _HourBars(counts: report.demandByHour),
                ),
                const SizedBox(height: LuxSpacing.lg),
                _ChartGrid(children: [
                  _ChartCard(
                    title: l.adminReportsVehicleMix,
                    height: null,
                    child: _ShareRows(rows: [
                      for (final e in report.byVehicle.entries)
                        (label: e.key.localizedLabel(l), count: e.value),
                    ]),
                  ),
                  _ChartCard(
                    title: l.adminReportsServiceMix,
                    height: null,
                    child: _ShareRows(rows: [
                      for (final e in report.byService.entries)
                        (label: e.key.localizedLabel(l), count: e.value),
                    ]),
                  ),
                  _ChartCard(
                    title: l.adminReportsCancellations,
                    height: null,
                    child: report.cancelled == 0
                        ? Text(l.adminReportsNoCancellations,
                            style: LuxTypography.bodyMedium)
                        : _ShareRows(rows: _cancelRows(l, report)),
                  ),
                ]),
                const SizedBox(height: LuxSpacing.xl),
                _DriversTable(report: report),
              ],
            ],
          ),
        );
      },
    );
  }

  String? _peakLabel(BuildContext context, OpsReport r) {
    final l = context.l10n;
    final max = r.demandByHour.reduce(math.max);
    if (max == 0) return l.adminReportsPeakHoursHint;
    final hour = r.demandByHour.indexOf(max);
    final label = DateFormat.j().format(DateTime(2000, 1, 1, hour));
    return '${l.adminReportsPeakHour(label)} · ${l.adminReportsPeakHoursHint}';
  }

  List<({String label, int count})> _cancelRows(
      AppLocalizations l, OpsReport r) {
    final by = r.cancelledBy;
    final known = (by['rider'] ?? 0) + (by['admin'] ?? 0) + (by['system'] ?? 0);
    return [
      (label: l.adminReportsByRider, count: by['rider'] ?? 0),
      (label: l.adminReportsByAdmin, count: by['admin'] ?? 0),
      (label: l.adminReportsBySystem, count: by['system'] ?? 0),
      if (r.cancelled > known)
        (label: l.adminReportsByUnknown, count: r.cancelled - known),
    ];
  }
}

// ── KPIs ────────────────────────────────────────────────────────────────────

class _Kpis extends StatelessWidget {
  const _Kpis({required this.report, required this.prev});
  final OpsReport report;
  final OpsReport prev;

  String? _delta(AppLocalizations l, num now, num before) {
    if (before == 0) return now == 0 ? null : l.adminReportsNoPrevious;
    final pct = (now - before) / before;
    final f = NumberFormat.percentPattern()..maximumFractionDigits = 0;
    final sign = pct > 0 ? '+' : '';
    return l.adminReportsVsPrevious('$sign${f.format(pct)}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pct = NumberFormat.percentPattern()..maximumFractionDigits = 1;
    final n = NumberFormat.decimalPattern();
    final rating = report.avgRating;
    return LayoutBuilder(builder: (context, c) {
      // Two per row on phones, fixed-width tiles on wider screens.
      final w = c.maxWidth < 480 ? (c.maxWidth - LuxSpacing.md) / 2 : 210.0;
      return Wrap(
        spacing: LuxSpacing.md,
        runSpacing: LuxSpacing.md,
        children: [
          _ReportKpi(
            icon: Icons.check_circle_outline_rounded,
            label: l.adminReportsTrips,
            value: n.format(report.completed),
            sub: _delta(l, report.completed, prev.completed),
          ),
          _ReportKpi(
            icon: Icons.payments_outlined,
            label: l.adminReportsRevenue,
            value: LuxMoney.format(report.revenue),
            sub: _delta(l, report.revenue, prev.revenue),
          ),
          _ReportKpi(
            icon: Icons.receipt_long_outlined,
            label: l.adminReportsAvgTicket,
            value: LuxMoney.format(report.avgTicket),
            sub: l.adminReportsPerTrip,
          ),
          _ReportKpi(
            icon: Icons.event_busy_outlined,
            label: l.adminReportsCancellationRate,
            value: pct.format(report.cancellationRate),
            sub: l.adminReportsCancelledOf(report.cancelled, report.total),
          ),
          _ReportKpi(
            icon: Icons.timer_off_outlined,
            label: l.adminReportsLateCancellations,
            value: n.format(report.lateCancellations),
            sub: l.adminReportsLateHint,
          ),
          _ReportKpi(
            icon: Icons.person_off_outlined,
            label: l.adminReportsUnserved,
            value: n.format(report.unserved),
            sub: l.adminReportsUnservedHint,
          ),
          _ReportKpi(
            icon: Icons.star_outline_rounded,
            label: l.adminReportsAvgRating,
            value: rating == null
                ? '—'
                : (NumberFormat.decimalPattern()..maximumFractionDigits = 2)
                    .format(rating),
            sub: l.adminReportsRatingCount(report.ratingCount),
          ),
        ].map((t) => SizedBox(width: w, child: t)).toList(),
      );
    });
  }
}

class _ReportKpi extends StatelessWidget {
  const _ReportKpi(
      {required this.icon, required this.label, required this.value, this.sub});
  final IconData icon;
  final String label, value;
  final String? sub;

  @override
  Widget build(BuildContext context) => SizedBox(
        child: LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: LuxColors.accent, size: 18),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.caption
                          .copyWith(color: LuxColors.whiteSecondary)),
                ),
              ]),
              const SizedBox(height: LuxSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: LuxTypography.headlineLarge.copyWith(
                        color: LuxColors.white,
                        fontFamily: 'Cormorant Garamond',
                        fontSize: 34)),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: LuxTypography.caption),
              ],
            ],
          ),
        ),
      );
}

// ── Layout helpers ──────────────────────────────────────────────────────────

/// Two charts side by side on wide screens, stacked on narrow ones.
class _ChartGrid extends StatelessWidget {
  const _ChartGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 1100
            ? math.min(children.length, 3)
            : (c.maxWidth >= 720 ? math.min(children.length, 2) : 1);
        const gap = LuxSpacing.lg;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      });
}

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title,
      required this.child,
      this.subtitle,
      this.height = 200});
  final String title;
  final String? subtitle;
  final Widget child;

  /// Plot height; null lets list-style content size itself.
  final double? height;

  @override
  Widget build(BuildContext context) => LuxCard(
        padding: const EdgeInsets.all(LuxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: LuxTypography.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: LuxSpacing.xs),
              Text(subtitle!, style: LuxTypography.caption),
            ],
            const SizedBox(height: LuxSpacing.lg),
            if (height != null)
              SizedBox(height: height, child: child)
            else
              child,
          ],
        ),
      );
}

// ── Charts ──────────────────────────────────────────────────────────────────

FlGridData _grid() => FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: LuxColors.white.withOpacity(0.06), strokeWidth: 1),
    );

BarTouchData _touch(String Function(int index) text) => BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => LuxColors.blackElevated,
        tooltipBorder: const BorderSide(color: LuxColors.blackBorder),
        tooltipRoundedRadius: LuxRadius.sm,
        getTooltipItem: (group, _, __, ___) => BarTooltipItem(
          text(group.x),
          LuxTypography.caption.copyWith(color: LuxColors.white),
        ),
      ),
    );

BarChartRodData _rod(double y, double width) => BarChartRodData(
      toY: y,
      width: width,
      color: LuxColors.accent,
      // 4px rounded data end, square at the baseline.
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    );

/// Bar width that leaves at least a 2px gap between neighbours.
double _barWidth(double plotWidth, int n) =>
    ((plotWidth / n) * 0.6).clamp(2.0, 18.0).toDouble();

double _niceMax(double max) => max <= 0 ? 1 : max * 1.15;

class _DailyBars extends StatelessWidget {
  const _DailyBars({
    required this.days,
    required this.value,
    required this.axisLabel,
    required this.tooltip,
  });
  final List<OpsDay> days;
  final double Function(OpsDay) value;
  final String Function(double) axisLabel;
  final String Function(OpsDay) tooltip;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final n = days.length;
        final every = (n / 6).ceil();
        final maxY = _niceMax(days.map(value).fold(0.0, math.max));
        final dateFmt = DateFormat.Md();
        return BarChart(
          BarChartData(
            maxY: maxY,
            gridData: _grid(),
            borderData: FlBorderData(show: false),
            barTouchData: _touch((i) =>
                '${DateFormat.MMMEd().format(days[i].day)}\n${tooltip(days[i])}'),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, meta) => v == meta.max
                      ? const SizedBox.shrink()
                      : Text(axisLabel(v),
                          style: LuxTypography.caption.copyWith(fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= n || (n - 1 - i) % every != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(dateFmt.format(days[i].day),
                          style: LuxTypography.caption.copyWith(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < n; i++)
                BarChartGroupData(x: i, barRods: [
                  _rod(value(days[i]), _barWidth(c.maxWidth - 44, n))
                ]),
            ],
          ),
        );
      });
}

class _HourBars extends StatelessWidget {
  const _HourBars({required this.counts});
  final List<int> counts;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final l = context.l10n;
        final maxY = _niceMax(counts.fold(0, math.max).toDouble());
        String hour(int h) => DateFormat.j().format(DateTime(2000, 1, 1, h));
        return BarChart(
          BarChartData(
            maxY: maxY,
            gridData: _grid(),
            borderData: FlBorderData(show: false),
            barTouchData: _touch((h) =>
                '${hour(h)}\n${l.adminReportsTooltipBookings(counts[h])}'),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, meta) => v == meta.max || v % 1 != 0
                      ? const SizedBox.shrink()
                      : Text(NumberFormat.decimalPattern().format(v),
                          style: LuxTypography.caption.copyWith(fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (v, _) {
                    final h = v.toInt();
                    if (h % 3 != 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(hour(h),
                          style: LuxTypography.caption.copyWith(fontSize: 10)),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var h = 0; h < 24; h++)
                BarChartGroupData(x: h, barRods: [
                  _rod(counts[h].toDouble(), _barWidth(c.maxWidth - 32, 24))
                ]),
            ],
          ),
        );
      });
}

/// Horizontal share bars: label and value in text tokens, the bar carries
/// magnitude only. Rows keep a fixed order so categories never jump around.
class _ShareRows extends StatelessWidget {
  const _ShareRows({required this.rows});
  final List<({String label, int count})> rows;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold(0, (s, r) => s + r.count);
    final pct = NumberFormat.percentPattern();
    final n = NumberFormat.decimalPattern();
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: LuxSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(r.label,
                          overflow: TextOverflow.ellipsis,
                          style: LuxTypography.bodyMedium
                              .copyWith(color: LuxColors.white))),
                  Text(
                    '${n.format(r.count)} · ${pct.format(total == 0 ? 0 : r.count / total)}',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.whiteSecondary),
                  ),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Stack(children: [
                      Container(color: LuxColors.white.withOpacity(0.06)),
                      FractionallySizedBox(
                        widthFactor: total == 0 ? 0 : r.count / total,
                        child: Container(color: LuxColors.accent),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Tables & export ─────────────────────────────────────────────────────────

Future<void> _export(BuildContext context, String filename, String csv) async {
  final l = context.l10n;
  if (downloadTextFile(filename, csv)) {
    showLuxSnackbar(context, l.adminReportsDownloaded);
    return;
  }
  await Clipboard.setData(ClipboardData(text: csv));
  if (context.mounted) showLuxSnackbar(context, l.adminReportsCopied);
}

String _stamp(OpsReport r) => '${DateFormat('yyyyMMdd').format(r.from)}-'
    '${DateFormat('yyyyMMdd').format(r.to.subtract(const Duration(days: 1)))}';

TextStyle get _th => LuxTypography.caption
    .copyWith(color: LuxColors.whiteSecondary, fontWeight: FontWeight.w600);
TextStyle get _td => LuxTypography.bodyMedium.copyWith(color: LuxColors.white);

/// The table view behind the two daily charts (and their CSV export).
class _DailyTable extends StatelessWidget {
  const _DailyTable({required this.report});
  final OpsReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = NumberFormat.decimalPattern();
    return LuxCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: LuxColors.accent,
          collapsedIconColor: LuxColors.whiteSecondary,
          title:
              Text(l.adminReportsDailyTable, style: LuxTypography.bodyMedium),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.sm),
              child: TextButton.icon(
                onPressed: () => _export(
                  context,
                  'luxelane-dias-${_stamp(report)}.csv',
                  report.dailyCsv(
                    dateHeader: l.adminReportsColDate,
                    tripsHeader: l.adminReportsColTrips,
                    revenueHeader: l.adminReportsColRevenue,
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l.adminReportsExportDaily),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: _th,
                dataTextStyle: _td,
                columns: [
                  DataColumn(label: Text(l.adminReportsColDate)),
                  DataColumn(
                      label: Text(l.adminReportsColTrips), numeric: true),
                  DataColumn(
                      label: Text(l.adminReportsColRevenue), numeric: true),
                ],
                rows: [
                  for (final d in report.days.reversed)
                    DataRow(cells: [
                      DataCell(Text(DateFormat.yMMMEd().format(d.day))),
                      DataCell(Text(n.format(d.trips))),
                      DataCell(Text(LuxMoney.format(d.revenue))),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriversTable extends StatelessWidget {
  const _DriversTable({required this.report});
  final OpsReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = NumberFormat.decimalPattern();
    final r2 = NumberFormat.decimalPattern()..maximumFractionDigits = 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l.adminReportsDrivers),
        if (report.drivers.isNotEmpty) ...[
          const SizedBox(height: LuxSpacing.sm),
          TextButton.icon(
            onPressed: () => _export(
              context,
              'luxelane-choferes-${_stamp(report)}.csv',
              report.driversCsv(
                nameHeader: l.adminReportsColDriver,
                tripsHeader: l.adminReportsColTrips,
                revenueHeader: l.adminReportsColRevenue,
                ratingHeader: l.adminReportsColRating,
              ),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text(l.adminReportsExportDrivers),
          ),
        ],
        const SizedBox(height: LuxSpacing.md),
        LuxCard(
          padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
          child: report.drivers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(LuxSpacing.md),
                  child: Text(l.adminReportsNoDrivers,
                      style: LuxTypography.bodyMedium),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: _th,
                    dataTextStyle: _td,
                    columns: [
                      DataColumn(label: Text(l.adminReportsColDriver)),
                      DataColumn(
                          label: Text(l.adminReportsColTrips), numeric: true),
                      DataColumn(
                          label: Text(l.adminReportsColRevenue), numeric: true),
                      DataColumn(
                          label: Text(l.adminReportsColRating), numeric: true),
                    ],
                    rows: [
                      for (final d in report.drivers)
                        DataRow(cells: [
                          DataCell(Text(d.name.isEmpty
                              ? l.adminReportsUnknownDriver
                              : d.name)),
                          DataCell(Text(n.format(d.trips))),
                          DataCell(Text(LuxMoney.format(d.revenue))),
                          DataCell(Text(d.avgRating == null
                              ? '—'
                              : '${r2.format(d.avgRating)} (${d.ratingCount})')),
                        ]),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
