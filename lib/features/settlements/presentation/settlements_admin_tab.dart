import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../data/settlement_repository.dart';
import '../domain/settlement.dart';

/// "+Bs 120" / "−Bs 45" in the right words: who pays whom.
String settlementLabel(AppLocalizations l, double balance) {
  if (balance.abs() < 0.005) return l.settleEven;
  return balance > 0
      ? l.settleLuxelanePays(LuxMoney.format(balance, cents: true))
      : l.settleDriverOwes(LuxMoney.format(-balance, cents: true));
}

/// Admin panel → Liquidaciones: what each chauffeur is owed (rides Luxelane
/// collected) or owes (commission on rides they collected) for a week.
class SettlementsAdminTab extends StatefulWidget {
  const SettlementsAdminTab({super.key, this.repository, this.now});
  final SettlementRepository? repository;
  final DateTime? now;

  @override
  State<SettlementsAdminTab> createState() => _SettlementsAdminTabState();
}

class _SettlementsAdminTabState extends State<SettlementsAdminTab> {
  late final SettlementRepository _repo = widget.repository ?? sl<SettlementRepository>();
  late final Stream<double?> _commission = _repo.watchCommission();
  late DateTime _week = Settlements.weekStart(widget.now ?? DateTime.now());
  late Stream<List<Booking>> _bookings = _repo.watchCompleted(_week);
  late Stream<List<SettlementRecord>> _records = _repo.watchRecords(weekStart: _week);

  void _shift(int weeks) => setState(() {
        _week = DateTime(_week.year, _week.month, _week.day + 7 * weeks);
        _bookings = _repo.watchCompleted(_week);
        _records = _repo.watchRecords(weekStart: _week);
      });

  String get _adminId {
    final a = context.read<AuthBloc>().state;
    return a is AuthAuthenticated ? a.user.id : '';
  }

  Future<void> _editCommission(double? current) async {
    final l = context.l10n;
    final pct = await showDialog<double>(context: context, builder: (_) => _CommissionDialog(initial: current));
    if (pct == null || !mounted) return;
    try {
      await _repo.setCommission(pct, adminId: _adminId);
      if (mounted) showLuxSnackbar(context, l.settleCommissionSaved);
    } catch (_) {
      if (mounted) showLuxSnackbar(context, l.adminActionFailed, isError: true);
    }
  }

  Future<void> _export(List<DriverSettlement> rows) async {
    final l = context.l10n;
    final csv = Settlements.csv(rows, headers: [
      l.adminReportsColDriver,
      l.adminReportsColTrips,
      l.settleColGross,
      l.settleColByDriver,
      l.settleColByLuxelane,
      l.settleColCommission,
      l.settleColBalance,
    ]);
    final file = 'luxelane-liquidaciones-${DateFormat('yyyyMMdd').format(_week)}.csv';
    if (downloadTextFile(file, csv)) {
      showLuxSnackbar(context, l.adminReportsDownloaded);
      return;
    }
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) showLuxSnackbar(context, l.adminReportsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = Settlements.weekStart(widget.now ?? DateTime.now());
    final lastDay = Settlements.weekEnd(_week).subtract(const Duration(days: 1));
    return StreamBuilder<double?>(
      stream: _commission,
      builder: (context, cSnap) {
        final pct = cSnap.data;
        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            SectionHeader(title: l.settleTitle),
            const SizedBox(height: LuxSpacing.sm),
            Text(l.settleIntro, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            LuxCard(
              child: Row(children: [
                Icon(pct == null ? Icons.warning_amber_rounded : Icons.percent_rounded,
                    color: pct == null ? LuxColors.warning : LuxColors.accent),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: Text(
                    pct == null ? l.settleCommissionMissing : l.settleCommissionIs(NumberFormat.decimalPattern().format(pct)),
                    style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => _editCommission(pct),
                  child: Text(pct == null ? l.settleCommissionSet : l.settleCommissionEdit),
                ),
              ]),
            ),
            const SizedBox(height: LuxSpacing.lg),
            Row(children: [
              IconButton(tooltip: l.settlePrevWeek, icon: const Icon(Icons.chevron_left_rounded), onPressed: () => _shift(-1)),
              Expanded(
                child: Text(
                  l.settleWeekRange(DateFormat.MMMd().format(_week), DateFormat.yMMMd().format(lastDay)),
                  textAlign: TextAlign.center,
                  style: LuxTypography.titleLarge,
                ),
              ),
              IconButton(
                tooltip: l.settleNextWeek,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _week.isBefore(current) ? () => _shift(1) : null,
              ),
            ]),
            const SizedBox(height: LuxSpacing.md),
            if (pct == null)
              EmptyState(icon: Icons.percent_rounded, message: l.settleNeedsCommission)
            else
              StreamBuilder<List<Booking>>(
                stream: _bookings,
                builder: (context, bSnap) => StreamBuilder<List<SettlementRecord>>(
                  stream: _records,
                  builder: (context, rSnap) {
                    if (!bSnap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: LuxColors.accent));
                    }
                    final rows = Settlements.compute(bSnap.data!, _week, pct);
                    final records = {for (final r in rSnap.data ?? const <SettlementRecord>[]) r.driverId: r};
                    if (rows.isEmpty) {
                      return EmptyState(icon: Icons.receipt_long_outlined, message: l.settleNoTrips);
                    }
                    final toPay = rows.where((r) => r.balance > 0).fold(0.0, (s, r) => s + r.balance);
                    final toCollect = rows.where((r) => r.balance < 0).fold(0.0, (s, r) => s - r.balance);
                    final commission = rows.fold(0.0, (s, r) => s + r.commission);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(builder: (context, c) {
                          final w = c.maxWidth < 480 ? (c.maxWidth - LuxSpacing.md) / 2 : 200.0;
                          return Wrap(spacing: LuxSpacing.md, runSpacing: LuxSpacing.md, children: [
                            _Stat(l.settleStatCommission, LuxMoney.format(commission, cents: true), width: w),
                            _Stat(l.settleStatToPay, LuxMoney.format(toPay, cents: true), width: w),
                            _Stat(l.settleStatToCollect, LuxMoney.format(toCollect, cents: true), width: w),
                          ]);
                        }),
                        const SizedBox(height: LuxSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _export(rows),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(l.settleExport),
                          ),
                        ),
                        const SizedBox(height: LuxSpacing.sm),
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                            child: _SettlementCard(
                              settlement: r,
                              record: records[r.driverId],
                              onPaid: () => _repo.markPaid(r, _week, pct, adminId: _adminId),
                              onUndo: () => _repo.unmarkPaid(r.driverId, _week),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.width = 200});
  final String label, value;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: LuxCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 2, style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
            const SizedBox(height: LuxSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: LuxTypography.headlineMedium.copyWith(color: LuxColors.white)),
            ),
          ]),
        ),
      );
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement, required this.record, required this.onPaid, required this.onUndo});
  final DriverSettlement settlement;
  final SettlementRecord? record;
  final VoidCallback onPaid;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = settlement;
    final rec = record;
    final changed = rec != null && (rec.balance - s.balance).abs() >= 0.01;
    Widget line(String label, double amount) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(label, style: LuxTypography.caption)),
            Text(LuxMoney.format(amount, cents: true), style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
          ]),
        );
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(s.driverName.isEmpty ? l.adminReportsUnknownDriver : s.driverName,
                  overflow: TextOverflow.ellipsis, style: LuxTypography.titleMedium),
            ),
            Text(l.adminReportsTooltipTrips(s.trips), style: LuxTypography.caption),
          ]),
          const SizedBox(height: LuxSpacing.sm),
          line(l.settleColGross, s.gross),
          line(l.settleColByDriver, s.collectedByChauffeur),
          line(l.settleColByLuxelane, s.collectedByLuxelane),
          line(l.settleColCommission, s.commission),
          const Divider(color: LuxColors.blackBorder),
          Text(settlementLabel(l, s.balance),
              style: LuxTypography.titleMedium.copyWith(color: s.balance >= 0 ? LuxColors.accent : LuxColors.white)),
          const SizedBox(height: LuxSpacing.sm),
          if (rec == null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: onPaid,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(l.settleMarkPaid),
            )
          else
            Wrap(spacing: LuxSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Icon(Icons.verified_rounded, color: LuxColors.success, size: 18),
              Text(
                rec.paidAt == null ? l.settlePaid : l.settlePaidOn(DateFormat.MMMd().format(rec.paidAt!)),
                style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white),
              ),
              TextButton(onPressed: onUndo, child: Text(l.settleUndo)),
              if (changed)
                Text(l.settleChangedSincePaid(settlementLabel(l, rec.balance)),
                    style: LuxTypography.caption.copyWith(color: LuxColors.warning)),
            ]),
        ],
      ),
    );
  }
}

class _CommissionDialog extends StatefulWidget {
  const _CommissionDialog({this.initial});
  final double? initial;

  @override
  State<_CommissionDialog> createState() => _CommissionDialogState();
}

class _CommissionDialogState extends State<_CommissionDialog> {
  late final _ctrl = TextEditingController(
      text: widget.initial == null ? '' : NumberFormat.decimalPattern().format(widget.initial));
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 50) {
      setState(() => _error = context.l10n.settleCommissionRange);
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(l.settleCommissionTitle, style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.settleCommissionHelp, style: LuxTypography.bodyMedium),
          const SizedBox(height: LuxSpacing.md),
          LuxTextField(
            controller: _ctrl,
            label: l.settleCommissionLabel,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          ),
          if (_error != null) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(_error!, style: LuxTypography.caption.copyWith(color: LuxColors.error)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.commonCancel)),
        TextButton(
          onPressed: _save,
          child: Text(l.settleSave, style: const TextStyle(color: LuxColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
