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
// Scroll notifier — propagates scroll position to the tree
// ============================================================

/// A [ChangeNotifier] that holds the current vertical scroll offset.
/// Call [update] from the parent [ScrollController] listener.
class LuxScrollNotifier extends ChangeNotifier {
  double _scrollY = 0;
  double get scrollY => _scrollY;

  void update(double y) {
    _scrollY = y;
    notifyListeners();
  }
}

/// An [InheritedNotifier] that makes [LuxScrollNotifier] accessible to the
/// entire widget tree below [WebHomePage]. Descendants that call
/// [LuxScrollProvider.of] will rebuild (and have [didChangeDependencies] fired)
/// every time the scroll position changes — which is exactly what
/// [VisibilityDetectorWrapper] needs.
class LuxScrollProvider extends InheritedNotifier<LuxScrollNotifier> {
  const LuxScrollProvider({
    super.key,
    required LuxScrollNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Returns the [LuxScrollNotifier] and registers a dependency on it,
  /// so the calling widget rebuilds on every scroll update.
  static LuxScrollNotifier? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LuxScrollProvider>()?.notifier;
}

// ============================================================
// Scroll-reveal wrapper  (portfolio / editorial reveal)
// ============================================================

/// Wraps [child] so it animates in (fade + slide + scale) the first time it
/// enters the viewport. Works with [LuxScrollProvider]: any ancestor that
/// calls [LuxScrollProvider.of] will receive a dependency update on every
/// scroll tick, driving [didChangeDependencies] → [_check].
class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    /// Horizontal offset in logical pixels (positive = from right, negative = from left)
    this.dx = 0,
    /// Vertical offset in logical pixels (positive = from below)
    this.dy = 72,
    this.duration = const Duration(milliseconds: 1100),
    /// Fraction of viewport height the element must pass before triggering.
    /// 1.0 = trigger when top edge reaches the bottom of the screen.
    /// 0.85 = trigger slightly earlier (recommended for large blocks).
    this.threshold = 1.0,
  });

  final Widget child;
  final Duration delay;
  final double dx;
  final double dy;
  final Duration duration;
  final double threshold;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  bool _triggered = false;

  static const _curve = Cubic(0.16, 1, 0.3, 1); // expo-out feel

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _ctrl, curve: _curve);

    _fade = Tween<double>(begin: 0, end: 1).animate(curved);

    _slide = Tween<Offset>(
      begin: Offset(widget.dx / 800, widget.dy / 800),
      end: Offset.zero,
    ).animate(curved);

    // Subtle scale: 0.94 → 1.0 gives a satisfying "emerge" feel
    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(curved);
  }

  void _triggerIfVisible() {
    if (_triggered || !mounted) return;
    final ctx = context;
    // We need the rendered box of the actual child — use a post-frame callback
    // so layout is done before we measure.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_triggered || !mounted) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final pos = box.localToGlobal(Offset.zero);
      final screenH = MediaQuery.sizeOf(ctx).height;
      if (pos.dy < screenH * widget.threshold) {
        _triggered = true;
        Future.delayed(widget.delay, () {
          if (mounted) _ctrl.forward();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to LuxScrollProvider — this fires on every scroll tick.
    LuxScrollProvider.of(context);
    _triggerIfVisible();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-register dependency each build so didChangeDependencies keeps firing.
    LuxScrollProvider.of(context);
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.bottomCenter,
          child: widget.child,
        ),
      ),
    );
  }
}

// ============================================================
// Visibility detector (used by AnimatedCounter)
// ============================================================

/// Fires [onVisible] the first time the widget enters the viewport.
/// Listens to [LuxScrollProvider] instead of a [NotificationListener] — the
/// latter only catches bubbles from *descendants*, not ancestor scrollables.
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
  bool _fired = false;

  void _check() {
    if (_fired || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.sizeOf(context).height;
    if (pos.dy < screenH * 1.05) {
      _fired = true;
      widget.onVisible();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LuxScrollProvider.of(context); // register dependency
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  Widget build(BuildContext context) {
    LuxScrollProvider.of(context); // keep dependency alive each rebuild
    return widget.child;
  }
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
