import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_states.dart';
import '../../../../l10n/l10n.dart';
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
          // La lista está en vivo: no hace falta un botón de recargar.
          title: Text(context.l10n.tripsTitle),
        ),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading || state is BookingInitial) {
              return const LuxSkeletonList();
            }
            if (state is BookingError) {
              return LuxErrorState(
                message: context.l10n.tripsLoadError,
                onRetry: _loadTrips,
              );
            }
            if (state is BookingTripsLoaded) {
              final trips = state.bookings;
              if (trips.isEmpty) return _empty(context);

              // Upcoming first (soonest on top), then history (latest on top):
              // the question a traveller opens this screen with is "what's next?".
              final upcoming = trips
                  .where((b) => _upcomingStatuses.contains(b.status))
                  .toList()
                ..sort((a, b) => a.effectivePickup.compareTo(b.effectivePickup));
              final past = trips
                  .where((b) => !_upcomingStatuses.contains(b.status))
                  .toList()
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
                      SectionHeader(title: context.l10n.tripsUpcoming),
                      const SizedBox(height: LuxSpacing.sm + 2),
                      for (final (i, b) in upcoming.indexed) ...[
                        LuxFadeIn(index: i, child: _TripCard(booking: b)),
                        const SizedBox(height: LuxSpacing.sm),
                      ],
                      const SizedBox(height: LuxSpacing.lg),
                    ],
                    if (past.isNotEmpty) ...[
                      SectionHeader(title: context.l10n.tripsPast),
                      const SizedBox(height: LuxSpacing.sm + 2),
                      for (final (i, b) in past.indexed) ...[
                        LuxFadeIn(
                            index: upcoming.length + i,
                            child: _TripCard(booking: b)),
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
        message: context.l10n.tripsEmpty,
        actionLabel: context.l10n.tripsBookNow,
        onAction: () => context.go('/'),
        icon: Icons.directions_car_outlined,
      );
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking});
  final Booking booking;

  bool get _hourly => booking.serviceType == ServiceType.byTheHour;

  /// Lo que la persona recuerda de un viaje: a dónde fue.
  String _title(AppLocalizations l) {
    final o = booking.origin.displayName;
    if (_hourly) {
      return booking.days > 1
          ? l.tripsRouteByDays(o, booking.days, booking.hours ?? 2)
          : l.tripsRouteByHour(o, booking.hours ?? 2);
    }
    return '$o → ${booking.destination.displayName}';
  }

  String get _date => '${DateFormat.yMMMd().format(booking.effectivePickup)} · '
      '${DateFormat.jm().format(booking.effectivePickup)}';

  String get _price => LuxMoney.format(booking.finalPrice ?? booking.estimatedPrice);

  bool get _toRate =>
      booking.status == BookingStatus.completed && booking.riderRating == null;

  /// Qué hace el toque: seguir el viaje, valorarlo o ver la reserva.
  String? get _cta {
    switch (booking.status) {
      case BookingStatus.confirmed:
      case BookingStatus.driverArriving:
      case BookingStatus.driverArrived:
      case BookingStatus.inProgress:
        return 'Seguir en el mapa';
      case BookingStatus.completed:
        return _toRate ? 'Calificar viaje' : null;
      case BookingStatus.pending:
        return 'Ver reserva';
      default:
        return null;
    }
  }

  /// Finished trips open their receipt (an unrated one opens the trip to
  /// rate it first); anything else is followed on the trip screen.
  void _open(BuildContext context) {
    final finished = booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled;
    if (finished && !_toRate) {
      context.push('/viajes/${booking.id}/recibo', extra: booking);
    } else {
      context.push('/ride/${booking.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status == BookingStatus.cancelled;
    return LuxCard(
      onTap: () => _open(context),
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
                      _title(context.l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.titleLarge.copyWith(
                        color:
                            cancelled ? LuxColors.inkTertiary : LuxColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(_date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxTypography.caption.copyWith(fontSize: 12)),
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
                  booking.vehicleClass.localizedLabel(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxTypography.caption.copyWith(fontSize: 12),
                ),
              ),
              if (_cta != null) ...[
                Text(_cta!,
                    style: LuxTypography.caption.copyWith(
                        color: LuxColors.sapphire,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: LuxColors.sapphire),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
