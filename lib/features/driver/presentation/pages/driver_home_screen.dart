import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:map_launcher/map_launcher.dart' as ml;
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/driver_bloc.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  /// Tracks which booking ID we're currently showing a sheet for — avoids duplicates.
  String? _activeSheetId;

  void _maybeShowRequest(BuildContext context, Booking booking) {
    if (_activeSheetId == booking.id) return;
    _activeSheetId = booking.id;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomingRequestSheet(
        booking: booking,
        onAccept: () {
          final auth = context.read<AuthBloc>().state;
          if (auth is AuthAuthenticated) {
            context.read<DriverBloc>().add(DriverRequestAccepted(
                  bookingId: booking.id,
                  driverId: auth.user.id,
                ));
          }
          if (mounted) Navigator.of(context).pop();
          _activeSheetId = null;
        },
        onDecline: () {
          context.read<DriverBloc>().add(
                DriverRequestDeclined(bookingId: booking.id),
              );
          if (mounted) Navigator.of(context).pop();
          _activeSheetId = null;
        },
      ),
    ).then((_) => _activeSheetId = null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverBloc, DriverState>(
      listenWhen: (prev, curr) {
        if (curr is! DriverLoaded) return false;
        final prevId = prev is DriverLoaded ? prev.currentRequest?.id : null;
        final currId = curr.currentRequest?.id;
        return prevId != currId || curr.isAvailable != (prev as DriverLoaded).isAvailable;
      },
      listener: (context, state) {
        if (state is DriverLoaded) {
          final req = state.currentRequest;
          if (req != null && state.isAvailable) {
            _maybeShowRequest(context, req);
          } else if (_activeSheetId != null) {
            // The request disappeared or driver went offline
            if (mounted) Navigator.of(context, rootNavigator: true).pop();
            _activeSheetId = null;
          }
        }
      },
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isAuthedDriver = authState is AuthAuthenticated && 
                              authState.user.role == UserRole.driver;

        if (state is DriverError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: LuxColors.error, size: 48),
                  const SizedBox(height: 16),
                  const Text('Connection Error', style: LuxTypography.headlineMedium),
                  const SizedBox(height: 8),
                  Text(state.message, style: LuxTypography.caption, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  LuxButton(
                    label: 'Retry',
                    onPressed: () {
                      final auth = context.read<AuthBloc>().state;
                      if (auth is AuthAuthenticated) {
                        context.read<DriverBloc>().add(DriverStarted(userId: auth.user.id));
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! DriverLoaded) {
          // If we are authenticated but data is still loading, show spinner.
          if (isAuthedDriver) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const Scaffold(backgroundColor: Colors.black);
        }
        final active = state.activeBooking;
        return Scaffold(
          appBar: AppBar(
            title: const LuxelaneWordmark(),
            centerTitle: false,
            actions: [
              _AvailabilityToggle(
                isAvailable: state.isAvailable,
                isTracking: state.isTracking,
              ),
              const SizedBox(width: LuxSpacing.md),
            ],
          ),
          body: active != null
              ? _ActiveRidePanel(booking: active)
              : _IdlePanel(state: state),
        );
      },
    );
  }
}

// ── Availability toggle ────────────────────────────────────────────────────

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({
    required this.isAvailable,
    required this.isTracking,
  });
  final bool isAvailable;
  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final userId = () {
      final s = context.read<AuthBloc>().state;
      return s is AuthAuthenticated ? s.user.id : '';
    }();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isTracking)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: LuxSpacing.sm),
            decoration: const BoxDecoration(
              color: LuxColors.success,
              shape: BoxShape.circle,
            ),
          ),
        Switch(
          value: isAvailable,
          activeColor: LuxColors.sapphire,
          onChanged: (val) => context.read<DriverBloc>().add(
                DriverAvailabilityToggled(userId: userId, isAvailable: val),
              ),
        ),
      ],
    );
  }
}

// ── Idle panel ─────────────────────────────────────────────────────────────

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({required this.state});
  final DriverLoaded state;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(LuxSpacing.md),
        children: [
          _StatusBanner(isAvailable: state.isAvailable),
          const SizedBox(height: LuxSpacing.lg),
          const SectionHeader(title: "Today's Summary"),
          const SizedBox(height: LuxSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Completed',
                  value: '${state.completedBookings.length}',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Earnings',
                  value: 'Bs${state.totalEarnings.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuxSpacing.lg),
          if (!state.isAvailable) ...[
            const SectionHeader(title: 'Go Online'),
            const SizedBox(height: LuxSpacing.md),
            LuxButton(
              label: 'Go Online',
              icon: Icons.power_settings_new_rounded,
              onPressed: () {
                final s = context.read<AuthBloc>().state;
                if (s is AuthAuthenticated) {
                  context.read<DriverBloc>().add(DriverAvailabilityToggled(
                        userId: s.user.id,
                        isAvailable: true,
                      ));
                }
              },
            ),
          ],
        ],
      );
}

// ── Status banner ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isAvailable});
  final bool isAvailable;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: isAvailable
              ? LuxColors.success.withValues(alpha: 0.08)
              : LuxColors.blackElevated,
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          border: Border.all(
            color: isAvailable
                ? LuxColors.success.withValues(alpha: 0.3)
                : LuxColors.blackBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isAvailable
                  ? Icons.wifi_tethering_rounded
                  : Icons.wifi_tethering_off_rounded,
              color: isAvailable ? LuxColors.success : LuxColors.whiteTertiary,
              size: 24,
            ),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAvailable ? 'You are online' : 'You are offline',
                    style: LuxTypography.titleMedium.copyWith(
                      color:
                          isAvailable ? LuxColors.success : LuxColors.white,
                    ),
                  ),
                  Text(
                    isAvailable
                        ? 'Waiting for new ride requests'
                        : 'Toggle the switch to go online',
                    style: LuxTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Active ride panel ──────────────────────────────────────────────────────

class _ActiveRidePanel extends StatelessWidget {
  const _ActiveRidePanel({required this.booking});
  final Booking booking;

  String get _actionLabel {
    switch (booking.status) {
      case BookingStatus.confirmed:      return 'Head to Pickup';
      case BookingStatus.driverArriving: return 'I Have Arrived';
      case BookingStatus.driverArrived:  return 'Start Ride';
      case BookingStatus.inProgress:     return 'Complete Ride';
      default:                           return '';
    }
  }

  void _advance(BuildContext context) {
    final bloc = context.read<DriverBloc>();
    switch (booking.status) {
      case BookingStatus.confirmed:
        bloc.add(DriverBookingAccepted(bookingId: booking.id));
      case BookingStatus.driverArriving:
        bloc.add(DriverArrivedAtPickup(bookingId: booking.id));
      case BookingStatus.driverArrived:
        bloc.add(DriverTripStarted(bookingId: booking.id));
      case BookingStatus.inProgress:
        bloc.add(DriverTripCompleted(bookingId: booking.id));
      default:
        break;
    }
  }

  Future<void> _openMaps(BuildContext context, Place target) async {
    try {
      if (kIsWeb) {
        final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${target.lat},${target.lng}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw 'Could not launch $url';
        }
        return;
      }

      final availableMaps = await ml.MapLauncher.installedMaps;
      if (!context.mounted) return;

      if (availableMaps.isEmpty) {
        showLuxSnackbar(context, 'No map apps installed', isError: true);
        return;
      }

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(LuxSpacing.md),
                  child: Text('Navigate to ${target.address}', 
                      style: LuxTypography.titleMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableMaps.length,
                    itemBuilder: (context, index) {
                      final map = availableMaps[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const Icon(Icons.map_outlined, color: LuxColors.sapphire, size: 24),
                        ),
                        title: Text(map.mapName, style: LuxTypography.bodyLarge),
                        onTap: () {
                          map.showMarker(
                            coords: ml.Coords(target.lat, target.lng),
                            title: target.address,
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        showLuxSnackbar(context, 'Could not open maps', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool goingToPickup = booking.status == BookingStatus.confirmed || 
                               booking.status == BookingStatus.driverArriving;
    final targetPlace = goingToPickup ? booking.origin : booking.destination;

    return Padding(
      padding: const EdgeInsets.all(LuxSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Active Ride'),
          const SizedBox(height: LuxSpacing.md),
          LuxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BookingStatusChip(status: booking.status),
                    const Spacer(),
                    Text(
                      '\$${booking.estimatedPrice.toStringAsFixed(0)}',
                      style: LuxTypography.headlineLarge
                          .copyWith(color: LuxColors.sapphire),
                    ),
                  ],
                ),
                const SizedBox(height: LuxSpacing.md),
                _AddressRow(
                  icon: Icons.radio_button_checked,
                  color: LuxColors.sapphire,
                  label: 'Pick up',
                  address: booking.origin.address,
                  isCurrent: goingToPickup,
                ),
                const SizedBox(height: LuxSpacing.sm),
                _AddressRow(
                  icon: Icons.location_on_rounded,
                  color: LuxColors.error,
                  label: 'Drop off',
                  address: booking.destination.address,
                  isCurrent: !goingToPickup,
                ),
              ],
            ),
          ),
          const SizedBox(height: LuxSpacing.md),
          LuxButton(label: _actionLabel, onPressed: () => _advance(context)),
          const SizedBox(height: LuxSpacing.sm),
          LuxOutlinedButton(
            label: 'Navigate TO ${goingToPickup ? 'PICKUP' : 'DESTINATION'}',
            icon: Icons.navigation_outlined,
            onPressed: () => _openMaps(context, targetPlace),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
    this.isCurrent = false,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String address;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isCurrent)
                _PulseIndicator(color: color),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: LuxTypography.caption.copyWith(
                  color: isCurrent ? color : LuxColors.whiteTertiary,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                )),
                Text(address,
                    style: LuxTypography.bodyMedium.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      );
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator({required this.color});
  final Color color;
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(begin: 1.0, end: 1.8).animate(_ctrl),
    child: FadeTransition(
      opacity: Tween(begin: 0.5, end: 0.0).animate(_ctrl),
      child: Container(
        width: 14, height: 14,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Column(
          children: [
            Icon(icon, color: LuxColors.sapphire, size: 24),
            const SizedBox(height: LuxSpacing.sm),
            Text(value,
                style:
                    LuxTypography.headlineLarge.copyWith(color: LuxColors.sapphire)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: LuxTypography.caption),
          ],
        ),
      );
}

// ── Incoming request sheet ─────────────────────────────────────────────────

class _IncomingRequestSheet extends StatefulWidget {
  const _IncomingRequestSheet({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  });
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_IncomingRequestSheet> createState() => _IncomingRequestSheetState();
}

class _IncomingRequestSheetState extends State<_IncomingRequestSheet> {
  RouteInfo? _route;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final maps = GetIt.instance<MapsService>();
      final info = await maps.getRoute(
        origin: widget.booking.origin,
        destination: widget.booking.destination,
      );
      if (mounted) setState(() => _route = info);
    } catch (e) {
      debugPrint('Map Route Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: LuxColors.blackSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: LuxColors.blackBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LuxColors.blackBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Header: label ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEW RIDE REQUEST',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: LuxColors.sapphire,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.booking.vehicleClass.label,
                        style: LuxTypography.headlineLarge,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.notifications_active_rounded, 
                    color: LuxColors.sapphire, size: 40),
              ],
            ),
            const SizedBox(height: 20),

            // ── Price ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: LuxColors.sapphire.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LuxColors.sapphire.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money_rounded,
                      color: LuxColors.sapphire, size: 20),
                  const SizedBox(width: 8),
                  const Text('Estimated fare', style: LuxTypography.caption),
                  const Spacer(),
                  Text(
                    'Bs${widget.booking.estimatedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Cormorant',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: LuxColors.sapphire,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── MAP VIEW ─────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: LuxMap(
                  origin: widget.booking.origin,
                  destination: widget.booking.destination,
                  routeInfo: _route,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Route Addresses ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LuxColors.blackElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                   _RouteItem(
                    icon: Icons.radio_button_checked,
                    color: LuxColors.sapphire,
                    label: 'PICKUP',
                    address: widget.booking.origin.address,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(7, 5, 0, 5),
                    child: Container(
                      width: 1.5,
                      height: 18,
                      color: LuxColors.blackBorder,
                    ),
                  ),
                  _RouteItem(
                    icon: Icons.location_on_rounded,
                    color: LuxColors.error,
                    label: 'DROP OFF',
                    address: widget.booking.destination.address,
                  ),
                ],
              ),
            ),

            if (widget.booking.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LuxColors.blackElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded,
                        size: 15, color: LuxColors.whiteTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.booking.notes!,
                          style: LuxTypography.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            // ── Action buttons ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onDecline,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LuxColors.error,
                      side: const BorderSide(color: LuxColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.onAccept,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept Ride'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuxColors.sapphire,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteItem extends StatelessWidget {
  const _RouteItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: LuxColors.whiteTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: LuxTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
}
