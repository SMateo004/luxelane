import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../special/presentation/widgets/special_services_sheet.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/design/lux_promise.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/booking_form_data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/personalization/rider_insights.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/utils/service_area.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../../core/widgets/map_picker_dialog.dart';
import '../../../../core/widgets/place_autocomplete_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import 'home_web_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mapsService = sl<MapsService>();

  ServiceType _serviceType = ServiceType.oneWay;
  Place? _origin;
  Place? _destination;
  RouteInfo? _routeInfo;
  DateTime _date = LuxFormat.nextQuarter();
  int _hours = 3;
  bool _locating = false;
  VehicleClass? _preferredClass;

  // Personalización: se recalcula con cada cambio en sus reservas.
  RiderInsights _insights = RiderInsights.empty;
  StreamSubscription<List<Booking>>? _bookingsSub;
  String? _watchedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watchRider(context.read<AuthBloc>().state);
  }

  void _watchRider(AuthState state) {
    final uid = state is AuthAuthenticated ? state.user.id : null;
    if (uid == _watchedUid) return;
    _watchedUid = uid;
    _bookingsSub?.cancel();
    _bookingsSub = null;
    if (uid == null) {
      setState(() => _insights = RiderInsights.empty);
      return;
    }
    _bookingsSub =
        sl<BookingRepository>().watchBookingsByRider(uid).listen((list) {
      if (!mounted) return;
      final insights = RiderInsights.from(list);
      setState(() {
        _insights = insights;
        // Su clase habitual queda propuesta, sin imponerla.
        _preferredClass ??= insights.favoriteClass;
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  /// Repite un viaje anterior: mismos lugares, nueva hora.
  void _repeat(Booking b) {
    setState(() {
      _serviceType = b.serviceType == ServiceType.byTheHour
          ? ServiceType.byTheHour
          : ServiceType.oneWay;
      _origin = b.origin;
      _destination =
          b.serviceType == ServiceType.byTheHour ? null : b.destination;
      _routeInfo = null;
      _preferredClass = b.vehicleClass;
      if (b.hours != null) _hours = b.hours!;
    });
    if (_destination != null) _fetchRoute();
  }

  /// Un lugar habitual completa lo que falte: primero el destino.
  void _usePlace(Place p) {
    if (_origin != null && _serviceType == ServiceType.oneWay) {
      _onDestinationSelected(p);
    } else {
      _onOriginSelected(p);
    }
  }

  // ---------------------------------------------------------------------------
  // Location & Route
  // ---------------------------------------------------------------------------

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final pos = await _mapsService.getCurrentPosition();

    LatLng initial;
    if (pos != null) {
      initial = LatLng(pos.latitude, pos.longitude);
    } else {
      // Default to Santa Cruz de la Sierra center
      initial = const LatLng(-17.7833, -63.1821);
    }

    if (!mounted) return;
    setState(() => _locating = false);

    // Open map picker centered on detected/default location
    final picked = await showMapPickerDialog(
      context,
      initial: initial,
      title: 'Seleccionar lugar de recogida',
    );
    if (!mounted || picked == null) return;
    _onOriginSelected(picked);
  }

  Future<void> _pickOriginFromMap() async {
    final picked = await showMapPickerDialog(
      context,
      initial: _origin != null
          ? LatLng(_origin!.lat, _origin!.lng)
          : const LatLng(-17.7833, -63.1821),
      title: 'Seleccionar lugar de recogida',
    );
    if (!mounted || picked == null) return;
    _onOriginSelected(picked);
  }

  Future<void> _pickDestinationFromMap() async {
    final picked = await showMapPickerDialog(
      context,
      initial: _destination != null
          ? LatLng(_destination!.lat, _destination!.lng)
          : _origin != null && ServiceArea.hasCoords(_origin!)
              ? LatLng(_origin!.lat, _origin!.lng)
              : const LatLng(-17.7833, -63.1821),
      title: 'Seleccionar destino',
    );
    if (!mounted || picked == null) return;
    _onDestinationSelected(picked);
  }

  Future<void> _fetchRoute() async {
    if (_origin == null || _destination == null) return;
    final route = await _mapsService.getRoute(
      origin: _origin!,
      destination: _destination!,
    );
    if (mounted) setState(() => _routeInfo = route);
  }

  /// A destination in another city than the new pickup no longer applies.
  void _onOriginSelected(Place p) {
    final dest = _destination;
    final stale = dest != null && ServiceArea.destinationError(p, dest) != null;
    setState(() {
      _origin = p;
      if (stale) {
        _destination = null;
        _routeInfo = null;
      }
    });
    if (stale) {
      showLuxSnackbar(context,
          'El destino estaba en otra ciudad. Elige uno en la ciudad de recogida.',
          isError: true);
    } else if (_destination != null) {
      _fetchRoute();
    }
  }

  void _onDestinationSelected(Place p) {
    final error =
        _origin == null ? null : ServiceArea.destinationError(_origin!, p);
    if (error != null) {
      showLuxSnackbar(context, error, isError: true);
      return;
    }
    setState(() => _destination = p);
    if (_origin != null) _fetchRoute();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _search() {
    if (_origin == null) {
      showLuxSnackbar(context, 'Ingresa un lugar de recogida', isError: true);
      return;
    }
    final originError = ServiceArea.originError(_origin!);
    if (originError != null) {
      showLuxSnackbar(context, originError, isError: true);
      return;
    }
    // La pantalla de inicio sigue viva entre visitas: una hora elegida (o la
    // de por defecto) puede haber quedado en el pasado.
    final later = adjustedPickup(_date);
    if (later != null) {
      setState(() => _date = later);
      showLuxSnackbar(
          context,
          'Esa hora ya no da tiempo: la movimos a '
          '${LuxFormat.dateTime(later)}. Revísala y continúa.',
          isError: true);
      return;
    }
    if (_serviceType == ServiceType.oneWay && _destination == null) {
      showLuxSnackbar(context, 'Ingresa un destino', isError: true);
      return;
    }
    final cityError = _destination == null
        ? null
        : ServiceArea.destinationError(_origin!, _destination!);
    if (cityError != null) {
      showLuxSnackbar(context, cityError, isError: true);
      return;
    }
    context.go(
      '/booking',
      extra: BookingFormData(
        origin: _origin!,
        destination: _destination,
        serviceType: _serviceType,
        scheduledAt: _date,
        hours: _hours,
        routeDistanceKm: _routeInfo?.distanceKm ?? 0,
        routeDurationMin: _routeInfo?.durationMin ?? 0,
        polylinePoints: _routeInfo?.polylinePoints ?? [],
        preferredClass: _preferredClass,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) =>
      isWeb(context) ? _webLayout() : _mobileLayout();

  // ---------------------------------------------------------------------------
  // Mobile
  // ---------------------------------------------------------------------------

  Widget _mobileLayout() => BlocListener<AuthBloc, AuthState>(
        listener: (_, state) => _watchRider(state),
        child: Scaffold(
          backgroundColor: LuxColors.bg,
          body: Stack(
            children: [
              Positioned.fill(
                child: LuxMap(
                  origin: _origin,
                  destination: _destination,
                  routeInfo: _routeInfo,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _MobileTopBar(
                      onLocate: _detectLocation,
                      locating: _locating,
                    ),
                    const Spacer(),
                    _MobileBottomPanel(
                      serviceType: _serviceType,
                      onServiceTypeChanged: (t) =>
                          setState(() => _serviceType = t),
                      origin: _origin,
                      destination: _destination,
                      date: _date,
                      hours: _hours,
                      onDateChanged: (d) => setState(() => _date = d),
                      onHoursChanged: (h) => setState(() => _hours = h),
                      onOriginSelected: _onOriginSelected,
                      onDestinationSelected: _onDestinationSelected,
                      onSearch: _search,
                      onLocate: _detectLocation,
                      onOriginMapPick: _pickOriginFromMap,
                      onDestinationMapPick: _pickDestinationFromMap,
                      routeInfo: _routeInfo,
                      insights: _insights,
                      preferredClass: _preferredClass,
                      onPlaceChip: _usePlace,
                      onRepeat: _repeat,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Web — New editorial landing page
  // ---------------------------------------------------------------------------

  Widget _webLayout() => WebHomePage(
        serviceType: _serviceType,
        origin: _origin,
        destination: _destination,
        date: _date,
        hours: _hours,
        locating: _locating,
        routeInfo: _routeInfo,
        onServiceTypeChanged: (t) => setState(() => _serviceType = t),
        onOriginSelected: _onOriginSelected,
        onDestinationSelected: _onDestinationSelected,
        onDateChanged: (d) => setState(() => _date = d),
        onHoursChanged: (h) => setState(() => _hours = h),
        onLocate: _detectLocation,
        onSearch: _search,
        onOriginMapPick: _pickOriginFromMap,
        onDestinationMapPick: _pickDestinationFromMap,
        onChooseClass: (vc) => setState(() => _preferredClass = vc),
      );
}

// ---------------------------------------------------------------------------
// Mobile sub-widgets
// ---------------------------------------------------------------------------

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.onLocate, required this.locating});
  final VoidCallback onLocate;
  final bool locating;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        // Ivory scrim so the brand mark stays legible over any map tile.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF2FAFBFE), Color(0x00FAFBFE)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              LuxSpacing.md + 4, LuxSpacing.sm, LuxSpacing.md, LuxSpacing.lg),
          child: Row(
            children: [
              const LuxelaneWordmark(size: 11),
              const Spacer(),
              const NotificationBell(),
              const SizedBox(width: LuxSpacing.sm),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final name =
                      state is AuthAuthenticated ? state.user.displayName : '';
                  return Semantics(
                    button: true,
                    label: 'Mi perfil',
                    child: GestureDetector(
                      onTap: () => context.go(
                          state is AuthAuthenticated ? '/profile' : '/login'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LuxColors.sapphire,
                          border:
                              Border.all(color: LuxColors.surface, width: 2),
                          boxShadow: luxSoftShadow,
                        ),
                        alignment: Alignment.center,
                        child: name.isNotEmpty
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Cormorant Garamond',
                                  color: LuxColors.onAccent,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                ),
                              )
                            : const Icon(Icons.person_outline_rounded,
                                size: 18, color: LuxColors.onAccent),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class _MobileBottomPanel extends StatelessWidget {
  const _MobileBottomPanel({
    required this.serviceType,
    required this.onServiceTypeChanged,
    required this.origin,
    required this.destination,
    required this.date,
    required this.hours,
    required this.onDateChanged,
    required this.onHoursChanged,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onSearch,
    required this.onLocate,
    required this.insights,
    required this.onPlaceChip,
    required this.onRepeat,
    this.preferredClass,
    this.onOriginMapPick,
    this.onDestinationMapPick,
    this.routeInfo,
  });

  final ServiceType serviceType;
  final ValueChanged<ServiceType> onServiceTypeChanged;
  final Place? origin;
  final Place? destination;
  final DateTime date;
  final int hours;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<Place> onOriginSelected;
  final ValueChanged<Place> onDestinationSelected;
  final VoidCallback onSearch;
  final VoidCallback onLocate;
  final VoidCallback? onOriginMapPick;
  final VoidCallback? onDestinationMapPick;
  final RouteInfo? routeInfo;
  final RiderInsights insights;
  final VehicleClass? preferredClass;
  final ValueChanged<Place> onPlaceChip;
  final ValueChanged<Booking> onRepeat;

  @override
  Widget build(BuildContext context) {
    final next = insights.nextTrip;
    final last = insights.lastTrip;
    // Los lugares que ya están elegidos no se vuelven a sugerir.
    final chips = insights.recentPlaces
        .where((p) =>
            p.displayName != origin?.displayName &&
            p.displayName != destination?.displayName)
        .take(3)
        .toList();
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
      decoration: const BoxDecoration(
        color: LuxColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(LuxRadius.xl + 4)),
        boxShadow: [
          BoxShadow(
              color: LuxColors.shadow, blurRadius: 32, offset: Offset(0, -8)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md + 4, LuxSpacing.sm, LuxSpacing.md + 4, LuxSpacing.lg),
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
            const SizedBox(height: LuxSpacing.md),
            LuxFadeIn(child: _Greeting(nextTrip: next)),
            if (next != null) ...[
              const SizedBox(height: LuxSpacing.md),
              LuxFadeIn(index: 1, child: _NextTripCard(booking: next)),
            ],
            const SizedBox(height: LuxSpacing.md + 4),
            LuxFadeIn(
              index: 2,
              child: ServiceTypeTab(
                  selected: serviceType, onChanged: onServiceTypeChanged),
            ),
            const SizedBox(height: LuxSpacing.sm + 4),
            LuxFadeIn(
              index: 3,
              child: _RouteCard(
                serviceType: serviceType,
                origin: origin,
                destination: destination,
                hours: hours,
                onHoursChanged: onHoursChanged,
                onOriginSelected: onOriginSelected,
                onDestinationSelected: onDestinationSelected,
                onLocate: onLocate,
                onOriginMapPick: onOriginMapPick,
                onDestinationMapPick: onDestinationMapPick,
              ),
            ),
            if (chips.isNotEmpty || last != null) ...[
              const SizedBox(height: LuxSpacing.sm + 4),
              LuxFadeIn(
                index: 4,
                child: _PlaceChips(
                  places: chips,
                  last: origin == null ? last : null,
                  onPlace: onPlaceChip,
                  onRepeat: onRepeat,
                ),
              ),
            ],
            const SizedBox(height: LuxSpacing.sm + 4),
            LuxFadeIn(
                index: 5,
                child: _DateTimeTile(date: date, onChanged: onDateChanged)),
            AnimatedSize(
              duration: LuxMotion.of(context, LuxMotion.base),
              curve: LuxMotion.emphasized,
              child: routeInfo == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: LuxSpacing.sm + 4),
                      child: _RouteInfoBadge(
                          route: routeInfo!, preferredClass: preferredClass),
                    ),
            ),
            const SizedBox(height: LuxSpacing.md + 4),
            LuxFadeIn(
              index: 6,
              child: LuxButton(
                label: 'Ver vehículos y precios',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: onSearch,
              ),
            ),
            const SizedBox(height: LuxSpacing.sm + 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: LuxSpacing.md,
              runSpacing: 4,
              children: [
                for (final p in const [
                  LuxPromise.fixedPrice,
                  LuxPromise.freeCancel
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 12, color: LuxColors.inkTertiary),
                      const SizedBox(width: 4),
                      Text(p, style: LuxTypography.caption),
                    ],
                  ),
              ],
            ),
            // Servicios especiales (aerotaxi, paseos): al final y en voz baja.
            const Center(child: MoreServicesLink()),
          ],
        ),
      ),
    );
  }
}

/// Saludo personal según la hora y lo que tiene por delante.
class _Greeting extends StatelessWidget {
  const _Greeting({this.nextTrip});
  final Booking? nextTrip;

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final full =
              state is AuthAuthenticated ? state.user.displayName.trim() : '';
          final first = full.isEmpty ? '' : full.split(' ').first;
          final now = DateTime.now();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (first.isEmpty
                        ? LuxFormat.greeting(now)
                        : '${LuxFormat.greeting(now)}, $first')
                    .toUpperCase(),
                style: LuxTypography.eyebrow,
              ),
              const SizedBox(height: 6),
              Text(
                contextualPrompt(now, nextTrip: nextTrip),
                style: LuxTypography.displayMedium.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          );
        },
      );
}

/// El viaje que viene, siempre a mano: hora, destino y estado.
class _NextTripCard extends StatelessWidget {
  const _NextTripCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final hourly = booking.serviceType == ServiceType.byTheHour;
    final where = hourly
        ? '${booking.hours ?? 2} h desde ${booking.origin.displayName}'
        : booking.destination.displayName;
    return LuxPressable(
      onTap: () => context.go('/ride/${booking.id}'),
      semanticLabel: 'Ver tu próximo trayecto',
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: LuxColors.sapphireTint,
          borderRadius: BorderRadius.circular(LuxRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: LuxColors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                LuxFormat.time(booking.scheduledAt),
                style: LuxTypography.caption.copyWith(
                    color: LuxColors.sapphire, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: LuxSpacing.md - 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TU PRÓXIMO TRAYECTO',
                      style: LuxTypography.eyebrow.copyWith(fontSize: 9)),
                  const SizedBox(height: 3),
                  Text(
                    where,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxTypography.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LuxFormat.dateTime(booking.scheduledAt),
                    style: LuxTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: LuxSpacing.sm),
            BookingStatusChip(status: booking.status),
          ],
        ),
      ),
    );
  }
}

/// Recogida y destino en una sola tarjeta, unidos por una línea: se lee
/// como un trayecto, no como dos formularios.
class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.serviceType,
    required this.origin,
    required this.destination,
    required this.hours,
    required this.onHoursChanged,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onLocate,
    this.onOriginMapPick,
    this.onDestinationMapPick,
  });

  final ServiceType serviceType;
  final Place? origin;
  final Place? destination;
  final int hours;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<Place> onOriginSelected;
  final ValueChanged<Place> onDestinationSelected;
  final VoidCallback onLocate;
  final VoidCallback? onOriginMapPick;
  final VoidCallback? onDestinationMapPick;

  @override
  Widget build(BuildContext context) {
    final oneWay = serviceType == ServiceType.oneWay;
    return Container(
      decoration: BoxDecoration(
        color: LuxColors.surface,
        borderRadius: BorderRadius.circular(LuxRadius.lg),
        border: Border.all(color: LuxColors.border),
      ),
      child: Stack(
        children: [
          // Hilo que une recogida y destino.
          if (oneWay)
            const Positioned(
              left: 21.5,
              top: 30,
              bottom: 30,
              child: SizedBox(
                width: 1,
                child: ColoredBox(color: LuxColors.border),
              ),
            ),
          Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 16),
                  const _RouteDot(),
                  Expanded(
                    child: PlaceAutocompleteField(
                      label: 'Lugar de recogida',
                      hint: 'Recogida',
                      bare: true,
                      initialValue: origin,
                      onPlaceSelected: onOriginSelected,
                      onMapPick: onOriginMapPick,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Usar mi ubicación',
                    onPressed: () {
                      LuxHaptics.tap();
                      onLocate();
                    },
                    icon: const Icon(Icons.near_me_outlined,
                        size: 20, color: LuxColors.sapphire),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 44),
                child: LuxDivider(),
              ),
              if (oneWay)
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const _RouteDot(square: true),
                    Expanded(
                      child: PlaceAutocompleteField(
                        label: 'Destino',
                        hint: '¿A dónde vas?',
                        bare: true,
                        initialValue: destination,
                        sameCityAs: origin,
                        onPlaceSelected: onDestinationSelected,
                        onMapPick: onDestinationMapPick,
                      ),
                    ),
                    if (onDestinationMapPick != null)
                      IconButton(
                        tooltip: 'Elegir en el mapa',
                        onPressed: () {
                          LuxHaptics.tap();
                          onDestinationMapPick!();
                        },
                        icon: const Icon(Icons.map_outlined,
                            size: 20, color: LuxColors.inkTertiary),
                      ),
                  ],
                )
              else
                _HourSelector(hours: hours, onChanged: onHoursChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  const _RouteDot({this.square = false});
  final bool square;

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: square ? LuxColors.ink : LuxColors.surface,
          shape: square ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: square ? BorderRadius.circular(2) : null,
          border:
              square ? null : Border.all(color: LuxColors.sapphire, width: 3.5),
        ),
      );
}

/// Atajos personales: sus lugares de siempre y repetir el último viaje.
class _PlaceChips extends StatelessWidget {
  const _PlaceChips({
    required this.places,
    required this.onPlace,
    required this.onRepeat,
    this.last,
  });

  final List<Place> places;
  final Booking? last;
  final ValueChanged<Place> onPlace;
  final ValueChanged<Booking> onRepeat;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            if (last != null)
              _Chip(
                icon: Icons.replay_rounded,
                label: 'Repetir último',
                emphasized: true,
                onTap: () => onRepeat(last!),
              ),
            for (final p in places)
              _Chip(
                icon: Icons.history_rounded,
                label: p.displayName,
                onTap: () => onPlace(p),
              ),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: LuxSpacing.sm),
        child: LuxPressable(
          onTap: onTap,
          semanticLabel: label,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: emphasized ? LuxColors.sapphireTint : LuxColors.surface,
              borderRadius: BorderRadius.circular(LuxRadius.xl),
              border: Border.all(
                  color: emphasized ? Colors.transparent : LuxColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 15,
                    color: emphasized
                        ? LuxColors.sapphire
                        : LuxColors.inkTertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxTypography.caption.copyWith(
                      fontSize: 12,
                      color: emphasized ? LuxColors.sapphire : LuxColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RouteInfoBadge extends StatelessWidget {
  const _RouteInfoBadge({required this.route, this.preferredClass});
  final RouteInfo route;
  final VehicleClass? preferredClass;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.route_outlined,
              size: 16, color: LuxColors.inkTertiary),
          const SizedBox(width: 6),
          Text(
            '${route.distanceKm.toStringAsFixed(1)} km · ${route.durationMin} min',
            style: LuxTypography.caption
                .copyWith(color: LuxColors.ink, fontSize: 12),
          ),
          if (preferredClass != null) ...[
            const Spacer(),
            Flexible(
              child: Text(
                'Tu ${preferredClass!.label}',
                overflow: TextOverflow.ellipsis,
                style: LuxTypography.caption
                    .copyWith(color: LuxColors.sapphire, fontSize: 12),
              ),
            ),
          ],
        ],
      );
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: date.isBefore(now) ? now : date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'FECHA DE RECOGIDA',
      cancelText: 'Cancelar',
      confirmText: 'Siguiente',
    );
    if (d == null || !context.mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date),
      helpText: 'HORA DE RECOGIDA',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (t == null || !context.mounted) return;
    var picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    final earliest = now.add(const Duration(minutes: 30));
    if (picked.isBefore(earliest)) picked = earliest;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final soon = date.difference(DateTime.now()).inMinutes <= 45;
    return LuxPressable(
      onTap: () => _pick(context),
      semanticLabel: 'Cambiar fecha y hora de recogida',
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: LuxColors.surfaceMuted,
          borderRadius: BorderRadius.circular(LuxRadius.lg),
        ),
        child: Row(
          children: [
            Icon(soon ? Icons.bolt_rounded : Icons.event_outlined,
                size: 18, color: LuxColors.ink),
            const SizedBox(width: LuxSpacing.md - 4),
            Expanded(
              child: Text(
                soon
                    ? 'Lo antes posible · ${LuxFormat.time(date)}'
                    : LuxFormat.dateTime(date),
                style: LuxTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            Text('Programar',
                style: LuxTypography.caption.copyWith(
                    color: LuxColors.sapphire,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: LuxColors.sapphire),
          ],
        ),
      ),
    );
  }
}

class _HourSelector extends StatelessWidget {
  const _HourSelector({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 6, 2),
        child: Row(
          children: [
            const Icon(Icons.schedule_outlined,
                size: 18, color: LuxColors.inkTertiary),
            const SizedBox(width: LuxSpacing.md - 2),
            Text('Duración',
                style: LuxTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w500, fontSize: 14)),
            const Spacer(),
            _StepButton(
              icon: Icons.remove_rounded,
              onTap: hours > 2 ? () => onChanged(hours - 1) : null,
            ),
            SizedBox(
              width: 48,
              child: AnimatedSwitcher(
                duration: LuxMotion.of(context, LuxMotion.fast),
                transitionBuilder: (c, a) =>
                    FadeTransition(opacity: a, child: c),
                child: Text('${hours}h',
                    key: ValueKey(hours),
                    textAlign: TextAlign.center,
                    style: LuxTypography.titleLarge),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              onTap: hours < 24 ? () => onChanged(hours + 1) : null,
            ),
          ],
        ),
      );
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LuxPressable(
        onTap: onTap,
        scale: 0.9,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: LuxColors.border),
          ),
          child: Icon(icon,
              size: 18,
              color: onTap == null ? LuxColors.border : LuxColors.ink),
        ),
      );
}
