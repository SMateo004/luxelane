import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/driver_bloc.dart';

class DriverQueueScreen extends StatelessWidget {
  const DriverQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driverQueueTitle)),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state is! DriverLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final pending = state.pendingRequests
              .where((b) => !state.declinedIds.contains(b.id))
              .toList()
            ..sort((a, b) => a.effectivePickup.compareTo(b.effectivePickup));

          final upcoming = state.bookings.where((b) {
            return b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.driverArriving ||
                b.status == BookingStatus.driverArrived;
          }).toList()
            ..sort((a, b) => a.effectivePickup.compareTo(b.effectivePickup));

          if (pending.isEmpty && upcoming.isEmpty) {
            return const _EmptyQueue(isAvailable: true); // Show 'No jobs yet' instead of 'Go online'
          }

          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionTitle(title: context.l10n.driverQueueAvailable, isGold: true),
                const SizedBox(height: LuxSpacing.sm),
                ...pending.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                      child: _JobCard(booking: b, isPending: true),
                    )),
                const SizedBox(height: LuxSpacing.lg),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionTitle(title: context.l10n.driverQueueMyActive, isGold: false),
                const SizedBox(height: LuxSpacing.sm),
                ...upcoming.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                      child: _JobCard(booking: b, isPending: false),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isGold});
  final String title;
  final bool isGold;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isGold ? LuxColors.accent : LuxColors.whiteTertiary,
          letterSpacing: 2,
        ),
      );
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.isAvailable});
  final bool isAvailable;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAvailable
                  ? Icons.hourglass_empty_rounded
                  : Icons.wifi_tethering_off_rounded,
              size: 48,
              color: LuxColors.whiteTertiary,
            ),
            const SizedBox(height: LuxSpacing.md),
            Text(
              isAvailable ? context.l10n.driverQueueEmptyTitle : context.l10n.driverQueueOfflineTitle,
              style: LuxTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LuxSpacing.sm),
            Text(
              isAvailable
                  ? context.l10n.driverQueueEmptyBody
                  : context.l10n.driverQueueOfflineBody,
              style: LuxTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        ),
      );
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.booking, required this.isPending});
  final Booking booking;
  final bool isPending;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BookingStatusChip(status: booking.status),
                const Spacer(),
                Text(
                  LuxMoney.format(booking.estimatedPrice),
                  style: LuxTypography.titleMedium
                      .copyWith(color: LuxColors.accent),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.sm),
            Text(
              '${DateFormat.MMMEd().format(booking.effectivePickup)} · '
              '${DateFormat.jm().format(booking.effectivePickup)}',
              style: LuxTypography.caption,
            ),
            const SizedBox(height: LuxSpacing.md),
            _RouteRow(origin: booking.origin, destination: booking.destination),
            const SizedBox(height: LuxSpacing.md),
            _JobActions(booking: booking, isPending: isPending),
          ],
        ),
      );
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.origin, required this.destination});
  final Place origin;
  final Place destination;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.radio_button_checked,
                  color: LuxColors.accent, size: 16),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(origin.address,
                    style: LuxTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(
                width: 2,
                height: 16,
                color: LuxColors.blackBorder),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: LuxColors.error, size: 16),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(destination.address,
                    style: LuxTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      );
}

class _JobActions extends StatelessWidget {
  const _JobActions({required this.booking, required this.isPending});
  final Booking booking;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DriverBloc>();
    final auth = context.read<AuthBloc>().state;
    final driverId = auth is AuthAuthenticated ? auth.user.id : '';

    if (isPending) {
      return LuxButton(
        label: context.l10n.driverAcceptRide,
        icon: Icons.check_circle_outline_rounded,
        onPressed: () => bloc.add(DriverRequestAccepted(
          bookingId: booking.id,
          driverId: driverId,
        )),
      );
    }

    switch (booking.status) {
      case BookingStatus.confirmed:
        return LuxButton(
          label: context.l10n.driverActionGoToPickupShort,
          icon: Icons.navigation_rounded,
          onPressed: () =>
              bloc.add(DriverBookingAccepted(bookingId: booking.id)),
        );
      case BookingStatus.driverArriving:
        return LuxButton(
          label: context.l10n.driverActionArrived,
          icon: Icons.where_to_vote_rounded,
          onPressed: () =>
              bloc.add(DriverArrivedAtPickup(bookingId: booking.id)),
        );
      case BookingStatus.driverArrived:
        return LuxButton(
          label: context.l10n.driverActionStartTrip,
          icon: Icons.play_arrow_rounded,
          onPressed: () =>
              bloc.add(DriverTripStarted(bookingId: booking.id)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
