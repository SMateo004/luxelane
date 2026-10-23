import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../incidents/presentation/widgets/sos_entry.dart';
import '../bloc/driver_bloc.dart';
import '../widgets/driver_step_action.dart';
import '../widgets/flight_info_card.dart';

class DriverActiveRideScreen extends StatelessWidget {
  const DriverActiveRideScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverBloc, DriverState>(
      builder: (context, state) {
        if (state is! DriverLoaded) {
          return const Scaffold(body: LuxSkeletonList(count: 3));
        }

        Booking? booking;
        try {
          booking = state.bookings.firstWhere((b) => b.id == bookingId);
        } catch (_) {}

        if (booking == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Viaje no encontrado')),
          );
        }

        final web = isWeb(context);
        return DriverFeedbackListener(
          child: Scaffold(
            body:
                web
                    ? _webLayout(context, booking, state)
                    : _mobileLayout(context, booking, state),
          ),
        );
      },
    );
  }

  Widget _mobileLayout(
    BuildContext context,
    Booking booking,
    DriverLoaded state,
  ) => Stack(
    children: [
      LuxMap(origin: booking.origin, destination: booking.destination),
      SafeArea(
        child: Column(
          children: [
            _DriverTopBar(booking: booking),
            const Spacer(),
            _DriverBottomPanel(booking: booking),
          ],
        ),
      ),
    ],
  );

  Widget _webLayout(
    BuildContext context,
    Booking booking,
    DriverLoaded state,
  ) => Row(
    children: [
      Expanded(
        child: LuxMap(origin: booking.origin, destination: booking.destination),
      ),
      SizedBox(
        width: 400,
        child: Container(
          color: LuxColors.surface,
          child: Column(
            children: [
              _DriverWebHeader(booking: booking),
              const LuxDivider(),
              Expanded(child: _DriverSidePanel(booking: booking)),
            ],
          ),
        ),
      ),
    ],
  );
}

/// SOS del chófer (solo lo ve él; el pasajero nunca se entera).
Widget _driverSos(Booking b) =>
    b.driverId == null
        ? const SizedBox.shrink()
        : SosEntry(bookingId: b.id, uid: b.driverId!, status: b.status);

class _DriverTopBar extends StatelessWidget {
  const _DriverTopBar({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(LuxSpacing.md),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LuxColors.surface,
              borderRadius: BorderRadius.circular(LuxRadius.sm),
              border: Border.all(color: LuxColors.border),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: LuxColors.ink,
            ),
          ),
        ),
        const SizedBox(width: LuxSpacing.md),
        const LuxelaneWordmark(),
        const Spacer(),
        _driverSos(booking),
      ],
    ),
  );
}

class _DriverWebHeader extends StatelessWidget {
  const _DriverWebHeader({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(LuxSpacing.md),
    child: Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const LuxelaneWordmark(),
        const Spacer(),
        _driverSos(booking),
        const SizedBox(width: LuxSpacing.sm),
        BookingStatusChip(status: booking.status),
      ],
    ),
  );
}

class _DriverBottomPanel extends StatelessWidget {
  const _DriverBottomPanel({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: LuxColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
      border: Border(top: BorderSide(color: LuxColors.border)),
    ),
    padding: const EdgeInsets.fromLTRB(
      LuxSpacing.md,
      LuxSpacing.md,
      LuxSpacing.md,
      LuxSpacing.xxl,
    ),
    child: _DriverSidePanel(booking: booking),
  );
}

class _DriverSidePanel extends StatelessWidget {
  const _DriverSidePanel({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RideProgressBar(status: booking.status),
      const SizedBox(height: LuxSpacing.md),
      Row(
        children: [
          BookingStatusChip(status: booking.status),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(
            child: Text(
              DriverStepAction.message(booking),
              style: LuxTypography.bodyMedium,
            ),
          ),
        ],
      ),
      const SizedBox(height: LuxSpacing.md),
      const LuxDivider(),
      const SizedBox(height: LuxSpacing.md),
      _RideInfoRow(booking: booking),
      const SizedBox(height: LuxSpacing.md),
      DriverStepAction(
        booking: booking,
        onCompleted: () => context.go('/driver'),
      ),
    ],
  );
}

class _RideInfoRow extends StatelessWidget {
  const _RideInfoRow({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const Icon(
            Icons.radio_button_checked,
            color: LuxColors.sapphire,
            size: 16,
          ),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(
            child: Text(
              booking.origin.address,
              style: LuxTypography.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: LuxSpacing.sm),
      Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: LuxColors.error,
            size: 16,
          ),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(
            child: Text(
              booking.destination.address,
              style: LuxTypography.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      if (booking.guest != null) ...[
        const SizedBox(height: LuxSpacing.md),
        LuxGroup(
          children: [
            LuxListRow(
              icon: Icons.person_outline_rounded,
              title: 'Pasajero: ${booking.guest!.fullName}',
              subtitle:
                  booking.guest!.contactLine.isEmpty
                      ? null
                      : booking.guest!.contactLine,
            ),
          ],
        ),
      ],
      if (!booking.riderPreferences.isEmpty) ...[
        const SizedBox(height: LuxSpacing.md),
        RiderPreferencesNote(preferences: booking.riderPreferences),
      ],
      if (booking.flightNumber?.isNotEmpty == true) ...[
        const SizedBox(height: LuxSpacing.md),
        FlightInfoCard(booking: booking),
      ],
      const SizedBox(height: LuxSpacing.md),
      Container(
        padding: const EdgeInsets.all(LuxSpacing.sm),
        decoration: BoxDecoration(
          color: LuxColors.surfaceMuted,
          borderRadius: BorderRadius.circular(LuxRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tarifa estimada', style: LuxTypography.caption),
            Text(
              'Bs${booking.estimatedPrice.toStringAsFixed(2)}',
              style: LuxTypography.bodyLarge.copyWith(
                color: LuxColors.sapphire,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
