import 'package:cloud_firestore/cloud_firestore.dart';
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

  BookingStatus get _status =>
      _booking?.status ?? BookingStatus.confirmed;

  String get _statusMessage {
    switch (_status) {
      case BookingStatus.confirmed:
        return 'Driver assigned · en route to you';
      case BookingStatus.driverArriving:
        return 'Driver is on the way';
      case BookingStatus.driverArrived:
        return 'Your driver has arrived';
      case BookingStatus.inProgress:
        return 'En route to destination';
      case BookingStatus.completed:
        return 'You have arrived. Thank you!';
      default:
        return 'Processing…';
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
          driverName: 'Your driver',
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
        title = 'Driver assigned';
        body = 'Your driver is on the way to pick you up.';
        type = 'booking_confirmed';
        break;
      case BookingStatus.driverArriving:
        title = 'Driver is on the way';
        body = 'Your driver is heading to your pickup location.';
        type = 'driver_arriving';
        break;
      case BookingStatus.driverArrived:
        title = 'Driver has arrived';
        body = 'Your driver is waiting at your pickup location.';
        type = 'driver_arrived';
        break;
      case BookingStatus.inProgress:
        title = 'Ride started';
        body = 'You are now on your way to your destination.';
        type = 'ride_started';
        break;
      case BookingStatus.completed:
        title = 'Ride completed';
        body = 'You have arrived. Thank you for riding with Luxelane!';
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
                  _buildScaffold(snap.data?.currentLocation),
            )
          : _buildScaffold(null),
    );
  }

  Widget _buildScaffold(GeoPoint? driverGeo) {
    final driverLatLng = driverGeo != null
        ? LatLng(driverGeo.latitude, driverGeo.longitude)
        : null;
    final web = isWeb(context);
    return Scaffold(
      body: web
          ? _webLayout(driverLatLng)
          : _mobileLayout(driverLatLng),
    );
  }

  Widget _mobileLayout(LatLng? driverLatLng) => Stack(
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
                  onAdvance: _advance,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _webLayout(LatLng? driverLatLng) => Row(
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
                          const DriverCard(
                            name: 'James Whitmore',
                            rating: 4.9,
                            vehicle: 'Mercedes-Benz S-Class · Black',
                            plate: 'LUX · 2891',
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: LuxOutlinedButton(
                                  label: 'Contact',
                                  onPressed: () {},
                                  icon: Icons.call_outlined,
                                ),
                              ),
                              const SizedBox(width: LuxSpacing.sm),
                              Expanded(
                                child: LuxButton(
                                  label: _status ==
                                          BookingStatus.completed
                                      ? 'Rate & Done'
                                      : 'Next (dev)',
                                  onPressed: _advance,
                                ),
                              ),
                            ],
                          ),
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
    required this.onAdvance,
  });

  final BookingStatus status;
  final String message;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: LuxColors.blackSurface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
          border: Border(top: BorderSide(color: LuxColors.blackBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(
          LuxSpacing.md,
          LuxSpacing.md,
          LuxSpacing.md,
          LuxSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                BookingStatusChip(status: status),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: Text(message, style: LuxTypography.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.md),
            const LuxDivider(),
            const SizedBox(height: LuxSpacing.md),
            const DriverCard(
              name: 'James Whitmore',
              rating: 4.9,
              vehicle: 'Mercedes-Benz S-Class · Black',
              plate: 'LUX · 2891',
            ),
            const SizedBox(height: LuxSpacing.md),
            Row(
              children: [
                Expanded(
                  child: LuxOutlinedButton(
                    label: 'Contact',
                    onPressed: () {},
                    icon: Icons.call_outlined,
                  ),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: LuxButton(
                    label: status == BookingStatus.completed
                        ? 'Rate & Done'
                        : 'Next (dev)',
                    onPressed: onAdvance,
                  ),
                ),
              ],
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
        title: const Text('Rate your ride',
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
            label: 'Submit',
            onPressed: () => widget.onSubmit(_rating),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(
            LuxSpacing.md, 0, LuxSpacing.md, LuxSpacing.md),
      );

  String _ratingLabel(double r) {
    if (r >= 5) return 'Excellent';
    if (r >= 4) return 'Good';
    if (r >= 3) return 'Average';
    if (r >= 2) return 'Poor';
    return 'Very Poor';
  }
}
