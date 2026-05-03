import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/booking_form_data.dart';
import '../../../../core/models/place_model.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/widgets/components.dart';
import '../../../../core/widgets/lux_map.dart';
import '../../../../core/widgets/map_picker_dialog.dart';
import '../../../../core/widgets/place_autocomplete_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

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
  DateTime _date = DateTime.now().add(const Duration(hours: 2));
  int _hours = 3;
  bool _locating = false;

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

    if (!mounted) { setState(() => _locating = false); return; }
    setState(() => _locating = false);

    // Open map picker centered on detected/default location
    final picked = await showMapPickerDialog(
      context,
      initial: initial,
      title: 'Select pickup location',
    );
    if (!mounted || picked == null) return;
    setState(() => _origin = picked);
    if (_destination != null) _fetchRoute();
  }

  Future<void> _pickOriginFromMap() async {
    final picked = await showMapPickerDialog(
      context,
      initial: _origin != null
          ? LatLng(_origin!.lat, _origin!.lng)
          : const LatLng(-17.7833, -63.1821),
      title: 'Select pickup location',
    );
    if (!mounted || picked == null) return;
    setState(() => _origin = picked);
    if (_destination != null) _fetchRoute();
  }

  Future<void> _pickDestinationFromMap() async {
    final picked = await showMapPickerDialog(
      context,
      initial: _destination != null
          ? LatLng(_destination!.lat, _destination!.lng)
          : const LatLng(-17.7833, -63.1821),
      title: 'Select destination',
    );
    if (!mounted || picked == null) return;
    setState(() => _destination = picked);
    if (_origin != null) _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (_origin == null || _destination == null) return;
    final route = await _mapsService.getRoute(
      origin: _origin!,
      destination: _destination!,
    );
    if (mounted) setState(() => _routeInfo = route);
  }

  void _onOriginSelected(Place p) {
    setState(() => _origin = p);
    if (_destination != null) _fetchRoute();
  }

  void _onDestinationSelected(Place p) {
    setState(() => _destination = p);
    if (_origin != null) _fetchRoute();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _search() {
    if (_origin == null) {
      showLuxSnackbar(context, 'Enter a pickup location', isError: true);
      return;
    }
    if (_serviceType == ServiceType.oneWay && _destination == null) {
      showLuxSnackbar(context, 'Enter a destination', isError: true);
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

  Widget _mobileLayout() => Scaffold(
        backgroundColor: LuxColors.black,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Web — Landing Page (Blacklane-style)
  // ---------------------------------------------------------------------------

  Widget _webLayout() => Scaffold(
        backgroundColor: LuxColors.black,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero ───────────────────────────────────────────────────
              _WebHero(
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
              ),
              // ── Stats strip ────────────────────────────────────────────
              const _WebStatsStrip(),
              // ── How it works ───────────────────────────────────────────
              const _WebHowItWorks(),
              // ── Fleet ──────────────────────────────────────────────────
              const _WebFleetSection(),
              // ── Chauffeur ──────────────────────────────────────────────
              const _WebChauffeurSection(),
              // ── CTA ────────────────────────────────────────────────────
              const _WebCTASection(),
              // ── Footer ─────────────────────────────────────────────────
              const _WebFooter(),
            ],
          ),
        ),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: LuxSpacing.md, vertical: LuxSpacing.sm),
        child: Row(
          children: [
            const LuxelaneWordmark(),
            const Spacer(),
            _LocateButton(onTap: onLocate, loading: locating),
            const SizedBox(width: LuxSpacing.sm),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final initial = state is AuthAuthenticated
                    ? state.user.displayName[0].toUpperCase()
                    : 'U';
                return GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: LuxColors.blackSurface,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: LuxColors.sapphire,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.onTap, required this.loading});
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LuxColors.blackSurface,
            border: Border.all(color: LuxColors.blackBorder),
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor:
                            AlwaysStoppedAnimation(LuxColors.sapphire)),
                  ),
                )
              : const Icon(Icons.my_location_rounded,
                  size: 18, color: LuxColors.white),
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

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: LuxColors.blackSurface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(LuxRadius.xl)),
          border: Border(top: BorderSide(color: LuxColors.blackBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md, LuxSpacing.sm, LuxSpacing.md, LuxSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: LuxColors.whiteTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: LuxSpacing.md),
            ServiceTypeTab(
                selected: serviceType, onChanged: onServiceTypeChanged),
            const SizedBox(height: LuxSpacing.md),
            _BookingForm(
              serviceType: serviceType,
              origin: origin,
              destination: destination,
              date: date,
              hours: hours,
              locating: false,
              onDateChanged: onDateChanged,
              onHoursChanged: onHoursChanged,
              onOriginSelected: onOriginSelected,
              onDestinationSelected: onDestinationSelected,
              onLocate: onLocate,
              onOriginMapPick: onOriginMapPick,
              onDestinationMapPick: onDestinationMapPick,
            ),
            if (routeInfo != null) ...[
              const SizedBox(height: LuxSpacing.sm),
              _RouteInfoBadge(route: routeInfo!),
            ],
            const SizedBox(height: LuxSpacing.md),
            LuxButton(label: 'Search Vehicles', onPressed: onSearch),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Shared booking form
// ---------------------------------------------------------------------------

class _BookingForm extends StatelessWidget {
  const _BookingForm({
    required this.serviceType,
    required this.origin,
    required this.destination,
    required this.date,
    required this.hours,
    required this.locating,
    required this.onDateChanged,
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
  final DateTime date;
  final int hours;
  final bool locating;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<Place> onOriginSelected;
  final ValueChanged<Place> onDestinationSelected;
  final VoidCallback onLocate;
  final VoidCallback? onOriginMapPick;
  final VoidCallback? onDestinationMapPick;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locBg = isDark ? LuxColors.blackElevated : const Color(0xFFF0EFEb);
    final locIconColor = isDark ? LuxColors.whiteTertiary : const Color(0xFFAAAAAA);
    return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PlaceAutocompleteField(
                  label: 'Pickup Location',
                  hint: 'Calle, barrio, aeropuerto…',
                  prefixIcon: Icons.radio_button_checked_outlined,
                  initialValue: origin,
                  onPlaceSelected: onOriginSelected,
                  onMapPick: onOriginMapPick,
                ),
              ),
              const SizedBox(width: LuxSpacing.sm),
              // Locate / map-pick button
              GestureDetector(
                onTap: onLocate,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: locBg,
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                    border: Border.all(
                      color: isDark ? LuxColors.blackBorder : const Color(0xFFE4E1DA),
                    ),
                  ),
                  child: locating
                      ? Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(locIconColor),
                            ),
                          ),
                        )
                      : Icon(Icons.my_location_rounded,
                          size: 18, color: locIconColor),
                ),
              ),
            ],
          ),
          if (serviceType == ServiceType.oneWay) ...[
            const SizedBox(height: LuxSpacing.sm),
            PlaceAutocompleteField(
              label: 'Destination',
              hint: '¿A dónde vas?',
              prefixIcon: Icons.location_on_outlined,
              initialValue: destination,
              onPlaceSelected: onDestinationSelected,
              onMapPick: onDestinationMapPick,
            ),
          ],
          const SizedBox(height: LuxSpacing.sm),
          _DateTimeTile(date: date, onChanged: onDateChanged),
          if (serviceType == ServiceType.byTheHour) ...[
            const SizedBox(height: LuxSpacing.sm),
            _HourSelector(hours: hours, onChanged: onHoursChanged),
          ],
        ],
      );
  }
}

class _RouteInfoBadge extends StatelessWidget {
  const _RouteInfoBadge({required this.route});
  final RouteInfo route;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: LuxSpacing.md, vertical: LuxSpacing.sm),
        decoration: BoxDecoration(
          color: LuxColors.sapphireSubtle,
          borderRadius: BorderRadius.circular(LuxRadius.sm),
          border: Border.all(color: LuxColors.sapphire.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined,
                size: 16, color: LuxColors.sapphire),
            const SizedBox(width: LuxSpacing.xs),
            Text(
              '${route.distanceKm.toStringAsFixed(1)} km · ${route.durationMin} min',
              style: LuxTypography.caption
                  .copyWith(color: LuxColors.sapphire),
            ),
          ],
        ),
      );
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: LuxColors.sapphire,
                  onPrimary: LuxColors.black,
                  surface: LuxColors.blackSurface,
                ),
              ),
              child: child!,
            ),
          );
          if (picked == null || !context.mounted) return;
          onChanged(DateTime(
              picked.year, picked.month, picked.day, date.hour, date.minute));
        },
        child: Builder(builder: (context) {
          final dark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: dark ? LuxColors.blackElevated : const Color(0xFFF5F4F1),
              borderRadius: BorderRadius.circular(LuxRadius.sm),
              border: Border.all(
                color: dark ? LuxColors.blackBorder : const Color(0xFFE4E1DA),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20,
                    color: dark
                        ? LuxColors.whiteTertiary
                        : const Color(0xFFAAAAAA)),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: Text(
                    _fmt(date),
                    style: TextStyle(
                      color: dark ? LuxColors.white : const Color(0xFF111111),
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      );
}

class _HourSelector extends StatelessWidget {
  const _HourSelector({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        dark ? LuxColors.whiteTertiary : const Color(0xFFAAAAAA);
    final textColor = dark ? LuxColors.white : const Color(0xFF111111);
    final accentColor = dark ? LuxColors.sapphire : const Color(0xFF111111);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? LuxColors.blackElevated : const Color(0xFFF5F4F1),
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        border: Border.all(
          color: dark ? LuxColors.blackBorder : const Color(0xFFE4E1DA),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined, size: 20, color: iconColor),
          const SizedBox(width: LuxSpacing.md),
          Text('Duration',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              )),
          const Spacer(),
          IconButton(
            onPressed: hours > 2 ? () => onChanged(hours - 1) : null,
            icon: Icon(Icons.remove_circle_outline, color: accentColor),
            iconSize: 22,
          ),
          SizedBox(
            width: 40,
            child: Text('${hours}h',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center),
          ),
          IconButton(
            onPressed: hours < 12 ? () => onChanged(hours + 1) : null,
            icon: Icon(Icons.add_circle_outline, color: accentColor),
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Web Landing Page — Blacklane palette: white / warm-white / black, no gold
// ===========================================================================

// ── Palette (landing-page only, overrides dark app theme) ──────────────────
abstract class _LP {
  // Backgrounds
  static const bg          = Color(0xFFFFFFFF); // pure white
  static const bgWarm      = Color(0xFFF6F4F0); // warm off-white
  static const bgDark      = Color(0xFF111111); // dark sections
  // Text
  static const text        = Color(0xFF111111);
  static const textMid     = Color(0xFF666666);
  static const textLight   = Color(0xFF999999);
  static const textInverse = Color(0xFFFFFFFF);
  // Border
  static const border      = Color(0xFFE4E1DA);
  // Button
  static const btnDark     = Color(0xFF111111);
  static const btnLight    = Color(0xFFFFFFFF);
}

// ── Unsplash images ────────────────────────────────────────────────────────
abstract class _Img {
  static const hero =
      'https://images.unsplash.com/photo-1549317661-bd32c8ce0729'
      '?auto=format&fit=crop&w=1920&q=85';
  static const business =
      'https://images.unsplash.com/photo-1555215695-3004980ad54e'
      '?auto=format&fit=crop&w=900&q=85';
  static const firstClass =
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70'
      '?auto=format&fit=crop&w=900&q=85';
  static const van =
      'https://images.unsplash.com/photo-1544636331-e26879cd4d9b'
      '?auto=format&fit=crop&w=900&q=85';
  static const chauffeur =
      'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d'
      '?auto=format&fit=crop&w=1200&q=85';
}

// ── Shared text styles (light context) ─────────────────────────────────────
abstract class _TS {
  static const eyebrow = TextStyle(
    color: _LP.textLight,
    fontSize: 10,
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w600,
    letterSpacing: 3,
  );
  static const h1 = TextStyle(
    color: _LP.text,
    fontSize: 54,
    fontFamily: 'Cormorant',
    fontWeight: FontWeight.w300,
    height: 1.06,
    letterSpacing: -0.5,
  );
  static const h2 = TextStyle(
    color: _LP.text,
    fontSize: 40,
    fontFamily: 'Cormorant',
    fontWeight: FontWeight.w300,
    height: 1.1,
  );
  static const h3 = TextStyle(
    color: _LP.text,
    fontSize: 18,
    fontFamily: 'Cormorant',
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  static const body = TextStyle(
    color: _LP.textMid,
    fontSize: 13,
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w300,
    height: 1.85,
    letterSpacing: 0.1,
  );
  static const label = TextStyle(
    color: _LP.textLight,
    fontSize: 9,
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w600,
    letterSpacing: 2.5,
  );
  // inverse (on dark)
  static const h1Inv = TextStyle(
    color: _LP.textInverse,
    fontSize: 54,
    fontFamily: 'Cormorant',
    fontWeight: FontWeight.w300,
    height: 1.06,
    letterSpacing: -0.5,
  );
  static const bodyInv = TextStyle(
    color: Color(0xFFAAAAAA),
    fontSize: 13,
    fontFamily: 'Montserrat',
    fontWeight: FontWeight.w300,
    height: 1.85,
  );
}

// ===========================================================================
// HERO — full-bleed photo, dark overlay, headline + booking card
// ===========================================================================

class _WebHero extends StatelessWidget {
  const _WebHero({
    required this.serviceType,
    required this.origin,
    required this.destination,
    required this.date,
    required this.hours,
    required this.locating,
    required this.routeInfo,
    required this.onServiceTypeChanged,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onDateChanged,
    required this.onHoursChanged,
    required this.onLocate,
    required this.onSearch,
    this.onOriginMapPick,
    this.onDestinationMapPick,
  });

  final ServiceType serviceType;
  final Place? origin;
  final Place? destination;
  final DateTime date;
  final int hours;
  final bool locating;
  final RouteInfo? routeInfo;
  final ValueChanged<ServiceType> onServiceTypeChanged;
  final ValueChanged<Place> onOriginSelected;
  final ValueChanged<Place> onDestinationSelected;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onHoursChanged;
  final VoidCallback onLocate;
  final VoidCallback onSearch;
  final VoidCallback? onOriginMapPick;
  final VoidCallback? onDestinationMapPick;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 700,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // photo
            Image.network(_Img.hero,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF1A1A1A))),
            // gradient: strong left, lighter right
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xD9000000), Color(0x7A000000), Color(0x55000000)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Row(
                children: [
                  // headline side
                  Expanded(
                    flex: 55,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PROFESSIONAL CHAUFFEUR SERVICE',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 10,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3,
                            )),
                        const SizedBox(height: 24),
                        const Text(
                          'Your journey,\nperfectly\ndriven.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 68,
                            fontFamily: 'Cormorant',
                            fontWeight: FontWeight.w300,
                            height: 1.02,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Fixed prices · Professional drivers\nAvailable in 50+ countries worldwide.',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w300,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Row(children: [
                          const _HStat('50+', 'COUNTRIES'),
                          _HDivider(),
                          const _HStat('4.9 / 5', 'RATING'),
                          _HDivider(),
                          const _HStat('24 / 7', 'SUPPORT'),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 56),
                  // booking card — white on dark photo
                  SizedBox(
                    width: 400,
                    child: _BookingCard(
                      serviceType: serviceType,
                      origin: origin,
                      destination: destination,
                      date: date,
                      hours: hours,
                      locating: locating,
                      routeInfo: routeInfo,
                      onServiceTypeChanged: onServiceTypeChanged,
                      onOriginSelected: onOriginSelected,
                      onDestinationSelected: onDestinationSelected,
                      onDateChanged: onDateChanged,
                      onHoursChanged: onHoursChanged,
                      onLocate: onLocate,
                      onSearch: onSearch,
                      onOriginMapPick: onOriginMapPick,
                      onDestinationMapPick: onDestinationMapPick,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HStat extends StatelessWidget {
  const _HStat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Cormorant',
                fontWeight: FontWeight.w400,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 9,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              )),
        ],
      );
}

class _HDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: const Color(0xFF333333),
          margin: const EdgeInsets.symmetric(horizontal: 32));
}

// ===========================================================================
// BOOKING CARD — white, light theme inputs
// ===========================================================================

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.serviceType,
    required this.origin,
    required this.destination,
    required this.date,
    required this.hours,
    required this.locating,
    required this.routeInfo,
    required this.onServiceTypeChanged,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onDateChanged,
    required this.onHoursChanged,
    required this.onLocate,
    required this.onSearch,
    this.onOriginMapPick,
    this.onDestinationMapPick,
  });

  final ServiceType serviceType;
  final Place? origin;
  final Place? destination;
  final DateTime date;
  final int hours;
  final bool locating;
  final RouteInfo? routeInfo;
  final ValueChanged<ServiceType> onServiceTypeChanged;
  final ValueChanged<Place> onOriginSelected;
  final ValueChanged<Place> onDestinationSelected;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onHoursChanged;
  final VoidCallback onLocate;
  final VoidCallback onSearch;
  final VoidCallback? onOriginMapPick;
  final VoidCallback? onDestinationMapPick;

  @override
  Widget build(BuildContext context) {
    // Override theme to LIGHT so PlaceAutocompleteField and other
    // brightness-aware widgets render dark text on the white card.
    final lightTheme = Theme.of(context).copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF111111),
        secondary: Color(0xFF555555),
        onSecondary: Colors.white,
        onSurface: Color(0xFF111111),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F4F1),
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 13,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w300,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          fontFamily: 'Montserrat',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFF111111)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: const Color(0xFF111111),
            displayColor: const Color(0xFF111111),
          ),
      iconTheme: const IconThemeData(color: Color(0xFF888888), size: 18),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Theme(
        data: lightTheme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plan your journey',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 22,
                  fontFamily: 'Cormorant',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                )),
            const SizedBox(height: 4),
            const Text('Fixed price · No surge pricing',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 11,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.3,
                )),
            const SizedBox(height: 24),
            // Service tabs — restyled for light
            _LightServiceTabs(
                selected: serviceType, onChanged: onServiceTypeChanged),
            const SizedBox(height: 16),
            _BookingForm(
              serviceType: serviceType,
              origin: origin,
              destination: destination,
              date: date,
              hours: hours,
              locating: locating,
              onDateChanged: onDateChanged,
              onHoursChanged: onHoursChanged,
              onOriginSelected: onOriginSelected,
              onDestinationSelected: onDestinationSelected,
              onLocate: onLocate,
              onOriginMapPick: onOriginMapPick,
              onDestinationMapPick: onDestinationMapPick,
            ),
            if (routeInfo != null) ...[
              const SizedBox(height: 12),
              _RouteInfoBadge(route: routeInfo!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                  textStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
                child: const Text('GET PRICES'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightServiceTabs extends StatelessWidget {
  const _LightServiceTabs({required this.selected, required this.onChanged});
  final ServiceType selected;
  final ValueChanged<ServiceType> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: ServiceType.values.map((t) {
          final active = t == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t),
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF111111) : const Color(0xFFF0EFEb),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: EdgeInsets.only(
                    right: t != ServiceType.values.last ? 4 : 0),
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF888888),
                    fontSize: 11,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
}

// ===========================================================================
// STATS — warm-white bg, clean numbers
// ===========================================================================

class _WebStatsStrip extends StatelessWidget {
  const _WebStatsStrip();

  @override
  Widget build(BuildContext context) => Container(
        color: _LP.bgWarm,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _StatItem('150,000+', 'RIDES COMPLETED'),
            _SDivider(),
            const _StatItem('50+', 'COUNTRIES'),
            _SDivider(),
            const _StatItem('4.9 / 5', 'AVERAGE RATING'),
            _SDivider(),
            const _StatItem('24 / 7', 'SUPPORT'),
          ],
        ),
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 30,
                fontFamily: 'Cormorant',
                fontWeight: FontWeight.w400,
              )),
          const SizedBox(height: 4),
          Text(label, style: _TS.label),
        ]),
      );
}

class _SDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: _LP.border);
}

// ===========================================================================
// HOW IT WORKS — white bg
// ===========================================================================

class _WebHowItWorks extends StatelessWidget {
  const _WebHowItWorks();

  static const _steps = [
    ('01', 'Enter your journey',
     'Specify pickup, destination and date.\nYour fixed price is calculated instantly.'),
    ('02', 'Choose your vehicle',
     'Select from Business, First Class or Van.\nEvery model is premium and recent.'),
    ('03', 'Relax and arrive',
     'Your chauffeur is punctual, uniformed\nand meets you door to door.'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: _LP.bg,
        padding: const EdgeInsets.fromLTRB(96, 96, 96, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOW IT WORKS', style: _TS.eyebrow),
            const SizedBox(height: 16),
            const Text('Simple.\nTransparent.\nReliable.', style: _TS.h1),
            const SizedBox(height: 72),
            // thin divider
            Container(height: 1, color: _LP.border),
            const SizedBox(height: 56),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _steps.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _steps.length - 1 ? 48 : 0),
                      child: _HowStep(
                        number: _steps[i].$1,
                        title: _steps[i].$2,
                        body: _steps[i].$3,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _HowStep extends StatelessWidget {
  const _HowStep(
      {required this.number, required this.title, required this.body});
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number,
              style: const TextStyle(
                color: Color(0xFFE8E5DF),
                fontSize: 80,
                fontFamily: 'Cormorant',
                fontWeight: FontWeight.w700,
                height: 1,
              )),
          const SizedBox(height: 20),
          Text(title, style: _TS.h3),
          const SizedBox(height: 10),
          Container(width: 28, height: 1, color: const Color(0xFFCCCAC6)),
          const SizedBox(height: 16),
          Text(body, style: _TS.body),
        ],
      );
}

// ===========================================================================
// FLEET — warm-white bg, photo cards
// ===========================================================================

class _WebFleetSection extends StatelessWidget {
  const _WebFleetSection();

  static const _vehicles = [
    ('BUSINESS CLASS',
     'Mercedes E-Class or equivalent. The standard of elegance for every transfer.',
     _Img.business),
    ('FIRST CLASS',
     'Mercedes S-Class or equivalent. Our highest tier of comfort and refinement.',
     _Img.firstClass),
    ('BUSINESS VAN',
     'Mercedes V-Class or equivalent. Space and privacy for groups up to 7.',
     _Img.van),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: _LP.bgWarm,
        padding: const EdgeInsets.fromLTRB(96, 80, 96, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OUR FLEET', style: _TS.eyebrow),
                    SizedBox(height: 16),
                    Text('Premium vehicles,\nno exceptions.', style: _TS.h1),
                  ],
                ),
                Spacer(),
                SizedBox(
                  width: 340,
                  child: Text(
                    'Every vehicle is less than five years old, '
                    'fully licensed and impeccably maintained.',
                    style: _TS.body,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 56),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _vehicles.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _vehicles.length - 1 ? 24 : 0),
                      child: _FleetCard(
                        name: _vehicles[i].$1,
                        desc: _vehicles[i].$2,
                        img: _vehicles[i].$3,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _FleetCard extends StatelessWidget {
  const _FleetCard(
      {required this.name, required this.desc, required this.img});
  final String name;
  final String desc;
  final String img;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // photo
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFFE8E5DF))),
          ),
          const SizedBox(height: 20),
          Text(name, style: _TS.label.copyWith(color: const Color(0xFF111111))),
          const SizedBox(height: 10),
          Container(width: 24, height: 1, color: _LP.border),
          const SizedBox(height: 12),
          Text(desc, style: _TS.body),
        ],
      );
}

// ===========================================================================
// CHAUFFEUR — white bg, split image + text
// ===========================================================================

class _WebChauffeurSection extends StatelessWidget {
  const _WebChauffeurSection();

  @override
  Widget build(BuildContext context) => Container(
        color: _LP.bg,
        child: Row(children: [
          // photo
          Expanded(
            child: SizedBox(
              height: 520,
              child: Image.network(_Img.chauffeur,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: _LP.bgWarm)),
            ),
          ),
          // text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('PROFESSIONAL CHAUFFEURS', style: _TS.eyebrow),
                  const SizedBox(height: 20),
                  const Text('Vetted, trained\nand always on time.', style: _TS.h2),
                  const SizedBox(height: 32),
                  ...[
                    'Minimum 5 years of professional experience',
                    'Full background screening and continuous review',
                    'Multilingual and culturally aware',
                    'Uniformed, discreet and punctual',
                  ].map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 14,
                              height: 1,
                              margin: const EdgeInsets.only(top: 10),
                              color: const Color(0xFFBBBBBB),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(s, style: _TS.body)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ]),
      );
}

// ===========================================================================
// CTA — dark section
// ===========================================================================

class _WebCTASection extends StatelessWidget {
  const _WebCTASection();

  @override
  Widget build(BuildContext context) => Container(
        color: _LP.bgDark,
        padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 88),
        child: Row(children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your next journey\nstarts here.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontFamily: 'Cormorant',
                      fontWeight: FontWeight.w300,
                      height: 1.1,
                    )),
                SizedBox(height: 16),
                Text('Book in under 2 minutes. Fixed price guaranteed.',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 13,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.2,
                    )),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111111),
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(
                    ),
                textStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
              child: const Text('BOOK NOW'),
            ),
          ),
        ]),
      );
}

// ===========================================================================
// FOOTER
// ===========================================================================

class _WebFooter extends StatelessWidget {
  const _WebFooter();

  @override
  Widget build(BuildContext context) => Container(
        color: _LP.bgDark,
        padding: const EdgeInsets.fromLTRB(96, 0, 96, 40),
        child: Column(children: [
          Container(height: 1, color: const Color(0xFF1E1E1E)),
          const SizedBox(height: 48),
          const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // brand
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LUXELANE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      )),
                  SizedBox(height: 12),
                  Text('Professional chauffeur\nservice worldwide.',
                      style: TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w300,
                        height: 1.8,
                      )),
                ],
              ),
            ),
            _FCol('SERVICES', ['One Way Transfer', 'By The Hour', 'Airport Transfer', 'Corporate']),
            _FCol('COMPANY',  ['About Us', 'For Business', 'Become a Driver', 'Press']),
            _FCol('SUPPORT',  ['Help Center', 'Terms', 'Privacy Policy', 'Contact']),
          ]),
          const SizedBox(height: 48),
          Row(children: [
            Text('© ${DateTime.now().year} Luxelane. All rights reserved.',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 11,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w300,
                )),
            const Spacer(),
            const Text('Worldwide luxury transportation',
                style: TextStyle(
                  color: Color(0xFF2A2A2A),
                  fontSize: 11,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w300,
                )),
          ]),
        ]),
      );
}

class _FCol extends StatelessWidget {
  const _FCol(this.title, this.links);
  final String title;
  final List<String> links;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _TS.label),
            const SizedBox(height: 16),
            ...links.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(l,
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w300,
                      )),
                )),
          ],
        ),
      );
}
