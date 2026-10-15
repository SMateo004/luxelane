import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  Stream<List<Booking>>? _stream;
  String? _riderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthBloc>().state;
    final id = auth is AuthAuthenticated ? auth.user.id : null;
    if (id != _riderId) {
      _riderId = id;
      _stream =
          id == null ? null : sl<BookingRepository>().watchRiderBookings(id);
    }
  }

  void _retry() {
    final id = _riderId;
    if (id == null) return;
    setState(() => _stream = sl<BookingRepository>().watchRiderBookings(id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mis viajes')),
        // En vivo: el estado de cada reserva se actualiza solo, sin
        // depender del bloc que comparte la pantalla de reserva.
        body: StreamBuilder<List<Booking>>(
          stream: _stream,
          builder: (context, snap) {
            if (_stream == null) return _empty(context);
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos cargar tus viajes.',
                        style: LuxTypography.bodyMedium),
                    const SizedBox(height: LuxSpacing.md),
                    LuxOutlinedButton(label: 'Reintentar', onPressed: _retry),
                  ],
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            {
              final trips = snap.data!;
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
                onRefresh: () async => _retry(),
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
    final o = booking.origin.displayName;
    if (booking.isHourly) return '$o · ${booking.hours ?? 1} h por horas';
    return '$o → ${booking.destination.displayName}';
  }

  String get _vehicle => booking.vehicleClass.label;

  String get _price => LuxFormat.bs(booking.chargedAmount);

  String get _date => LuxFormat.dateTime(booking.scheduledAt);

  /// Qué puede hacer el pasajero al tocar la tarjeta.
  String? get _cta => switch (booking.status) {
        BookingStatus.pending => 'VER O CANCELAR →',
        BookingStatus.completed =>
          booking.riderRating == null && booking.driverId != null
              ? 'CALIFICAR VIAJE →'
              : null,
        BookingStatus.cancelled => null,
        _ => 'SEGUIR EN EL MAPA →',
      };

  @override
  Widget build(BuildContext context) => LuxCard(
        // Cualquier reserva se abre: seguir, cancelar o valorar.
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
