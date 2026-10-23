import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/driver_bloc.dart';
import '../widgets/driver_step_action.dart';
import '../widgets/flight_info_card.dart';

class DriverQueueScreen extends StatelessWidget {
  const DriverQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes')),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state is! DriverLoaded) return const LuxSkeletonList();

          // Solo las de su clase de vehículo.
          final pending =
              state.matchingRequests
                ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          final upcoming =
              state.bookings.where((b) {
                  return b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.driverArriving ||
                      b.status == BookingStatus.driverArrived ||
                      b.status == BookingStatus.verified;
                }).toList()
                ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          if (pending.isEmpty && upcoming.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_outlined,
              message:
                  state.isAvailable
                      ? 'Las nuevas solicitudes\naparecerán aquí.'
                      : 'Conéctate para\nrecibir solicitudes.',
            );
          }
          var i = 0;

          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              if (pending.isNotEmpty) ...[
                const SectionHeader(title: 'Disponibles para ti'),
                const SizedBox(height: LuxSpacing.sm + 2),
                for (final b in pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                    child: LuxFadeIn(
                      index: i++,
                      child: _RequestCard(request: b),
                    ),
                  ),
                const SizedBox(height: LuxSpacing.md),
              ],
              if (upcoming.isNotEmpty) ...[
                const SectionHeader(title: 'Tus viajes asignados'),
                const SizedBox(height: LuxSpacing.sm + 2),
                for (final b in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                    child: LuxFadeIn(index: i++, child: _JobCard(booking: b)),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Solicitud abierta: zona, hora, clase y tarifa. Los datos del pasajero y
/// la dirección exacta se ven al aceptar.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final OpenRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final hourly = r.serviceType == ServiceType.byTheHour;
    return LuxCard(
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
                      hourly
                          ? '${r.hours ?? 2} h a disposición'
                          : r.dropoffLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${LuxFormat.dateTime(r.scheduledAt)} · '
                      'desde ${r.pickupLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LuxSpacing.md),
              Text(
                'Bs ${r.estimatedPrice.toStringAsFixed(0)}',
                style: LuxTypography.headlineLarge.copyWith(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: LuxSpacing.sm + 2),
          Row(
            children: [
              const BookingStatusChip(status: BookingStatus.pending),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(
                  [
                    r.vehicleClass.label,
                    if (r.tripKm != null) '~${r.tripKm!.toStringAsFixed(0)} km',
                    '${r.passengerCount} pax',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxTypography.caption.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: LuxSpacing.md),
          _JobActions(bookingId: r.id, isPending: true),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final hourly = booking.serviceType == ServiceType.byTheHour;
    return LuxCard(
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
                      hourly
                          ? '${booking.hours ?? 2} h a disposición'
                          : booking.destination.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${LuxFormat.dateTime(booking.scheduledAt)} · '
                      'desde ${booking.origin.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LuxSpacing.md),
              Text(
                'Bs ${booking.estimatedPrice.toStringAsFixed(0)}',
                style: LuxTypography.headlineLarge.copyWith(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: LuxSpacing.sm + 2),
          Row(
            children: [
              BookingStatusChip(status: booking.status),
              const SizedBox(width: LuxSpacing.sm),
              Text(
                booking.vehicleClass.label,
                style: LuxTypography.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
          if (!booking.riderPreferences.isEmpty) ...[
            const SizedBox(height: LuxSpacing.md),
            RiderPreferencesNote(preferences: booking.riderPreferences),
          ],
          if (booking.flightNumber?.isNotEmpty == true) ...[
            const SizedBox(height: LuxSpacing.md),
            FlightInfoCard(booking: booking),
          ],
          const SizedBox(height: LuxSpacing.md),
          _JobActions(bookingId: booking.id, booking: booking),
        ],
      ),
    );
  }
}

class _JobActions extends StatelessWidget {
  const _JobActions({
    required this.bookingId,
    this.booking,
    this.isPending = false,
  });
  final String bookingId;

  /// Reserva aceptada: su siguiente paso. Las pendientes no la tienen.
  final Booking? booking;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DriverBloc>();
    final auth = context.read<AuthBloc>().state;
    final driverId = auth is AuthAuthenticated ? auth.user.id : '';

    if (isPending) {
      final s = bloc.state;
      final loaded = s is DriverLoaded ? s : null;
      final blocker =
          loaded == null
              ? 'Cargando…'
              : !loaded.profile.documentsVerified
              ? 'Pendiente de verificación'
              : loaded.activeBooking != null
              ? 'Termina tu viaje actual'
              : !loaded.isAvailable
              ? 'Conéctate para aceptar'
              : null;
      return LuxButton(
        label: blocker ?? 'Aceptar viaje',
        icon: Icons.check_circle_outline_rounded,
        onPressed:
            blocker != null
                ? null
                : () => bloc.add(
                  DriverRequestAccepted(
                    bookingId: bookingId,
                    driverId: driverId,
                  ),
                ),
      );
    }

    final b = booking;
    return b == null ? const SizedBox.shrink() : DriverStepAction(booking: b);
  }
}
