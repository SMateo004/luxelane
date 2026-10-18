import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:map_launcher/map_launcher.dart' as ml;
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../bloc/driver_bloc.dart';
import '../widgets/flight_info_card.dart';

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
    // Una solicitud nueva se siente en la mano, aunque no se mire la pantalla.
    LuxHaptics.warning();

    showModalBottomSheet<void>(
      context: context,
      // En el navegador raíz, para poder cerrarlo desde el listener.
      useRootNavigator: true,
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
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          _activeSheetId = null;
        },
        onDecline: () {
          context.read<DriverBloc>().add(
                DriverRequestDeclined(bookingId: booking.id),
              );
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          _activeSheetId = null;
        },
      ),
    ).then((_) => _activeSheetId = null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverBloc, DriverState>(
      listenWhen: (prev, curr) {
        if (curr is DriverOnboardingRequired) return true;
        if (curr is! DriverLoaded) return false;
        final prevId = prev is DriverLoaded ? prev.currentRequest?.id : null;
        final currId = curr.currentRequest?.id;
        final prevAvail = prev is DriverLoaded ? prev.isAvailable : false;
        final prevSeq = prev is DriverLoaded ? prev.noticeSeq : 0;
        return prevId != currId ||
            curr.isAvailable != prevAvail ||
            curr.noticeSeq != prevSeq;
      },
      listener: (context, state) {
        if (state is DriverOnboardingRequired) {
          context.go('/driver/onboarding');
          return;
        }
        if (state is DriverLoaded && state.notice != null) {
          showLuxSnackbar(context, state.notice!);
        }
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
            body: EmptyState(
              icon: Icons.wifi_off_rounded,
              message: 'No pudimos abrir tu panel.',
              actionLabel: 'Reintentar',
              onAction: () {
                final auth = context.read<AuthBloc>().state;
                if (auth is AuthAuthenticated) {
                  context
                      .read<DriverBloc>()
                      .add(DriverStarted(userId: auth.user.id));
                }
              },
            ),
          );
        }

        if (state is! DriverLoaded) {
          return Scaffold(
            body: isAuthedDriver
                ? const SafeArea(child: LuxSkeletonList(count: 3))
                : const SizedBox.shrink(),
          );
        }
        final active = state.activeBooking;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: LuxMotion.of(context, LuxMotion.slow),
              switchInCurve: LuxMotion.decelerate,
              switchOutCurve: LuxMotion.accelerate,
              child: active != null
                  ? _ActiveRidePanel(key: ValueKey(active.id), booking: active)
                  : _IdlePanel(key: const ValueKey('idle'), state: state),
            ),
          ),
        );
      },
    );
  }
}

Widget _topLeft(Widget? current, List<Widget> previous) => Stack(
      alignment: Alignment.topLeft,
      children: [...previous, if (current != null) current],
    );

// ── Cabecera ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.title});
  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    final first = name.trim().split(' ').first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (first.isEmpty
                        ? LuxFormat.greeting()
                        : '${LuxFormat.greeting()}, $first')
                    .toUpperCase(),
                style: LuxTypography.eyebrow,
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: LuxMotion.of(context, LuxMotion.base),
                layoutBuilder: _topLeft,
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: LuxTypography.displayMedium
                      .copyWith(fontSize: 30, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ),
        const NotificationBell(color: LuxColors.ink),
      ],
    );
  }
}

// ── Sin viaje activo ───────────────────────────────────────────────────────

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({super.key, required this.state});
  final DriverLoaded state;

  void _toggle(BuildContext context, bool online) {
    final s = context.read<AuthBloc>().state;
    if (s is! AuthAuthenticated) return;
    context
        .read<DriverBloc>()
        .add(DriverAvailabilityToggled(userId: s.user.id, isAvailable: online));
  }

  @override
  Widget build(BuildContext context) {
    final online = state.isAvailable;
    final now = DateTime.now();
    final upcoming = state.bookings
        .where((b) =>
            b.status == BookingStatus.confirmed && b.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final rating = state.profile.rating;
    var i = 0;
    Widget item(Widget w) => LuxFadeIn(index: i++, child: w);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          LuxSpacing.md + 4, LuxSpacing.md, LuxSpacing.md + 4, LuxSpacing.xl),
      children: [
        item(_Header(
          name: state.user.displayName,
          title: online ? 'Estás en línea.' : 'Estás desconectado.',
        )),
        const SizedBox(height: LuxSpacing.lg),
        item(_GoControl(
          online: online,
          classLabel: state.vehicleClass?.label,
          onChanged: (v) => _toggle(context, v),
        )),
        // Lo que impide recibir viajes, dicho claramente.
        if (!state.profile.documentsVerified)
          item(const _Notice(
              'Tus documentos están en revisión. Podrás aceptar viajes '
              'cuando Luxelane los verifique.'))
        else if (state.vehicleClass == null)
          item(const _Notice('No tienes un vehículo activo registrado. Pide a '
              'Luxelane que lo active para recibir solicitudes.')),
        const SizedBox(height: LuxSpacing.xl),
        item(const SectionHeader(title: 'Hoy')),
        const SizedBox(height: LuxSpacing.sm),
        item(Container(
          padding: const EdgeInsets.symmetric(vertical: LuxSpacing.md),
          decoration: BoxDecoration(
            color: LuxColors.surface,
            borderRadius: BorderRadius.circular(LuxRadius.lg),
            border: Border.all(color: LuxColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _Metric(
                    value: 'Bs ${state.todayEarnings.toStringAsFixed(0)}',
                    label: 'Ganancias netas',
                    big: true),
                const LuxDivider(vertical: true),
                _Metric(
                    value: '${state.completedToday.length}', label: 'Viajes'),
                const LuxDivider(vertical: true),
                _Metric(
                    value: rating > 0 ? '★ ${rating.toStringAsFixed(1)}' : '—',
                    label: 'Valoración'),
              ],
            ),
          ),
        )),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: LuxSpacing.xl),
          item(const SectionHeader(title: 'Tus próximas reservas')),
          const SizedBox(height: LuxSpacing.sm),
          item(LuxGroup(children: [
            for (final b in upcoming.take(3))
              LuxListRow(
                icon: Icons.schedule_rounded,
                title: b.serviceType == ServiceType.byTheHour
                    ? '${b.hours ?? 2} h desde ${b.origin.displayName}'
                    : b.destination.displayName,
                subtitle:
                    '${LuxFormat.dateTime(b.scheduledAt)} · ${b.vehicleClass.label}',
                onTap: () => context.push('/driver/active-ride/${b.id}'),
              ),
          ])),
        ],
      ],
    );
  }
}

/// El interruptor principal del chófer: un gran botón redondo. Desconectado
/// invita a conectarse; en línea, unas ondas lentas muestran que la app
/// está buscando viajes.
class _GoControl extends StatefulWidget {
  const _GoControl({
    required this.online,
    required this.onChanged,
    this.classLabel,
  });
  final bool online;
  final ValueChanged<bool> onChanged;
  final String? classLabel;

  @override
  State<_GoControl> createState() => _GoControlState();
}

class _GoControlState extends State<_GoControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waves = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_GoControl old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.online && !LuxMotion.reduced(context)) {
      if (!_waves.isAnimating) _waves.repeat();
    } else {
      _waves.stop();
      _waves.value = 0;
    }
  }

  @override
  void dispose() {
    _waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.online;
    const size = 132.0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: LuxSpacing.xl),
      decoration: BoxDecoration(
        color: online ? LuxColors.sapphireTint : LuxColors.surface,
        borderRadius: BorderRadius.circular(LuxRadius.xl),
        border:
            Border.all(color: online ? Colors.transparent : LuxColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: size * 1.7,
            height: size * 1.7,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (online)
                  AnimatedBuilder(
                    animation: _waves,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final offset in const [0.0, 0.5])
                          Builder(builder: (_) {
                            final t = (_waves.value + offset) % 1.0;
                            return Container(
                              width: size * (1 + 0.7 * t),
                              height: size * (1 + 0.7 * t),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: LuxColors.sapphire
                                      .withValues(alpha: 0.35 * (1 - t)),
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                LuxPressable(
                  onTap: () => widget.onChanged(!online),
                  semanticLabel: online ? 'Desconectarse' : 'Conectarse',
                  scale: 0.94,
                  haptic: false,
                  child: AnimatedContainer(
                    duration: LuxMotion.of(context, LuxMotion.slow),
                    curve: LuxMotion.emphasized,
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online ? LuxColors.surface : LuxColors.sapphire,
                      boxShadow: LuxElevation.mid,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          online
                              ? Icons.radar_rounded
                              : Icons.power_settings_new_rounded,
                          size: 30,
                          color:
                              online ? LuxColors.sapphire : LuxColors.onAccent,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          online ? 'En línea' : 'Conectarse',
                          style: LuxTypography.button.copyWith(
                            fontSize: 14,
                            color: online
                                ? LuxColors.sapphire
                                : LuxColors.onAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            online
                ? 'Buscando viajes${widget.classLabel != null ? ' de ${widget.classLabel}' : ''}'
                : 'Conéctate para recibir solicitudes',
            textAlign: TextAlign.center,
            style: LuxTypography.bodyMedium.copyWith(color: LuxColors.ink),
          ),
          if (online)
            TextButton(
              onPressed: () {
                LuxHaptics.tap();
                widget.onChanged(false);
              },
              child: const Text('Desconectarme'),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.big = false});
  final String value;
  final String label;
  final bool big;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: big ? 4 : 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: LuxTypography.headlineLarge.copyWith(
                  fontSize: big ? 28 : 24,
                  color: LuxColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: LuxTypography.caption),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: LuxSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(LuxSpacing.md),
          decoration: BoxDecoration(
            color: LuxColors.warning.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(LuxRadius.lg),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: LuxColors.warning, size: 20),
            const SizedBox(width: LuxSpacing.sm + 4),
            Expanded(
                child: Text(text,
                    style: LuxTypography.bodyMedium
                        .copyWith(color: LuxColors.ink))),
          ]),
        ),
      );
}

// ── Viaje activo ───────────────────────────────────────────────────────────

class _ActiveRidePanel extends StatelessWidget {
  const _ActiveRidePanel({super.key, required this.booking});
  final Booking booking;

  String get _title => switch (booking.status) {
        BookingStatus.confirmed => 'Dirígete a la recogida.',
        BookingStatus.driverArriving => 'En camino a la recogida.',
        BookingStatus.driverArrived => 'Esperando al pasajero.',
        BookingStatus.inProgress => 'Rumbo al destino.',
        _ => 'Viaje activo.',
      };

  String get _actionLabel => switch (booking.status) {
        BookingStatus.confirmed => 'Salir hacia la recogida',
        BookingStatus.driverArriving => 'He llegado',
        BookingStatus.driverArrived => 'Iniciar viaje',
        BookingStatus.inProgress => 'Completar viaje',
        _ => '',
      };

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
        final url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${target.lat},${target.lng}');
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
        showLuxSnackbar(context, 'No hay aplicaciones de mapas disponibles',
            isError: true);
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
                  child: Text('Navegar hacia ${target.address}',
                      style: LuxTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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
                          child: const Icon(Icons.map_outlined,
                              color: LuxColors.sapphire, size: 24),
                        ),
                        title:
                            Text(map.mapName, style: LuxTypography.bodyLarge),
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
        showLuxSnackbar(context, 'No se pudieron abrir los mapas',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goingToPickup = booking.status == BookingStatus.confirmed ||
        booking.status == BookingStatus.driverArriving ||
        booking.status == BookingStatus.driverArrived;
    final target = goingToPickup ? booking.origin : booking.destination;
    final hourly = booking.serviceType == ServiceType.byTheHour;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LuxSpacing.md + 4, LuxSpacing.md,
                LuxSpacing.md + 4, LuxSpacing.md),
            children: [
              RideProgressBar(status: booking.status),
              const SizedBox(height: LuxSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: LuxMotion.of(context, LuxMotion.base),
                      layoutBuilder: _topLeft,
                      child: Text(
                        _title,
                        key: ValueKey(booking.status),
                        style: LuxTypography.displayMedium.copyWith(
                            fontSize: 30, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                  const NotificationBell(color: LuxColors.ink),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${LuxFormat.dateTime(booking.scheduledAt)} · '
                '${booking.vehicleClass.label} · '
                'Bs ${booking.chargedAmount.toStringAsFixed(0)}',
                style: LuxTypography.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: LuxSpacing.lg),
              LuxGroup(children: [
                _Stop(
                  label: 'Recogida',
                  place: booking.origin,
                  current: goingToPickup,
                ),
                if (!hourly)
                  _Stop(
                    label: 'Destino',
                    place: booking.destination,
                    current: !goingToPickup,
                    last: true,
                  ),
              ]),
              if (!booking.riderPreferences.isEmpty) ...[
                const SizedBox(height: LuxSpacing.md),
                RiderPreferencesNote(preferences: booking.riderPreferences),
              ],
              if (booking.flightNumber?.isNotEmpty == true) ...[
                const SizedBox(height: LuxSpacing.md),
                FlightInfoCard(booking: booking),
              ],
              if (booking.notes?.isNotEmpty == true) ...[
                const SizedBox(height: LuxSpacing.md),
                LuxGroup(children: [
                  LuxListRow(
                    icon: Icons.notes_rounded,
                    title: 'Nota del pasajero',
                    subtitle: booking.notes,
                  ),
                ]),
              ],
            ],
          ),
        ),
        // Acciones fijas abajo, al alcance del pulgar.
        Container(
          padding: const EdgeInsets.fromLTRB(LuxSpacing.md + 4, LuxSpacing.sm,
              LuxSpacing.md + 4, LuxSpacing.md),
          decoration: const BoxDecoration(
            color: LuxColors.surface,
            border: Border(top: BorderSide(color: LuxColors.border)),
          ),
          child: Column(
            children: [
              LuxOutlinedButton(
                label: goingToPickup
                    ? 'Navegar a la recogida'
                    : 'Navegar al destino',
                icon: Icons.navigation_outlined,
                onPressed: () => _openMaps(context, target),
              ),
              const SizedBox(height: LuxSpacing.sm),
              if (_actionLabel.isNotEmpty)
                LuxSlideToConfirm(
                  label: _actionLabel,
                  onConfirmed: () => _advance(context),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Una parada del trayecto; la actual se destaca y respira.
class _Stop extends StatelessWidget {
  const _Stop({
    required this.label,
    required this.place,
    required this.current,
    this.last = false,
  });
  final String label;
  final Place place;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (current) const _PulseIndicator(color: LuxColors.sapphire),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: last ? LuxColors.ink : LuxColors.surface,
                      shape: last ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: last ? BorderRadius.circular(2) : null,
                      border: last
                          ? null
                          : Border.all(color: LuxColors.sapphire, width: 3.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: LuxTypography.eyebrow.copyWith(
                          fontSize: 9,
                          color: current
                              ? LuxColors.sapphire
                              : LuxColors.inkTertiary)),
                  const SizedBox(height: 3),
                  Text(place.displayName,
                      style: LuxTypography.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight:
                              current ? FontWeight.w600 : FontWeight.w500)),
                  if (place.name.isNotEmpty && place.address != place.name)
                    Text(place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxTypography.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator({required this.color});
  final Color color;
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.9).animate(_ctrl),
        child: FadeTransition(
          opacity: Tween(begin: 0.45, end: 0.0).animate(_ctrl),
          child: Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
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
    final b = widget.booking;
    final hourly = b.serviceType == ServiceType.byTheHour;
    final mins = b.scheduledAt.difference(DateTime.now()).inMinutes;
    final when = mins <= 45
        ? (mins <= 1 ? 'Ahora' : 'En $mins min')
        : LuxFormat.dateTime(b.scheduledAt);
    final trip = _route == null
        ? null
        : '${_route!.distanceKm.toStringAsFixed(1)} km · ${_route!.durationMin} min';
    return Container(
      decoration: const BoxDecoration(
        color: LuxColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(LuxRadius.xl + 4)),
        boxShadow: LuxElevation.high,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LuxColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LuxFadeIn(
                child: Column(
                  children: [
                    Text(
                        'NUEVA SOLICITUD · ${b.vehicleClass.label.toUpperCase()}',
                        textAlign: TextAlign.center,
                        style: LuxTypography.eyebrow),
                    const SizedBox(height: 8),
                    Text(
                      'Bs ${b.estimatedPrice.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: LuxTypography.displayLarge
                          .copyWith(fontSize: 52, height: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [when, if (trip != null) trip].join(' · '),
                      textAlign: TextAlign.center,
                      style: LuxTypography.bodyMedium
                          .copyWith(color: LuxColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LuxFadeIn(
                index: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LuxRadius.lg),
                  child: SizedBox(
                    height: 150,
                    child: LuxMap(
                      origin: b.origin,
                      destination: b.destination,
                      routeInfo: _route,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LuxFadeIn(
                index: 2,
                child: LuxGroup(children: [
                  _RouteItem(
                    icon: Icons.radio_button_checked,
                    color: LuxColors.sapphire,
                    label: 'RECOGIDA',
                    address: b.origin.displayName,
                  ),
                  if (!hourly)
                    _RouteItem(
                      icon: Icons.stop_rounded,
                      color: LuxColors.ink,
                      label: 'DESTINO',
                      address: b.destination.displayName,
                    )
                  else
                    _RouteItem(
                      icon: Icons.schedule_rounded,
                      color: LuxColors.ink,
                      label: 'POR HORAS',
                      address: '${b.hours ?? 2} h a disposición',
                    ),
                ]),
              ),
              if (!b.riderPreferences.isEmpty) ...[
                const SizedBox(height: 12),
                RiderPreferencesNote(preferences: b.riderPreferences),
              ],
              if (b.flightNumber?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                FlightInfoCard(booking: b),
              ],
              if (b.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                LuxGroup(children: [
                  LuxListRow(
                    icon: Icons.notes_rounded,
                    title: 'Nota del pasajero',
                    subtitle: b.notes,
                  ),
                ]),
              ],
              const SizedBox(height: 20),
              LuxButton(
                label: 'Aceptar viaje',
                icon: Icons.check_rounded,
                onPressed: widget.onAccept,
              ),
              const SizedBox(height: 4),
              LuxButton.ghost(label: 'Rechazar', onPressed: widget.onDecline),
            ],
          ),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: LuxTypography.eyebrow
                          .copyWith(fontSize: 9, color: LuxColors.inkTertiary)),
                  const SizedBox(height: 3),
                  Text(address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxTypography.titleMedium.copyWith(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );
}
