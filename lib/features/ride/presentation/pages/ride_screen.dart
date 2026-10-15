import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';

/// Seguimiento de una reserva del pasajero. Escucha su propia reserva (no un
/// bloc compartido) y solo usa lo que el pasajero puede leer: la reserva, con
/// los datos del chófer que copia el servidor, y la ubicación del chófer.
class RideScreen extends StatefulWidget {
  const RideScreen({super.key, required this.rideId});

  /// Id de la reserva.
  final String rideId;

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final _repo = sl<BookingRepository>();
  StreamSubscription<Booking>? _sub;
  Booking? _booking;
  bool _notFound = false;
  bool _cancelling = false;
  bool _ratingShown = false;

  String? _profileFor;
  Stream<DriverProfile?>? _profileStream;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    if (widget.rideId.isEmpty) {
      _notFound = true;
      return;
    }
    // Si la reserva no existe el stream no emite nada: se da por perdida
    // tras unos segundos para no dejar un spinner eterno.
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (mounted && _booking == null) setState(() => _notFound = true);
    });
    _sub = _repo.watchBooking(widget.rideId).listen(
      (b) {
        if (!mounted) return;
        setState(() {
          _booking = b;
          _notFound = false;
        });
        _maybeAskRating(b);
      },
      onError: (Object _) {
        // Sin permiso (no es su reserva) o reserva ilegible.
        if (mounted) setState(() => _notFound = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Stream<DriverProfile?>? _driverProfile(String? driverId) {
    if (driverId == null || driverId.isEmpty) return null;
    if (_profileFor != driverId) {
      _profileFor = driverId;
      _profileStream = sl<UserRepository>().watchDriverProfile(driverId);
    }
    return _profileStream;
  }

  BookingStatus get _status => _booking?.status ?? BookingStatus.pending;

  bool get _canCancel => const {
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.driverArriving,
        BookingStatus.driverArrived,
      }.contains(_status);

  String get _statusMessage {
    final b = _booking;
    switch (_status) {
      case BookingStatus.pending:
        final soon = b == null ||
            b.scheduledAt.difference(DateTime.now()) < const Duration(hours: 1);
        return soon
            ? 'Buscando a tu chófer. Te avisaremos en cuanto lo tengamos.'
            : 'Reserva recibida para ${LuxFormat.dateTime(b.scheduledAt)}. '
                'Te avisaremos al asignar chófer.';
      case BookingStatus.confirmed:
        return 'Tu chófer está confirmado. Te avisaremos cuando salga hacia ti.';
      case BookingStatus.driverArriving:
        return 'Tu chófer va de camino al punto de recogida.';
      case BookingStatus.driverArrived:
        return 'Tu chófer ha llegado y te espera.';
      case BookingStatus.inProgress:
        return 'Disfruta del trayecto.';
      case BookingStatus.completed:
        return 'Has llegado. Gracias por viajar con Luxelane.';
      case BookingStatus.cancelled:
        return switch (b?.cancelledBy) {
          'rider' => 'Cancelaste esta reserva.',
          'system' =>
            'No encontramos chófer a tiempo y cancelamos la reserva. No se te cobrará.',
          'driver' =>
            'El chófer no pudo realizar el viaje. Puedes reservar de nuevo.',
          'pricing' =>
            'Las tarifas cambiaron mientras reservabas. Vuelve a reservar para '
                'ver el precio actual. No se te cobrará.',
          _ => 'Esta reserva fue cancelada.',
        };
    }
  }

  Future<void> _callDriver() async {
    final phone = _booking?.driverPhone ?? '';
    if (phone.isEmpty) return;
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && mounted) {
      showLuxSnackbar(context, 'No se pudo abrir el teléfono', isError: true);
    }
  }

  Future<void> _cancel() async {
    if (_cancelling || !_canCancel) return;
    final arrived = _status == BookingStatus.driverArrived;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar la reserva?'),
        content: Text(arrived
            ? 'Tu chófer ya está esperándote en el punto de recogida.'
            : _booking?.driverId != null
                ? 'Tu chófer ya está asignado a este viaje.'
                : 'Dejaremos de buscar chófer para este viaje.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, cancelar',
                style: TextStyle(color: LuxColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _cancelling = true);
    final result = await _repo.cancelBooking(widget.rideId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    result.fold(
      (f) => showLuxSnackbar(context, f.message, isError: true),
      (_) => showLuxSnackbar(context, 'Reserva cancelada'),
    );
  }

  void _maybeAskRating(Booking b) {
    if (_ratingShown ||
        b.status != BookingStatus.completed ||
        b.riderRating != null ||
        b.driverId == null) {
      return;
    }
    _ratingShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showRatingDialog();
    });
  }

  void _showRatingDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _RatingDialog(
        driverName: _booking?.driverName ?? 'tu chófer',
        onSkip: () => Navigator.of(ctx).pop(),
        onSubmit: (rating) async {
          Navigator.of(ctx).pop();
          final result = await _repo.rateBooking(widget.rideId, rating.round());
          if (!mounted) return;
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
    if (_booking == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(),
              Expanded(
                child: Center(
                  child: _notFound
                      ? Padding(
                          padding: const EdgeInsets.all(LuxSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 48, color: LuxColors.inkTertiary),
                              const SizedBox(height: LuxSpacing.md),
                              const Text('No encontramos esta reserva',
                                  style: LuxTypography.titleMedium),
                              const SizedBox(height: LuxSpacing.lg),
                              LuxButton(
                                label: 'Ver mis viajes',
                                onPressed: () => context.go('/trips'),
                              ),
                            ],
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final stream = _driverProfile(_booking!.driverId);
    if (stream == null) return _buildScaffold(null, null);
    return StreamBuilder<DriverProfile?>(
      stream: stream,
      builder: (context, snap) {
        // La ubicación solo importa mientras el chófer viene o lleva al
        // pasajero; antes o después no se muestra.
        final live = const {
          BookingStatus.driverArriving,
          BookingStatus.driverArrived,
          BookingStatus.inProgress,
        }.contains(_status);
        return _buildScaffold(
            live ? snap.data?.currentLocation : null, snap.data);
      },
    );
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

  Widget _actions() {
    final b = _booking!;
    final canCall = (b.driverPhone ?? '').isNotEmpty &&
        b.status != BookingStatus.completed &&
        b.status != BookingStatus.cancelled;
    final canRate = b.status == BookingStatus.completed &&
        b.riderRating == null &&
        b.driverId != null;
    final children = <Widget>[
      if (canCall)
        LuxOutlinedButton(
          label: 'Llamar al chófer',
          onPressed: _callDriver,
          icon: Icons.call_outlined,
        ),
      if (canRate)
        LuxButton(label: 'Calificar viaje', onPressed: _showRatingDialog),
      if (b.status == BookingStatus.completed ||
          b.status == BookingStatus.cancelled)
        LuxOutlinedButton(
          label: 'Volver al inicio',
          onPressed: () => context.go('/'),
        ),
      if (_canCancel)
        TextButton(
          onPressed: _cancelling ? null : _cancel,
          child: Text(_cancelling ? 'Cancelando…' : 'Cancelar reserva',
              style: const TextStyle(color: LuxColors.error)),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in children) ...[w, const SizedBox(height: LuxSpacing.sm)],
      ],
    );
  }

  Widget _driverSection(DriverProfile? profile) {
    final b = _booking!;
    if (b.status == BookingStatus.cancelled) return const SizedBox.shrink();
    if (b.driverId == null) return const _AssigningCard();
    return DriverCard(
      name: b.driverName ?? 'Tu chófer',
      rating: (profile?.rating ?? 0) > 0 ? profile!.rating : 5.0,
      vehicle: b.vehicleLabel ?? b.vehicleClass.label,
      plate: b.vehiclePlate ?? '',
      photoUrl: b.driverPhotoUrl,
    );
  }

  Widget _tripSummary() {
    final b = _booking!;
    return Text(
      '${LuxFormat.dateTime(b.scheduledAt)} · ${LuxFormat.bs(b.chargedAmount)}'
      '${b.paymentMethod == 'cash' ? ' · efectivo' : ''}',
      style: LuxTypography.caption,
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
                  status: _status,
                  message: _statusMessage,
                  summary: _tripSummary(),
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
                  _WebRideHeader(status: _status),
                  const LuxDivider(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(LuxSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_statusMessage, style: LuxTypography.bodyMedium),
                          const SizedBox(height: LuxSpacing.sm),
                          _tripSummary(),
                          const SizedBox(height: LuxSpacing.lg),
                          _driverSection(profile),
                          const SizedBox(height: LuxSpacing.lg),
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
    required this.summary,
    required this.driver,
    required this.actions,
  });

  final BookingStatus status;
  final String message;
  final Widget summary;
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
            const SizedBox(height: LuxSpacing.xs),
            summary,
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
    required this.onSkip,
  });
  final String driverName;
  final void Function(double rating) onSubmit;
  final VoidCallback onSkip;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double _rating = 5;

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
          LuxButton(
            label: 'Enviar',
            onPressed: () => widget.onSubmit(_rating),
          ),
          TextButton(onPressed: widget.onSkip, child: const Text('Ahora no')),
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
