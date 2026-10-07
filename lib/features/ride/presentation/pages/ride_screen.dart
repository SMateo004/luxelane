import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../booking/presentation/bloc/booking_bloc.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../bloc/ride_bloc.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key, required this.rideId});
  // rideId is the booking ID navigated from BookingScreen
  final String rideId;

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  Booking? _booking;
  User?    _driver;       // assigned chauffeur's account (name, phone)
  String?  _actualRideId; // real ride doc ID fetched after completion
  bool _ratingSubmitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.rideId.isNotEmpty) {
      context
          .read<BookingBloc>()
          .add(BookingStatusWatched(bookingId: widget.rideId));
    }
    _initNotifications();
  }

  void _initNotifications() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      sl<NotificationService>().init(userId: authState.user.id);
    }
  }

  // Fetch the actual ride document for this booking so we can submit rating
  Future<void> _fetchRideId() async {
    if (_actualRideId != null) return;
    final result = await sl<RideRepository>()
        .getRideByBooking(widget.rideId);
    result.fold((_) {}, (ride) {
      if (mounted) setState(() => _actualRideId = ride.id);
    });
  }

  Future<void> _ensureDriver() async {
    final id = _booking?.driverId;
    if (id == null || id.isEmpty || _driver?.id == id) return;
    final result = await sl<UserRepository>().getUserById(id);
    result.fold((_) {}, (u) {
      if (mounted) setState(() => _driver = u);
    });
  }

  Future<void> _callDriver() async {
    final phone = _driver?.phone ?? '';
    if (phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  BookingStatus get _status =>
      _booking?.status ?? BookingStatus.confirmed;

  String get _statusMessage {
    switch (_status) {
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

  static const _nextStatus = {
    BookingStatus.confirmed: BookingStatus.driverArriving,
    BookingStatus.driverArriving: BookingStatus.driverArrived,
    BookingStatus.driverArrived: BookingStatus.inProgress,
    BookingStatus.inProgress: BookingStatus.completed,
  };

  void _advance() {
    if (_status == BookingStatus.completed) {
      if (!_ratingSubmitted) {
        _showRatingDialog();
      } else {
        context.go('/');
      }
      return;
    }
    final next = _nextStatus[_status];
    if (next != null && widget.rideId.isNotEmpty) {
      context.read<BookingBloc>().add(
            BookingUpdateStatusRequested(
              bookingId: widget.rideId,
              status: next,
            ),
          );
    }
  }

  void _showRatingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: context.read<RideBloc>(),
        child: _RatingDialog(
          driverName: _driver?.displayName ?? 'tu chófer',
          rideId: _actualRideId,
          onSubmit: (rating) {
            // Submit rating to Firestore if ride doc exists
            if (_actualRideId != null) {
              context.read<RideBloc>().add(RideRatingSubmitted(
                    rideId: _actualRideId!,
                    rating: rating,
                    isRiderRating: true,
                  ));
            }
            setState(() => _ratingSubmitted = true);
            Navigator.of(context).pop();
            context.go('/');
          },
        ),
      ),
    );
  }

  void _createStatusNotification(
    BuildContext context,
    BookingStatus status, {
    required String riderId,
  }) {
    String title, body, type;
    switch (status) {
      case BookingStatus.confirmed:
        title = 'Chófer asignado';
        body = 'Tu chófer está en camino para recogerte.';
        type = 'booking_confirmed';
        break;
      case BookingStatus.driverArriving:
        title = 'El chófer está en camino';
        body = 'Tu chófer se dirige a tu punto de recogida.';
        type = 'driver_arriving';
        break;
      case BookingStatus.driverArrived:
        title = 'El chófer ha llegado';
        body = 'Tu chófer te espera en el punto de recogida.';
        type = 'driver_arrived';
        break;
      case BookingStatus.inProgress:
        title = 'Viaje iniciado';
        body = 'Ya estás en camino hacia tu destino.';
        type = 'ride_started';
        break;
      case BookingStatus.completed:
        title = 'Viaje completado';
        body = '¡Has llegado. Gracias por viajar con Luxelane!';
        type = 'ride_completed';
        break;
      default:
        return;
    }
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
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingStatusUpdated) {
          setState(() => _booking = state.booking);
          _ensureDriver();
          _createStatusNotification(context, state.booking.status,
              riderId: state.booking.riderId);
          if (state.booking.status == BookingStatus.completed &&
              !_ratingSubmitted) {
            // Fetch the actual ride document, then show rating
            _fetchRideId().then((_) {
              if (mounted) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _showRatingDialog());
              }
            });
          }
        }
      },
      child: _booking?.driverId != null
          ? StreamBuilder<DriverProfile?>(
              stream: sl<UserRepository>()
                  .watchDriverProfile(_booking!.driverId!),
              builder: (context, snap) =>
                  _buildScaffold(snap.data?.currentLocation, snap.data),
            )
          : _buildScaffold(null, null),
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

  /// The action row: contact the chauffeur when we have a number; the manual
  /// status stepper only exists in debug builds, never in front of a client.
  Widget _actions() {
    final canCall = (_driver?.phone ?? '').isNotEmpty;
    final completed = _status == BookingStatus.completed;
    final showAdvance = completed || kDebugMode;
    if (!canCall && !showAdvance) return const SizedBox.shrink();
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
        if (canCall && showAdvance) const SizedBox(width: LuxSpacing.sm),
        if (showAdvance)
          Expanded(
            child: LuxButton(
              label: completed ? 'Calificar viaje' : 'Siguiente (dev)',
              onPressed: _advance,
            ),
          ),
      ],
    );
  }

  Widget _driverSection(DriverProfile? profile) {
    final d = _driver;
    if (d == null) return const _AssigningCard();
    return DriverCard(
      name: d.displayName,
      rating: profile?.rating ?? 5.0,
      vehicle: _booking != null
          ? '${_booking!.vehicleClass.label} · ${_booking!.vehicleClass.description}'
          : '',
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
                  status: _status,
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
              color: LuxColors.blackSurface,
              child: Column(
                children: [
                  _WebRideHeader(status: _status),
                  const LuxDivider(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(LuxSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_statusMessage,
                              style: LuxTypography.bodyMedium),
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
                  color: LuxColors.blackSurface,
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                  border: Border.all(color: LuxColors.blackBorder),
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: LuxColors.white),
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
          color: LuxColors.blackSurface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
          border: Border(top: BorderSide(color: LuxColors.blackBorder)),
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
                style: LuxTypography.bodyLarge.copyWith(height: 1.5)),
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
                  strokeWidth: 1.2, color: LuxColors.sapphireBright),
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
                          .copyWith(color: LuxColors.whiteSecondary)),
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
    this.rideId,
  });
  final String driverName;
  final String? rideId;
  final void Function(double rating) onSubmit;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double _rating = 5;

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
                style: LuxTypography.bodyMedium
                    .copyWith(color: LuxColors.whiteTertiary)),
            const SizedBox(height: LuxSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: LuxSpacing.xs),
                    child: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
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
