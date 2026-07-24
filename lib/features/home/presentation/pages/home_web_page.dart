import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show GoogleMap, GoogleMapController, CameraPosition, CameraUpdate,
         Marker, MarkerId;
import 'package:video_player/video_player.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/place_model.dart';
import '../../../../core/widgets/place_autocomplete_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import 'home_design.dart';

// ============================================================
// WebHomePage
// ============================================================

class WebHomePage extends StatefulWidget {
  const WebHomePage({
    super.key,
    required this.serviceType,
    required this.origin,
    required this.destination,
    required this.date,
    required this.hours,
    required this.locating,
    required this.onServiceTypeChanged,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onDateChanged,
    required this.onHoursChanged,
    required this.onLocate,
    required this.onSearch,
    required this.onOriginMapPick,
    required this.onDestinationMapPick,
    required this.routeInfo,
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
  final VoidCallback onOriginMapPick;
  final VoidCallback onDestinationMapPick;

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  final _scroll     = ScrollController();
  final _luxScroll  = LuxScrollNotifier();
  double _scrollY   = 0;

  // Section keys — used for scroll-to-section navigation
  final _fleetKey    = GlobalKey();
  final _businessKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final y = _scroll.offset;
      setState(() => _scrollY = y);
      _luxScroll.update(y);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _luxScroll.dispose();
    super.dispose();
  }

  /// Smoothly scroll so that [key]'s widget is at the top of the viewport.
  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) return;
      final dy = box.localToGlobal(Offset.zero).dy;
      final target = (_scroll.offset + dy - 72).clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 700),
        curve: const Cubic(0.16, 1, 0.3, 1),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LD.dark,
      body: LuxScrollProvider(
        notifier: _luxScroll,
        child: Stack(
          children: [
            // ── Main scrollable content ──────────────────────────────
            SingleChildScrollView(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 72px spacer — reserved for fixed nav overlay
                  const SizedBox(height: 72),

                  // ── Hero ─────────────────────────────────────────────
                  _HeroSection(
                    serviceType:           widget.serviceType,
                    origin:                widget.origin,
                    destination:           widget.destination,
                    date:                  widget.date,
                    hours:                 widget.hours,
                    locating:              widget.locating,
                    onServiceTypeChanged:  widget.onServiceTypeChanged,
                    onOriginSelected:      widget.onOriginSelected,
                    onDestinationSelected: widget.onDestinationSelected,
                    onDateChanged:         widget.onDateChanged,
                    onHoursChanged:        widget.onHoursChanged,
                    onLocate:              widget.onLocate,
                    onSearch:              widget.onSearch,
                    onOriginMapPick:       widget.onOriginMapPick,
                    onDestinationMapPick:  widget.onDestinationMapPick,
                    scrollY:               _scrollY,
                  ),

                  // ── Marquee ticker ────────────────────────────────────
                  const _MarqueeBar(),

                  // ── Book portfolio (scroll-driven 3D flip) ────────────
                  const _BookSection(),

                  // ── Fleet horizontal carousel ─────────────────────────
                  _FleetSection(
                    sectionKey: _fleetKey,
                    onBook: widget.onSearch,
                  ),

                  // ── Testimonials ──────────────────────────────────────
                  const _TestimonialsSection(),

                  // ── Business split ────────────────────────────────────
                  _BusinessSection(
                    sectionKey:  _businessKey,
                    onLearnMore: widget.onSearch,
                  ),

                  // ── CTA full-bleed ────────────────────────────────────
                  _CtaSection(
                    onBook:      widget.onSearch,
                    onViewFleet: () => _scrollToKey(_fleetKey),
                  ),

                  // ── Footer ───────────────────────────────────────────
                  _FooterSection(
                    onFleet:      () => _scrollToKey(_fleetKey),
                    onServices:   () => _scrollToKey(_fleetKey),
                    onBusiness:   () => _scrollToKey(_businessKey),
                  ),
                ],
              ),
            ),

            // ── Fixed nav overlay (on top of scroll) ────────────────
            _LuxNav(
              scrollY:    _scrollY,
              onFleet:    () => _scrollToKey(_fleetKey),
              onServices: () => _scrollToKey(_fleetKey),
              onBusiness: () => _scrollToKey(_businessKey),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Fixed Nav
// ============================================================

class _LuxNav extends StatelessWidget {
  const _LuxNav({
    required this.scrollY,
    required this.onFleet,
    required this.onServices,
    required this.onBusiness,
  });

  final double scrollY;
  final VoidCallback onFleet;
  final VoidCallback onServices;
  final VoidCallback onBusiness;

  @override
  Widget build(BuildContext context) {
    final scrolled = scrollY > 60;
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 900;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 72,
      decoration: BoxDecoration(
        color: scrolled ? const Color(0xF5070E18) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? Colors.white.withAlpha(25) : Colors.transparent,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 24 : 56),
        child: Row(
          children: [
            // Logo → always goes home
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/'),
                child: const _LuxLogo(light: true),
              ),
            ),
            const Spacer(),
            // Hide nav links on narrow screens — keep only CTA
            if (!narrow) ...[
              const _ServicesDropdownLink(),
              const SizedBox(width: 32),
              _NavLink('Flota',        light: true, onTap: onFleet),
              const SizedBox(width: 32),
              _NavLink('Para empresas',light: true, onTap: onBusiness),
              const SizedBox(width: 40),
            ],
            // Auth-aware right side
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, auth) {
                if (auth is AuthAuthenticated) {
                  return Row(children: [
                    if (!narrow) _NavCta(onTap: () => ctx.go('/')),
                    if (!narrow) const SizedBox(width: 12),
                    const NotificationBell(color: Colors.white),
                    const SizedBox(width: 8),
                    _AvatarDot(
                      name:  auth.user.displayName,
                      onTap: () => ctx.go('/profile'),
                    ),
                  ]);
                }
                return _NavCta(onTap: () => ctx.go('/'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxLogo extends StatelessWidget {
  const _LuxLogo({this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              border: Border.all(
                color: light ? Colors.white.withAlpha(200) : LD.ink,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                'L',
                style: TextStyle(
                  fontFamily: kSerif, fontSize: 15, fontWeight: FontWeight.w500,
                  color: light ? Colors.white : LD.ink,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LUXELANE',
            style: TextStyle(
              fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w600,
              letterSpacing: 3.0,
              color: light ? Colors.white : LD.ink,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      );
}

class _NavLink extends StatefulWidget {
  const _NavLink(this.label, {required this.onTap, this.light = false});
  final String label;
  final VoidCallback onTap;
  final bool light;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontFamily: kSans, fontSize: 11, fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
              color: _hover
                  ? (widget.light ? Colors.white : LD.ink)
                  : (widget.light ? Colors.white.withAlpha(160) : LD.ink3),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
}

// ── Services dropdown nav link ────────────────────────────────────────────────

class _ServicesDropdownLink extends StatefulWidget {
  const _ServicesDropdownLink();

  @override
  State<_ServicesDropdownLink> createState() => _ServicesDropdownLinkState();
}

class _ServicesDropdownLinkState extends State<_ServicesDropdownLink> {
  bool _hover = false;
  bool _dropHover = false;
  final _portalController = OverlayPortalController();
  final _key = GlobalKey();

  void _show() {
    setState(() => _hover = true);
    if (!_portalController.isShowing) _portalController.show();
  }

  void _hide() {
    setState(() => _hover = false);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_dropHover && mounted) {
        _portalController.hide();
      }
    });
  }

  static const _items = [
    ('Recogida inmediata',       '/servicios/recogida-inmediata'),
    ('Traslado al aeropuerto',   '/servicios/traslado-aeropuerto'),
    ('Contratación por horas',   '/servicios/contratacion-por-horas'),
  ];

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (_) {
          final box = _key.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return const SizedBox.shrink();
          final offset = box.localToGlobal(Offset.zero);
          final size   = box.size;
          return Positioned(
            left: offset.dx - 12,
            top:  offset.dy + size.height + 4,
            child: MouseRegion(
              onEnter: (_) => setState(() => _dropHover = true),
              onExit:  (_) {
                setState(() => _dropHover = false);
                _hide();
              },
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1220),
                  border: Border.all(color: const Color(0xFF1A2B40)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _items.map((item) => _DropItem(
                    label: item.$1,
                    onTap: () {
                      _portalController.hide();
                      context.go(item.$2);
                    },
                  )).toList(),
                ),
              ),
            ),
          );
        },
        child: MouseRegion(
          key: _key,
          onEnter: (_) => _show(),
          onExit:  (_) => _hide(),
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SERVICIOS',
                style: TextStyle(
                  fontFamily: kSans, fontSize: 11, fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                  color: _hover ? Colors.white : Colors.white.withAlpha(160),
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: _hover ? Colors.white : Colors.white.withAlpha(160),
              ),
            ],
          ),
        ),
      );
}

class _DropItem extends StatefulWidget {
  const _DropItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_DropItem> createState() => _DropItemState();
}

class _DropItemState extends State<_DropItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _hover ? const Color(0xFF1B4F8A).withAlpha(30) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 3, height: 3,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B4F8A), shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                    color: _hover ? Colors.white : Colors.white.withAlpha(180),
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavCta extends StatefulWidget {
  const _NavCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_NavCta> createState() => _NavCtaState();
}

class _NavCtaState extends State<_NavCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            color: _hover ? LD.sphLt : LD.sph,
            child: const Text(
              'RESERVAR UN VIAJE',
              style: TextStyle(
                fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w500,
                letterSpacing: 1.8, color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: LD.sphTint),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontFamily: kSans, fontSize: 13, fontWeight: FontWeight.w500,
                color: LD.sph, decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// Hero Section
// ============================================================

class _HeroSection extends StatefulWidget {
  const _HeroSection({
    required this.serviceType,
    required this.origin,
    required this.destination,
    required this.date,
    required this.hours,
    required this.locating,
    required this.onServiceTypeChanged,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onDateChanged,
    required this.onHoursChanged,
    required this.onLocate,
    required this.onSearch,
    required this.onOriginMapPick,
    required this.onDestinationMapPick,
    required this.scrollY,
  });

  final ServiceType serviceType;
  final Place? origin;
  final Place? destination;
  final DateTime date;
  final int hours;
  final bool locating;
  final ValueChanged<ServiceType> onServiceTypeChanged;
  final ValueChanged<Place> onOriginSelected;
  final ValueChanged<Place> onDestinationSelected;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onHoursChanged;
  final VoidCallback onLocate;
  final VoidCallback onSearch;
  final VoidCallback onOriginMapPick;
  final VoidCallback onDestinationMapPick;
  final double scrollY;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _intro;

  // ── Map-drawer state (independent per field) ──────────────────
  bool   _originMapOpen = false;
  bool   _destMapOpen   = false;
  Place? _originMapPlace;
  Place? _destMapPlace;

  // ── Inline date/time panel state ───────────────────────────────
  bool _dateOpen = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();
  }

  @override
  void didUpdateWidget(_HeroSection old) {
    super.didUpdateWidget(old);
    // Track new locations
    if (widget.origin != old.origin && widget.origin != null) {
      setState(() { _originMapPlace = widget.origin; _originMapOpen = true; });
    }
    if (widget.destination != old.destination && widget.destination != null) {
      setState(() { _destMapPlace = widget.destination; _destMapOpen = true; });
    }
    // Service-type switch: hide dest map for "Por horas", restore for "Solo ida"
    if (widget.serviceType != old.serviceType) {
      if (widget.serviceType == ServiceType.byTheHour) {
        setState(() => _destMapOpen = false);
      } else if (widget.serviceType == ServiceType.oneWay &&
                 _destMapPlace != null &&
                 (_destMapPlace!.lat != 0.0 || _destMapPlace!.lng != 0.0)) {
        setState(() => _destMapOpen = true);
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _fade(double from, double to) => CurvedAnimation(
        parent: _intro,
        curve: Interval(from, to, curve: Curves.easeOut),
      );

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height - 72;
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 900;
    final isOneWay = widget.serviceType == ServiceType.oneWay;

    return SizedBox(
      height: h,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Full-bleed luxury photo
          const Positioned.fill(child: _HeroBg()),

          // Top vignette — nav legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF060C16).withAlpha(210),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38],
                ),
              ),
            ),
          ),

          // Bottom gradient — booking bar legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF060C16).withAlpha(240),
                    const Color(0xFF060C16).withAlpha(160),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.65],
                ),
              ),
            ),
          ),

          // ── Bottom-anchored column: headline + bar + map drawer ──
          // Everything lives here so they all slide up together when
          // the drawer opens (column grows upward since it's pinned bottom).
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _fade(0.35, 1.0),
              child: Padding(
                padding: EdgeInsets.fromLTRB(narrow ? 20 : 56, 0, narrow ? 20 : 56, narrow ? 28 : 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Headline ────────────────────────────────────
                    Center(
                      child: _ClipReveal(
                        delay: const Duration(milliseconds: 300),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Tu chofer ',
                                style: displayText(size: narrow ? 52 : 100, color: Colors.white),
                              ),
                              TextSpan(
                                text: 'te espera.',
                                style: displayText(
                                  size: narrow ? 52 : 100, color: Colors.white,
                                  style: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Service pill toggle ──────────────────────────
                    _ServicePillToggle(
                      isOneWay: isOneWay,
                      onChanged: widget.onServiceTypeChanged,
                    ),
                    const SizedBox(height: 12),

                    // ── Liquid-glass booking bar ──────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          // No fixed height on narrow — content determines size
                          height: narrow ? null : 84,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withAlpha(55),
                            ),
                          ),
                          child: narrow
                              // ── Mobile: stacked fields ──────────────
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _BarField(
                                      label: 'RECOGIDA',
                                      icon: Icons.radio_button_checked,
                                      child: PlaceAutocompleteField(
                                        label: '¿Dónde estás?',
                                        hint: '¿Dónde estás?',
                                        initialValue: widget.origin,
                                        onPlaceSelected: widget.onOriginSelected,
                                        onMapPick: widget.onOriginMapPick,
                                        glass: true,
                                      ),
                                    ),
                                    Container(height: 1, color: Colors.white.withAlpha(30)),
                                    isOneWay
                                        ? _BarField(
                                            label: 'DESTINO',
                                            icon: Icons.south,
                                            child: PlaceAutocompleteField(
                                              label: '¿A dónde vas?',
                                              initialValue: widget.destination,
                                              onPlaceSelected: widget.onDestinationSelected,
                                              onMapPick: widget.onDestinationMapPick,
                                              glass: true,
                                            ),
                                          )
                                        : _BarField(
                                            label: 'DURACIÓN',
                                            icon: Icons.schedule_outlined,
                                            child: _HoursPicker(
                                              hours: widget.hours,
                                              onChanged: widget.onHoursChanged,
                                            ),
                                          ),
                                    Container(height: 1, color: Colors.white.withAlpha(30)),
                                    _BarField(
                                      label: 'FECHA Y HORA',
                                      icon: Icons.calendar_today_outlined,
                                      child: _DateDisplayTrigger(
                                        date: widget.date,
                                        isOpen: _dateOpen,
                                        onTap: () => setState(
                                            () => _dateOpen = !_dateOpen),
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(13),
                                        bottomRight: Radius.circular(13),
                                      ),
                                      child: _BarCta(onTap: widget.onSearch),
                                    ),
                                  ],
                                )
                              // ── Desktop: horizontal row ──────────────
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _BarField(
                                        label: 'RECOGIDA',
                                        icon: Icons.radio_button_checked,
                                        child: PlaceAutocompleteField(
                                          label: '¿Dónde estás?',
                                          hint: '¿Dónde estás?',
                                          initialValue: widget.origin,
                                          onPlaceSelected: widget.onOriginSelected,
                                          onMapPick: widget.onOriginMapPick,
                                          glass: true,
                                        ),
                                      ),
                                    ),
                                    const _BarSeparator(),
                                    Expanded(
                                      flex: 3,
                                      child: isOneWay
                                          ? _BarField(
                                              label: 'DESTINO',
                                              icon: Icons.south,
                                              child: PlaceAutocompleteField(
                                                label: '¿A dónde vas?',
                                                initialValue: widget.destination,
                                                onPlaceSelected: widget.onDestinationSelected,
                                                onMapPick: widget.onDestinationMapPick,
                                                glass: true,
                                              ),
                                            )
                                          : _BarField(
                                              label: 'DURACIÓN',
                                              icon: Icons.schedule_outlined,
                                              child: _HoursPicker(
                                                hours: widget.hours,
                                                onChanged: widget.onHoursChanged,
                                              ),
                                            ),
                                    ),
                                    const _BarSeparator(),
                                    Expanded(
                                      flex: 2,
                                      child: _BarField(
                                        label: 'FECHA Y HORA',
                                        icon: Icons.calendar_today_outlined,
                                        child: _DateDisplayTrigger(
                                          date: widget.date,
                                          isOpen: _dateOpen,
                                          onTap: () => setState(
                                              () => _dateOpen = !_dateOpen),
                                        ),
                                      ),
                                    ),
                                    _BarCta(onTap: widget.onSearch),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    // ── Inline panels row — aligns with bar columns ──────
                    // Each panel uses the same flex as its bar column so they
                    // sit perfectly below their respective field.
                    // Hidden on narrow screens (panels don't fit in small widths).
                    if (!narrow && (_originMapOpen || _destMapOpen || _dateOpen))
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup map
                          Expanded(
                            flex: 3,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeInOut,
                              child: _originMapOpen &&
                                      _originMapPlace != null &&
                                      (_originMapPlace!.lat != 0.0 ||
                                       _originMapPlace!.lng != 0.0)
                                  ? _InlineMapPanel(
                                      place: _originMapPlace!,
                                      label: 'RECOGIDA',
                                      onChangeTap: widget.onOriginMapPick,
                                      onClose: () => setState(
                                          () => _originMapOpen = false),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 1),
                          // Destination map
                          Expanded(
                            flex: 3,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeInOut,
                              child: _destMapOpen &&
                                      _destMapPlace != null &&
                                      (_destMapPlace!.lat != 0.0 ||
                                       _destMapPlace!.lng != 0.0)
                                  ? _InlineMapPanel(
                                      place: _destMapPlace!,
                                      label: 'DESTINO',
                                      onChangeTap: widget.onDestinationMapPick,
                                      onClose: () => setState(
                                          () => _destMapOpen = false),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 1),
                          // Date / time inline panel
                          Expanded(
                            flex: 2,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeInOut,
                              child: _dateOpen
                                  ? _InlineDatePanel(
                                      date: widget.date,
                                      onChanged: (d) {
                                        widget.onDateChanged(d);
                                        setState(() => _dateOpen = false);
                                      },
                                      onClose: () =>
                                          setState(() => _dateOpen = false),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 180), // matches _BarCta
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBg extends StatelessWidget {
  const _HeroBg();
  static const _asset = 'assets/images/home/hero_bg.png';

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF060C16), Color(0xFF0D1B2E), Color(0xFF091525)],
              ),
            ),
          ),
          CustomPaint(painter: _DotGridPainter(), child: const SizedBox.expand()),
          Image.asset(
            _asset, fit: BoxFit.cover,
            width: double.infinity, height: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x0FFFFFFF);
    const s = 40.0;
    for (double x = s; x < size.width;  x += s)
    for (double y = s; y < size.height; y += s)
      canvas.drawCircle(Offset(x, y), 1.2, p);
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

class _ClipReveal extends StatefulWidget {
  const _ClipReveal({required this.child, required this.delay});
  final Widget child;
  final Duration delay;

  @override
  State<_ClipReveal> createState() => _ClipRevealState();
}

class _ClipRevealState extends State<_ClipReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Cubic(0.16, 1, 0.3, 1)));
    Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ClipRect(
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ============================================================
// Inline Map Panel
// Grayscale Google Map anchored below its booking-bar field.
// ============================================================

// Dark navy map style — matches the date/time panel background (0xFF090F1A)
// so all inline panels feel visually unified.
const _kDarkMapStyle = '''[
  {"elementType":"geometry",
   "stylers":[{"color":"#090f1a"}]},
  {"elementType":"labels.text.stroke",
   "stylers":[{"color":"#090f1a"}]},
  {"elementType":"labels.text.fill",
   "stylers":[{"color":"#3a5f8a"}]},
  {"featureType":"administrative","elementType":"geometry",
   "stylers":[{"color":"#1a2b3c"}]},
  {"featureType":"poi","elementType":"all",
   "stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry",
   "stylers":[{"color":"#1a2538"}]},
  {"featureType":"road","elementType":"geometry.stroke",
   "stylers":[{"color":"#0d1624"}]},
  {"featureType":"road","elementType":"labels.text.fill",
   "stylers":[{"color":"#4a6a8a"}]},
  {"featureType":"road.highway","elementType":"geometry",
   "stylers":[{"color":"#1e3455"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill",
   "stylers":[{"color":"#6a90b8"}]},
  {"featureType":"transit","elementType":"all",
   "stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry",
   "stylers":[{"color":"#030b14"}]},
  {"featureType":"water","elementType":"labels.text.fill",
   "stylers":[{"color":"#1a3a5a"}]}
]''';

class _InlineMapPanel extends StatefulWidget {
  const _InlineMapPanel({
    required this.place,
    required this.label,
    required this.onChangeTap,
    required this.onClose,
  });

  final Place        place;
  final String       label;       // 'RECOGIDA' or 'DESTINO'
  final VoidCallback onChangeTap;
  final VoidCallback onClose;

  @override
  State<_InlineMapPanel> createState() => _InlineMapPanelState();
}

class _InlineMapPanelState extends State<_InlineMapPanel> {
  GoogleMapController? _ctrl;

  @override
  void didUpdateWidget(_InlineMapPanel old) {
    super.didUpdateWidget(old);
    // Animate camera when the selected place changes
    if (widget.place != old.place) {
      _ctrl?.animateCamera(
        CameraUpdate.newLatLng(widget.place.latLng),
      );
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      height: 220,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: Stack(
        children: [
          // ── Grayscale map ─────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.place.latLng,
              zoom: 15,
            ),
            onMapCreated: (ctrl) {
              _ctrl = ctrl;
              ctrl.setMapStyle(_kDarkMapStyle);
            },
            markers: {
              Marker(
                markerId: const MarkerId('pin'),
                position: widget.place.latLng,
              ),
            },
            zoomControlsEnabled:    false,
            mapToolbarEnabled:      false,
            myLocationButtonEnabled: false,
            liteModeEnabled: !kIsWeb,
          ),

          // ── "Cambiar ubicación" button — bottom-left ──────────────
          Positioned(
            bottom: 10, left: 10,
            child: GestureDetector(
              onTap: widget.onChangeTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  color: const Color(0xEE060C16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_location_alt_outlined,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'CAMBIAR UBICACIÓN',
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Close button — top-right ──────────────────────────────
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: widget.onClose,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  color: const Color(0xCC060C16),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicePillToggle extends StatelessWidget {
  const _ServicePillToggle({required this.isOneWay, required this.onChanged});
  final bool isOneWay;
  final ValueChanged<ServiceType> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pill(label: 'Solo ida',   selected: isOneWay,  onTap: () => onChanged(ServiceType.oneWay)),
            _Pill(label: 'Por horas',  selected: !isOneWay, onTap: () => onChanged(ServiceType.byTheHour)),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kSans, fontSize: 11, fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: selected ? LD.ink : Colors.white.withAlpha(170),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
}

class _BarField extends StatelessWidget {
  const _BarField({required this.label, required this.icon, required this.child});
  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 11, color: Colors.white.withAlpha(160)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontFamily: kSans, fontSize: 9.5, fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: Colors.white.withAlpha(160),
                decoration: TextDecoration.none,
              )),
            ]),
            const SizedBox(height: 5),
            child,
          ],
        ),
      );
}

class _BarSeparator extends StatelessWidget {
  const _BarSeparator();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.white.withAlpha(50));
}

class _BarCta extends StatefulWidget {
  const _BarCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BarCta> createState() => _BarCtaState();
}

class _BarCtaState extends State<_BarCta> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight:    Radius.circular(13),
              bottomRight: Radius.circular(13),
            ),
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 180,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _hover ? LD.sphLt : LD.sph,
              border: Border(
                left: BorderSide(color: Colors.white.withAlpha(40)),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'VER OPCIONES',
              style: TextStyle(
                fontFamily: kSans, fontSize: 10.5, fontWeight: FontWeight.w600,
                letterSpacing: 2.2, color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          ),   // ClipRRect
        ),
      );
}

// ── Shared button widgets ─────────────────────────────────────

class _SolidBtn extends StatefulWidget {
  const _SolidBtn({required this.label, required this.onTap, this.white = false});
  final String label;
  final VoidCallback onTap;
  final bool white;

  @override
  State<_SolidBtn> createState() => _SolidBtnState();
}

class _SolidBtnState extends State<_SolidBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit:  (_) => setState(() => _h = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            color: widget.white
                ? (_h ? const Color(0xFFE8EDF7) : Colors.white)
                : (_h ? LD.sphLt : LD.sph),
            child: Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: widget.white ? LD.ink : Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
}

class _GhostBtn extends StatefulWidget {
  const _GhostBtn({required this.label, required this.onTap, this.light = false});
  final String label;
  final VoidCallback onTap;
  final bool light;

  @override
  State<_GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<_GhostBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit:  (_) => setState(() => _h = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _h
                    ? (widget.light ? Colors.white : LD.ink)
                    : (widget.light ? Colors.white.withAlpha(90) : LD.border),
              ),
              color: _h
                  ? (widget.light ? Colors.white.withAlpha(20) : LD.bg3)
                  : Colors.transparent,
            ),
            child: Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w500,
                letterSpacing: 1.8,
                color: widget.light
                    ? (_h ? Colors.white : Colors.white.withAlpha(166))
                    : LD.ink,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
}

// ── Date / Hours pickers ──────────────────────────────────────

// ── Date display trigger (inside the white bar) ───────────────────────────────
// Just shows the formatted date and a chevron; tapping toggles the inline panel.

class _DateDisplayTrigger extends StatelessWidget {
  const _DateDisplayTrigger({
    required this.date,
    required this.isOpen,
    required this.onTap,
  });
  final DateTime date;
  final bool     isOpen;
  final VoidCallback onTap;

  String _fmt(DateTime d) {
    const m = ['Ene','Feb','Mar','Abr','May','Jun',
                'Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${m[d.month-1]} ${d.day},  '
           '${d.hour.toString().padLeft(2,'0')}:'
           '${d.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(children: [
            Text(_fmt(date), style: const TextStyle(
              fontFamily: kSans, fontSize: 13, color: Colors.white,
              decoration: TextDecoration.none,
            )),
            const Spacer(),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(Icons.expand_more, size: 16,
                  color: Colors.white.withAlpha(160)),
            ),
          ]),
        ),
      );
}

// ── Inline date + time panel ──────────────────────────────────────────────────

class _InlineDatePanel extends StatefulWidget {
  const _InlineDatePanel({
    required this.date,
    required this.onChanged,
    required this.onClose,
  });
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClose;

  @override
  State<_InlineDatePanel> createState() => _InlineDatePanelState();
}

class _InlineDatePanelState extends State<_InlineDatePanel> {
  late DateTime _month;    // first-day of the browsed month
  late DateTime _selected; // full date being built

  static const _monthNames = [
    'Enero','Febrero','Marzo','Abril','Mayo','Junio',
    'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre',
  ];
  static const _dayLabels = ['L','M','X','J','V','S','D'];

  @override
  void initState() {
    super.initState();
    _selected = widget.date;
    _month = DateTime(_selected.year, _selected.month);
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  void _pickDay(int day) => setState(() => _selected = DateTime(
      _month.year, _month.month, day, _selected.hour, _selected.minute));

  void _setHour(int h)   => setState(() => _selected = DateTime(
      _selected.year, _selected.month, _selected.day, h, _selected.minute));
  void _setMinute(int m) => setState(() => _selected = DateTime(
      _selected.year, _selected.month, _selected.day, _selected.hour, m));

  @override
  Widget build(BuildContext context) {
    final now         = DateTime.now();
    final today       = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // weekday: 1=Mon … 7=Sun → offset = weekday - 1
    final startOffset = DateTime(_month.year, _month.month, 1).weekday - 1;

    const bg      = Color(0xFF090F1A);
    const divider = Color(0xFF1A2538);
    const white60 = Color(0x99FFFFFF);
    const white30 = Color(0x4DFFFFFF);

    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Month nav ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
            child: Row(children: [
              _ChevBtn(icon: Icons.chevron_left,  onTap: _prevMonth),
              Expanded(
                child: Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: kSans, fontSize: 10.5,
                    fontWeight: FontWeight.w600, letterSpacing: 1.4,
                    color: Colors.white, decoration: TextDecoration.none,
                  ),
                ),
              ),
              _ChevBtn(icon: Icons.chevron_right, onTap: _nextMonth),
            ]),
          ),

          // ── Weekday header row ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: _dayLabels
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                            style: const TextStyle(
                              fontFamily: kSans, fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: white30,
                              decoration: TextDecoration.none,
                            )),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ── Day grid ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 2,
              crossAxisSpacing: 1,
              childAspectRatio: 1.15,
              children: [
                // Empty leading cells
                for (int i = 0; i < startOffset; i++)
                  const SizedBox.shrink(),
                // Day cells
                for (int d = 1; d <= daysInMonth; d++) ...[
                  Builder(builder: (_) {
                    final cellDate =
                        DateTime(_month.year, _month.month, d);
                    final isPast  = cellDate.isBefore(today);
                    final isSel   = _selected.year  == _month.year &&
                                    _selected.month == _month.month &&
                                    _selected.day   == d;
                    return GestureDetector(
                      onTap: isPast ? null : () => _pickDay(d),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSel ? LD.sph : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text('$d',
                          style: TextStyle(
                            fontFamily: kSans, fontSize: 10.5,
                            fontWeight: isSel
                                ? FontWeight.w600 : FontWeight.w400,
                            color: isPast
                                ? white30
                                : isSel
                                    ? Colors.white
                                    : white60,
                            decoration: TextDecoration.none,
                          )),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 6),
          Container(height: 1, color: divider),

          // ── Time selector ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimeStep(
                  value: _selected.hour,
                  onInc: () => _setHour((_selected.hour + 1) % 24),
                  onDec: () => _setHour((_selected.hour - 1 + 24) % 24),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(':',
                    style: TextStyle(
                      fontFamily: kSans, fontSize: 22,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    )),
                ),
                _TimeStep(
                  value: _selected.minute,
                  // Steps of 15 min
                  onInc: () => _setMinute((_selected.minute + 15) % 60),
                  onDec: () => _setMinute(
                      (_selected.minute - 15 + 60) % 60),
                ),
              ],
            ),
          ),

          Container(height: 1, color: divider),

          // ── Confirm ────────────────────────────────────────────
          GestureDetector(
            onTap: () => widget.onChanged(_selected),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                color: LD.sph,
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                child: const Text('CONFIRMAR',
                  style: TextStyle(
                    fontFamily: kSans, fontSize: 10,
                    fontWeight: FontWeight.w600, letterSpacing: 2.0,
                    color: Colors.white, decoration: TextDecoration.none,
                  )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Small chevron button used in the month nav header
class _ChevBtn extends StatelessWidget {
  const _ChevBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: const Color(0x80FFFFFF)),
          ),
        ),
      );
}

// Hour / minute stepper column  (▲  value  ▼)
class _TimeStep extends StatelessWidget {
  const _TimeStep({
    required this.value,
    required this.onInc,
    required this.onDec,
  });
  final int value;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onInc,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: const Icon(Icons.keyboard_arrow_up,
                  size: 18, color: Color(0x80FFFFFF)),
            ),
          ),
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: kSans, fontSize: 26,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          GestureDetector(
            onTap: onDec,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Color(0x80FFFFFF)),
            ),
          ),
        ],
      );
}

class _HoursPicker extends StatelessWidget {
  const _HoursPicker({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        Text('$hours hora${hours > 1 ? 's' : ''}', style: const TextStyle(
          fontFamily: kSans, fontSize: 13, color: Colors.white,
          decoration: TextDecoration.none,
        )),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.remove, size: 16,
              color: Colors.white.withAlpha(160)),
          onPressed: hours > 1 ? () => onChanged(hours - 1) : null,
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.add, size: 16,
              color: Colors.white.withAlpha(160)),
          onPressed: hours < 12 ? () => onChanged(hours + 1) : null,
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]);
}

/// Forces light theme on PlaceAutocompleteField inside the white booking bar.
class _LightField extends StatelessWidget {
  const _LightField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          brightness: Brightness.light,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            hintStyle: TextStyle(
              fontFamily: kSans,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: const Color(0xFFB0BAC8),
            ),
          ),
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: kSans, bodyColor: LD.ink, displayColor: LD.ink,
              ),
        ),
        child: child,
      );
}

// ============================================================
// Marquee Bar
// ============================================================

class _MarqueeBar extends StatefulWidget {
  const _MarqueeBar();

  @override
  State<_MarqueeBar> createState() => _MarqueeBarState();
}

class _MarqueeBarState extends State<_MarqueeBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _items = [
    'Precios Fijos','Chóferes Profesionales','Cobertura Mundial',
    'Disponibilidad 24/7','Flota Premium','Puntualidad Garantizada',
    'Traslados Aeroportuarios','Viajes Corporativos','Privacidad y Discreción','Conductores Multilingüe',
  ];
  static const _oneSetPx = 2200.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 36))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
        height: 40, color: LD.dark,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-_ctrl.value * _oneSetPx, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int r = 0; r < 3; r++)
                    for (int i = 0; i < _items.length; i++) ...[
                      Text(
                        _items[i].toUpperCase(),
                        style: TextStyle(
                          fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w300,
                          letterSpacing: 3.0,
                          color: Colors.white.withAlpha(70),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 3, height: 3,
                        decoration: const BoxDecoration(color: LD.sph, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// Stats Section
// ============================================================

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        child: Column(children: [
          Container(height: 1, color: LD.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Row(children: [
              _StatItem(value: 150000, format: (v) => v >= 150000 ? '150K+' : '${(v/1000).round()}K', label: 'Viajes completados'),
              _StatDivider(),
              _StatItem(value: 50, format: (v) => '$v+', label: 'Ciudades atendidas'),
              _StatDivider(),
              _StatItem(value: 49, format: (v) => '${(v/10).toStringAsFixed(1)}', label: 'Calificación promedio', suffix: '/5'),
              _StatDivider(),
              _StatItem(value: 24, format: (v) => v >= 24 ? '24 / 7' : '$v', label: 'Atención al cliente'),
            ]),
          ),
          Container(height: 1, color: LD.border),
        ]),
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.format,
    required this.label,
    this.suffix,
  });
  final int value;
  final String Function(int) format;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) => Expanded(
        child: RevealOnScroll(
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedCounter(
                  target: value,
                  format: format,
                  style: displayText(size: 64, color: LD.ink),
                ),
                if (suffix != null)
                  Text(suffix!, style: const TextStyle(
                    fontFamily: kSans, fontSize: 35, fontWeight: FontWeight.w300,
                    color: LD.ink3, decoration: TextDecoration.none,
                  )),
              ],
            ),
            const SizedBox(height: 10),
            Text(label.toUpperCase(), style: const TextStyle(
              fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w400,
              letterSpacing: 2.4, color: LD.ink3, decoration: TextDecoration.none,
            )),
          ]),
        ),
      );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 64, color: LD.border);
}

// ============================================================
// Immersive Strip
// ============================================================

class _ImmersiveStrip extends StatelessWidget {
  const _ImmersiveStrip();
  static const _photo = 'assets/images/home/immersive_bg.jpg';

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 480,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(_photo, fit: BoxFit.cover,
              width: double.infinity, height: double.infinity,
              errorBuilder: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [LD.ink, const Color(0xFF0D2040)],
                  ),
                ),
              )),
          // Lateral darkening overlay (matches .immersive-overlay)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                  colors: [
                    Colors.black.withAlpha(100),
                    Colors.black.withAlpha(20),
                    Colors.black.withAlpha(100),
                  ],
                ),
              ),
            ),
          ),
          // Centred caption
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              RevealOnScroll(
                dy: 48, threshold: 0.9,
                child: Text('LLEGA CON ESTILO', style: TextStyle(
                  fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w400,
                  letterSpacing: 5.0,
                  color: Colors.white.withAlpha(160),
                  decoration: TextDecoration.none,
                )),
              ),
              const SizedBox(height: 16),
              RevealOnScroll(
                delay: const Duration(milliseconds: 100),
                dy: 64, threshold: 0.9,
                child: Text('Cada viaje, una declaración.', style: TextStyle(
                  fontFamily: kSerif, fontSize: 52, fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  color: Colors.white, height: 1.12,
                  decoration: TextDecoration.none,
                )),
              ),
            ]),
          ),
        ]),
      );
}

// ============================================================
// Fleet Section
// ============================================================

class _FleetSection extends StatelessWidget {
  const _FleetSection({required this.sectionKey, required this.onBook});
  final GlobalKey sectionKey;
  final VoidCallback onBook;

  static final _vehicles = [
    _FleetItem(cls: 'Business Class',  model: 'Mercedes E-Class / o similar',  asset: 'assets/images/vehicles/business/car.png',    tags: ['4 Asientos','Interior de cuero','Wi-Fi'], accent: const Color(0xFF1B4F8A)),
    _FleetItem(cls: 'First Class',     model: 'Mercedes S-Class / o similar',  asset: 'assets/images/vehicles/first_class/car.png', tags: ['4 Asientos','Audio premium','Champán'], accent: const Color(0xFFC9A96E)),
    _FleetItem(cls: 'Business Van',    model: 'Mercedes V-Class / o similar',  asset: 'assets/images/vehicles/van/car.png',          tags: ['7 Asientos','Equipaje extra','Wi-Fi'], accent: const Color(0xFF2E6FBF)),
    _FleetItem(cls: 'Electric Class',  model: 'Tesla Model S / o similar',     asset: 'assets/images/vehicles/electric/car.png',    tags: ['4 Asientos','Cero emisiones','Premium'], accent: const Color(0xFF3DA05E)),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 900;
    final hPad = narrow ? 24.0 : 64.0;
    final vPad = narrow ? 56.0 : 100.0;
    return Container(
        key: sectionKey,
        color: LD.dark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, narrow ? 28 : 56),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RevealOnScroll(child: const LuxEyebrow('Nuestra Flota')),
                  const SizedBox(height: 20),
                  RevealOnScroll(
                    delay: const Duration(milliseconds: 80),
                    child: Text('Vehículos premium,\nsin excepciones.',
                        style: displayText(size: narrow ? 36 : 52, color: Colors.white)),
                  ),
                ]),
              ),
              if (!narrow) RevealOnScroll(
                delay: const Duration(milliseconds: 160),
                child: Text('DESLIZA PARA EXPLORAR →', style: TextStyle(
                  fontFamily: kSans, fontSize: 9, letterSpacing: 2.4,
                  color: Colors.white.withAlpha(60),
                  decoration: TextDecoration.none,
                )),
              ),
            ]),
          ),
          // Horizontal card list
          SizedBox(
            height: narrow ? 360 : 460,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
              itemCount: _vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (_, i) => _FleetCard(item: _vehicles[i], onBook: onBook),
            ),
          ),
          const SizedBox(height: 72),
        ]),
      );
  }
}

@immutable
class _FleetItem {
  const _FleetItem({
    required this.cls,
    required this.model,
    required this.asset,
    required this.tags,
    required this.accent,
  });
  final String cls;
  final String model;
  final String asset;
  final List<String> tags;
  final Color accent;
}

class _FleetCard extends StatefulWidget {
  const _FleetCard({required this.item, required this.onBook});
  final _FleetItem item;
  final VoidCallback onBook;

  @override
  State<_FleetCard> createState() => _FleetCardState();
}

class _FleetCardState extends State<_FleetCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onBook,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 340,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2E),
              border: Border.all(
                color: _hover ? widget.item.accent.withAlpha(180) : Colors.white.withAlpha(18),
              ),
            ),
            child: Stack(children: [
              // Accent gradient wash
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [widget.item.accent.withAlpha(_hover ? 45 : 20), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Car image
              Positioned(
                bottom: 110, left: 0, right: 0, height: 220,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Image.asset(widget.item.asset, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.directions_car_rounded, size: 80,
                        color: Colors.white.withAlpha(16),
                      )),
                ),
              ),
              // Bottom info bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [const Color(0xFF070E18).withAlpha(242), Colors.transparent],
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Class name — 22px serif
                    Text(widget.item.cls, style: const TextStyle(
                      fontFamily: kSerif, fontSize: 22, fontWeight: FontWeight.w400,
                      color: Colors.white, height: 1.1,
                      decoration: TextDecoration.none,
                    )),
                    const SizedBox(height: 4),
                    // Model — 12px dim
                    Text(widget.item.model, style: TextStyle(
                      fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(115), height: 1.5,
                      decoration: TextDecoration.none,
                    )),
                    const SizedBox(height: 16),
                    // Tags
                    Wrap(spacing: 6, runSpacing: 6,
                      children: widget.item.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withAlpha(36)),
                        ),
                        child: Text(t, style: TextStyle(
                          fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Colors.white.withAlpha(128),
                          decoration: TextDecoration.none,
                        )),
                      )).toList()),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

// ============================================================
// Promise Section
// ============================================================

class _PromiseSection extends StatelessWidget {
  const _PromiseSection();

  static const _points = [
    ('Chóferes verificados',
     'Cada conductor pasa una rigurosa verificación de antecedentes, inspección vehicular y programa de formación.'),
    ('Precio fijo, siempre',
     'Tu precio se confirma al reservar. Sin precios dinámicos, sin cargos ocultos — nunca.'),
    ('Cobertura global',
     'Disponible en más de 50 ciudades en Europa, América, Medio Oriente y Asia.'),
    ('Las 24 horas',
     'Nuestro equipo de operaciones monitorea cada viaje las 24 horas del día, los 365 días del año.'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: LD.dark,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Left — atmospheric photo panel
            const Expanded(child: _PromisePhotoPanel()),
            // Right — editorial list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(72, 100, 64, 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RevealOnScroll(
                    dx: 160,
                    child: const LuxEyebrow('El estándar Luxelane'),
                  ),
                  const SizedBox(height: 28),
                  RevealOnScroll(
                    delay: const Duration(milliseconds: 80), dx: 160,
                    child: Text('El estándar\nque otros siguen.',
                        style: displayText(size: 52, color: Colors.white)),
                  ),
                  const SizedBox(height: 56),
                  ..._points.asMap().entries.map((e) => RevealOnScroll(
                        delay: Duration(milliseconds: 140 + e.key * 80),
                        dx: 120, dy: 20,
                        child: _PromisePoint(title: e.value.$1, body: e.value.$2),
                      )),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _PromisePhotoPanel extends StatelessWidget {
  const _PromisePhotoPanel();
  static const _photo = 'assets/images/home/promise_photo.jpg';

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFF0D2040), Color(0xFF060C16)],
          ),
          image: DecorationImage(
            image: const AssetImage(_photo),
            fit: BoxFit.cover, onError: (_, __) {},
          ),
        ),
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Colors.transparent, LD.dark.withAlpha(200)],
          ),
        ),
        child: Stack(children: [
          Positioned(bottom: 0, left: -40, right: 0,
            child: Image.asset('assets/images/vehicles/business/car.png',
                fit: BoxFit.contain, alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          // Sapphire top accent
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 2, color: LD.sph)),
        ]),
      );
}

class _PromisePoint extends StatelessWidget {
  const _PromisePoint({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: Colors.white.withAlpha(18),
              margin: const EdgeInsets.only(bottom: 20)),
          Text(title, style: const TextStyle(
            fontFamily: kSerif, fontSize: 20, fontWeight: FontWeight.w400,
            color: Colors.white, decoration: TextDecoration.none,
          )),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(
            fontFamily: kSans, fontSize: 13, fontWeight: FontWeight.w300,
            height: 1.8, color: Colors.white.withAlpha(120),
            decoration: TextDecoration.none,
          )),
          const SizedBox(height: 24),
        ],
      );
}

// ============================================================
// Experience Section
// ============================================================

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({required this.sectionKey});
  final GlobalKey sectionKey;

  static const _features = [
    ('✦', 'Bienvenida personalizada', 'Tu chófer te espera antes de llegar — cartel con tu nombre, refrigerios, atención total.'),
    ('◈', 'Privacidad y discreción',  'Acuerdos de confidencialidad, formación en privacidad y cultura de discreción absoluta.'),
    ('◉', 'Precio fijo',              'El precio que ves al reservar es lo que pagas. Sin recargos de tráfico, sin sorpresas.'),
    ('⬡', 'Soporte 24 / 7',           'Nuestro equipo de operaciones monitorea cada viaje a toda hora, todos los días del año.'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        key: sectionKey,
        color: LD.bg,
        padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 64),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header (2-col grid: left = text, right = empty)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RevealOnScroll(child: const LuxEyebrow('La Experiencia')),
                const SizedBox(height: 20),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 80),
                  child: Text('Cada detalle,\ncuidado.',
                      style: displayText(size: 52, color: LD.ink)),
                ),
              ]),
            ),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 72),
          // 4-column feature grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _features.asMap().entries.map((e) {
              final i = e.key;
              final f = e.value;
              return Expanded(
                child: RevealOnScroll(
                  delay: Duration(milliseconds: i * 80), dy: 24,
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _features.length - 1 ? 48 : 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(height: 1, color: LD.sph, margin: const EdgeInsets.only(bottom: 24)),
                      Text(f.$1, style: const TextStyle(
                        fontSize: 18, color: LD.sph, decoration: TextDecoration.none,
                      )),
                      const SizedBox(height: 20),
                      Text(f.$2, style: const TextStyle(
                        fontFamily: kSerif, fontSize: 22, fontWeight: FontWeight.w400,
                        color: LD.ink, decoration: TextDecoration.none,
                      )),
                      const SizedBox(height: 12),
                      Text(f.$3, style: bodyText(size: 13, color: LD.ink3)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ]),
      );
}

// ============================================================
// Testimonials
// ============================================================

class _TestimonialsSection extends StatefulWidget {
  const _TestimonialsSection();

  @override
  State<_TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<_TestimonialsSection> {
  int _current = 0;

  static const _reviews = [
    (quote: 'Absolutamente impecable de principio a fin. El chófer llegó antes de tiempo y el auto estaba inmaculado. No usaré a nadie más.',
     name: 'Alexandra M.', location: 'Londres, Reino Unido'),
    (quote: 'Los precios fijos y los chóferes confiables hacen de Luxelane el único servicio en el que confío para todos mis viajes de negocios.',
     name: 'Marcus T.', location: 'Nueva York, EE. UU.'),
    (quote: 'Del aeropuerto al hotel, cada detalle fue manejado a la perfección. Así es como debería sentirse el viaje de lujo.',
     name: 'Isabelle R.', location: 'París, Francia'),
  ];

  @override
  Widget build(BuildContext context) {
    final r = _reviews[_current];
    return Container(
      color: const Color(0xFFF7F5F0),
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 140),
      child: Column(children: [
        // Decorative large quote mark
        RevealOnScroll(
          child: Text('"', style: TextStyle(
            fontFamily: kSerif, fontSize: 180, fontWeight: FontWeight.w300,
            color: LD.sph.withAlpha(23), height: 0.6,
            decoration: TextDecoration.none,
          )),
        ),
        const SizedBox(height: 12),
        // Rotating quote
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(r.quote,
            key: ValueKey(_current),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kSerif, fontSize: 34, fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic, color: LD.ink, height: 1.6,
              decoration: TextDecoration.none,
            )),
        ),
        const SizedBox(height: 44),
        // Author
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Column(key: ValueKey('a$_current'), children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 12, color: LD.sph)),
            ),
            const SizedBox(height: 12),
            Text('${r.name} · ${r.location}'.toUpperCase(), style: const TextStyle(
              fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w400,
              letterSpacing: 2.0, color: LD.ink3, decoration: TextDecoration.none,
            )),
          ]),
        ),
        const SizedBox(height: 48),
        // Dot navigation
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_reviews.length, (i) => GestureDetector(
            onTap: () => setState(() => _current = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: i == _current ? 28 : 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _current ? LD.sph : LD.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          )),
        ),
      ]),
    );
  }
}

// ============================================================
// Business Section
// ============================================================

class _BusinessSection extends StatelessWidget {
  const _BusinessSection({required this.sectionKey, required this.onLearnMore});
  final GlobalKey sectionKey;
  final VoidCallback onLearnMore;

  // 🎬 Place video at: assets/videos/business_bg.mp4
  static const _videoAsset = 'assets/videos/business_bg.mp4';

  static const _perks = [
    'Facturación y cobros centralizados',
    'Gerente de cuenta dedicado',
    'Herramientas de cumplimiento de política de viajes',
    'Reservas prioritarias para ejecutivos',
    'Monitoreo de viajes en tiempo real',
    'Cobertura global en múltiples ciudades',
  ];

  Widget _perksPanel(double hPad, double vPad) => Stack(
        children: [
          Positioned.fill(child: _VideoBackground(assetPath: _videoAsset)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: const [Color(0xCC070E18), Color(0xE8070E18)],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _perks.asMap().entries.map((e) {
                final i = e.key;
                return RevealOnScroll(
                  delay: Duration(milliseconds: i * 70), dy: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20))),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 36,
                        child: Text('0${i + 1}', style: TextStyle(
                          fontFamily: kSerif, fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: LD.sph.withAlpha(180),
                          decoration: TextDecoration.none,
                        )),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(
                          fontFamily: kSans, fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xE6FFFFFF),
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        )),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final hPad = narrow ? 24.0 : 64.0;
    final vPad = narrow ? 48.0 : 100.0;

    final headlinePanel = Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RevealOnScroll(dx: -160, child: const LuxEyebrow('Para Empresas')),
        const SizedBox(height: 28),
        RevealOnScroll(
          delay: const Duration(milliseconds: 80), dx: -160,
          child: Text('Viajes corporativos,\nredefinidos.',
              style: displayText(size: narrow ? 36 : 52, color: Colors.white)),
        ),
        const SizedBox(height: 28),
        RevealOnScroll(
          delay: const Duration(milliseconds: 160), dx: -120,
          child: Text(
            'Luxelane para Empresas brinda a tu equipo acceso a servicio de chófer premium con los controles e informes que tu equipo financiero exige.',
            style: bodyText(size: 14, color: const Color(0xCCFFFFFF)),
          ),
        ),
        const SizedBox(height: 44),
        RevealOnScroll(
          delay: const Duration(milliseconds: 220), dx: -120,
          child: _GhostBtn(label: 'Más información', light: true, onTap: onLearnMore),
        ),
      ]),
    );

    return Container(
      key: sectionKey,
      color: LD.dark,
      child: narrow
          ? Column(children: [
              headlinePanel,
              SizedBox(height: 320, child: _perksPanel(hPad, 32)),
            ])
          : IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: headlinePanel),
                Expanded(child: _perksPanel(hPad, vPad)),
              ]),
            ),
    );
  }
}

// ============================================================
// CTA Section
// ============================================================

class _CtaSection extends StatelessWidget {
  const _CtaSection({required this.onBook, required this.onViewFleet});
  final VoidCallback onBook;
  final VoidCallback onViewFleet;

  // 🎬 Place your video file at: assets/videos/cta_bg.mp4
  static const _videoAsset = 'assets/videos/cta_bg.mp4';

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          // Video background (looping, muted, full-bleed)
          Positioned.fill(
            child: _VideoBackground(assetPath: _videoAsset),
          ),
          // Dark overlay — video stays cinematic, text is bright
          const Positioned.fill(
            child: ColoredBox(color: Color(0x85050A12)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 80, 64, 80),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RevealOnScroll(
                      dx: -100, threshold: 0.9,
                      child: const Text('CUANDO QUIERAS. DONDE QUIERAS.',
                        style: TextStyle(
                          fontFamily: kSans, fontSize: 9, fontWeight: FontWeight.w600,
                          letterSpacing: 4.0,
                          color: Color(0xE0FFFFFF),
                          decoration: TextDecoration.none,
                        )),
                    ),
                    const SizedBox(height: 24),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 80),
                      dx: -100, threshold: 0.9,
                      child: Text('Tu próximo viaje,',
                          style: displayText(size: 96, color: Colors.white)),
                    ),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 120),
                      dx: -100, threshold: 0.9,
                      child: Text('en tus términos.',
                          style: displayText(size: 96, color: Colors.white,
                              style: FontStyle.italic)),
                    ),
                    const SizedBox(height: 48),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 160),
                      dx: -80, threshold: 0.9,
                      child: const Text(
                        'Precio fijo  ·  Chóferes profesionales  ·  En todo el mundo',
                        style: TextStyle(
                          fontFamily: kSans, fontSize: 11, fontWeight: FontWeight.w400,
                          letterSpacing: 2.8,
                          color: Color(0xCCFFFFFF),
                          decoration: TextDecoration.none,
                        )),
                    ),
                    const SizedBox(height: 52),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 220),
                      dx: -80, threshold: 0.9,
                      child: Row(children: [
                        _SolidBtn(
                          label: 'Reservar un viaje', white: true,
                          onTap: onBook,
                        ),
                        const SizedBox(width: 20),
                        _GhostBtn(label: 'Ver flota', light: true, onTap: onViewFleet),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

// ============================================================
// Shared looping video background
// ============================================================

// 🎬 VIDEO ASSET LOCATIONS:
//   Business section  →  assets/videos/business_bg.mp4
//   CTA section       →  assets/videos/cta_bg.mp4
// Both are already registered in pubspec.yaml under flutter > assets.
// Drop the .mp4 files in place and hot-restart to see them.

class _VideoBackground extends StatefulWidget {
  const _VideoBackground({required this.assetPath});
  final String assetPath;

  @override
  State<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<_VideoBackground> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ctrl = VideoPlayerController.asset(widget.assetPath);
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      await ctrl.setVolume(0);
      await ctrl.setLooping(true);
      await ctrl.play();
      setState(() { _ctrl = ctrl; _ready = true; });
    } catch (_) {
      // Asset not present yet — section shows solid dark colour as fallback
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      // Fallback: dark colour while video loads / file not placed yet
      return const ColoredBox(color: Color(0xFF070E18));
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width:  _ctrl!.value.size.width,
        height: _ctrl!.value.size.height,
        child: VideoPlayer(_ctrl!),
      ),
    );
  }
}

// ============================================================
// Footer
// ============================================================

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.onFleet,
    required this.onServices,
    required this.onBusiness,
  });
  final VoidCallback onFleet;
  final VoidCallback onServices;
  final VoidCallback onBusiness;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final links = [
      ('Servicios', onServices),
      ('Flota',     onFleet),
      ('Nosotros',  () {}),
      ('Contacto',  () {}),
    ];

    return Container(
      color: const Color(0xFF03050A),
      child: Stack(children: [
        // Sapphire top line (40% opacity)
        Positioned(top: 0, left: 0, right: 0,
          child: Container(height: 1, color: LD.sph.withAlpha(102))),
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 24 : 48, 60, narrow ? 24 : 48, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(children: [
                // Logo (35% opacity)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withAlpha(90), width: 1.5),
                    ),
                    child: Center(
                      child: Text('L', style: TextStyle(
                        fontFamily: kSerif, fontSize: 15, fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(90),
                        decoration: TextDecoration.none,
                      )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('LUXELANE', style: TextStyle(
                    fontFamily: kSans, fontSize: 12, fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                    color: Colors.white.withAlpha(90),
                    decoration: TextDecoration.none,
                  )),
                ]),
                const SizedBox(height: 28),
                // Tappable nav links — wrap on narrow
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 0,
                  runSpacing: 8,
                  children: links.map((l) => GestureDetector(
                    onTap: l.$2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(l.$1.toUpperCase(), style: TextStyle(
                          fontFamily: kSans, fontSize: 9.5, fontWeight: FontWeight.w400,
                          letterSpacing: 2.5,
                          color: Colors.white.withAlpha(71),
                          decoration: TextDecoration.none,
                        )),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 28),
                Text('© 2026 Luxelane. Todos los derechos reservados.', style: TextStyle(
                  fontFamily: kSans, fontSize: 9.5, fontWeight: FontWeight.w300,
                  letterSpacing: 1.0,
                  color: Colors.white.withAlpha(38),
                  decoration: TextDecoration.none,
                )),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// Book Section — scroll-driven 3D page-flip portfolio showcase
// ============================================================

@immutable
class _BookPageData {
  const _BookPageData({
    required this.num,
    required this.label,
    required this.sub,
    this.photoPath,
    this.carPath,
    required this.tag,
    required this.headline,
    required this.body,
    required this.bullets,
  });
  final String num;
  final String label;
  final String sub;
  final String? photoPath;
  final String? carPath;
  final String tag;
  final String headline;
  final String body;
  final List<String> bullets;
}

const List<_BookPageData> _kBookPages = [
  // Index 0: Cover (portada) — special: left=back cover, right=logo
  _BookPageData(
    num: '', label: 'LUXELANE', sub: 'Servicio de Chófer Premium',
    tag: '', headline: '', body: '', bullets: [],
  ),
  // Index 1: El Estándar (content page 01)
  _BookPageData(
    num: '01', label: 'El Estándar', sub: 'La Promesa Que Cumplimos',
    photoPath: 'assets/images/home/promise_photo.jpg',
    tag: 'El Estándar Luxelane', headline: 'El estándar que\notros siguen.',
    body: 'Cada chófer supera una rigurosa verificación de antecedentes, inspección del vehículo y programa de capacitación en servicio.',
    bullets: ['Chóferes verificados','Precio fijo, siempre','Cobertura global — más de 50 ciudades','A toda hora, 24/7'],
  ),
  // Index 2: La Experiencia (content page 02)
  _BookPageData(
    num: '02', label: 'La Experiencia', sub: 'Cada Detalle Considerado',
    photoPath: 'assets/images/home/immersive_bg.jpg',
    tag: 'La Experiencia', headline: 'Cada detalle,\ncuidado.',
    body: 'Desde agua fría y listas de reproducción seleccionadas hasta privacidad con cancelación de ruido — tus preferencias recordadas, siempre.',
    bullets: ['Interiores de cuero premium','Wi-Fi y carga inalámbrica','Servicio de champán disponible','Control de clima ambiental'],
  ),
  // Index 3: Para Empresas (content page 03)
  _BookPageData(
    num: '03', label: 'Para Empresas', sub: 'Viajes Corporativos Redefinidos',
    photoPath: 'assets/images/home/business_photo.jpg',
    tag: 'Para Empresas', headline: 'Viajes corporativos,\nredefinidos.',
    body: 'Luxelane para Empresas brinda a tu equipo acceso a servicio de chófer premium con los controles e informes que tu equipo financiero exige.',
    bullets: ['Facturación centralizada','Gerente de cuenta dedicado','Cumplimiento de política de viajes','Reservas prioritarias para ejecutivos'],
  ),
  // Index 4: Back to cover (cierre del libro)
  _BookPageData(
    num: '', label: 'LUXELANE', sub: 'Servicio de Chófer Premium',
    tag: '', headline: '', body: '', bullets: [],
  ),
];

class _BookSection extends StatefulWidget {
  const _BookSection();

  @override
  State<_BookSection> createState() => _BookSectionState();
}

class _BookSectionState extends State<_BookSection> {
  final _sectionKey = GlobalKey();
  double? _absoluteTop; // measured once, then all math is pure scroll arithmetic
  static const _numPages = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LuxScrollProvider.of(context); // register dependency for scroll-driven rebuilds
    // Measure absolute top only once (before sticky kicks in)
    if (_absoluteTop == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureOnce());
    }
  }

  void _measureOnce() {
    if (!mounted || _absoluteTop != null) return;
    final box = _sectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final notifier = LuxScrollProvider.of(context);
    final scrollY  = notifier?.scrollY ?? 0.0;
    // absoluteTop = scroll offset + relative-to-viewport position
    setState(() => _absoluteTop = scrollY + box.localToGlobal(Offset.zero).dy);
  }

  @override
  Widget build(BuildContext context) {
    // Re-register dependency so we rebuild on every scroll tick
    final scrollY  = LuxScrollProvider.of(context)?.scrollY ?? 0.0;
    final screenH  = MediaQuery.sizeOf(context).height;
    final w        = MediaQuery.sizeOf(context).width;
    final isMobile = w < 800;

    // Pure arithmetic from scroll position — no post-frame callback, no jitter
    final double progress;
    final double stickyOffset;
    if (_absoluteTop == null) {
      progress     = 0;
      stickyOffset = 0;
    } else {
      final raw = (scrollY - _absoluteTop!) / screenH;
      progress     = raw.clamp(0.0, _numPages.toDouble());
      stickyOffset = (scrollY - _absoluteTop!).clamp(0.0, (_numPages - 1) * screenH);
    }

    final pageIdx   = progress.floor().clamp(0, _numPages - 1);
    final t         = progress % 1.0;
    // Smooth cubic-out ease — no jitter at page boundaries
    final eased     = 1 - math.pow(1 - t, 3).toDouble();
    final flipAngle = eased * math.pi;

    return SizedBox(
      key: _sectionKey,
      height: screenH * _numPages,
      child: Stack(clipBehavior: Clip.none, children: [
        Transform.translate(
          offset: Offset(0, stickyOffset),
          child: SizedBox(
            height: screenH,
            child: Container(
              color: LD.dark,
              child: Stack(children: [
                // Radial sapphire glow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.3), radius: 0.85,
                        colors: [LD.sph.withAlpha(70), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Eyebrow
                Positioned(top: 44, left: 0, right: 0,
                  child: Center(child: Text('OUR SIGNATURE EXPERIENCE',
                    style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w500,
                      letterSpacing: 4.0, color: LD.sph.withAlpha(200),
                      decoration: TextDecoration.none)))),

                // Book
                Center(
                  child: _BookWidget(
                    pages: _kBookPages, currentPage: pageIdx,
                    flipAngle: flipAngle, isMobile: isMobile,
                  ),
                ),

                // Page dots — only show content pages (1, 2, 3)
                Positioned(bottom: 30, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final contentPageIdx = i + 1; // content pages are at indices 1, 2, 3
                      final active = pageIdx == contentPageIdx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: active ? 7.5 : 5, height: active ? 7.5 : 5,
                        decoration: BoxDecoration(
                          color: active ? LD.sph : LD.sph.withAlpha(70),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  )),

                // Scroll cue
                Positioned(right: 44, top: 0, bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: progress < 0.2 ? 0.4 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 1, height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [LD.sph, Colors.transparent],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        RotatedBox(quarterTurns: 1,
                          child: Text('SCROLL',
                            style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w500,
                              letterSpacing: 3.5, color: LD.sph,
                              decoration: TextDecoration.none))),
                      ]),
                    ),
                  )),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BookWidget extends StatelessWidget {
  const _BookWidget({
    super.key,
    required this.pages,
    required this.currentPage,
    required this.flipAngle,
    required this.isMobile,
  });

  final List<_BookPageData> pages;
  final int currentPage;
  final double flipAngle;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final w     = MediaQuery.sizeOf(context).width;
    final bookW = isMobile ? w - 40 : math.min(w - 160, 1080.0);
    final bookH = isMobile ? bookW * 0.75 : bookW * 0.56;

    final current  = pages[currentPage];
    final next     = pages[(currentPage + 1) % pages.length];
    final leafFront = flipAngle < math.pi / 2;
    final showLeaf  = flipAngle > 0.005;

    return SizedBox(
      width: bookW, height: bookH,
      child: Stack(children: [
        // Left panel
        Positioned(left: 0, top: 0, bottom: 0, width: bookW / 2,
          child: _BookLeftPanel(data: current, height: bookH, isMobile: isMobile)),

        // Right panel
        Positioned(right: 0, top: 0, bottom: 0, width: bookW / 2,
          child: _BookRightPanel(data: leafFront ? current : next, isMobile: isMobile)),

        // Spine (10px, matches .book-spine)
        Positioned(left: bookW / 2 - 5, top: 0, bottom: 0, width: 10,
          child: Stack(children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF040A12), Color(0xFF1B3050), Color(0xFF040A12)],
                ),
              ),
            ),
            Center(
              child: FractionallySizedBox(
                heightFactor: 0.64,
                child: Container(
                  width: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, LD.sph.withAlpha(180), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ])),

        // Flipping leaf
        if (showLeaf)
          Positioned(right: 0, top: 0, bottom: 0, width: bookW / 2,
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(-flipAngle),
              child: ClipRect(
                child: leafFront
                    ? _BookRightPanel(data: current, isMobile: isMobile)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: _BookLeftPanel(data: next, height: bookH, isMobile: isMobile),
                      ),
              ),
            )),

        // Gloss sheen
        if (showLeaf)
          Positioned(right: 0, top: 0, bottom: 0, width: bookW / 2,
            child: IgnorePointer(
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(-flipAngle),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withAlpha((math.sin(flipAngle.abs()) * 55).round()),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ]),
    );
  }
}

class _BookLeftPanel extends StatelessWidget {
  const _BookLeftPanel({super.key, required this.data, required this.height, required this.isMobile});
  final _BookPageData data;
  final double height;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 20.0 : 36.0;
    // Back cover: dark with minimal branding
    if (data.headline.isEmpty) {
      return ClipRect(
        child: Container(
          color: const Color(0xFF04090F),
          child: Stack(children: [
            Positioned(bottom: 40, left: 0, right: 0,
              child: Center(child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: LD.sph.withAlpha(60), width: 1),
                ),
                child: Center(child: Text('L', style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, fontWeight: FontWeight.w400,
                  color: LD.sph.withAlpha(80), decoration: TextDecoration.none,
                ))),
              ))),
          ]),
        ),
      );
    }
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: data.photoPath == null
              ? const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF060E1A), Color(0xFF0D2040), Color(0xFF060E1A)],
                  stops: [0, 0.55, 1])
              : null,
          image: data.photoPath != null
              ? DecorationImage(image: AssetImage(data.photoPath!), fit: BoxFit.cover, onError: (_, __) {})
              : null,
        ),
        child: Stack(children: [
          // Photo dark overlay
          if (data.photoPath != null)
            Positioned.fill(child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFF070E18).withAlpha(122)),
            )),

          // Ghost page number
          Positioned(bottom: -10, right: -6,
            child: Text(data.num,
              style: GoogleFonts.cormorantGaramond(
                fontSize: isMobile ? 100 : 180, fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(6), height: 1,
                decoration: TextDecoration.none))),

          // Car PNG (page 0)
          if (data.carPath != null)
            Positioned(bottom: 48, left: 0, right: 0, height: isMobile ? 100 : 180,
              child: Image.asset(data.carPath!, fit: BoxFit.contain, alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink())),

          // Deco label top-left
          Positioned(top: pad, left: pad,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 24, height: 1, color: LD.sph.withAlpha(180)),
              const SizedBox(width: 10),
              Text(data.label.toUpperCase(),
                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w500,
                  letterSpacing: 3.0, color: LD.sph.withAlpha(200),
                  decoration: TextDecoration.none)),
            ])),

          // Caption strip
          Positioned(bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(pad, 28, pad, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [const Color(0xFF040A12).withAlpha(230), Colors.transparent],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('— ${data.num}',
                  style: GoogleFonts.cormorantGaramond(fontSize: 10, fontWeight: FontWeight.w400,
                    letterSpacing: 3.0, color: LD.sph, decoration: TextDecoration.none)),
                const SizedBox(height: 5),
                Text(data.sub,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic, color: Colors.white.withAlpha(140),
                    decoration: TextDecoration.none)),
              ]),
            )),
        ]),
      ),
    );
  }
}

class _BookRightPanel extends StatelessWidget {
  const _BookRightPanel({super.key, required this.data, required this.isMobile});
  final _BookPageData data;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final hPad = isMobile ? 24.0 : 56.0;
    final vPad = isMobile ? 24.0 : 52.0;
    // Front cover: clean white page with centered logo
    if (data.headline.isEmpty) {
      return Container(
        color: const Color(0xFFF7F5F0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: LD.ink, width: 1.5),
                ),
                child: Center(child: Text('L', style: GoogleFonts.cormorantGaramond(
                  fontSize: 36, fontWeight: FontWeight.w400,
                  color: LD.ink, decoration: TextDecoration.none,
                ))),
              ),
              const SizedBox(height: 20),
              Text('LUXELANE', style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w600,
                letterSpacing: 5.0, color: LD.ink,
                decoration: TextDecoration.none,
              )),
              const SizedBox(height: 10),
              Text('Servicio de Chófer Premium', style: GoogleFonts.cormorantGaramond(
                fontSize: 14, fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic, color: LD.ink3,
                decoration: TextDecoration.none,
              )),
            ],
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFFF7F5F0),
      child: Stack(children: [
        // Ghost number
        Positioned(bottom: -12, right: -8,
          child: Text(data.num,
            style: GoogleFonts.cormorantGaramond(
              fontSize: isMobile ? 100 : 180, fontWeight: FontWeight.w600,
              color: LD.sph.withAlpha(10), height: 1,
              decoration: TextDecoration.none))),

        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(data.tag,
              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w500,
                letterSpacing: 3.5, color: LD.sph, decoration: TextDecoration.none)),
            const SizedBox(height: 22),
            Text(data.headline,
              style: GoogleFonts.cormorantGaramond(
                fontSize: isMobile ? 26 : 42, fontWeight: FontWeight.w300, height: 1.06,
                color: LD.ink, letterSpacing: -0.01 * (isMobile ? 26 : 42),
                decoration: TextDecoration.none)),
            const SizedBox(height: 20),
            Text(data.body,
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 12 : 12.5, fontWeight: FontWeight.w300,
                height: 1.9, color: LD.ink2, decoration: TextDecoration.none)),
            const SizedBox(height: 24),
            ...data.bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(width: 18, height: 1, color: LD.sph, margin: const EdgeInsets.only(right: 14)),
                Expanded(child: Text(b,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 11 : 11.5, fontWeight: FontWeight.w400,
                    letterSpacing: 0.02 * (isMobile ? 11 : 11.5),
                    color: LD.ink2, decoration: TextDecoration.none))),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }
}
