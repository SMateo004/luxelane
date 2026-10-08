import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
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
import '../../../../l10n/l10n.dart';
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
      title: context.l10n.homePickPickupTitle,
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
      title: context.l10n.homePickPickupTitle,
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
      title: context.l10n.homePickDestinationTitle,
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
      showLuxSnackbar(context, context.l10n.homeErrorPickupRequired, isError: true);
      return;
    }
    if (_serviceType == ServiceType.oneWay && _destination == null) {
      showLuxSnackbar(context, context.l10n.homeErrorDestinationRequired, isError: true);
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
        backgroundColor: const Color(0xFF0D1B2E),
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
            const SizedBox(width: LuxSpacing.xs),
            const NotificationBell(),
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
                        color: LuxColors.accent,
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
                            AlwaysStoppedAnimation(LuxColors.accent)),
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
            LuxButton(label: context.l10n.homeSearchVehicles, onPressed: onSearch),
            const SizedBox(height: LuxSpacing.sm),
            // City to city: popular routes out of Santa Cruz.
            TextButton.icon(
              onPressed: () => context.push('/servicios/ciudad-a-ciudad'),
              icon: const Icon(Icons.route_outlined, size: 18, color: LuxColors.accent),
              label: Text(context.l10n.intercityHomeLink,
                  style: const TextStyle(color: LuxColors.accent)),
            ),
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
    final l = context.l10n;
    return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PlaceAutocompleteField(
                  label: l.homeFormPickupLabel,
                  hint: l.homeFormPickupHint,
                  prefixIcon: Icons.radio_button_checked_outlined,
                  initialValue: origin,
                  onPlaceSelected: onOriginSelected,
                  onMapPick: onOriginMapPick,
                ),
              ),
              const SizedBox(width: LuxSpacing.sm),
              // Locate / map-pick button
              Tooltip(
                message: l.homeLocateMe,
                child: GestureDetector(
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
              ),
            ],
          ),
          if (serviceType == ServiceType.oneWay) ...[
            const SizedBox(height: LuxSpacing.sm),
            PlaceAutocompleteField(
              label: l.homeBarDestination,
              hint: l.homeBarDestinationHint,
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
          color: LuxColors.accentSubtle,
          borderRadius: BorderRadius.circular(LuxRadius.sm),
          border: Border.all(color: LuxColors.accent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined,
                size: 16, color: LuxColors.accent),
            const SizedBox(width: LuxSpacing.xs),
            Flexible(
              child: Text(
                context.l10n.homeRouteSummary(
                  NumberFormat.decimalPatternDigits(decimalDigits: 1)
                      .format(route.distanceKm),
                  localizedDuration(
                      context.l10n, Duration(minutes: route.durationMin)),
                ),
                style: LuxTypography.caption
                    .copyWith(color: LuxColors.accent),
              ),
            ),
          ],
        ),
      );
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  String _fmt(AppLocalizations l, DateTime d) =>
      l.homeDateTimeShort(DateFormat.yMMMEd().format(d), DateFormat.jm().format(d));

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
                  primary: LuxColors.accent,
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
                    _fmt(context.l10n, date),
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
    final accentColor = dark ? LuxColors.accent : const Color(0xFF111111);
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
          Expanded(
            child: Text(context.l10n.homeBarDuration,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
              )),
          ),
          IconButton(
            onPressed: hours > 2 ? () => onChanged(hours - 1) : null,
            icon: Icon(Icons.remove_circle_outline, color: accentColor),
            iconSize: 22,
          ),
          SizedBox(
            width: 40,
            child: Text(context.l10n.homeHoursShort(hours),
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
