import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/place_model.dart';
import '../../../../core/widgets/place_autocomplete_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import 'home_design.dart';

// ============================================================
// WebHomePage — orchestrates all sections
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
  final _scroll = ScrollController();
  double _scrollY = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      setState(() => _scrollY = _scroll.offset);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LD.bg,
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Spacer for fixed nav
                const SizedBox(height: 72),
                // Hero
                _HeroSection(
                  serviceType: widget.serviceType,
                  origin: widget.origin,
                  destination: widget.destination,
                  date: widget.date,
                  hours: widget.hours,
                  locating: widget.locating,
                  onServiceTypeChanged: widget.onServiceTypeChanged,
                  onOriginSelected: widget.onOriginSelected,
                  onDestinationSelected: widget.onDestinationSelected,
                  onDateChanged: widget.onDateChanged,
                  onHoursChanged: widget.onHoursChanged,
                  onLocate: widget.onLocate,
                  onSearch: widget.onSearch,
                  onOriginMapPick: widget.onOriginMapPick,
                  onDestinationMapPick: widget.onDestinationMapPick,
                  scrollY: _scrollY,
                ),
                // Marquee
                const _MarqueeBar(),
                // Stats
                const _StatsSection(),
                // Immersive photo strip
                const _ImmersiveStrip(),
                // Promise — dark split
                const _PromiseSection(),
                // How it works
                const _HowItWorksSection(),
                // Fleet
                const _FleetSection(),
                // Experience
                const _ExperienceSection(),
                // Testimonials
                const _TestimonialsSection(),
                // Business
                const _BusinessSection(),
                // CTA
                const _CtaSection(),
                // Footer
                const _FooterSection(),
              ],
            ),
          ),
          // Fixed nav overlay
          _LuxNav(scrollY: _scrollY),
        ],
      ),
    );
  }
}

// ============================================================
// Fixed Nav
// ============================================================

class _LuxNav extends StatelessWidget {
  const _LuxNav({required this.scrollY});
  final double scrollY;

  @override
  Widget build(BuildContext context) {
    final scrolled = scrollY > 60;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 72,
      decoration: BoxDecoration(
        // Solid semi-opaque bg when scrolled — no BackdropFilter
        // (BackdropFilter blurs ALL content below in Flutter Web)
        color: scrolled
            ? const Color(0xF2FAFBFE)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? LD.border : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: Row(
          children: [
            _LuxLogo(light: !scrolled),
            const Spacer(),
            _NavLink('Services', light: !scrolled, onTap: () {}),
            const SizedBox(width: 32),
            _NavLink('Fleet', light: !scrolled, onTap: () {}),
            const SizedBox(width: 32),
            _NavLink('For Business', light: !scrolled, onTap: () {}),
            const SizedBox(width: 40),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, auth) {
                if (auth is AuthAuthenticated) {
                  return Row(children: [
                    NotificationBell(color: scrolled ? LD.ink : Colors.white),
                    const SizedBox(width: 8),
                    _AvatarDot(name: auth.user.displayName,
                        onTap: () => ctx.go('/profile')),
                  ]);
                }
                return Row(children: [
                  _NavLink('Sign In', light: !scrolled,
                      onTap: () => ctx.go('/login')),
                  const SizedBox(width: 20),
                  _NavCta(onTap: () => ctx.go('/')),
                ]);
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
            width: 26,
            height: 26,
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
                  fontFamily: kSerif,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: light ? Colors.white : LD.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LUXELANE',
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.0,
              color: light ? Colors.white : LD.ink,
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
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
              color: _hover
                  ? (widget.light ? Colors.white : LD.ink)
                  : (widget.light
                      ? Colors.white.withAlpha(160)
                      : LD.ink3),
            ),
          ),
        ),
      );
}

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
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            color: _hover ? LD.sphLt : LD.sph,
            child: const Text(
              'BOOK A RIDE',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.8,
                color: Colors.white,
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
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LD.sphTint,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontFamily: kSans,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: LD.sph,
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

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _fade(double from, double to) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(from, to, curve: Curves.easeOut),
      );

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height - 72;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          // ── Full-bleed luxury photo ──────────────────────────────────
          const Positioned.fill(child: _HeroBg()),

          // ── Top vignette — nav legibility ────────────────────────────
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

          // ── Bottom gradient — booking bar legibility ─────────────────
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
                  stops: const [0.0, 0.28, 0.55],
                ),
              ),
            ),
          ),

          // ── Centred headline ─────────────────────────────────────────
          Positioned(
            left: 0, right: 0,
            top: 0,
            bottom: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _fade(0.0, 0.45),
                    child: Text(
                      'PROFESSIONAL CHAUFFEUR SERVICE',
                      style: TextStyle(
                        fontFamily: kSans,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.0,
                        color: Colors.white.withAlpha(140),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ClipReveal(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Your chauffeur awaits.',
                      textAlign: TextAlign.center,
                      style: displayText(size: 78, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom booking bar ────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _fade(0.45, 1.0),
              child: _BottomBookingBar(
                serviceType: widget.serviceType,
                origin: widget.origin,
                destination: widget.destination,
                date: widget.date,
                hours: widget.hours,
                locating: widget.locating,
                onServiceTypeChanged: widget.onServiceTypeChanged,
                onOriginSelected: widget.onOriginSelected,
                onDestinationSelected: widget.onDestinationSelected,
                onDateChanged: widget.onDateChanged,
                onHoursChanged: widget.onHoursChanged,
                onLocate: widget.onLocate,
                onSearch: widget.onSearch,
                onOriginMapPick: widget.onOriginMapPick,
                onDestinationMapPick: widget.onDestinationMapPick,
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ============================================================
// Luxury photo background
// ============================================================

class _HeroBg extends StatelessWidget {
  const _HeroBg();

  // Place your hero photo at:  assets/images/home/hero_bg.jpg
  // Any JPG/PNG with a luxury interior or exterior works great.
  static const _assetPath = 'assets/images/home/hero_bg.png';

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Deep luxury gradient — always visible, image layers on top
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF060C16),
                  Color(0xFF0D1B2E),
                  Color(0xFF091525),
                ],
              ),
            ),
          ),
          // Subtle texture dots (pure Flutter, no image needed)
          CustomPaint(painter: _DotGridPainter(), child: const SizedBox.expand()),
          // Hero photo — load from local assets
          Image.asset(
            _assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // If the file doesn't exist yet, SizedBox keeps the gradient showing
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      );
}

/// Subtle dot grid painted over the dark gradient (visible when no photo yet)
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0FFFFFFF);
    const spacing = 40.0;
    const radius = 1.2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// Clip-reveal animation for headline lines
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _ctrl, curve: const Cubic(0.16, 1, 0.3, 1)));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ============================================================
// Bottom Booking Bar  (Blacklane-style)
// ============================================================

class _BottomBookingBar extends StatelessWidget {
  const _BottomBookingBar({
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

  @override
  Widget build(BuildContext context) {
    final isOneWay = serviceType == ServiceType.oneWay;

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 0, 56, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Service type pill toggle ──────────────────────────────────
          _ServicePillToggle(
            isOneWay: isOneWay,
            onChanged: onServiceTypeChanged,
          ),
          const SizedBox(height: 12),

          // ── Horizontal booking bar ────────────────────────────────────
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF060C16).withAlpha(80),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pickup
                Expanded(
                  flex: 3,
                  child: _BarField(
                    label: 'PICKUP',
                    icon: Icons.trip_origin,
                    child: _LightField(
                      child: PlaceAutocompleteField(
                        label: 'Where are you?',
                        hint: 'Street, airport, hotel…',
                        initialValue: origin,
                        onPlaceSelected: onOriginSelected,
                        onMapPick: onOriginMapPick,
                      ),
                    ),
                  ),
                ),

                const _BarSeparator(),

                // Destination or hours
                Expanded(
                  flex: 3,
                  child: isOneWay
                      ? _BarField(
                          label: 'DESTINATION',
                          icon: Icons.location_on_outlined,
                          child: _LightField(
                            child: PlaceAutocompleteField(
                              label: 'Where to?',
                              initialValue: destination,
                              onPlaceSelected: onDestinationSelected,
                              onMapPick: onDestinationMapPick,
                            ),
                          ),
                        )
                      : _BarField(
                          label: 'DURATION',
                          icon: Icons.schedule_outlined,
                          child: _HoursPicker(
                            hours: hours,
                            onChanged: onHoursChanged,
                          ),
                        ),
                ),

                const _BarSeparator(),

                // Date & time
                Expanded(
                  flex: 2,
                  child: _BarField(
                    label: 'DATE & TIME',
                    icon: Icons.calendar_today_outlined,
                    child: _DatePicker(
                      date: date,
                      onChanged: onDateChanged,
                    ),
                  ),
                ),

                // CTA button — flush right, fills full height
                _BarCta(onTap: onSearch),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pill toggle above the bar
class _ServicePillToggle extends StatelessWidget {
  const _ServicePillToggle({
    required this.isOneWay,
    required this.onChanged,
  });

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
            _Pill(
              label: 'One way',
              selected: isOneWay,
              onTap: () => onChanged(ServiceType.oneWay),
            ),
            _Pill(
              label: 'By the hour',
              selected: !isOneWay,
              onTap: () => onChanged(ServiceType.byTheHour),
            ),
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
              fontFamily: kSans,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              color: selected ? LD.ink : Colors.white.withAlpha(170),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
}

// A single labeled column inside the booking bar
class _BarField extends StatelessWidget {
  const _BarField({
    required this.label,
    required this.icon,
    required this.child,
  });
  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Icon(icon, size: 10, color: LD.ink3),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: kSans,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                    color: LD.ink3,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      );
}

// Thin vertical divider between bar fields
class _BarSeparator extends StatelessWidget {
  const _BarSeparator();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: const Color(0xFFE8E5DF),
      );
}

// CTA button — full-height, flush right edge
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
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 168,
            color: _hover ? LD.sphLt : LD.sph,
            alignment: Alignment.center,
            child: const Text(
              'VIEW OPTIONS',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// Solid button
// ============================================================

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
        onExit: (_) => setState(() => _h = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            color: widget.white
                ? (_h ? const Color(0xFFE8EDF7) : Colors.white)
                : (_h ? LD.sphLt : LD.sph),
            child: Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.8,
                color: widget.white ? LD.ink : Colors.white,
              ),
            ),
          ),
        ),
      );
}

// Ghost / outline button
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
        onExit: (_) => setState(() => _h = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(
                color: _h
                    ? (widget.light ? Colors.white : LD.ink)
                    : (widget.light
                        ? Colors.white.withAlpha(120)
                        : LD.border),
              ),
              color: _h
                  ? (widget.light
                      ? Colors.white.withAlpha(20)
                      : LD.bg3)
                  : Colors.transparent,
            ),
            child: Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.8,
                color: widget.light ? Colors.white : LD.ink,
              ),
            ),
          ),
        ),
      );
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, $h:$m';
  }

  static ThemeData _pickerTheme() => ThemeData(
        useMaterial3: true,
        fontFamily: kSans,
        colorScheme: const ColorScheme.light(
          primary: LD.sph,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: LD.ink,
          secondary: LD.sphLt,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: kSans),
          bodyMedium: TextStyle(fontFamily: kSans),
          labelLarge: TextStyle(fontFamily: kSans, letterSpacing: 1.2),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      );

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          // Date
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (ctx, child) => Theme(data: _pickerTheme(), child: child!),
          );
          if (!context.mounted || picked == null) return;
          // Time
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date),
            builder: (ctx, child) => Theme(data: _pickerTheme(), child: child!),
          );
          if (time != null) {
            onChanged(DateTime(
              picked.year, picked.month, picked.day,
              time.hour, time.minute,
            ));
          } else {
            onChanged(picked);
          }
        },
        child: Row(
          children: [
            Text(
              _fmt(date),
              style: const TextStyle(
                fontFamily: kSans,
                fontSize: 13,
                color: LD.ink,
                decoration: TextDecoration.none,
              ),
            ),
            const Spacer(),
            const Icon(Icons.expand_more, size: 16, color: LD.ink3),
          ],
        ),
      );
}

class _HoursPicker extends StatelessWidget {
  const _HoursPicker({required this.hours, required this.onChanged});
  final int hours;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            '$hours hour${hours > 1 ? 's' : ''}',
            style: const TextStyle(
              fontFamily: kSans,
              fontSize: 13,
              color: LD.ink,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove, size: 16, color: LD.ink3),
            onPressed:
                hours > 1 ? () => onChanged(hours - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, size: 16, color: LD.ink3),
            onPressed:
                hours < 12 ? () => onChanged(hours + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
}

/// Forces light theme on any child that reads Theme.of(context).brightness.
/// Used to keep PlaceAutocompleteField white inside the booking card even
/// when the app-level theme is dark.
class _LightField extends StatelessWidget {
  const _LightField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          brightness: Brightness.light,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFFF5F7FC),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: kSans,
                bodyColor: LD.ink,
                displayColor: LD.ink,
              ),
        ),
        child: child,
      );
}

// ============================================================
// Marquee Bar — dark ticker
// ============================================================

class _MarqueeBar extends StatefulWidget {
  const _MarqueeBar();

  @override
  State<_MarqueeBar> createState() => _MarqueeBarState();
}

class _MarqueeBarState extends State<_MarqueeBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _items = [
    'Fixed Pricing',
    'Professional Chauffeurs',
    'Worldwide Coverage',
    '24/7 Availability',
    'Premium Fleet',
    'Punctuality Guaranteed',
    'Airport Transfers',
    'Corporate Travel',
    'Privacy & Discretion',
    'Multilingual Drivers',
  ];

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        color: LD.dark,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => FractionalTranslation(
              translation: Offset(-_ctrl.value, 0),
              child: Row(
                children: [
                  for (int r = 0; r < 3; r++)
                    for (int i = 0; i < _items.length; i++) ...[
                      Text(
                        _items[i].toUpperCase(),
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 3.0,
                          color: Colors.white.withAlpha(70),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: LD.sph,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                ],
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// Stats — editorial white numbers
// ============================================================

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(height: 1, color: LD.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Row(
              children: [
                _StatItem(
                  value: 150000,
                  format: (v) => v >= 150000 ? '150K+' : '${(v / 1000).round()}K',
                  label: 'Rides completed',
                ),
                _StatDivider(),
                _StatItem(
                  value: 50,
                  format: (v) => '$v+',
                  label: 'Cities served',
                ),
                _StatDivider(),
                _StatItem(
                  value: 49,
                  format: (v) => '${(v / 10).toStringAsFixed(1)}',
                  label: 'Average rating',
                  suffix: '/5',
                ),
                _StatDivider(),
                _StatItem(
                  value: 24,
                  format: (v) => v >= 24 ? '24 / 7' : '$v',
                  label: 'Customer support',
                ),
              ],
            ),
          ),
          Container(height: 1, color: LD.border),
        ],
      ),
    );
  }
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
          child: Column(
            children: [
              AnimatedCounter(
                target: value,
                format: format,
                style: displayText(size: 64, color: LD.ink),
              ),
              const SizedBox(height: 10),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.4,
                  color: LD.ink3,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 64, color: LD.border,
      );
}

// ============================================================
// Promise — dark split section
// ============================================================

class _PromiseSection extends StatelessWidget {
  const _PromiseSection();

  static const _points = [
    (
      'Vetted chauffeurs',
      'Every driver passes a rigorous background check, vehicle inspection, and service training programme.',
    ),
    (
      'Fixed price, always',
      'Your price is confirmed at booking. No surge, no hidden fees — ever.',
    ),
    (
      'Global coverage',
      'Available in 50+ cities across Europe, the Americas, the Middle East, and Asia.',
    ),
    (
      'Around the clock',
      'Our operations team monitors every ride 24 hours a day, 365 days a year.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.dark,
      child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left — atmospheric car panel
          const Expanded(child: _PromisePhotoPanel()),
          // Right — editorial list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(72, 100, 64, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RevealOnScroll(
                    child: const LuxEyebrow('The Luxelane Standard', dark: true),
                  ),
                  const SizedBox(height: 28),
                  RevealOnScroll(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      'The standard\nothers follow.',
                      style: displayText(size: 52, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 56),
                  ..._points.asMap().entries.map((e) => RevealOnScroll(
                        delay: Duration(milliseconds: 140 + e.key * 80),
                        dy: 20,
                        child: _PromisePoint(
                          title: e.value.$1,
                          body: e.value.$2,
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _PromisePhotoPanel extends StatelessWidget {
  const _PromisePhotoPanel();

  // Upload: assets/images/home/promise_photo.jpg
  // Ideal: chauffeur opening car door, or car arriving at hotel entrance
  // Size: 900×1200px minimum, portrait orientation
  static const _photo = 'assets/images/home/promise_photo.jpg';

  @override
  Widget build(BuildContext context) => Container(
        // Gradient base — always visible
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0D2040), Color(0xFF060C16)],
          ),
          // Service photo layers on top when present
          image: DecorationImage(
            image: const AssetImage(_photo),
            fit: BoxFit.cover,
            onError: (_, __) {},
          ),
        ),
        // Right-edge gradient so the panel blends into the text column
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.transparent, LD.dark.withAlpha(200)],
          ),
        ),
        child: Stack(
          children: [
            // Fallback car PNG shown when no photo is uploaded
            Positioned(
              bottom: 0, left: -40, right: 0,
              child: Image.asset(
                'assets/images/vehicles/business/car.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Sapphire top accent line
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 2, color: LD.sph),
            ),
          ],
        ),
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
          Container(
            height: 1,
            color: Colors.white.withAlpha(18),
            margin: const EdgeInsets.only(bottom: 20),
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: kSerif,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: bodyText(size: 13, color: Color(0x78FFFFFF))),
          const SizedBox(height: 24),
        ],
      );
}

// ============================================================
// Immersive photo strip — full-bleed between stats and promise
// ============================================================

class _ImmersiveStrip extends StatelessWidget {
  const _ImmersiveStrip();

  // Upload: assets/images/home/immersive_bg.jpg
  // Ideal: wide interior shot of luxury car, or city night with car
  // Size: 2400x900px minimum, landscape, ultra-wide crop
  static const _photo = 'assets/images/home/immersive_bg.jpg';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          Image.asset(
            _photo,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [LD.ink, const Color(0xFF0D2040)],
                ),
              ),
            ),
          ),
          // Subtle dark overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withAlpha(100),
                    Colors.black.withAlpha(20),
                    Colors.black.withAlpha(100),
                  ],
                ),
              ),
            ),
          ),
          // Centered caption
          Center(
            child: RevealOnScroll(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ARRIVE IN STYLE',
                    style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 5.0,
                      color: Colors.white.withAlpha(160),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Every journey, a statement.',
                    style: TextStyle(
                      fontFamily: kSerif,
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// How It Works — editorial numbered steps
// ============================================================

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.bg,
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RevealOnScroll(child: const LuxEyebrow('How It Works')),
                    const SizedBox(height: 20),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Three steps\nto your door.',
                        style: displayText(size: 56, color: LD.ink),
                      ),
                    ),
                  ],
                ),
              ),
              RevealOnScroll(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  'Book in under two minutes.\nFixed price, no surprises.',
                  textAlign: TextAlign.right,
                  style: bodyText(size: 14, color: LD.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HowStep(
                number: '01',
                title: 'Enter your\njourney',
                desc: 'Set pickup, destination and date. We instantly show your fixed price — no guessing.',
                delay: Duration.zero,
              ),
              _HowStep(
                number: '02',
                title: 'Choose your\nvehicle',
                desc: 'Business, First Class, Van, or Electric. Every class, every time — same standard.',
                delay: const Duration(milliseconds: 100),
              ),
              _HowStep(
                number: '03',
                title: 'Relax and\narrive',
                desc: 'Your chauffeur meets you on time, every time. Sit back, disconnect, arrive.',
                delay: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({
    required this.number,
    required this.title,
    required this.desc,
    required this.delay,
  });
  final String number;
  final String title;
  final String desc;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Expanded(
        child: RevealOnScroll(
          delay: delay,
          dy: 28,
          child: Padding(
            padding: const EdgeInsets.only(right: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 130,
                    fontWeight: FontWeight.w300,
                    color: LD.ink.withAlpha(10),
                    height: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
                Container(height: 1, color: LD.border, margin: const EdgeInsets.only(bottom: 24)),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: LD.ink,
                    height: 1.15,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                Text(desc, style: bodyText(size: 14, color: LD.ink3)),
              ],
            ),
          ),
        ),
      );
}

// ============================================================
// Fleet — dark editorial with car assets
// ============================================================

class _FleetSection extends StatelessWidget {
  const _FleetSection();

  static const _vehicles = [
    _FleetItem(
      cls: 'Business Class',
      model: 'Mercedes E-Class\nor similar',
      asset: 'assets/images/vehicles/business/car.png',
      tags: ['Up to 3 passengers', 'Fixed price', 'WiFi'],
      accent: Color(0xFF1B4F8A),
    ),
    _FleetItem(
      cls: 'First Class',
      model: 'Mercedes S-Class\nor similar',
      asset: 'assets/images/vehicles/first_class/car.png',
      tags: ['Up to 3 passengers', 'Premium audio', 'Champagne'],
      accent: Color(0xFF3D2080),
    ),
    _FleetItem(
      cls: 'Business Van',
      model: 'Mercedes V-Class\nor similar',
      asset: 'assets/images/vehicles/van/car.png',
      tags: ['Up to 7 passengers', 'Extra luggage', 'WiFi'],
      accent: Color(0xFF0D3066),
    ),
    _FleetItem(
      cls: 'Electric',
      model: 'Tesla Model S\nor similar',
      asset: 'assets/images/vehicles/electric/car.png',
      tags: ['Up to 3 passengers', 'Zero emissions', 'Tech interior'],
      accent: Color(0xFF1A5C3A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 100, 64, 56),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RevealOnScroll(child: const LuxEyebrow('Our Fleet', dark: true)),
                      const SizedBox(height: 20),
                      RevealOnScroll(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'Premium vehicles,\nno exceptions.',
                          style: displayText(size: 52, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 160),
                  child: Text(
                    'Swipe to explore →'.toUpperCase(),
                    style: TextStyle(
                      fontFamily: kSans,
                      fontSize: 9,
                      letterSpacing: 2.4,
                      color: Colors.white.withAlpha(60),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 460,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(64, 0, 64, 0),
              itemCount: _vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (_, i) => _FleetCard(item: _vehicles[i]),
            ),
          ),
          const SizedBox(height: 72),
        ],
      ),
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
  const _FleetCard({required this.item});
  final _FleetItem item;

  @override
  State<_FleetCard> createState() => _FleetCardState();
}

class _FleetCardState extends State<_FleetCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 340,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2E),
            border: Border.all(
              color: _hover ? widget.item.accent.withAlpha(180) : Colors.white.withAlpha(12),
            ),
          ),
          child: Stack(
            children: [
              // Accent gradient wash
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.item.accent.withAlpha(_hover ? 45 : 20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Car image
              Positioned(
                bottom: 110,
                left: 0,
                right: 0,
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Image.asset(
                    widget.item.asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.directions_car_rounded,
                      size: 80,
                      color: Colors.white.withAlpha(16),
                    ),
                  ),
                ),
              ),
              // Bottom info bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: _hover
                            ? widget.item.accent.withAlpha(120)
                            : Colors.white.withAlpha(14),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.cls.toUpperCase(),
                        style: TextStyle(
                          fontFamily: kSans,
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.8,
                          color: _hover
                              ? widget.item.accent == const Color(0xFF1B4F8A)
                                  ? LD.sphLt
                                  : Colors.white.withAlpha(200)
                              : Colors.white.withAlpha(110),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.item.model,
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.item.tags
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.white.withAlpha(18)),
                                  ),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontFamily: kSans,
                                      fontSize: 9,
                                      letterSpacing: 0.8,
                                      color: Colors.white.withAlpha(90),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ============================================================
// Experience — 4-column feature strip
// ============================================================

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection();

  static const _features = [
    (Icons.schedule_rounded,       'Always on time',   'Flight tracking and proactive planning ensure your driver is ready when you are.'),
    (Icons.receipt_long_outlined,  'Fixed pricing',    'One clear price from the start. Agreed before you step in — no exceptions.'),
    (Icons.shield_outlined,        'Fully insured',    'Every ride is backed by comprehensive commercial insurance across all territories.'),
    (Icons.language_rounded,       'Multilingual',     'Comfortable conversation, guaranteed discretion. We speak your language.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.bg,
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RevealOnScroll(child: const LuxEyebrow('The Experience')),
                    const SizedBox(height: 20),
                    RevealOnScroll(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Every detail,\nconsidered.',
                        style: displayText(size: 52, color: LD.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 72),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _features.asMap().entries.map((e) {
              final i = e.key;
              final f = e.value;
              return Expanded(
                child: RevealOnScroll(
                  delay: Duration(milliseconds: i * 80),
                  dy: 24,
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: i < _features.length - 1 ? 48 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          color: LD.sph,
                          margin: const EdgeInsets.only(bottom: 24),
                        ),
                        Icon(f.$1, size: 22, color: LD.sph),
                        const SizedBox(height: 20),
                        Text(
                          f.$2,
                          style: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: LD.ink,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(f.$3, style: bodyText(size: 13, color: LD.ink3)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Testimonials — large editorial rotating quote
// ============================================================

class _TestimonialsSection extends StatefulWidget {
  const _TestimonialsSection();

  @override
  State<_TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<_TestimonialsSection> {
  int _current = 0;

  static const _reviews = [
    (
      quote: 'Absolutely impeccable from start to finish. The driver was early, the car immaculate. I won\'t use anyone else.',
      name: 'Alexandra M.',
      location: 'London, UK',
    ),
    (
      quote: 'Fixed pricing and reliable drivers make Luxelane the only chauffeur service I trust for all my business travel.',
      name: 'Marcus T.',
      location: 'New York, USA',
    ),
    (
      quote: 'From airport to hotel, every detail was handled perfectly. This is what luxury travel should feel like.',
      name: 'Isabelle R.',
      location: 'Paris, France',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = _reviews[_current];
    return Container(
      color: const Color(0xFFF7F5F0),
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 140),
      child: Column(
        children: [
          // Decorative quote mark
          RevealOnScroll(
            child: Text(
              '“',
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: 180,
                fontWeight: FontWeight.w300,
                color: LD.sph.withAlpha(35),
                height: 0.6,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rotating quote
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              r.quote,
              key: ValueKey(_current),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kSerif,
                fontSize: 34,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: LD.ink,
                height: 1.6,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 44),
          // Attribution
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Column(
              key: ValueKey('attr_$_current'),
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (_) => const Icon(Icons.star_rounded,
                        size: 12, color: LD.sph),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${r.name} · ${r.location}'.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: kSans,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.0,
                    color: LD.ink3,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Dot navigation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _reviews.length,
              (i) => GestureDetector(
                onTap: () => setState(() => _current = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: i == _current ? 28 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _current ? LD.sph : LD.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Business — dark split section
// ============================================================

class _BusinessSection extends StatelessWidget {
  const _BusinessSection();

  static const _perks = [
    'Centralised billing & invoicing',
    'Dedicated account manager',
    'Travel policy compliance tools',
    'Priority booking for executives',
    'Real-time ride monitoring',
    'Multi-city global coverage',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.dark,
      child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left — headline block
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(64, 100, 64, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RevealOnScroll(
                    child: const LuxEyebrow('For Business', dark: true),
                  ),
                  const SizedBox(height: 28),
                  RevealOnScroll(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      'Corporate travel,\nredefined.',
                      style: displayText(size: 52, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 28),
                  RevealOnScroll(
                    delay: const Duration(milliseconds: 160),
                    child: Text(
                      'Luxelane for Business gives your team access to premium chauffeur service with the controls and reporting your finance team demands.',
                      style: bodyText(
                          size: 14, color: const Color(0x78FFFFFF)),
                    ),
                  ),
                  const SizedBox(height: 44),
                  RevealOnScroll(
                    delay: const Duration(milliseconds: 220),
                    child: _GhostBtn(
                        label: 'Learn More', light: true, onTap: () {}),
                  ),
                ],
              ),
            ),
          ),
          // Right — numbered perks list
          // Upload: assets/images/home/business_photo.jpg
          // Ideal: executive entering car / airport VIP lounge
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2E),
                image: DecorationImage(
                  image: const AssetImage('assets/images/home/business_photo.jpg'),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                ),
              ),
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    const Color(0xFF060C16).withAlpha(180),
                    const Color(0xFF0D1B2E).withAlpha(230),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(64, 100, 64, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _perks.asMap().entries.map((e) {
                  final i = e.key;
                  return RevealOnScroll(
                    delay: Duration(milliseconds: i * 70),
                    dy: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withAlpha(14)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '0${i + 1}',
                            style: TextStyle(
                              fontFamily: kSerif,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: LD.sphLt.withAlpha(140),
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            e.value,
                            style: const TextStyle(
                              fontFamily: kSans,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward,
                              size: 13,
                              color: Colors.white.withAlpha(35)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ============================================================
// CTA — full-bleed editorial
// ============================================================

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  // Upload: assets/images/home/cta_bg.jpg
  // Ideal: aerial city shot at night, or car driving on empty highway at dusk
  // Size: 2400×1000px minimum, very wide landscape
  static const _ctaBg = 'assets/images/home/cta_bg.jpg';

  @override
  Widget build(BuildContext context) {
    return Container(
      // Photo loads as decoration — silently falls back to colour if missing
      decoration: BoxDecoration(
        color: LD.ink,
        image: DecorationImage(
          image: const AssetImage(_ctaBg),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      // Gradient overlay on top of photo
      foregroundDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [LD.ink.withAlpha(160), LD.ink.withAlpha(220)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(64, 140, 64, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RevealOnScroll(
            child: Text('Your next ride,',
                style: displayText(size: 96, color: Colors.white)),
          ),
          RevealOnScroll(
            delay: const Duration(milliseconds: 80),
            child: Text(
              'on your terms.',
              style: displayText(
                  size: 96, color: Colors.white, style: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 48),
          RevealOnScroll(
            delay: const Duration(milliseconds: 160),
            child: Text(
              'Fixed price  ·  Professional chauffeurs  ·  Worldwide',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.8,
                color: Colors.white.withAlpha(90),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 52),
          RevealOnScroll(
            delay: const Duration(milliseconds: 220),
            child: Row(
              children: [
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (ctx, auth) => _SolidBtn(
                    label: auth is AuthAuthenticated
                        ? 'Book a Ride'
                        : 'Get Started',
                    white: true,
                    onTap: () => ctx.go('/'),
                  ),
                ),
                const SizedBox(width: 20),
                _GhostBtn(label: 'View Fleet', light: true, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Footer
// ============================================================

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.dark,
      padding: const EdgeInsets.fromLTRB(64, 72, 64, 48),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand column
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LuxLogo(light: true),
                    const SizedBox(height: 20),
                    Text(
                      'Professional chauffeur service.\nWorldwide coverage, fixed pricing.',
                      style: bodyText(
                          size: 13,
                          color: Colors.white.withAlpha(100)),
                    ),
                  ],
                ),
              ),
              // Link columns
              _FooterCol(title: 'Services', links: const [
                'One Way Transfer',
                'By the Hour',
                'Airport Transfer',
                'Corporate'
              ]),
              _FooterCol(title: 'Company', links: const [
                'About Us',
                'For Business',
                'Become a Driver',
                'Press'
              ]),
              _FooterCol(title: 'Support', links: const [
                'Help Center',
                'Terms',
                'Privacy Policy',
                'Contact'
              ]),
            ],
          ),
          const SizedBox(height: 48),
          Container(height: 1, color: Colors.white.withAlpha(18)),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '© 2026 Luxelane. All rights reserved.',
                style: uiLabel(
                    size: 11,
                    color: Colors.white.withAlpha(80),
                    spacing: 0.2),
              ),
              const Spacer(),
              Text(
                'Worldwide · Est. 2020',
                style: uiLabel(
                    size: 11,
                    color: Colors.white.withAlpha(80),
                    spacing: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  const _FooterCol({required this.title, required this.links});
  final String title;
  final List<String> links;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: uiLabel(
                  size: 10,
                  color: Colors.white.withAlpha(180),
                  spacing: 1.8),
            ),
            const SizedBox(height: 16),
            ...links.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  l,
                  style: bodyText(
                      size: 13,
                      color: Colors.white.withAlpha(80)),
                ),
              ),
            ),
          ],
        ),
      );
}
