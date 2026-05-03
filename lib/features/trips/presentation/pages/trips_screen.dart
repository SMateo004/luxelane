import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
            BookingRiderTripsRequested(riderId: authState.user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadTrips,
            ),
          ],
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BookingError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: LuxTypography.bodyMedium),
                    const SizedBox(height: LuxSpacing.md),
                    LuxOutlinedButton(
                        label: 'Retry', onPressed: _loadTrips),
                  ],
                ),
              );
            }
            if (state is BookingTripsLoaded) {
              final trips = state.bookings;
              if (trips.isEmpty) {
                return EmptyState(
                  message: 'No rides yet.\nBook your first experience.',
                  actionLabel: 'Book Now',
                  onAction: () => context.go('/booking'),
                  icon: Icons.directions_car_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(LuxSpacing.md),
                itemCount: trips.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: LuxSpacing.sm),
                itemBuilder: (_, i) => _TripCard(booking: trips[i]),
              );
            }
            return EmptyState(
              message: 'No rides yet.\nBook your first experience.',
              actionLabel: 'Book Now',
              onAction: () => context.go('/booking'),
              icon: Icons.directions_car_outlined,
            );
          },
        ),
      );
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking});
  final Booking booking;

  String get _route {
    final o = booking.origin.address;
    final d = booking.destination.address;
    return '$o → $d';
  }

  String get _vehicle => booking.vehicleClass.label;

  String get _price =>
      '\$${booking.estimatedPrice.toStringAsFixed(0)}';

  String get _date {
    final dt = booking.scheduledAt;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LuxColors.blackElevated,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: const Icon(Icons.directions_car_outlined,
                  color: LuxColors.sapphire, size: 24),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_route,
                      style: LuxTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_vehicle, style: LuxTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(_date, style: LuxTypography.caption),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_price,
                    style: LuxTypography.titleLarge
                        .copyWith(color: LuxColors.sapphire)),
                const SizedBox(height: 4),
                BookingStatusChip(status: booking.status),
              ],
            ),
          ],
        ),
      );
}
