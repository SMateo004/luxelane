import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/place_model.dart';
import '../../../../core/widgets/components.dart';
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
        color: scrolled
            ? const Color(0xF0FAFBFE)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: scrolled ? LD.border : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: BackdropFilter(
        filter: scrolled
            ? ImageFilter.blur(sigmaX: 24, sigmaY: 24)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56),
          child: Row(
            children: [
              // Logo
              _LuxLogo(light: !scrolled),
              const Spacer(),
              // Nav links
              _NavLink('Services', light: !scrolled, onTap: () {}),
              const SizedBox(width: 32),
              _NavLink('Fleet', light: !scrolled, onTap: () {}),
              const SizedBox(width: 32),
              _NavLink('For Business', light: !scrolled, onTap: () {}),
              const SizedBox(width: 40),
              // Auth-sensitive items
              BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, auth) {
                  if (auth is AuthAuthenticated) {
                    return Row(children: [
                      NotificationBell(
                        color: scrolled ? LD.ink : Colors.white,
                      ),
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
  Offset _mouseNorm = const Offset(0.5, 0.5);

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
    return MouseRegion(
      onHover: (e) {
        final s = MediaQuery.sizeOf(context);
        setState(() => _mouseNorm =
            Offset(e.position.dx / s.width, e.position.dy / s.height));
      },
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            // Canvas background
            Positioned.fill(
              child: _HeroCanvas(
                mouseNorm: _mouseNorm,
                scrollY: widget.scrollY,
              ),
            ),
            // White gradient overlay (left side)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      LD.bg.withAlpha(245),
                      LD.bg.withAlpha(200),
                      LD.bg.withAlpha(100),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.35, 0.55, 0.75],
                  ),
                ),
              ),
            ),
            // Left content
            Positioned(
              left: 64,
              top: 0,
              bottom: 0,
              width: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Eyebrow
                  FadeTransition(
                    opacity: _fade(0.0, 0.4),
                    child: const LuxEyebrow(
                        'Professional Chauffeur Service — Worldwide'),
                  ),
                  const SizedBox(height: 28),
                  // Hero title — 3 lines
                  _ClipReveal(
                    delay: const Duration(milliseconds: 500),
                    child: Text('Your journey,',
                        style: displayText(size: 72, color: LD.ink)),
                  ),
                  _ClipReveal(
                    delay: const Duration(milliseconds: 650),
                    child: Text('perfectly',
                        style: displayText(
                          size: 72,
                          color: LD.sph,
                          style: FontStyle.italic,
                        )),
                  ),
                  _ClipReveal(
                    delay: const Duration(milliseconds: 800),
                    child: Text('driven.',
                        style: displayText(size: 72, color: LD.ink)),
                  ),
                  const SizedBox(height: 28),
                  // Sub-text
                  FadeTransition(
                    opacity: _fade(0.55, 0.85),
                    child: Text(
                      'Fixed prices · Professional drivers\nAvailable in 50+ countries worldwide.',
                      style: bodyText(size: 15, color: LD.ink2),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // CTAs
                  FadeTransition(
                    opacity: _fade(0.65, 0.95),
                    child: Row(
                      children: [
                        _SolidBtn(
                          label: 'Book a Ride',
                          onTap: widget.onSearch,
                        ),
                        const SizedBox(width: 16),
                        _GhostBtn(
                          label: 'View Fleet',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Booking card (right side)
            Positioned(
              right: 64,
              top: 0,
              bottom: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fade(0.6, 1.0),
                  child: _BookingCard(
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
            ),
            // Stats row (bottom left)
            Positioned(
              left: 64,
              bottom: 40,
              child: FadeTransition(
                opacity: _fade(0.75, 1.0),
                child: const _HeroStats(),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

// Solid button
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

// ============================================================
// Hero Canvas — 3D Driving Scene (CustomPainter)
// ============================================================

class _HeroCanvas extends StatefulWidget {
  const _HeroCanvas({required this.mouseNorm, required this.scrollY});
  final Offset mouseNorm;
  final double scrollY;

  @override
  State<_HeroCanvas> createState() => _HeroCanvasState();
}

class _HeroCanvasState extends State<_HeroCanvas>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _t = elapsed.inMilliseconds / 1000.0);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DrivingScenePainter(
          t: _t,
          mouseNorm: widget.mouseNorm,
          scrollSpeed: (widget.scrollY * 0.002).clamp(0, 2),
        ),
        child: const SizedBox.expand(),
      );
}

class _DrivingScenePainter extends CustomPainter {
  _DrivingScenePainter({
    required this.t,
    required this.mouseNorm,
    required this.scrollSpeed,
  });

  final double t;
  final Offset mouseNorm;
  final double scrollSpeed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vanishing point drifts with mouse
    final vpX = w * (0.62 + (mouseNorm.dx - 0.5) * 0.04);
    final vpY = h * (0.42 + (mouseNorm.dy - 0.5) * 0.02);

    // --- Sky ---
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFEEF2FA), Color(0xFFDDE6F5)],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.55));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.55), skyPaint);

    // Sky radial glow at horizon
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1B4F8A).withAlpha(25),
          Colors.transparent,
        ],
        radius: 0.6,
      ).createShader(
          Rect.fromCenter(center: Offset(vpX, vpY), width: w * 1.2, height: h * 0.8));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(vpX, vpY), width: w * 1.2, height: h * 0.5),
        glowPaint);

    // --- Ground ---
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFCDD5E8), Color(0xFFB8C5DC)],
      ).createShader(Rect.fromLTWH(0, vpY, w, h - vpY));
    canvas.drawRect(Rect.fromLTWH(0, vpY, w, h - vpY), groundPaint);

    // --- City silhouette ---
    _drawCitySilhouette(canvas, w, vpX, vpY);

    // --- Road ---
    _drawRoad(canvas, w, h, vpX, vpY);

    // --- Road markings ---
    _drawRoadMarkings(canvas, w, h, vpX, vpY);

    // --- Streetlights ---
    _drawStreetlights(canvas, w, h, vpX, vpY);

    // --- Luxury car ---
    _drawLuxuryCar(canvas, w, h, vpX, vpY);
  }

  void _drawCitySilhouette(Canvas canvas, double w, double vpX, double vpY) {
    final paint = Paint()..color = const Color(0xFFC4CEDF).withAlpha(180);
    final buildingData = [
      [0.35, 0.22, 0.04, 0.13],
      [0.39, 0.30, 0.05, 0.09],
      [0.44, 0.18, 0.03, 0.15],
      [0.47, 0.25, 0.06, 0.12],
      [0.53, 0.20, 0.04, 0.14],
      [0.57, 0.28, 0.05, 0.10],
      [0.62, 0.16, 0.03, 0.17],
      [0.65, 0.24, 0.06, 0.13],
      [0.71, 0.19, 0.04, 0.15],
      [0.75, 0.27, 0.05, 0.11],
    ];
    for (final b in buildingData) {
      final rect = Rect.fromLTWH(
        w * b[0],
        vpY - vpY * b[2] - vpY * b[3],
        w * b[1],
        vpY * b[3],
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _drawRoad(Canvas canvas, double w, double h, double vpX, double vpY) {
    // Road surface
    final roadPaint = Paint()..color = const Color(0xFF9EAABC);
    final roadPath = Path()
      ..moveTo(vpX, vpY)
      ..lineTo(vpX - w * 0.12, h)
      ..lineTo(vpX + w * 0.25, h)
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    // Shoulder lines
    final shoulderPaint = Paint()
      ..color = const Color(0xFFB5C2D6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final side in [-1.0, 1.0]) {
      final lPath = Path()
        ..moveTo(vpX, vpY)
        ..lineTo(vpX + side * w * 0.18, h);
      canvas.drawPath(lPath, shoulderPaint);
    }
  }

  void _drawRoadMarkings(
      Canvas canvas, double w, double h, double vpX, double vpY) {
    final dashPaint = Paint()
      ..color = const Color(0xFFD4DCE9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Center dashes — animated offset
    final dashOffset = (t * (1 + scrollSpeed) * 0.15) % 1.0;
    const dashCount = 12;
    for (int i = 0; i < dashCount; i++) {
      final progress = ((i / dashCount) + dashOffset) % 1.0;
      if (progress > 0.9) continue; // skip partial dash
      // Perspective lerp
      final y1 = vpY + (h - vpY) * progress;
      final y2 = vpY + (h - vpY) * math.min(progress + 0.04, 1.0);
      final x1 = vpX + (vpX * 0 + (vpX - w * 0.05 - vpX) * progress);
      final x2 = vpX + (vpX * 0 + (vpX - w * 0.05 - vpX) * (progress + 0.04).clamp(0, 1));
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
    }
  }

  void _drawStreetlights(
      Canvas canvas, double w, double h, double vpX, double vpY) {
    final polePaint = Paint()
      ..color = const Color(0xFF8A96AA)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const lightCount = 5;
    for (int i = 0; i < lightCount; i++) {
      final progress = (i / lightCount + 0.05).clamp(0.0, 1.0);
      final x = vpX - (vpX - w * 0.1) * progress;
      final yBase = vpY + (h - vpY) * progress;
      final poleH = 60.0 * progress;

      // Pole
      canvas.drawLine(
          Offset(x, yBase), Offset(x, yBase - poleH), polePaint);

      // Arm
      canvas.drawLine(
          Offset(x, yBase - poleH),
          Offset(x + 10 * progress, yBase - poleH - 8 * progress),
          polePaint);

      // Glow
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.amber.withAlpha(80),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCenter(
            center: Offset(x + 10 * progress, yBase - poleH - 10 * progress),
            width: 30 * progress,
            height: 30 * progress,
          ),
        );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + 10 * progress, yBase - poleH - 10 * progress),
          width: 30 * progress,
          height: 20 * progress,
        ),
        glowPaint,
      );
    }
  }

  void _drawLuxuryCar(
      Canvas canvas, double w, double h, double vpX, double vpY) {
    // Position car at left-center of screen
    final carX = w * 0.18;
    final carY = h * 0.72;
    final carW = w * 0.28;
    final carH = carW * 0.28;

    // Ground shadow
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x50000000),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(carX + carW * 0.5, carY + carH * 0.85),
          width: carW * 1.1,
          height: carH * 0.4,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(carX + carW * 0.5, carY + carH * 0.85),
        width: carW * 1.1,
        height: carH * 0.3,
      ),
      shadowPaint,
    );

    // Car body — sapphire gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF2E5FA0), Color(0xFF0D2848)],
      ).createShader(Rect.fromLTWH(carX, carY, carW, carH));

    // Fastback silhouette
    final bodyPath = Path()
      ..moveTo(carX + carW * 0.08, carY + carH * 0.55) // front bumper base
      ..lineTo(carX + carW * 0.12, carY + carH * 0.28) // hood rise
      ..lineTo(carX + carW * 0.32, carY + carH * 0.10) // windscreen base
      ..lineTo(carX + carW * 0.50, carY + carH * 0.01) // roof peak
      ..lineTo(carX + carW * 0.78, carY + carH * 0.08) // rear roof
      ..lineTo(carX + carW * 0.92, carY + carH * 0.30) // trunk
      ..lineTo(carX + carW * 0.96, carY + carH * 0.55) // rear base
      ..lineTo(carX + carW * 0.08, carY + carH * 0.55)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Glass — semi-transparent blue
    final glassPaint = Paint()..color = const Color(0x441E4B82);
    final glassPath = Path()
      ..moveTo(carX + carW * 0.34, carY + carH * 0.12)
      ..lineTo(carX + carW * 0.50, carY + carH * 0.04)
      ..lineTo(carX + carW * 0.74, carY + carH * 0.11)
      ..lineTo(carX + carW * 0.68, carY + carH * 0.25)
      ..lineTo(carX + carW * 0.38, carY + carH * 0.25)
      ..close();
    canvas.drawPath(glassPath, glassPaint);

    // Chrome trim line
    final trimPaint = Paint()
      ..color = const Color(0xFFB0C0D8).withAlpha(180)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(carX + carW * 0.08, carY + carH * 0.38),
      Offset(carX + carW * 0.94, carY + carH * 0.38),
      trimPaint,
    );

    // B-pillar
    final bpillarPaint = Paint()..color = const Color(0xFF0D2848);
    canvas.drawRect(
      Rect.fromLTWH(
        carX + carW * 0.52,
        carY + carH * 0.10,
        carW * 0.03,
        carH * 0.15,
      ),
      bpillarPaint,
    );

    // Wheels
    _drawWheel(canvas, carX + carW * 0.22, carY + carH * 0.68, carH * 0.20);
    _drawWheel(canvas, carX + carW * 0.76, carY + carH * 0.68, carH * 0.20);

    // Headlights
    final headlightPaint = Paint()..color = const Color(0xFFF0F4FF);
    canvas.drawRect(
      Rect.fromLTWH(
          carX + carW * 0.08, carY + carH * 0.32, carW * 0.06, carH * 0.06),
      headlightPaint,
    );
    // Headlight glow
    final hlGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withAlpha(160), Colors.transparent],
      ).createShader(
        Rect.fromCenter(
          center: Offset(carX + carW * 0.11, carY + carH * 0.35),
          width: carW * 0.14,
          height: carH * 0.12,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(carX + carW * 0.07, carY + carH * 0.35),
        width: carW * 0.14,
        height: carH * 0.10,
      ),
      hlGlowPaint,
    );

    // Taillights
    final taillightPaint = Paint()..color = const Color(0xFFCC2222);
    canvas.drawRect(
      Rect.fromLTWH(
          carX + carW * 0.88, carY + carH * 0.32, carW * 0.06, carH * 0.06),
      taillightPaint,
    );
  }

  void _drawWheel(Canvas canvas, double cx, double cy, double r) {
    // Tire
    final tirePaint = Paint()..color = const Color(0xFF1A1E28);
    canvas.drawCircle(Offset(cx, cy), r, tirePaint);
    // Rim
    final rimPaint = Paint()
      ..color = const Color(0xFFB8C6D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.22;
    canvas.drawCircle(Offset(cx, cy), r * 0.68, rimPaint);
    // Spokes (5-spoke, rotates with time)
    final spokePaint = Paint()
      ..color = const Color(0xFFB8C6D8)
      ..strokeWidth = r * 0.1;
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * math.pi * 2 + t * 3;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * r * 0.65,
            cy + math.sin(angle) * r * 0.65),
        spokePaint,
      );
    }
    // Hub
    canvas.drawCircle(Offset(cx, cy), r * 0.15,
        Paint()..color = const Color(0xFF9AAABB));
  }

  @override
  bool shouldRepaint(_DrivingScenePainter old) =>
      old.t != t || old.mouseNorm != mouseNorm;
}

// ============================================================
// Hero stats row
// ============================================================

class _HeroStats extends StatelessWidget {
  const _HeroStats();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('150K+', 'Rides'),
      ('50+', 'Countries'),
      ('4.9/5', 'Rating'),
      ('24/7', 'Support'),
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0)
            Container(width: 1, height: 32, color: LD.border,
                margin: const EdgeInsets.symmetric(horizontal: 24)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats[i].$1,
                style: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: LD.ink,
                  height: 1,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stats[i].$2.toUpperCase(),
                style: const TextStyle(
                  fontFamily: kSans,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.8,
                  color: LD.ink3,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ============================================================
// Booking Card
// ============================================================

class _BookingCard extends StatefulWidget {
  const _BookingCard({
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
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  @override
  Widget build(BuildContext context) {
    final isOneWay = widget.serviceType == ServiceType.oneWay;

    return Container(
      width: 356,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        border: const Border(
          top: BorderSide(color: LD.sph, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: LD.ink.withAlpha(20),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan your journey',
                  style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: LD.ink,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fixed price · No surge pricing',
                  style: TextStyle(
                    fontFamily: kSans,
                    fontSize: 11,
                    color: LD.ink3,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                // Tabs
                Row(
                  children: [
                    _Tab(
                      label: 'One Way',
                      selected: isOneWay,
                      onTap: () => widget
                          .onServiceTypeChanged(ServiceType.oneWay),
                    ),
                    const SizedBox(width: 4),
                    _Tab(
                      label: 'By the Hour',
                      selected: !isOneWay,
                      onTap: () => widget
                          .onServiceTypeChanged(ServiceType.byTheHour),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: LD.border),
          // Inputs
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Origin
                _CardField(
                  icon: Icons.trip_origin,
                  child: PlaceAutocompleteField(
                    label: 'Pickup',
                    hint: 'Street, airport…',
                    initialValue: widget.origin,
                    onPlaceSelected: widget.onOriginSelected,
                    onMapPick: widget.onOriginMapPick,
                  ),
                ),
                Container(height: 1, color: LD.border),
                // Destination
                if (isOneWay) ...[
                  _CardField(
                    icon: Icons.location_on_outlined,
                    child: PlaceAutocompleteField(
                      label: 'Destination',
                      initialValue: widget.destination,
                      onPlaceSelected: widget.onDestinationSelected,
                      onMapPick: widget.onDestinationMapPick,
                    ),
                  ),
                  Container(height: 1, color: LD.border),
                ],
                // Date / Hours
                if (!isOneWay) ...[
                  _CardField(
                    icon: Icons.schedule,
                    child: _HoursPicker(
                      hours: widget.hours,
                      onChanged: widget.onHoursChanged,
                    ),
                  ),
                  Container(height: 1, color: LD.border),
                ],
                _CardField(
                  icon: Icons.calendar_today_outlined,
                  child: _DatePicker(
                    date: widget.date,
                    onChanged: widget.onDateChanged,
                  ),
                ),
                const SizedBox(height: 16),
                // CTA
                _SolidBtn(
                  label: 'Get Prices →',
                  onTap: widget.onSearch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          color: selected ? LD.sph : LD.bg2,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kSans,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: selected ? Colors.white : LD.ink3,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
}

class _CardField extends StatelessWidget {
  const _CardField({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: LD.ink3),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
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

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked);
        },
        child: Text(
          _fmt(date),
          style: const TextStyle(
            fontFamily: kSans,
            fontSize: 13,
            color: LD.ink,
            decoration: TextDecoration.none,
          ),
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
