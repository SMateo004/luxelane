import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/eta.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';

/// Rider's live trip view: chauffeur, ETA, flight status and rating.
class RideScreen extends StatefulWidget {
  const RideScreen({super.key, required this.rideId});
  // rideId is the booking ID navigated from BookingScreen
  final String rideId;

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  Booking? _booking;
  BookingStatus? _notifiedStatus;
  bool _ratingPrompted = false;

  static const _trackedStatuses = {
    BookingStatus.confirmed,
    BookingStatus.driverArriving,
    BookingStatus.driverArrived,
    BookingStatus.inProgress,
  };

  @override
  void initState() {
    super.initState();
    if (widget.rideId.isNotEmpty) {
      context
          .read<BookingBloc>()
          .add(BookingStatusWatched(bookingId: widget.rideId));
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      sl<NotificationService>().init(userId: authState.user.id);
    }
  }

  BookingStatus get _status => _booking?.status ?? BookingStatus.pending;

  void _onBooking(Booking booking) {
    final previous = _booking?.status;
    setState(() => _booking = booking);
    // Snapshots also arrive for chauffeur/flight updates — only notify on
    // real status changes.
    if (previous != null && previous != booking.status && _notifiedStatus != booking.status) {
      _notifiedStatus = booking.status;
      _createStatusNotification(booking.status, riderId: booking.riderId);
    }
    if (booking.status == BookingStatus.completed &&
        booking.riderRating == null &&
        !_ratingPrompted) {
      _ratingPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRatingDialog();
      });
    }
  }

  void _showRatingDialog() {
    final booking = _booking;
    if (booking == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => _RatingDialog(
        driverName: booking.chauffeur?.name ?? 'Tu chófer',
        onSubmit: (rating, comment) async {
          final result = await sl<BookingRepository>().rateBooking(
            bookingId: booking.id,
            rating: rating,
            comment: comment,
          );
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          if (!mounted) return;
          result.fold(
            (f) => showLuxSnackbar(context, f.message, isError: true),
            (_) => showLuxSnackbar(context, '¡Gracias por tu calificación!'),
          );
        },
      ),
    );
  }

  void _createStatusNotification(BookingStatus status, {required String riderId}) {
    final (String title, String body, String type) = switch (status) {
      BookingStatus.confirmed => ('Chófer asignado', 'Tu chófer confirmó la reserva.', 'booking_confirmed'),
      BookingStatus.driverArriving => ('El chófer está en camino', 'Tu chófer se dirige a tu punto de recogida.', 'driver_arriving'),
      BookingStatus.driverArrived => ('El chófer ha llegado', 'Tu chófer te espera en el punto de recogida.', 'driver_arrived'),
      BookingStatus.inProgress => ('Viaje iniciado', 'Ya estás en camino hacia tu destino.', 'ride_started'),
      BookingStatus.completed => ('Viaje completado', '¡Has llegado! Gracias por viajar con Luxelane.', 'ride_completed'),
      _ => ('', '', ''),
    };
    if (type.isEmpty) return;
    context.read<NotificationBloc>().add(
          NotificationCreated(
            notification: AppNotification(
              id: '',
              userId: riderId,
              title: title,
              body: body,
              type: type,
              isRead: false,
              createdAt: DateTime.now(),
              bookingId: widget.rideId,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final tracked = _booking?.driverId != null && _trackedStatuses.contains(_status);
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingStatusUpdated && state.booking.id == widget.rideId) {
          _onBooking(state.booking);
        }
      },
      child: tracked
          ? StreamBuilder<LiveLocation?>(
              stream: sl<BookingRepository>().watchLiveLocation(widget.rideId),
              builder: (context, snap) => _buildScaffold(snap.data),
            )
          : _buildScaffold(null),
    );
  }

  Widget _buildScaffold(LiveLocation? live) {
    final driverLatLng = live != null ? LatLng(live.lat, live.lng) : null;
    final panel = _TripPanel(
      booking: _booking,
      status: _status,
      live: live,
      onRate: _showRatingDialog,
    );
    return Scaffold(
      body: isWeb(context)
          ? Row(
              children: [
                Expanded(child: _MapArea(booking: _booking, driverLocation: driverLatLng)),
                SizedBox(
                  width: 420,
                  child: Container(
                    color: LuxColors.blackSurface,
                    child: Column(
                      children: [
                        _WebRideHeader(status: _status),
                        const LuxDivider(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(LuxSpacing.lg),
                            child: panel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                _MapArea(booking: _booking, driverLocation: driverLatLng),
                SafeArea(
                  child: Column(
                    children: [
                      const _TopBar(),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: LuxColors.blackSurface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
                          border: Border(top: BorderSide(color: LuxColors.blackBorder)),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                            LuxSpacing.md, LuxSpacing.md, LuxSpacing.md, LuxSpacing.xl),
                        child: panel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trip panel
// ---------------------------------------------------------------------------

class _TripPanel extends StatelessWidget {
  const _TripPanel({
    required this.booking,
    required this.status,
    required this.live,
    required this.onRate,
  });

  final Booking? booking;
  final BookingStatus status;
  final LiveLocation? live;
  final VoidCallback onRate;

  /// Headline + supporting line, ETA-aware.
  (String, String?) _headline() {
    final b = booking;
    if (b == null) return ('Cargando tu reserva…', null);
    final pickup = DateFormat('EEE d MMM · HH:mm', 'es').format(b.effectivePickup);
    final eta = _eta();
    return switch (status) {
      BookingStatus.pending => ('Asignando a tu chófer', 'Recogida $pickup'),
      BookingStatus.confirmed =>
        eta != null ? ('Tu chófer llega en ${Eta.format(eta)}', 'Recogida $pickup') : ('Chófer confirmado', 'Recogida $pickup'),
      BookingStatus.driverArriving =>
        eta != null ? ('Llega en ${Eta.format(eta)}', 'Tu chófer está en camino') : ('Tu chófer está en camino', null),
      BookingStatus.driverArrived => ('Tu chófer te espera', b.chauffeur != null ? '${b.chauffeur!.vehicleLine} · ${b.chauffeur!.plate}' : null),
      BookingStatus.inProgress =>
        eta != null ? ('Llegas en ${Eta.format(eta)}', b.destination.displayName) : ('En camino a tu destino', b.destination.displayName),
      BookingStatus.completed => ('¡Has llegado!', 'Gracias por viajar con Luxelane'),
      BookingStatus.cancelled => ('Reserva cancelada', null),
    };
  }

  Duration? _eta() {
    final b = booking;
    final l = live;
    if (b == null || l == null || l.isStale) return null;
    final target = status == BookingStatus.inProgress ? b.destination : b.origin;
    return Eta.estimate(fromLat: l.lat, fromLng: l.lng, toLat: target.lat, toLng: target.lng);
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _headline();
    final b = booking;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BookingStatusChip(status: status),
            const Spacer(),
            if (live != null && !live!.isStale && status != BookingStatus.completed)
              const _LiveDot(),
          ],
        ),
        const SizedBox(height: LuxSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Text(title, style: LuxTypography.headlineLarge),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: LuxTypography.bodyMedium),
        ],
        if (b?.flight != null) ...[
          const SizedBox(height: LuxSpacing.md),
          _FlightCard(flight: b!.flight!, pickup: b.effectivePickup),
        ],
        const SizedBox(height: LuxSpacing.md),
        if (b?.chauffeur != null)
          _ChauffeurCard(chauffeur: b!.chauffeur!, showContact: _contactable(status))
        else if (status == BookingStatus.pending)
          const _AssigningCard(),
        if (status == BookingStatus.completed && b != null) ...[
          const SizedBox(height: LuxSpacing.md),
          if (b.riderRating == null)
            LuxButton(label: 'Calificar viaje', onPressed: onRate)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < b.riderRating! ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: LuxColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Gracias por calificar', style: LuxTypography.bodyMedium),
              ],
            ),
          const SizedBox(height: LuxSpacing.sm),
          LuxOutlinedButton(
            label: 'Ver recibo',
            icon: Icons.receipt_long_outlined,
            onPressed: () => context.push('/viajes/${b.id}/recibo', extra: b),
          ),
        ],
      ],
    );
  }

  static bool _contactable(BookingStatus s) =>
      s == BookingStatus.confirmed ||
      s == BookingStatus.driverArriving ||
      s == BookingStatus.driverArrived ||
      s == BookingStatus.inProgress;
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: LuxColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('EN VIVO', style: LuxTypography.caption.copyWith(letterSpacing: 1.6, color: LuxColors.success)),
        ],
      );
}

class _AssigningCard extends StatelessWidget {
  const _AssigningCard();

  @override
  Widget build(BuildContext context) => const LuxCard(
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: LuxColors.accent),
            ),
            SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Text(
                'Estamos confirmando a tu chófer. Te avisaremos apenas esté asignado.',
                style: LuxTypography.bodyMedium,
              ),
            ),
          ],
        ),
      );
}

class _ChauffeurCard extends StatelessWidget {
  const _ChauffeurCard({required this.chauffeur, required this.showContact});
  final Chauffeur chauffeur;
  final bool showContact;

  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      showLuxSnackbar(context, 'No se pudo abrir la aplicación', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = chauffeur.phone;
    final canContact = showContact && phone != null && phone.isNotEmpty;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: LuxColors.blackElevated,
                backgroundImage: chauffeur.photoUrl != null ? NetworkImage(chauffeur.photoUrl!) : null,
                child: chauffeur.photoUrl == null
                    ? Text(chauffeur.name.characters.first.toUpperCase(),
                        style: LuxTypography.headlineMedium.copyWith(color: LuxColors.accent))
                    : null,
              ),
              const SizedBox(width: LuxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chauffeur.name, style: LuxTypography.titleLarge),
                    const SizedBox(height: 2),
                    Text(chauffeur.vehicleLine, style: LuxTypography.bodyMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 13, color: LuxColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          chauffeur.totalRides > 0
                              ? 'Verificado · ${chauffeur.totalRides} viajes'
                              : 'Chófer verificado',
                          style: LuxTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (chauffeur.plate.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: LuxColors.accent),
                        borderRadius: BorderRadius.circular(LuxRadius.sm),
                      ),
                      child: Text(chauffeur.plate,
                          style: LuxTypography.titleMedium.copyWith(letterSpacing: 1.5)),
                    ),
                  if (chauffeur.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: LuxColors.accent, size: 16),
                        const SizedBox(width: 2),
                        Text(chauffeur.rating!.toStringAsFixed(1), style: LuxTypography.titleMedium),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (canContact) ...[
            const SizedBox(height: LuxSpacing.md),
            Row(
              children: [
                Expanded(
                  child: LuxOutlinedButton(
                    label: 'Llamar',
                    icon: Icons.call_outlined,
                    onPressed: () => _launch(context, Uri(scheme: 'tel', path: _digits(phone))),
                  ),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: LuxOutlinedButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_outlined,
                    onPressed: () => _launch(
                      context,
                      Uri.parse('https://wa.me/${_digits(phone).replaceAll('+', '')}'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.flight, required this.pickup});
  final FlightInfo flight;
  final DateTime pickup;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm', 'es');
    final color = flight.cancelled
        ? LuxColors.error
        : flight.delayed
            ? LuxColors.warning
            : LuxColors.success;
    final arrival = flight.estimatedArrival ?? flight.scheduledArrival;
    return Container(
      padding: const EdgeInsets.all(LuxSpacing.md),
      decoration: BoxDecoration(
        color: LuxColors.blackElevated,
        borderRadius: BorderRadius.circular(LuxRadius.md),
        border: Border.all(color: LuxColors.blackBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.flight_land_rounded, color: LuxColors.accent),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vuelo ${flight.number}${flight.terminal != null ? ' · Terminal ${flight.terminal}' : ''}',
                  style: LuxTypography.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (arrival != null) '${flight.arrived ? 'Aterrizó' : 'Llega'} ${time.format(arrival)}',
                    'Recogida ${time.format(pickup)}',
                  ].join(' · '),
                  style: LuxTypography.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(LuxRadius.sm),
            ),
            child: Text(flight.label, style: LuxTypography.caption.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map, top bar, header
// ---------------------------------------------------------------------------

class _MapArea extends StatelessWidget {
  const _MapArea({this.booking, this.driverLocation});
  final Booking? booking;
  final LatLng? driverLocation;

  @override
  Widget build(BuildContext context) => LuxMap(
        origin: booking?.origin,
        destination: booking?.destination,
        driverLocation: driverLocation,
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(LuxSpacing.md),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Volver al inicio',
              child: Material(
                color: LuxColors.blackSurface,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                  onTap: () => context.go('/'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(LuxRadius.sm),
                      border: Border.all(color: LuxColors.blackBorder),
                    ),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: LuxColors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            const LuxelaneWordmark(),
          ],
        ),
      );
}

class _WebRideHeader extends StatelessWidget {
  const _WebRideHeader({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        child: Row(
          children: [
            const LuxelaneWordmark(),
            const Spacer(),
            BookingStatusChip(status: status),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Rating Dialog
// ---------------------------------------------------------------------------

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({required this.driverName, required this.onSubmit});
  final String driverName;
  final Future<void> Function(int rating, String? comment) onSubmit;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  bool _sending = false;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: LuxColors.blackSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          side: const BorderSide(color: LuxColors.blackBorder),
        ),
        title: const Text('Califica tu viaje',
            style: LuxTypography.titleMedium, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.driverName,
                style: LuxTypography.bodyMedium.copyWith(color: LuxColors.whiteSecondary)),
            const SizedBox(height: LuxSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  tooltip: '$star ${star == 1 ? 'estrella' : 'estrellas'}',
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: LuxColors.accent,
                    size: 34,
                  ),
                );
              }),
            ),
            Text(
              _ratingLabel(_rating),
              style: LuxTypography.caption.copyWith(color: LuxColors.accent),
            ),
            const SizedBox(height: LuxSpacing.md),
            TextField(
              controller: _comment,
              maxLines: 2,
              maxLength: 500,
              style: LuxTypography.bodyLarge,
              decoration: const InputDecoration(hintText: 'Comentario (opcional)'),
            ),
          ],
        ),
        actions: [
          LuxButton(
            label: 'Enviar',
            loading: _sending,
            onPressed: _sending
                ? null
                : () async {
                    setState(() => _sending = true);
                    await widget.onSubmit(_rating, _comment.text);
                    if (mounted) setState(() => _sending = false);
                  },
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(LuxSpacing.md, 0, LuxSpacing.md, LuxSpacing.md),
      );

  String _ratingLabel(int r) => switch (r) {
        5 => 'Excelente',
        4 => 'Bueno',
        3 => 'Regular',
        2 => 'Malo',
        _ => 'Muy malo',
      };
}
