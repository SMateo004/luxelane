import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/driver_bloc.dart';

String _bs(double v) => 'Bs${v.toStringAsFixed(2)}';

String _pct(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganancias')),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state is! DriverLoaded) return const LuxSkeletonList();

          final completed = [...state.completedBookings]
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              LuxFadeIn(child: _EarningsSummary(state: state)),
              const SizedBox(height: LuxSpacing.lg),
              const SectionHeader(title: 'Viajes completados'),
              const SizedBox(height: LuxSpacing.sm + 2),
              if (completed.isEmpty)
                const _EmptyEarnings()
              else
                LuxFadeIn(
                  index: 1,
                  child: LuxGroup(children: [
                    for (final b in completed)
                      _EarningsCard(booking: b, split: state.earningsOf(b)),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.state});
  final DriverLoaded state;

  @override
  Widget build(BuildContext context) {
    final rides = state.completedBookings.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          LuxSpacing.lg, LuxSpacing.lg, LuxSpacing.lg, LuxSpacing.md),
      decoration: BoxDecoration(
        color: LuxColors.surface,
        borderRadius: BorderRadius.circular(LuxRadius.xl),
        border: Border.all(color: LuxColors.border),
        boxShadow: LuxElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TUS GANANCIAS NETAS', style: LuxTypography.eyebrow),
          const SizedBox(height: LuxSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _bs(state.totalEarnings),
              style: LuxTypography.displayLarge.copyWith(fontSize: 52),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$rides viaje${rides == 1 ? '' : 's'} completado${rides == 1 ? '' : 's'}',
            style: LuxTypography.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: LuxSpacing.md),
          const LuxDivider(),
          const SizedBox(height: LuxSpacing.sm),
          _Line(
              label: 'Tarifas de tus viajes', value: _bs(state.grossEarnings)),
          _Line(
              label: 'Comisión Luxelane',
              value: '− ${_bs(state.totalCommission)}'),
          if (state.hasProvisionalEarnings) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(
              'Los viajes provisionales se calculan con una comisión del '
              '${_pct(kDefaultCommissionPct)} % hasta que se confirme su '
              'liquidación.',
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
                child: Text(label,
                    style: LuxTypography.bodyMedium.copyWith(fontSize: 13))),
            Text(value,
                style: LuxTypography.titleMedium.copyWith(fontSize: 13)),
          ],
        ),
      );
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.booking, required this.split});
  final Booking booking;
  final BookingSettlement split;

  @override
  Widget build(BuildContext context) {
    final provisional = booking.settlement == null && !booking.refunded;
    final hourly = booking.serviceType == ServiceType.byTheHour;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hourly
                      ? '${booking.hours ?? 2} h desde ${booking.origin.displayName}'
                      : booking.destination.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxTypography.bodyLarge.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.refunded
                      ? '${LuxFormat.dateTime(booking.scheduledAt)} · reembolsado'
                      : '${LuxFormat.dateTime(booking.scheduledAt)} · '
                          'tarifa ${_bs(split.amount)} · '
                          '${_pct(split.commissionPct)} %',
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
              Text(_bs(split.driverPayout),
                  style: LuxTypography.titleMedium.copyWith(fontSize: 15)),
              if (provisional)
                Text('Provisional',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.warning, fontSize: 11)),
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
  Widget build(BuildContext context) => const SizedBox(
        height: 260,
        child: EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          message: 'Tu primer viaje\naparecerá aquí.',
        ),
      );
}
