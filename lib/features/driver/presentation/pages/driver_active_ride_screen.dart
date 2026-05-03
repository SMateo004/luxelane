import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../bloc/driver_bloc.dart';

class DriverActiveRideScreen extends StatelessWidget {
  const DriverActiveRideScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverBloc, DriverState>(
      builder: (context, state) {
        if (state is! DriverLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        Booking? booking;
        try {
          booking = state.bookings.firstWhere((b) => b.id == bookingId);
        } catch (_) {}

        if (booking == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Ride not found')),
          );
        }

        final web = isWeb(context);
        return Scaffold(
          body: web
              ? _webLayout(context, booking, state)
              : _mobileLayout(context, booking, state),
        );
      },
    );
  }

  Widget _mobileLayout(
    BuildContext context,
    Booking booking,
    DriverLoaded state,
  ) =>
      Stack(
        children: [
          LuxMap(
            origin: booking.origin,
            destination: booking.destination,
          ),
          SafeArea(
            child: Column(
              children: [
                _DriverTopBar(),
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
  ) =>
      Row(
        children: [
          Expanded(
            child: LuxMap(
              origin: booking.origin,
              destination: booking.destination,
            ),
          ),
          SizedBox(
            width: 400,
            child: Container(
              color: LuxColors.blackSurface,
              child: Column(
                children: [
                  _DriverWebHeader(booking: booking),
                  const LuxDivider(),
                  Expanded(
                    child: _DriverSidePanel(booking: booking),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _DriverTopBar extends StatelessWidget {
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
                  color: LuxColors.blackSurface,
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                  border: Border.all(color: LuxColors.blackBorder),
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: LuxColors.white),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            const LuxelaneWordmark(),
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
          color: LuxColors.blackSurface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
          border: Border(top: BorderSide(color: LuxColors.blackBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md, LuxSpacing.md, LuxSpacing.md, LuxSpacing.xxl),
        child: _DriverSidePanel(booking: booking),
      );
}

class _DriverSidePanel extends StatelessWidget {
  const _DriverSidePanel({required this.booking});
  final Booking booking;

  String get _message {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return 'Proceed to pickup location';
      case BookingStatus.driverArriving:
        return 'Heading to pickup · arriving soon';
      case BookingStatus.driverArrived:
        return 'Waiting for passenger';
      case BookingStatus.inProgress:
        return 'Ride in progress · head to destination';
      default:
        return '';
    }
  }

  String get _actionLabel {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return 'Head to Pickup';
      case BookingStatus.driverArriving:
        return 'I Have Arrived';
      case BookingStatus.driverArrived:
        return 'Start Ride';
      case BookingStatus.inProgress:
        return 'Complete Ride';
      default:
        return '';
    }
  }

  void _advance(BuildContext context) {
    final bloc = context.read<DriverBloc>();
    switch (booking.status) {
      case BookingStatus.confirmed:
        bloc.add(DriverBookingAccepted(bookingId: booking.id));
        break;
      case BookingStatus.driverArriving:
        bloc.add(DriverArrivedAtPickup(bookingId: booking.id));
        break;
      case BookingStatus.driverArrived:
        bloc.add(DriverTripStarted(bookingId: booking.id));
        break;
      case BookingStatus.inProgress:
        bloc.add(DriverTripCompleted(bookingId: booking.id));
        context.go('/driver');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BookingStatusChip(status: booking.status),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(_message, style: LuxTypography.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: LuxSpacing.md),
          const LuxDivider(),
          const SizedBox(height: LuxSpacing.md),
          _RideInfoRow(booking: booking),
          const SizedBox(height: LuxSpacing.md),
          if (_actionLabel.isNotEmpty)
            LuxButton(
              label: _actionLabel,
              onPressed: () => _advance(context),
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
              const Icon(Icons.radio_button_checked,
                  color: LuxColors.sapphire, size: 16),
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
              const Icon(Icons.location_on_rounded,
                  color: LuxColors.error, size: 16),
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
          const SizedBox(height: LuxSpacing.md),
          Container(
            padding: const EdgeInsets.all(LuxSpacing.sm),
            decoration: BoxDecoration(
              color: LuxColors.blackElevated,
              borderRadius: BorderRadius.circular(LuxRadius.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated fare', style: LuxTypography.caption),
                Text(
                  'Bs${booking.estimatedPrice.toStringAsFixed(2)}',
                  style: LuxTypography.bodyLarge
                      .copyWith(color: LuxColors.sapphire),
                ),
              ],
            ),
          ),
        ],
      );
}
