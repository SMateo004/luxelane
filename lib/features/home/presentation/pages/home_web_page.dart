import 'dart:async';
import 'dart:math' as math;
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
                // How it works
                const _HowItWorksSection(),
                // Fleet
                const _FleetSection(),
                // Experience
                const _ExperienceSection(),
                // Testimonials
                const _TestimonialsSection(),
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
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
        height: 44,
        color: LD.border,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return FractionalTranslation(
                translation: Offset(-_ctrl.value, 0),
                child: Row(
                  children: [
                    for (int r = 0; r < 3; r++)
                      for (int i = 0; i < _items.length; i++) ...[
                        Text(
                          _items[i].toUpperCase(),
                          style: const TextStyle(
                            fontFamily: kSans,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 2.8,
                            color: LD.ink3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: LD.sph,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                  ],
                ),
              );
            },
          ),
        ),
      );
}

// ============================================================
// Stats Section (dark)
// ============================================================

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.sphDim,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Row(
        children: [
          _StatCell(
            target: 150000,
            format: (v) => v >= 150000 ? '150K+' : '${(v / 1000).round()}K',
            label: 'Rides Completed',
          ),
          _StatCell(
            target: 50,
            format: (v) => '$v+',
            label: 'Countries',
          ),
          _StatCell(
            target: 49,
            format: (v) => '${(v / 10).toStringAsFixed(1)}/5',
            label: 'Average Rating',
          ),
          _StatCell(
            target: 24,
            format: (v) => v >= 24 ? '24/7' : '$v/7',
            label: 'Customer Support',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.target,
    required this.format,
    required this.label,
    this.last = false,
  });
  final int target;
  final String Function(int) format;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
                    right: BorderSide(color: Color(0x1FFFFFFF))),
          ),
          child: Column(
            children: [
              AnimatedCounter(
                target: target,
                format: format,
                style: displayText(size: 72, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.2,
                  color: Color(0x59FFFFFF),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );
}

// ============================================================
// How It Works
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
          RevealOnScroll(
            child: const LuxEyebrow('How It Works'),
          ),
          const SizedBox(height: 20),
          RevealOnScroll(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Simple.', style: displayText(size: 56, color: LD.ink)),
                Text('Transparent.',
                    style: displayText(size: 56, color: LD.ink)),
                Text('Reliable.',
                    style: displayText(size: 56, color: LD.ink)),
              ],
            ),
          ),
          const SizedBox(height: 64),
          Row(
            children: [
              _StepCard(
                number: '01',
                title: 'Enter your journey',
                desc:
                    'Set your pickup and destination. Instantly see a fixed price — no surprises, no surge.',
                delay: const Duration(milliseconds: 0),
              ),
              const SizedBox(width: 2),
              _StepCard(
                number: '02',
                title: 'Choose your vehicle',
                desc:
                    'Select the class that suits your needs. Business, First Class, Van, or Electric.',
                delay: const Duration(milliseconds: 100),
              ),
              const SizedBox(width: 2),
              _StepCard(
                number: '03',
                title: 'Relax and arrive',
                desc:
                    'Your professional chauffeur meets you on time. Sit back and enjoy the journey.',
                delay: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatefulWidget {
  const _StepCard({
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
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Expanded(
        child: RevealOnScroll(
          delay: widget.delay,
          dy: 24,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              color: LD.bg2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.number,
                    style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 100,
                      fontWeight: FontWeight.w300,
                      color: Color(0x0A0D1B2E),
                      height: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      color: LD.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.desc,
                    style: bodyText(size: 14, color: LD.ink3),
                  ),
                  const SizedBox(height: 28),
                  // Bottom accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 2,
                    width: _hover ? double.infinity : 0,
                    color: LD.sph,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// Fleet Section
// ============================================================

class _FleetSection extends StatelessWidget {
  const _FleetSection();

  static const _vehicles = [
    _VehicleData(
      cls: 'Business Class',
      model: 'Mercedes E-Class or similar',
      tags: ['3 passengers', 'WiFi', 'Fixed price'],
    ),
    _VehicleData(
      cls: 'First Class',
      model: 'Mercedes S-Class or similar',
      tags: ['3 passengers', 'Premium audio', 'Champagne'],
    ),
    _VehicleData(
      cls: 'Business Van',
      model: 'Mercedes V-Class or similar',
      tags: ['7 passengers', 'Extra luggage', 'WiFi'],
    ),
    _VehicleData(
      cls: 'Electric',
      model: 'Tesla Model S or similar',
      tags: ['3 passengers', 'Zero emissions', 'WiFi'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.bg2,
      padding: const EdgeInsets.fromLTRB(64, 100, 0, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RevealOnScroll(child: const LuxEyebrow('Our Fleet')),
                const SizedBox(height: 20),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Premium vehicles,',
                          style: displayText(size: 52, color: LD.ink)),
                      Text('no exceptions.',
                          style: displayText(size: 52, color: LD.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Horizontal scroll cards
          SizedBox(
            height: 360,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 64),
              itemCount: _vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (_, i) => _FleetCard(data: _vehicles[i]),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _VehicleData {
  const _VehicleData(
      {required this.cls, required this.model, required this.tags});
  final String cls;
  final String model;
  final List<String> tags;
}

class _FleetCard extends StatefulWidget {
  const _FleetCard({required this.data});
  final _VehicleData data;

  @override
  State<_FleetCard> createState() => _FleetCardState();
}

class _FleetCardState extends State<_FleetCard> {
  double _rotX = 0, _rotY = 0;
  bool _hover = false;

  void _onHover(PointerEvent e) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(e.position);
    final w = box.size.width;
    final h = box.size.height;
    setState(() {
      _rotX = -(local.dy / h - 0.5) * 12;
      _rotY = (local.dx / w - 0.5) * 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) {
        setState(() {
          _hover = false;
          _rotX = 0;
          _rotY = 0;
        });
      },
      onHover: _onHover,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: LD.ink.withAlpha(15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotX * math.pi / 180)
          ..rotateY(_rotY * math.pi / 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image placeholder
            Container(
              height: 220,
              color: LD.bg3,
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.directions_car_rounded,
                        size: 80, color: LD.border),
                  ),
                  // Desaturation overlay
                  Container(
                    color:
                        LD.bg2.withAlpha(_hover ? 0 : 30),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.cls.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: kSans,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.8,
                      color: LD.sph,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.data.model,
                    style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: LD.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.data.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: LD.border),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontFamily: kSans,
                                  fontSize: 9,
                                  letterSpacing: 1.0,
                                  color: LD.ink3,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Experience Section
// ============================================================

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.bg,
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RevealOnScroll(child: const LuxEyebrow('The Luxelane Experience')),
          const SizedBox(height: 20),
          RevealOnScroll(
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Every detail,',
                    style: displayText(size: 52, color: LD.ink)),
                Text('considered.',
                    style: displayText(size: 52, color: LD.ink)),
              ],
            ),
          ),
          const SizedBox(height: 64),
          Row(
            children: [
              _ExpCard(
                icon: Icons.schedule_rounded,
                title: 'Always On Time',
                desc:
                    'Flight tracking, real-time traffic, and proactive planning ensure your driver is always ready.',
                delay: Duration.zero,
              ),
              const SizedBox(width: 2),
              _ExpCard(
                icon: Icons.receipt_long_outlined,
                title: 'Fixed Pricing',
                desc:
                    'One clear price from the start. No surge, no hidden fees. Agreed before you step in.',
                delay: const Duration(milliseconds: 100),
              ),
              const SizedBox(width: 2),
              _ExpCard(
                icon: Icons.star_border_rounded,
                title: '5-Star Standard',
                desc:
                    'Vetted, trained, uniformed chauffeurs in premium vehicles — every single ride.',
                delay: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpCard extends StatefulWidget {
  const _ExpCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.delay,
  });
  final IconData icon;
  final String title;
  final String desc;
  final Duration delay;

  @override
  State<_ExpCard> createState() => _ExpCardState();
}

class _ExpCardState extends State<_ExpCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Expanded(
        child: RevealOnScroll(
          delay: widget.delay,
          dy: 20,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
              padding: const EdgeInsets.all(32),
              color: LD.bg2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 2,
                    width: _hover ? double.infinity : 0,
                    color: LD.sph,
                    margin: const EdgeInsets.only(bottom: 24),
                  ),
                  Icon(widget.icon, size: 28, color: LD.sph),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: LD.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.desc,
                      style: bodyText(size: 14, color: LD.ink3)),
                ],
              ),
            ),
          ),
        ),
      );
}

// ============================================================
// Testimonials
// ============================================================

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const _reviews = [
    (
      quote: 'Absolutely impeccable service from start to finish. The driver was professional, punctual, and the car was immaculate.',
      name: 'Alexandra M.',
      location: 'London, UK'
    ),
    (
      quote: 'I use Luxelane for all my business travel. Fixed pricing and reliable drivers make it the only chauffeur service I trust.',
      name: 'Marcus T.',
      location: 'New York, USA'
    ),
    (
      quote: 'From airport pickup to hotel, every detail was handled perfectly. This is what luxury travel should feel like.',
      name: 'Isabelle R.',
      location: 'Paris, France'
    ),
    (
      quote: 'The booking process is seamless and the pricing is transparent. No surprises — just exceptional service.',
      name: 'David K.',
      location: 'Dubai, UAE'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.sphTint,
      padding:
          const EdgeInsets.fromLTRB(64, 100, 0, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RevealOnScroll(
                    child: const LuxEyebrow('What Our Clients Say')),
                const SizedBox(height: 20),
                RevealOnScroll(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trust, built',
                          style: displayText(size: 52, color: LD.ink)),
                      Text('one ride at a time.',
                          style: displayText(size: 52, color: LD.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 64),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => const SizedBox(width: 2),
              itemBuilder: (_, i) => _ReviewCard(r: _reviews[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.r});
  final ({String quote, String name, String location}) r;

  @override
  Widget build(BuildContext context) => Container(
        width: 400,
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (_) => const Icon(Icons.star_rounded,
                    size: 14, color: LD.sph),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                '"${r.quote}"',
                style: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  color: LD.ink,
                  height: 1.55,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: LD.border),
            const SizedBox(height: 16),
            Text(
              '${r.name} · ${r.location}'.toUpperCase(),
              style: const TextStyle(
                fontFamily: kSans,
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.6,
                color: LD.ink2,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
}

// ============================================================
// CTA Section
// ============================================================

class _CtaSection extends StatefulWidget {
  const _CtaSection();

  @override
  State<_CtaSection> createState() => _CtaSectionState();
}

class _CtaSectionState extends State<_CtaSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _orb;

  @override
  void initState() {
    super.initState();
    _orb = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LD.ink,
      padding: const EdgeInsets.symmetric(vertical: 160, horizontal: 64),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated orb
          AnimatedBuilder(
            animation: _orb,
            builder: (_, __) {
              final pulse =
                  0.7 + 0.3 * math.sin(_orb.value * math.pi * 2);
              return Container(
                width: 800 * pulse,
                height: 800 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      LD.sph.withAlpha((50 * pulse).round()),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          Column(
            children: [
              RevealOnScroll(
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: displayText(size: 88, color: Colors.white),
                        children: const [
                          TextSpan(text: 'Your next journey\nstarts '),
                          TextSpan(
                            text: 'here.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: LD.sphLt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Book in under 2 minutes. Fixed price guaranteed.',
                      style: bodyText(size: 15,
                          color: Colors.white.withAlpha(160)),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(width: 16),
                        _GhostBtn(
                          label: 'View Fleet',
                          light: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
