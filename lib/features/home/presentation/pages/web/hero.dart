part of '../home_web_page.dart';

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
    final l = context.l10n;
    final headlineSize = narrow ? 52.0 : 100.0;

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
                    const Color(0xFF0A101C).withAlpha(210),
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
                    const Color(0xFF0A101C).withAlpha(240),
                    const Color(0xFF0A101C).withAlpha(160),
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
                        child: Text.rich(
                          TextSpan(
                            children: emphasisSpans(
                              l.homeHeroTitle,
                              style: displayText(size: headlineSize, color: Colors.white),
                              emphasis: displayText(
                                size: headlineSize, color: Colors.white,
                                style: FontStyle.italic,
                              ),
                            ),
                          ),
                          textAlign: TextAlign.center,
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
                                      label: l.homeBarPickup,
                                      icon: Icons.radio_button_checked,
                                      child: PlaceAutocompleteField(
                                        label: l.homeBarPickupHint,
                                        hint: l.homeBarPickupHint,
                                        initialValue: widget.origin,
                                        onPlaceSelected: widget.onOriginSelected,
                                        onMapPick: widget.onOriginMapPick,
                                        glass: true,
                                      ),
                                    ),
                                    Container(height: 1, color: Colors.white.withAlpha(30)),
                                    isOneWay
                                        ? _BarField(
                                            label: l.homeBarDestination,
                                            icon: Icons.south,
                                            child: PlaceAutocompleteField(
                                              label: l.homeBarDestinationHint,
                                              initialValue: widget.destination,
                                              onPlaceSelected: widget.onDestinationSelected,
                                              onMapPick: widget.onDestinationMapPick,
                                              glass: true,
                                            ),
                                          )
                                        : _BarField(
                                            label: l.homeBarDuration,
                                            icon: Icons.schedule_outlined,
                                            child: _HoursPicker(
                                              hours: widget.hours,
                                              onChanged: widget.onHoursChanged,
                                            ),
                                          ),
                                    Container(height: 1, color: Colors.white.withAlpha(30)),
                                    _BarField(
                                      label: l.homeBarDateTime,
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
                                      child: _BarCta(onTap: widget.onSearch, stacked: true),
                                    ),
                                  ],
                                )
                              // ── Desktop: horizontal row ──────────────
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _BarField(
                                        label: l.homeBarPickup,
                                        icon: Icons.radio_button_checked,
                                        child: PlaceAutocompleteField(
                                          label: l.homeBarPickupHint,
                                          hint: l.homeBarPickupHint,
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
                                              label: l.homeBarDestination,
                                              icon: Icons.south,
                                              child: PlaceAutocompleteField(
                                                label: l.homeBarDestinationHint,
                                                initialValue: widget.destination,
                                                onPlaceSelected: widget.onDestinationSelected,
                                                onMapPick: widget.onDestinationMapPick,
                                                glass: true,
                                              ),
                                            )
                                          : _BarField(
                                              label: l.homeBarDuration,
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
                                        label: l.homeBarDateTime,
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
                                      label: l.homeBarPickup,
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
                                      label: l.homeBarDestination,
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
                colors: [Color(0xFF0A101C), Color(0xFF0B1220), Color(0xFF091525)],
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
  final String       label;       // pickup or destination field label
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
                        context.l10n.homeMapChangeLocation.toUpperCase(),
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
            _Pill(label: ServiceType.oneWay.localizedLabel(context.l10n),    selected: isOneWay,  onTap: () => onChanged(ServiceType.oneWay)),
            _Pill(label: ServiceType.byTheHour.localizedLabel(context.l10n), selected: !isOneWay, onTap: () => onChanged(ServiceType.byTheHour)),
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
              Flexible(
                child: Text(label.toUpperCase(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kSans, fontSize: 9.5, fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                    color: Colors.white.withAlpha(160),
                    decoration: TextDecoration.none,
                  )),
              ),
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
  const _BarCta({required this.onTap, this.stacked = false});
  final VoidCallback onTap;

  /// Full-width button under stacked fields (narrow layout) instead of the
  /// fixed-width column at the end of the desktop bar.
  final bool stacked;

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
            borderRadius: widget.stacked
                ? BorderRadius.zero
                : const BorderRadius.only(
                    topRight:    Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.stacked ? double.infinity : 180,
            height: widget.stacked ? 56 : double.infinity,
            decoration: BoxDecoration(
              color: _hover ? LuxPalette.champagneLight : LD.cta,
              border: widget.stacked
                  ? null
                  : Border(left: BorderSide(color: Colors.white.withAlpha(40))),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.l10n.homeBarSeeOptions.toUpperCase(),
                style: const TextStyle(
                  fontFamily: kSans, fontSize: 10.5, fontWeight: FontWeight.w600,
                  letterSpacing: 2.2, color: LD.onCta,
                  decoration: TextDecoration.none,
                ),
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
                ? (_h ? const Color(0xFFE8E2D6) : Colors.white)
                : (_h ? LuxPalette.champagneLight : LD.cta),
            child: Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: kSans, fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: widget.white ? LD.ink : LD.onCta,
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

  String _fmt(AppLocalizations l, DateTime d) =>
      l.homeDateTimeShort(DateFormat.MMMd().format(d), DateFormat.jm().format(d));

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_fmt(context.l10n, date), style: const TextStyle(
                  fontFamily: kSans, fontSize: 13, color: Colors.white,
                  decoration: TextDecoration.none,
                )),
              ),
            ),
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
    // Weeks start on the locale's first day (Mon in es, Sun in en/pt).
    final material    = MaterialLocalizations.of(context);
    final firstDay    = material.firstDayOfWeekIndex; // 0 = Sunday
    final dayLabels   = [
      for (var i = 0; i < 7; i++) material.narrowWeekdays[(firstDay + i) % 7],
    ];
    // DateTime.weekday: 1=Mon … 7=Sun → Sunday-based index = weekday % 7
    final startOffset =
        (DateTime(_month.year, _month.month).weekday % 7 - firstDay + 7) % 7;
    final monthTitle  = toBeginningOfSentenceCase(
        DateFormat.yMMMM().format(_month));

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
                  monthTitle,
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
              children: dayLabels
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
                          color: isSel ? LD.accent : Colors.transparent,
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
                color: LD.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                child: Text(context.l10n.commonConfirm.toUpperCase(),
                  style: const TextStyle(
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
        Expanded(
          child: Text(context.l10n.unitHours(hours),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: kSans, fontSize: 13, color: Colors.white,
              decoration: TextDecoration.none,
            )),
        ),
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
