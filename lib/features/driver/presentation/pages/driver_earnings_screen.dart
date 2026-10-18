import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../settlements/presentation/driver_week_settlement.dart';
import '../bloc/driver_bloc.dart';

String _bs(double v) => LuxMoney.format(v, cents: true);

String _pct(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driverStatEarnings)),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state is! DriverLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final completed = [...state.completedBookings]
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              _EarningsSummary(state: state),
              const SizedBox(height: LuxSpacing.lg),
              SectionHeader(title: context.l10n.settleDriverTitle),
              const SizedBox(height: LuxSpacing.md),
              DriverWeekSettlement(driverId: state.user.id, bookings: completed),
              const SizedBox(height: LuxSpacing.lg),
              SectionHeader(title: context.l10n.driverCompletedTrips),
              const SizedBox(height: LuxSpacing.md),
              if (completed.isEmpty)
                const _EmptyEarnings()
              else
                ...completed.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                      child:
                          _EarningsCard(booking: b, split: state.earningsOf(b)),
                    )),
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
      padding: const EdgeInsets.all(LuxSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LuxColors.sapphire.withOpacity(0.12),
            LuxColors.surfaceMuted,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LuxRadius.lg),
        border: Border.all(color: LuxColors.sapphire.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('Tus ganancias netas', style: LuxTypography.caption),
          const SizedBox(height: LuxSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _bs(state.totalEarnings),
              style: const TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize: 48,
                fontWeight: FontWeight.w600,
                color: LuxColors.sapphire,
              ),
            ),
          ),
          const SizedBox(height: LuxSpacing.md),
          _Line(
              label: 'Tarifas de tus viajes', value: _bs(state.grossEarnings)),
          _Line(
              label: 'Comisión Luxelane',
              value: '− ${_bs(state.totalCommission)}'),
          const SizedBox(height: LuxSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: LuxColors.inkTertiary, size: 14),
              const SizedBox(width: LuxSpacing.xs),
              Flexible(
                child: Text(
                  context.l10n.driverCompletedCount(rides),
                  style: LuxTypography.caption,
                ),
              ),
            ],
          ),
          if (state.hasProvisionalEarnings) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(
              'Los viajes marcados como provisionales se calculan con una '
              'comisión del ${_pct(kDefaultCommissionPct)} % hasta que se '
              'confirme su liquidación.',
              textAlign: TextAlign.center,
              style:
                  LuxTypography.caption.copyWith(color: LuxColors.inkTertiary),
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
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: LuxTypography.caption)),
            Text(value,
                style: LuxTypography.bodyMedium
                    .copyWith(color: LuxColors.inkSecondary)),
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
    return LuxCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(booking.scheduledAt),
                  style: LuxTypography.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  booking.origin.address,
                  style: LuxTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '→ ${booking.destination.address}',
                  style: LuxTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  booking.refunded
                      ? 'Reembolsado al pasajero · sin comisión ni pago'
                      : 'Tarifa ${_bs(split.amount)} · comisión '
                          '${_pct(split.commissionPct)} % (${_bs(split.platformCommission)})',
                  style: LuxTypography.caption
                      .copyWith(color: LuxColors.inkTertiary),
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
                style: LuxTypography.titleMedium
                    .copyWith(color: LuxColors.sapphire),
              ),
              if (provisional) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LuxSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: LuxColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                  ),
                  child: Text(
                    'PROVISIONAL',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.warning, fontSize: 9),
                  ),
                ),
              ],
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_money, size: 48, color: LuxColors.inkTertiary),
              const SizedBox(height: LuxSpacing.md),
              Text(context.l10n.driverNoCompletedTrips,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: LuxColors.ink)),
            ],
          ),
        ),
      );
}
