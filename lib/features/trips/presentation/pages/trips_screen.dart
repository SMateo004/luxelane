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
          // La lista está en vivo: no hace falta un botón de recargar.
          title: const Text('Mis viajes'),
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading || state is BookingInitial) {
              return const LuxSkeletonList();
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
                  padding: const EdgeInsets.fromLTRB(
                    LuxSpacing.md,
                    LuxSpacing.md,
                    LuxSpacing.md,
                    LuxSpacing.xxl,
                  ),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      const SectionHeader(title: 'Próximos'),
                      const SizedBox(height: LuxSpacing.sm + 2),
                      for (final (i, b) in upcoming.indexed) ...[
                        LuxFadeIn(index: i, child: _TripCard(booking: b)),
                        const SizedBox(height: LuxSpacing.sm),
                      ],
                      const SizedBox(height: LuxSpacing.lg),
                    ],
                    if (past.isNotEmpty) ...[
                      const SectionHeader(title: 'Anteriores'),
                      const SizedBox(height: LuxSpacing.sm + 2),
                      for (final (i, b) in past.indexed) ...[
                        LuxFadeIn(
                          index: upcoming.length + i,
                          child: _TripCard(booking: b),
                        ),
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

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking});
  final Booking booking;

  bool get _hourly => booking.serviceType == ServiceType.byTheHour;

  /// Lo que la persona recuerda de un viaje: a dónde fue.
  String get _title => _hourly
      ? '${booking.hours ?? 2} h a disposición'
      : booking.destination.displayName;

  String get _from => '${LuxFormat.dateTime(booking.scheduledAt)} · '
      'desde ${booking.origin.displayName}';

  String get _price =>
      'Bs ${(booking.finalPrice ?? booking.estimatedPrice).toStringAsFixed(0)}';

  /// Qué hace el toque: seguir el viaje, valorarlo o ver la reserva.
  String? get _cta {
    switch (booking.status) {
      case BookingStatus.confirmed:
      case BookingStatus.driverArriving:
      case BookingStatus.driverArrived:
      case BookingStatus.verified:
      case BookingStatus.inProgress:
        return 'Seguir en el mapa';
      case BookingStatus.completed:
        return booking.riderRating == null ? 'Calificar viaje' : null;
      case BookingStatus.pending:
        return 'Ver reserva';
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return 'Ver reserva';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status == BookingStatus.cancelled;
    return LuxCard(
      // Cualquier viaje se abre: seguirlo, cancelarlo o valorarlo.
      onTap: () => context.go('/ride/${booking.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.titleLarge.copyWith(
                        color:
                            cancelled ? LuxColors.inkTertiary : LuxColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _from,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LuxSpacing.md),
              Text(
                _price,
                style: LuxTypography.titleLarge.copyWith(
                  color: cancelled ? LuxColors.inkTertiary : LuxColors.ink,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuxSpacing.sm + 4),
          Row(
            children: [
              BookingStatusChip(status: booking.status),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(
                  booking.vehicleClass.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxTypography.caption.copyWith(fontSize: 12),
                ),
              ),
              if (_cta != null) ...[
                Text(
                  _cta!,
                  style: LuxTypography.caption.copyWith(
                    color: LuxColors.sapphire,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: LuxColors.sapphire,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
