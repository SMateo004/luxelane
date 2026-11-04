import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/driver_trip.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/driver_bloc.dart';

String _bs(double v) => LuxFormat.money(v);

String _pct(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driverEarningsTitle)),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state is! DriverLoaded) return const LuxSkeletonList();
          final l10n = context.l10n;
          // Historial (driverHistory, ventana del chófer B1): cargando,
          // error con reintento, vacío o la lista.
          if (state.history == null && state.historyFailed) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              message: l10n.driverHistoryLoadFailed,
              actionLabel: l10n.driverRetry,
              onAction: () => context
                  .read<DriverBloc>()
                  .add(DriverHistoryWatched(driverId: state.user.id)),
            );
          }
          if (state.history == null) {
            return Semantics(
              container: true,
              excludeSemantics: true,
              label: l10n.driverHistoryLoading,
              child: const LuxSkeletonList(),
            );
          }
          final completed = state.completedTrips;

          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              if (state.historyFailed) ...[
                _HistoryErrorBanner(driverId: state.user.id),
                const SizedBox(height: LuxSpacing.md),
              ],
              LuxFadeIn(child: _EarningsSummary(state: state)),
              const SizedBox(height: LuxSpacing.lg),
              SectionHeader(title: l10n.driverEarningsCompleted),
              const SizedBox(height: LuxSpacing.sm + 2),
              if (completed.isEmpty)
                const _EmptyEarnings()
              else
                LuxFadeIn(
                  index: 1,
                  child: LuxGroup(
                    children: [
                      for (final t in completed)
                        _EarningsCard(trip: t, split: state.earningsOf(t)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// El historial ya cargado dejó de actualizarse: se avisa sin tapar lo que
/// ya se ve, con reintento.
class _HistoryErrorBanner extends StatelessWidget {
  const _HistoryErrorBanner({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Expanded(
            child: Text(l10n.driverHistoryLoadFailed,
                style: LuxTypography.bodyMedium),
          ),
          TextButton(
            onPressed: () => context
                .read<DriverBloc>()
                .add(DriverHistoryWatched(driverId: driverId)),
            child: Text(l10n.driverRetry),
          ),
        ],
      ),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.state});
  final DriverLoaded state;

  @override
  Widget build(BuildContext context) {
    final rides = state.completedTrips.length;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LuxSpacing.lg,
        LuxSpacing.lg,
        LuxSpacing.lg,
        LuxSpacing.md,
      ),
      decoration: BoxDecoration(
        color: LuxColors.surface,
        borderRadius: BorderRadius.circular(LuxRadius.xl),
        border: Border.all(color: LuxColors.border),
        boxShadow: LuxElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.driverEarningsNetTitle, style: LuxTypography.eyebrow),
          const SizedBox(height: LuxSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _bs(state.totalEarnings),
              style: LuxTypography.displayLarge.copyWith(fontSize: 52),
            ),
          ),
          const SizedBox(height: LuxSpacing.xs),
          Text(
            l10n.driverEarningsRides(rides),
            style: LuxTypography.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: LuxSpacing.md),
          const LuxDivider(),
          const SizedBox(height: LuxSpacing.sm),
          _Line(
            label: l10n.driverEarningsFares,
            value: _bs(state.grossEarnings),
          ),
          _Line(
            label: l10n.driverEarningsCommission,
            value: '− ${_bs(state.totalCommission)}',
          ),
          if (state.hasProvisionalEarnings) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(
              l10n.driverEarningsProvisionalNote(_pct(kDefaultCommissionPct)),
              style: LuxTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: LuxTypography.bodyMedium.copyWith(fontSize: 13),
              ),
            ),
            Text(value,
                style: LuxTypography.titleMedium.copyWith(fontSize: 13)),
          ],
        ),
      );
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.trip, required this.split});
  final DriverTripSummary trip;
  final BookingSettlement split;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provisional = trip.settlement == null && !trip.refunded;
    final hourly = trip.serviceType == ServiceType.byTheHour;
    // Solo la zona (sin dirección exacta): el resumen no tiene más.
    final area = (hourly ? trip.pickupArea : trip.dropoffArea) ??
        trip.pickupArea ??
        l10n.driverEarningsAreaUnknown;
    final date = trip.endedAt == null ? '—' : LuxFormat.dateTime(trip.endedAt!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hourly ? l10n.driverEarningsTripArea(area) : area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxTypography.bodyLarge.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  trip.refunded
                      ? l10n.driverEarningsRefunded(date)
                      : l10n.driverEarningsFareLine(
                          date,
                          _bs(split.amount),
                          _pct(split.commissionPct),
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxTypography.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: LuxSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _bs(split.driverPayout),
                style: LuxTypography.titleMedium.copyWith(fontSize: 15),
              ),
              if (provisional)
                Text(
                  l10n.driverEarningsProvisional,
                  style: LuxTypography.caption.copyWith(
                    color: LuxColors.warning,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyEarnings extends StatelessWidget {
  const _EmptyEarnings();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 260,
        child: EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          message: context.l10n.driverEarningsEmpty,
        ),
      );
}
