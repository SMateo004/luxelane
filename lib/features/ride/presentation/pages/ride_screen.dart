import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/config/remote_flags.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../driver/presentation/widgets/pickup_code_entry.dart'
    show CallDispatchButton;
import '../../../incidents/presentation/widgets/sos_entry.dart';
import '../widgets/cancel_booking_dialog.dart';
import '../widgets/pending_status.dart';
import '../widgets/pickup_code_card.dart';

/// Estados en que el chófer va, espera o lleva al pasajero: solo entonces
/// se ven su ubicación y su teléfono.
const kDriverLiveStatuses = {
  BookingStatus.driverArriving,
  BookingStatus.driverArrived,
  BookingStatus.verified,
  BookingStatus.inProgress,
};

/// «Llamar a tu chófer» solo dentro de la ventana activa y con teléfono.
bool showCallDriver(BookingStatus? status, String? phone) =>
    kDriverLiveStatuses.contains(status) && (phone ?? '').isNotEmpty;

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
  StreamSubscription<String?>? _phoneSub;
  Booking? _booking;

  /// Teléfono del chófer: solo existe para la pantalla mientras el viaje
  /// está activo (bookings/{id}/driverContact/phone).
  String? _driverPhone;
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
        _syncDriverPhone();
        // Al completarse, se invita a valorar una sola vez por visita.
        if (b.status == BookingStatus.completed &&
            b.riderRating == null &&
            !_ratingPrompted) {
          _ratingPrompted = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _showRatingDialog(),
          );
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
    _phoneSub?.cancel();
    super.dispose();
  }

  /// Escucha el teléfono solo dentro de la ventana activa; al salir se
  /// olvida, para que el historial y la valoración nunca lo muestren.
  void _syncDriverPhone() {
    final live = _driverLive && widget.rideId.isNotEmpty;
    if (live && _phoneSub == null) {
      _phoneSub =
          sl<BookingRepository>().watchDriverPhone(widget.rideId).listen((p) {
        if (mounted) setState(() => _driverPhone = p);
      }, onError: (_) {});
    } else if (!live && _phoneSub != null) {
      _phoneSub!.cancel();
      _phoneSub = null;
      _driverPhone = null;
    }
  }

  DriverInfo? get _driver => _booking?.driverInfo;

  /// SOS del pasajero (solo lo ve él; el chófer nunca se entera).
  Widget? _sos() {
    final b = _booking;
    if (b == null || widget.rideId.isEmpty) return null;
    return SosEntry(bookingId: b.id, uid: b.riderId, status: b.status);
  }

  Future<void> _callDriver() async {
    final phone = _driverPhone ?? '';
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
        return pendingMessage(pendingSituation(_booking!, DateTime.now()));
      case BookingStatus.confirmed:
        return 'Tu reserva está confirmada. Te avisaremos cuando tu chófer salga hacia ti.';
      case BookingStatus.driverArriving:
        return 'Tu chófer va de camino al punto de recogida.';
      case BookingStatus.driverArrived:
        return 'Tu chófer ha llegado y te espera. Tómate tu tiempo.';
      case BookingStatus.verified:
        return 'Código verificado. Tu viaje empieza en un momento.';
      case BookingStatus.inProgress:
        return 'Disfruta del trayecto. Llegarás a tu destino en breve.';
      case BookingStatus.completed:
        return 'Has llegado. Gracias por viajar con Luxelane.';
      case BookingStatus.cancelled:
        final b = _booking!;
        return b.hasCancellationFee
            ? 'Esta reserva fue cancelada. Recargo por cancelación: '
                'Bs ${b.cancellationFee!.toStringAsFixed(2)}.'
            : 'Esta reserva fue cancelada.';
      case BookingStatus.noShow:
        return 'Tu chófer no te encontró en el punto de recogida. Central '
            'fue avisada.';
    }
  }

  /// Estados en los que el pasajero aún puede cancelar (igual que
  /// RIDER_CANCELLABLE en functions/src/cancellation.ts).
  static const _cancellable = {
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.driverArriving,
    BookingStatus.driverArrived,
  };

  /// Recargo y motivo pasan por el servidor (cancelBooking); el diálogo
  /// muestra el recargo solo si es mayor que cero.
  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    await runCancelBookingFlow(
      context,
      sl<BookingRepository>(),
      widget.rideId,
    );
    if (mounted) setState(() => _cancelling = false);
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

  /// El chófer va, espera o lleva al pasajero: solo entonces se puede leer
  /// su ubicación en vivo.
  bool get _driverLive => kDriverLiveStatuses.contains(_status);

  Stream<GeoPoint?>? _locationStream;
  bool _locationLive = false;

  /// Una sola suscripción mientras el viaje está activo; fuera de ese tramo
  /// las reglas la rechazarían.
  Stream<GeoPoint?>? get _driverLocation {
    final live = _driverLive && widget.rideId.isNotEmpty;
    if (live != _locationLive) {
      _locationLive = live;
      _locationStream = live
          ? sl<BookingRepository>()
              .watchDriverLocation(widget.rideId)
              .handleError((_) {})
          : null;
    }
    return _locationStream;
  }

  @override
  Widget build(BuildContext context) {
    final location = _driverLocation;
    return location != null
        ? StreamBuilder<GeoPoint?>(
            stream: location,
            builder: (context, snap) => _buildScaffold(snap.data),
          )
        : _buildScaffold(null);
  }

  Widget _buildScaffold(GeoPoint? driverGeo) {
    final driverLatLng = driverGeo != null
        ? LatLng(driverGeo.latitude, driverGeo.longitude)
        : null;
    final web = isWeb(context);
    return Scaffold(
      body: web ? _webLayout(driverLatLng) : _mobileLayout(driverLatLng),
    );
  }

  /// Acciones del pasajero: llamar al chófer, cancelar mientras se pueda y
  /// valorar un viaje completado que aún no valoró.
  Widget _actions() {
    final canCall = showCallDriver(_status, _driverPhone);
    final canCancel = _cancellable.contains(_status);
    final canRate =
        _status == BookingStatus.completed && _booking?.riderRating == null;
    if (!canCall && !canCancel && !canRate) return const SizedBox.shrink();
    // Una acción visible a la vez; cancelar queda discreta debajo para que
    // nunca compita con lo que la persona suele querer hacer.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canRate)
          LuxButton(label: 'Calificar viaje', onPressed: _showRatingDialog)
        else if (canCall)
          LuxOutlinedButton(
            label: 'Llamar a tu chófer',
            onPressed: _callDriver,
            icon: Icons.call_outlined,
          ),
        if (canCancel)
          LuxButton.ghost(
            label: _cancelling ? 'Cancelando…' : 'Cancelar reserva',
            onPressed: _cancelling ? null : _cancel,
          ),
      ],
    );
  }

  Widget _driverSection() {
    final d = _driver;
    if (_status == BookingStatus.cancelled) return const SizedBox.shrink();
    if (d == null) {
      final b = _booking;
      final needsDispatch = b != null &&
          b.status == BookingStatus.pending &&
          pendingNeedsDispatch(pendingSituation(b, DateTime.now()));
      if (!needsDispatch) return const _AssigningCard();
      // Liberada o fuera de hora: además de esperar, puede llamar a central.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AssigningCard(),
          const SizedBox(height: LuxSpacing.sm),
          ValueListenableBuilder<String?>(
            valueListenable: RemoteFlags.instance.dispatchPhone,
            builder: (_, phone, __) => CallDispatchButton(phone: phone),
          ),
        ],
      );
    }
    final b = _booking!;
    return DriverCard(
      name: d.name.isNotEmpty ? d.name : 'Tu chófer',
      rating: d.rating ?? 5.0,
      vehicle: d.vehicle ??
          '${b.vehicleClass.label} · ${b.vehicleClass.description}',
      plate: d.plate,
      photoUrl: d.photoUrl,
    );
  }

  /// Mientras el chófer espera, el código que el pasajero (o su invitado)
  /// le da al subir. Al verificarse, la tarjeta desaparece.
  Widget _pickupSection() {
    if (_status != BookingStatus.driverArrived || widget.rideId.isEmpty) {
      return const SizedBox.shrink();
    }
    final guest = _booking?.guest;
    return Padding(
      padding: const EdgeInsets.only(bottom: LuxSpacing.md),
      child: PickupCodeCard(
        key: ValueKey('pickup-${widget.rideId}'),
        bookingId: widget.rideId,
        guestName: guest?.fullName,
      ),
    );
  }

  Widget _mobileLayout(LatLng? driverLatLng) => Stack(
        children: [
          _MapArea(booking: _booking, driverLocation: driverLatLng),
          SafeArea(
            child: Column(
              children: [
                _TopBar(trailing: _sos()),
                const Spacer(),
                _BottomPanel(
                  status: _status ?? BookingStatus.pending,
                  message: _statusMessage,
                  pickup: _pickupSection(),
                  driver: _driverSection(),
                  actions: _actions(),
                  preferences:
                      _booking?.riderPreferences ?? RidePreferences.none,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _webLayout(LatLng? driverLatLng) => Row(
        children: [
          Expanded(
            child: _MapArea(booking: _booking, driverLocation: driverLatLng),
          ),
          SizedBox(
            width: 400,
            child: Container(
              color: LuxColors.surface,
              child: Column(
                children: [
                  _WebRideHeader(
                    status: _status ?? BookingStatus.pending,
                    trailing: _sos(),
                  ),
                  const LuxDivider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(LuxSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_statusMessage, style: LuxTypography.bodyMedium),
                          const SizedBox(height: LuxSpacing.lg),
                          _pickupSection(),
                          _driverSection(),
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
  const _TopBar({this.trailing});
  final Widget? trailing;

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
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: LuxColors.ink,
                ),
              ),
            ),
            const SizedBox(width: LuxSpacing.md),
            const LuxelaneWordmark(),
            if (trailing != null) ...[const Spacer(), trailing!],
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
    this.pickup = const SizedBox.shrink(),
    this.preferences = RidePreferences.none,
  });

  final BookingStatus status;
  final String message;
  final Widget pickup;
  final Widget driver;
  final Widget actions;
  final RidePreferences preferences;

  @override
  Widget build(BuildContext context) {
    final duration = LuxMotion.of(context, LuxMotion.slow);
    final open =
        status != BookingStatus.completed && status != BookingStatus.cancelled;
    final notes = preferences.driverNotes;
    return Container(
      decoration: const BoxDecoration(
        color: LuxColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LuxRadius.xl + 4),
        ),
        boxShadow: [
          BoxShadow(
            color: LuxColors.shadow,
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        LuxSpacing.md + 4,
        LuxSpacing.lg,
        LuxSpacing.md + 4,
        LuxSpacing.xl,
      ),
      child: AnimatedSize(
        duration: duration,
        curve: LuxMotion.emphasized,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status != BookingStatus.cancelled) ...[
              RideProgressBar(status: status),
              const SizedBox(height: LuxSpacing.md),
            ],
            // Cada cambio de estado se anuncia con un fundido, no un salto.
            AnimatedSwitcher(
              duration: duration,
              switchInCurve: LuxMotion.decelerate,
              switchOutCurve: LuxMotion.accelerate,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Column(
                key: ValueKey(status),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookingStatusChip(status: status),
                  const SizedBox(height: LuxSpacing.sm + 2),
                  Text(
                    message,
                    style: LuxTypography.headlineLarge.copyWith(
                      fontSize: 26,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            if (open && notes.isNotEmpty) ...[
              const SizedBox(height: LuxSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: LuxColors.sapphire,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tu chófer conoce tu estilo: '
                      '${notes.take(3).join(' · ').toLowerCase()}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.caption.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: LuxSpacing.lg),
            pickup,
            driver,
            const SizedBox(height: LuxSpacing.md),
            actions,
          ],
        ),
      ),
    );
  }
}

/// Shown until a chauffeur is assigned — honest, calm, no placeholder person.
class _AssigningCard extends StatelessWidget {
  const _AssigningCard();

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Row(
          children: [
            const SizedBox(
              width: 32,
              child: LuxLoadingDots(color: LuxColors.sapphire, size: 5),
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asignando a tu chófer',
                    style: LuxTypography.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Verás su nombre, vehículo y valoración aquí.',
                    style: LuxTypography.caption.copyWith(
                      color: LuxColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _WebRideHeader extends StatelessWidget {
  const _WebRideHeader({required this.status, this.trailing});
  final BookingStatus status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        child: Row(
          children: [
            const LuxelaneWordmark(),
            const Spacer(),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: LuxSpacing.sm),
            ],
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
        title: const Text(
          'Califica tu viaje',
          style: LuxTypography.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.driverName,
              style: LuxTypography.bodyMedium.copyWith(
                color: LuxColors.inkTertiary,
              ),
            ),
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
          LuxSpacing.md,
          0,
          LuxSpacing.md,
          LuxSpacing.md,
        ),
      );

  String _ratingLabel(double r) {
    if (r >= 5) return 'Excelente';
    if (r >= 4) return 'Bueno';
    if (r >= 3) return 'Regular';
    if (r >= 2) return 'Malo';
    return 'Muy malo';
  }
}
