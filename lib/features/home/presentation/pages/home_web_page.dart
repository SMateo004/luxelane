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

part 'web/nav.dart';
part 'web/trust.dart';
part 'web/hero.dart';
part 'web/marquee.dart';
part 'web/fleet.dart';
part 'web/business_cta.dart';
part 'web/footer.dart';
part 'web/book.dart';

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

                  // ── Trust: promise + how it works ─────────────────────
                  _TrustSection(onBook: widget.onSearch),

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

