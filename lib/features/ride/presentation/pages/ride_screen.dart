import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import 'package:url_launcher/url_launcher.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key, required this.rideId});
  // rideId is the booking ID navigated from BookingScreen
  final String rideId;

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  // La pantalla sigue su propia reserva: con el BookingBloc compartido, una
  // reserva vista antes seguía emitiendo y pisaba esta y la lista de viajes.
  late final Stream<Booking> _bookingStream;
  StreamSubscription<Booking>? _sub;
  Booking? _booking;
  bool _loadError = false;
  bool _ratingPrompted = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _bookingStream = widget.rideId.isEmpty
        ? const Stream<Booking>.empty()
        : sl<BookingRepository>().watchBooking(widget.rideId);
    _sub = _bookingStream.listen(
      (b) {
        if (!mounted) return;
        setState(() {
          _booking = b;
          _loadError = false;
        });
        // Al completarse, se invita a valorar una sola vez por visita.
        if (b.status == BookingStatus.completed &&
            b.riderRating == null &&
            !_ratingPrompted) {
          _ratingPrompted = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showRatingDialog());
        }
      },
      onError: (_) {
        if (mounted) setState(() => _loadError = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  DriverInfo? get _driver => _booking?.driverInfo;

  Future<void> _callDriver() async {
    final phone = _driver?.phone ?? '';
    if (phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  BookingStatus? get _status => _booking?.status;

  String get _statusMessage {
    if (_loadError) {
      return 'No pudimos cargar tu reserva. Revisa tu conexión.';
    }
    switch (_status) {
      case null:
        return 'Cargando tu reserva…';
      case BookingStatus.pending:
        return 'Estamos asignando a tu chófer. Te avisaremos en cuanto esté confirmado.';
      case BookingStatus.confirmed:
        return 'Tu reserva está confirmada. Te avisaremos cuando tu chófer salga hacia ti.';
      case BookingStatus.driverArriving:
        return 'Tu chófer va de camino al punto de recogida.';
      case BookingStatus.driverArrived:
        return 'Tu chófer ha llegado y te espera. Tómate tu tiempo.';
      case BookingStatus.inProgress:
        return 'Disfruta del trayecto. Llegarás a tu destino en breve.';
      case BookingStatus.completed:
        return 'Has llegado. Gracias por viajar con Luxelane.';
      case BookingStatus.cancelled:
        return 'Esta reserva fue cancelada.';
    }
  }

  /// Estados en los que el pasajero aún puede cancelar (igual que las
  /// reglas de Firestore).
  static const _cancellable = {
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.driverArriving,
    BookingStatus.driverArrived,
  };

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuxColors.surface,
        title: const Text('Cancelar reserva', style: LuxTypography.titleMedium),
        content: const Text(
            'Tu chófer quedará libre y, si pagaste con tarjeta, se liberará '
            'la retención. ¿Quieres cancelar?',
            style: LuxTypography.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancelar reserva',
                  style: TextStyle(color: LuxColors.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    final result = await sl<BookingRepository>().cancelBooking(widget.rideId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    result.fold(
      (f) => showLuxSnackbar(context, f.message, isError: true),
      (_) => showLuxSnackbar(context, 'Reserva cancelada'),
    );
  }

  void _showRatingDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => _RatingDialog(
        driverName:
            _driver?.name.isNotEmpty == true ? _driver!.name : 'tu chófer',
        onSubmit: (rating) async {
          final result = await sl<BookingRepository>().rateBooking(
            bookingId: widget.rideId,
            rating: rating.round(),
          );
          if (!mounted || !ctx.mounted) return;
          Navigator.of(ctx).pop();
          result.fold(
            (f) => showLuxSnackbar(context, f.message, isError: true),
            (_) => showLuxSnackbar(context, '¡Gracias por tu valoración!'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverId = _booking?.driverId;
    return driverId != null
        ? StreamBuilder<DriverProfile?>(
            stream: sl<UserRepository>().watchDriverProfile(driverId),
            builder: (context, snap) =>
                _buildScaffold(snap.data?.currentLocation, snap.data),
          )
        : _buildScaffold(null, null);
  }

  Widget _buildScaffold(GeoPoint? driverGeo, DriverProfile? profile) {
    final driverLatLng = driverGeo != null
        ? LatLng(driverGeo.latitude, driverGeo.longitude)
        : null;
    final web = isWeb(context);
    return Scaffold(
      body: web
          ? _webLayout(driverLatLng, profile)
          : _mobileLayout(driverLatLng, profile),
    );
  }

  /// Acciones del pasajero: llamar al chófer, cancelar mientras se pueda y
  /// valorar un viaje completado que aún no valoró.
  Widget _actions() {
    final canCall = (_driver?.phone ?? '').isNotEmpty &&
        _status != BookingStatus.completed &&
        _status != BookingStatus.cancelled;
    final canCancel = _cancellable.contains(_status);
    final canRate =
        _status == BookingStatus.completed && _booking?.riderRating == null;
    if (!canCall && !canCancel && !canRate) return const SizedBox.shrink();
    return Row(
      children: [
        if (canCall)
          Expanded(
            child: LuxOutlinedButton(
              label: 'Llamar al chófer',
              onPressed: _callDriver,
              icon: Icons.call_outlined,
            ),
          ),
        if (canCall && (canCancel || canRate))
          const SizedBox(width: LuxSpacing.sm),
        if (canCancel)
          Expanded(
            child: LuxOutlinedButton(
              label: _cancelling ? 'Cancelando…' : 'Cancelar reserva',
              onPressed: _cancelling ? null : _cancel,
              icon: Icons.close_rounded,
            ),
          ),
        if (canRate)
          Expanded(
            child: LuxButton(
              label: 'Calificar viaje',
              onPressed: _showRatingDialog,
            ),
          ),
      ],
    );
  }

  Widget _driverSection(DriverProfile? profile) {
    final d = _driver;
    if (_status == BookingStatus.cancelled) return const SizedBox.shrink();
    if (d == null) return const _AssigningCard();
    final b = _booking!;
    return DriverCard(
      name: d.name.isNotEmpty ? d.name : 'Tu chófer',
      rating: profile?.rating ?? 5.0,
      vehicle: d.vehicle ??
          '${b.vehicleClass.label} · ${b.vehicleClass.description}',
      photoUrl: d.photoUrl,
    );
  }

  Widget _mobileLayout(LatLng? driverLatLng, DriverProfile? profile) => Stack(
        children: [
          _MapArea(
            booking: _booking,
            driverLocation: driverLatLng,
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(),
                const Spacer(),
                _BottomPanel(
                  status: _status ?? BookingStatus.pending,
                  message: _statusMessage,
                  driver: _driverSection(profile),
                  actions: _actions(),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _webLayout(LatLng? driverLatLng, DriverProfile? profile) => Row(
        children: [
          Expanded(
            child: _MapArea(
              booking: _booking,
              driverLocation: driverLatLng,
            ),
          ),
          SizedBox(
            width: 400,
            child: Container(
              color: LuxColors.surface,
              child: Column(
                children: [
                  _WebRideHeader(status: _status ?? BookingStatus.pending),
                  const LuxDivider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(LuxSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_statusMessage, style: LuxTypography.bodyMedium),
                          const SizedBox(height: LuxSpacing.lg),
                          _driverSection(profile),
                          const Spacer(),
                          _actions(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MapArea extends StatelessWidget {
  const _MapArea({this.booking, this.driverLocation});
  final Booking? booking;
  final LatLng? driverLocation;

  @override
  Widget build(BuildContext context) {
    final origin = booking?.origin;
    final destination = booking?.destination;
    return LuxMap(
      origin: origin,
      destination: destination,
      driverLocation: driverLocation,
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(LuxSpacing.md),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: LuxColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: LuxColors.border),
                  boxShadow: luxSoftShadow,
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: LuxColors.ink),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            const LuxelaneWordmark(),
          ],
        ),
      );
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.status,
    required this.message,
    required this.driver,
    required this.actions,
  });

  final BookingStatus status;
  final String message;
  final Widget driver;
  final Widget actions;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: LuxColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(LuxRadius.xl + 8)),
          boxShadow: [
            BoxShadow(
                color: LuxColors.shadow, blurRadius: 32, offset: Offset(0, -8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(
          LuxSpacing.md + 4,
          LuxSpacing.lg,
          LuxSpacing.md + 4,
          LuxSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookingStatusChip(status: status),
            const SizedBox(height: LuxSpacing.sm + 4),
            Text(message,
                style: LuxTypography.headlineLarge
                    .copyWith(fontSize: 24, height: 1.2)),
            const SizedBox(height: LuxSpacing.lg),
            driver,
            const SizedBox(height: LuxSpacing.md),
            actions,
          ],
        ),
      );
}

/// Shown until a chauffeur is assigned — honest, calm, no placeholder person.
class _AssigningCard extends StatelessWidget {
  const _AssigningCard();

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 1.2, color: LuxColors.sapphire),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Asignando a tu chófer',
                      style: LuxTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text('Verás su nombre, vehículo y valoración aquí.',
                      style: LuxTypography.caption
                          .copyWith(color: LuxColors.inkSecondary)),
                ],
              ),
            ),
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
  const _RatingDialog({
    required this.driverName,
    required this.onSubmit,
  });
  final String driverName;
  final Future<void> Function(double rating) onSubmit;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double _rating = 5;
  bool _sending = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: LuxColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          side: const BorderSide(color: LuxColors.border),
        ),
        title: const Text('Califica tu viaje',
            style: LuxTypography.titleMedium, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.driverName,
                style: LuxTypography.bodyMedium
                    .copyWith(color: LuxColors.inkTertiary)),
            const SizedBox(height: LuxSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star.toDouble()),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: LuxSpacing.xs),
                    child: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: LuxColors.sapphire,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: LuxSpacing.md),
            Text(
              _ratingLabel(_rating),
              style: LuxTypography.caption.copyWith(color: LuxColors.sapphire),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
          ),
          LuxButton(
            label: 'Enviar',
            width: 160,
            loading: _sending,
            onPressed: _sending
                ? null
                : () async {
                    setState(() => _sending = true);
                    await widget.onSubmit(_rating);
                    if (mounted) setState(() => _sending = false);
                  },
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(
            LuxSpacing.md, 0, LuxSpacing.md, LuxSpacing.md),
      );

  String _ratingLabel(double r) {
    if (r >= 5) return 'Excelente';
    if (r >= 4) return 'Bueno';
    if (r >= 3) return 'Regular';
    if (r >= 2) return 'Malo';
    return 'Muy malo';
  }
}
