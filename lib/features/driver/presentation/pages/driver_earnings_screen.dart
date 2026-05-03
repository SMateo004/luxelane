import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/driver_bloc.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state is! DriverLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final completed = state.completedBookings;
          final total = state.totalEarnings;

          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              _EarningsSummary(total: total, rides: completed.length),
              const SizedBox(height: LuxSpacing.lg),
              const SectionHeader(title: 'Completed Rides'),
              const SizedBox(height: LuxSpacing.md),
              if (completed.isEmpty)
                const _EmptyEarnings()
              else
                ...completed.map((b) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: LuxSpacing.sm),
                      child: _EarningsCard(booking: b),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.total, required this.rides});
  final double total;
  final int rides;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LuxColors.sapphire.withOpacity(0.12),
              LuxColors.blackElevated,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          border: Border.all(color: LuxColors.sapphire.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Text('Total Earnings', style: LuxTypography.caption),
            const SizedBox(height: LuxSpacing.sm),
            Text(
              'Bs${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Cormorant',
                fontSize: 48,
                fontWeight: FontWeight.w600,
                color: LuxColors.sapphire,
              ),
            ),
            const SizedBox(height: LuxSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: LuxColors.whiteTertiary, size: 14),
                const SizedBox(width: LuxSpacing.xs),
                Text(
                  '$rides ride${rides == 1 ? '' : 's'} completed',
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ],
        ),
      );
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy · h:mm a')
                        .format(booking.scheduledAt),
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
                ],
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Bs${(booking.finalPrice ?? booking.estimatedPrice).toStringAsFixed(2)}',
                  style: LuxTypography.titleMedium
                      .copyWith(color: LuxColors.sapphire),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LuxSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: LuxColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                  ),
                  child: Text(
                    'PAID',
                    style: LuxTypography.caption
                        .copyWith(color: LuxColors.success, fontSize: 9),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _EmptyEarnings extends StatelessWidget {
  const _EmptyEarnings();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: LuxSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_money,
                  size: 48, color: LuxColors.whiteTertiary),
              SizedBox(height: LuxSpacing.md),
              Text('No completed rides yet',
                  style: TextStyle(color: LuxColors.white)),
            ],
          ),
        ),
      );
}
