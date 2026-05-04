// ============================================================
// Luxelane Design Tokens — Light editorial palette
// ============================================================

import 'package:flutter/material.dart';

abstract class LD {
  // Backgrounds
  static const bg     = Color(0xFFFAFBFE);
  static const bg2    = Color(0xFFF2F5FB);
  static const bg3    = Color(0xFFE8EDF7);
  // Text
  static const ink    = Color(0xFF0D1B2E);
  static const ink2   = Color(0xFF2C3D55);
  static const ink3   = Color(0xFF637490);
  // Sapphire
  static const sph    = Color(0xFF1B4F8A);
  static const sphLt  = Color(0xFF2E6FBF);
  static const sphDim = Color(0xFF0D3066);
  static const sphTint= Color(0xFFEEF3FA);
  // Border
  static const border = Color(0xFFDDE4F0);
  // Dark
  static const dark   = Color(0xFF070E18);
}

// Semantic font family names
const kSerif = 'Cormorant Garamond';   // loaded via Google Fonts in index.html
const kSans  = 'Helvetica Neue';       // system Helvetica / fallback Arial

TextStyle eyebrow({Color color = LD.sph}) => TextStyle(
  fontFamily: kSans,
  fontSize: 10,
  fontWeight: FontWeight.w400,
  letterSpacing: 3.2,
  color: color,
  decoration: TextDecoration.none,
);

TextStyle uiLabel({double size = 10, Color color = LD.ink3, double spacing = 2.4}) =>
    TextStyle(
      fontFamily: kSans,
      fontSize: size,
      fontWeight: FontWeight.w400,
      letterSpacing: spacing,
      color: color,
      decoration: TextDecoration.none,
    );

TextStyle displayText({
  double size = 80,
  Color color = LD.ink,
  FontStyle style = FontStyle.normal,
  FontWeight weight = FontWeight.w300,
}) =>
    TextStyle(
      fontFamily: kSerif,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      color: color,
      height: 0.95,
      letterSpacing: -0.02 * size,
      decoration: TextDecoration.none,
    );

TextStyle bodyText({double size = 15, Color color = LD.ink2}) => TextStyle(
  fontFamily: kSans,
  fontSize: size,
  fontWeight: FontWeight.w300,
  color: color,
  height: 1.78,
  decoration: TextDecoration.none,
);

// ============================================================
// Shared helper widgets
// ============================================================

class LuxEyebrow extends StatelessWidget {
  const LuxEyebrow(this.text, {super.key, this.color = LD.sph, this.dark = false});
  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: eyebrow(color: dark ? const Color(0x7EFFFFFF) : color),
      );
}

// ============================================================
// Scroll-reveal wrapper
// ============================================================

class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.dx = 0,
    this.dy = 36,
  });
  final Widget child;
  final Duration delay;
  final double dx;
  final double dy;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: const Cubic(0.16, 1, 0.3, 1));
    _slide = Tween<Offset>(
      begin: Offset(widget.dx / 100, widget.dy / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: const Cubic(0.16, 1, 0.3, 1)));
  }

  void trigger() {
    if (_triggered) return;
    _triggered = true;
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
  Widget build(BuildContext context) => VisibilityDetectorWrapper(
        onVisible: trigger,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(opacity: _fade, child: widget.child),
        ),
      );
}

// Lightweight visibility detector using LayoutBuilder + NotificationListener
class VisibilityDetectorWrapper extends StatefulWidget {
  const VisibilityDetectorWrapper({
    super.key,
    required this.onVisible,
    required this.child,
  });
  final VoidCallback onVisible;
  final Widget child;

  @override
  State<VisibilityDetectorWrapper> createState() =>
      _VisibilityDetectorWrapperState();
}

class _VisibilityDetectorWrapperState
    extends State<VisibilityDetectorWrapper> {
  final _key = GlobalKey();
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_fired || !mounted) return;
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = MediaQuery.sizeOf(context);
    if (pos.dy < size.height * 1.1) {
      _fired = true;
      widget.onVisible();
    }
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _check();
          return false;
        },
        child: KeyedSubtree(key: _key, child: widget.child),
      );
}

// ============================================================
// Animated counter
// ============================================================

class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.target,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 1800),
  });
  final int target;
  final String Function(int) format;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
  }

  void start() {
    if (_started) return;
    _started = true;
    _ctrl.forward();
  }

  double _quarticEase(double t) => 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetectorWrapper(
        onVisible: start,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final val =
                (_quarticEase(_ctrl.value) * widget.target).round();
            return Text(
              widget.format(val),
              style: widget.style ??
                  displayText(size: 72, color: Colors.white),
            );
          },
        ),
      );
}
