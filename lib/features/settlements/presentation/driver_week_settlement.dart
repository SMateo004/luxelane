import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../data/settlement_repository.dart';
import '../domain/settlement.dart';

/// Chauffeur's view of this week and last week: earnings after commission,
/// who owes whom, and whether Luxelane already settled it.
class DriverWeekSettlement extends StatelessWidget {
  const DriverWeekSettlement({
    super.key,
    required this.driverId,
    required this.bookings,
    this.repository,
    this.now,
  });

  final String driverId;
  final List<Booking> bookings;
  final SettlementRepository? repository;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (repository == null && !sl.isRegistered<SettlementRepository>()) return const SizedBox.shrink();
    final repo = repository ?? sl<SettlementRepository>();
    final l = context.l10n;
    final thisWeek = Settlements.weekStart(now ?? DateTime.now());
    final lastWeek = DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7);
    return StreamBuilder<double?>(
      stream: repo.watchCommission(),
      builder: (context, cSnap) {
        final pct = cSnap.data;
        return StreamBuilder<List<SettlementRecord>>(
          stream: repo.watchRecords(driverId: driverId),
          builder: (context, rSnap) {
            final records = rSnap.data ?? const <SettlementRecord>[];
            SettlementRecord? recordFor(DateTime w) =>
                records.where((r) => Settlements.recordId(r.driverId, r.weekStart) == Settlements.recordId(driverId, w)).firstOrNull;

            Widget week(String title, DateTime start) {
              final s = Settlements.compute(bookings.where((b) => b.driverId == driverId).toList(), start, pct ?? 0)
                  .where((x) => x.driverId == driverId)
                  .firstOrNull;
              final rec = recordFor(start);
              return LuxCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(title, style: LuxTypography.titleMedium)),
                    Text(l.adminReportsTooltipTrips(s?.trips ?? 0), style: LuxTypography.caption),
                  ]),
                  const SizedBox(height: LuxSpacing.sm),
                  if (s == null)
                    Text(l.settleDriverNoTrips, style: LuxTypography.bodyMedium)
                  else if (pct == null)
                    Text(l.settleDriverGrossOnly(LuxMoney.format(s.gross, cents: true)), style: LuxTypography.bodyMedium)
                  else ...[
                    Text(l.settleDriverEarnings(LuxMoney.format(s.earnings, cents: true)),
                        style: LuxTypography.bodyLarge.copyWith(color: LuxColors.white)),
                    const SizedBox(height: 2),
                    Text(
                      l.settleDriverBreakdown(
                        LuxMoney.format(s.gross, cents: true),
                        NumberFormat.decimalPattern().format(pct),
                        LuxMoney.format(s.commission, cents: true),
                      ),
                      style: LuxTypography.caption,
                    ),
                    const SizedBox(height: LuxSpacing.sm),
                    Text(
                      s.balance.abs() < 0.005
                          ? l.settleEven
                          : s.balance > 0
                              ? l.settleDriverReceives(LuxMoney.format(s.balance, cents: true))
                              : l.settleDriverPays(LuxMoney.format(-s.balance, cents: true)),
                      style: LuxTypography.titleMedium.copyWith(color: LuxColors.accent),
                    ),
                  ],
                  if (rec != null) ...[
                    const SizedBox(height: LuxSpacing.xs),
                    Row(children: [
                      const Icon(Icons.verified_rounded, size: 16, color: LuxColors.success),
                      const SizedBox(width: 6),
                      Text(rec.paidAt == null ? l.settlePaid : l.settlePaidOn(DateFormat.MMMd().format(rec.paidAt!)),
                          style: LuxTypography.caption.copyWith(color: LuxColors.white)),
                    ]),
                  ],
                ]),
              );
            }

            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              week(l.settleThisWeek, thisWeek),
              const SizedBox(height: LuxSpacing.sm),
              week(l.settleLastWeek, lastWeek),
              const SizedBox(height: LuxSpacing.xs),
              Text(pct == null ? l.settleDriverNoCommission : l.settleDriverHow, style: LuxTypography.caption),
            ]);
          },
        );
      },
    );
  }
}
