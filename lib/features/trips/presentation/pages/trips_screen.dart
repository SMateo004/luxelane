import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_states.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  // Cached so unrelated BookingBloc states (e.g. a booking being watched
  // elsewhere) don't blank the list.
  List<Booking>? _trips;

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

  static const _upcomingStatuses = {
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.driverArriving,
    BookingStatus.driverArrived,
    BookingStatus.inProgress,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mis viajes'),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadTrips,
            ),
          ],
        ),
        body: BlocConsumer<BookingBloc, BookingState>(
          listener: (_, state) {
            if (state is BookingTripsLoaded) setState(() => _trips = state.bookings);
          },
          builder: (context, state) {
            final trips = _trips;
            if (trips == null) {
              if (state is BookingError) {
                return LuxErrorState(
                  message: 'No pudimos cargar tus viajes. Revisa tu conexión.',
                  onRetry: _loadTrips,
                );
              }
              return const LuxSkeletonList();
            }
            if (trips.isEmpty) {
              return EmptyState(
                message: 'Aún no tienes viajes.\nReserva tu primera experiencia.',
                actionLabel: 'Reservar ahora',
                onAction: () => context.go('/'),
                icon: Icons.directions_car_outlined,
              );
            }

            final upcoming = trips.where((b) => _upcomingStatuses.contains(b.status)).toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            final past = trips.where((b) => !_upcomingStatuses.contains(b.status)).toList()
              ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

            return RefreshIndicator(
              color: LuxColors.accent,
              onRefresh: () async => _loadTrips(),
              child: ListView(
                padding: const EdgeInsets.all(LuxSpacing.md),
                children: [
                  if (upcoming.isNotEmpty) ...[
                    const _SectionLabel('PRÓXIMOS'),
                    for (final b in upcoming) _TripCard(booking: b),
                    const SizedBox(height: LuxSpacing.lg),
                  ],
                  if (past.isNotEmpty) ...[
                    const _SectionLabel('ANTERIORES'),
                    for (final b in past) _TripCard(booking: b),
                  ],
                ],
              ),
            );
          },
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: LuxSpacing.sm, top: LuxSpacing.xs),
        child: Semantics(
          header: true,
          child: Text(text,
              style: LuxTypography.caption.copyWith(
                  letterSpacing: 2, color: LuxColors.whiteSecondary)),
        ),
      );
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking});
  final Booking booking;

  String get _route {
    final o = booking.origin.displayName;
    if (booking.serviceType == ServiceType.byTheHour) {
      return '$o · ${booking.hours ?? 2} h';
    }
    return '$o → ${booking.destination.displayName}';
  }

  String get _price => LuxMoney.format(booking.finalPrice ?? booking.estimatedPrice);

  String get _date => DateFormat('d MMM yyyy · HH:mm', 'es').format(booking.scheduledAt);

  void _open(BuildContext context) {
    switch (booking.status) {
      case BookingStatus.completed:
      case BookingStatus.cancelled:
        context.push('/viajes/${booking.id}/recibo', extra: booking);
      default:
        context.push('/ride/${booking.id}');
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(LuxRadius.md),
            onTap: () => _open(context),
            child: LuxCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LuxColors.blackElevated,
                      borderRadius: BorderRadius.circular(LuxRadius.sm),
                    ),
                    child: Icon(
                      booking.serviceType == ServiceType.byTheHour
                          ? Icons.schedule
                          : Icons.directions_car_outlined,
                      color: LuxColors.accent,
                      size: 24,
                    ),
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
                        Text(booking.vehicleClass.label, style: LuxTypography.bodyMedium),
                        const SizedBox(height: 2),
                        Text(_date, style: LuxTypography.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: LuxSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_price,
                          style: LuxTypography.titleLarge.copyWith(color: LuxColors.accent)),
                      const SizedBox(height: 4),
                      BookingStatusChip(status: booking.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
