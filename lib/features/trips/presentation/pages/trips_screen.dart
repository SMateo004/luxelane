import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';

/// Lista de viajes con su propio BookingBloc: el compartido también recibe
/// los estados de crear o seguir una reserva, que vaciaban esta lista.
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<BookingBloc>(
        create: (_) => sl<BookingBloc>(),
        child: const _TripsView(),
      );
}

class _TripsView extends StatefulWidget {
  const _TripsView();

  @override
  State<_TripsView> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<_TripsView> {
  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
            BookingRiderTripsWatched(riderId: authState.user.id),
          );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mis viajes'),
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
                        label: 'Reintentar', onPressed: _loadTrips),
                  ],
                ),
              );
            }
            if (state is BookingTripsLoaded) {
              final trips = state.bookings;
              if (trips.isEmpty) return _empty(context);

              // Upcoming first (soonest on top), then history (latest on top):
              // the question a traveller opens this screen with is "what's next?".
              const done = {BookingStatus.completed, BookingStatus.cancelled};
              final upcoming = trips
                  .where((b) => !done.contains(b.status))
                  .toList()
                ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
              final past = trips.where((b) => done.contains(b.status)).toList()
                ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

              return RefreshIndicator(
                color: LuxColors.sapphire,
                backgroundColor: LuxColors.surface,
                onRefresh: () async => _loadTrips(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(LuxSpacing.md,
                      LuxSpacing.md, LuxSpacing.md, LuxSpacing.xxl),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      const _SectionLabel('Próximos'),
                      for (final b in upcoming) ...[
                        _TripCard(booking: b),
                        const SizedBox(height: LuxSpacing.sm),
                      ],
                      const SizedBox(height: LuxSpacing.lg),
                    ],
                    if (past.isNotEmpty) ...[
                      const _SectionLabel('Anteriores'),
                      for (final b in past) ...[
                        _TripCard(booking: b),
                        const SizedBox(height: LuxSpacing.sm),
                      ],
                    ],
                  ],
                ),
              );
            }
            return _empty(context);
          },
        ),
      );

  Widget _empty(BuildContext context) => EmptyState(
        message: 'Tu primer trayecto\nte está esperando.',
        actionLabel: 'Reservar ahora',
        onAction: () => context.go('/'),
        icon: Icons.directions_car_outlined,
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: LuxSpacing.sm + 4, left: 2),
        child: Text(text.toUpperCase(),
            style: LuxTypography.caption.copyWith(
                color: LuxColors.inkSecondary,
                letterSpacing: 2.2,
                fontSize: 10)),
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
      'Bs ${(booking.finalPrice ?? booking.estimatedPrice).toStringAsFixed(0)}';

  String get _date => LuxFormat.dateTime(booking.scheduledAt);

  /// Qué hace el toque: seguir el viaje, valorarlo o ver la reserva.
  String? get _cta {
    switch (booking.status) {
      case BookingStatus.confirmed:
      case BookingStatus.driverArriving:
      case BookingStatus.driverArrived:
      case BookingStatus.inProgress:
        return 'SEGUIR EN EL MAPA →';
      case BookingStatus.completed:
        return booking.riderRating == null ? 'CALIFICAR VIAJE →' : null;
      case BookingStatus.pending:
        return 'VER RESERVA →';
      case BookingStatus.cancelled:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) => LuxCard(
        // Cualquier viaje se abre: seguirlo, cancelarlo o valorarlo.
        onTap: () => context.go('/ride/${booking.id}'),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LuxColors.surfaceMuted,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: Icon(
                  booking.serviceType == ServiceType.byTheHour
                      ? Icons.schedule_rounded
                      : Icons.directions_car_outlined,
                  color: LuxColors.sapphire,
                  size: 22),
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
                  if (_cta != null) ...[
                    const SizedBox(height: 6),
                    Text(_cta!,
                        style: LuxTypography.caption.copyWith(
                            color: LuxColors.sapphire,
                            letterSpacing: 1.4,
                            fontSize: 9.5)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_price, style: LuxTypography.titleLarge),
                const SizedBox(height: 4),
                BookingStatusChip(status: booking.status),
              ],
            ),
          ],
        ),
      );
}
