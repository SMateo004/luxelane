import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/lux_motion.dart';

// ---------------------------------------------------------------------------
// LuxFadeIn — entrada suave (aparece y sube 10 px). Con [index], los
// elementos de una lista entran en cascada en lugar de todos a la vez.
// ---------------------------------------------------------------------------

class LuxFadeIn extends StatefulWidget {
  const LuxFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 10,
    this.delay = Duration.zero,
  });

  final Widget child;
  final int index;
  final double offset;
  final Duration delay;

  @override
  State<LuxFadeIn> createState() => _LuxFadeInState();
}

class _LuxFadeInState extends State<LuxFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: LuxMotion.slow);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: LuxMotion.decelerate);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted || _timer != null) return;
    if (LuxMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    // Las listas largas no esperan: la cascada se corta en el 8.º elemento.
    final wait = widget.delay + LuxMotion.stagger * math.min(widget.index, 8);
    _timer = Timer(wait, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        builder: (_, child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _t.value)),
            child: child,
          ),
        ),
        child: widget.child,
      );
}

// ---------------------------------------------------------------------------
// LuxSkeleton — mientras algo carga se muestra su forma, con un brillo que
// recorre la superficie. La pantalla no salta cuando llegan los datos.
// ---------------------------------------------------------------------------

class LuxShimmer extends StatefulWidget {
  const LuxShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<LuxShimmer> createState() => _LuxShimmerState();
}

class _LuxShimmerState extends State<LuxShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (LuxMotion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final x = -1.0 + 3.0 * _c.value;
          return LinearGradient(
            begin: Alignment(x - 1, 0),
            end: Alignment(x, 0),
            colors: const [
              LuxColors.surfaceMuted,
              Color(0xFFFBFCFE),
              LuxColors.surfaceMuted,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Un bloque gris redondeado: la "forma" de un texto o una imagen.
class LuxSkeletonBox extends StatelessWidget {
  const LuxSkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = LuxRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: LuxColors.surfaceMuted,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Lista de tarjetas en esqueleto, para pantallas que cargan una lista.
class LuxSkeletonList extends StatelessWidget {
  const LuxSkeletonList({super.key, this.count = 4, this.itemHeight = 96});
  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando',
        child: LuxShimmer(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(LuxSpacing.md),
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(height: LuxSpacing.sm),
            itemBuilder: (_, __) => Container(
              height: itemHeight,
              padding: const EdgeInsets.all(LuxSpacing.md),
              decoration: BoxDecoration(
                color: LuxColors.surface,
                borderRadius: BorderRadius.circular(LuxRadius.lg),
                border: Border.all(color: LuxColors.border),
              ),
              child: const Row(
                children: [
                  LuxSkeletonBox(width: 44, height: 44, radius: 22),
                  SizedBox(width: LuxSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LuxSkeletonBox(width: 160, height: 12),
                        SizedBox(height: 10),
                        LuxSkeletonBox(width: 110, height: 10),
                      ],
                    ),
                  ),
                  LuxSkeletonBox(width: 48, height: 14),
                ],
              ),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Momento de éxito — un círculo que se cierra y un trazo que dibuja el
// visto bueno. Cierra una decisión importante con calma y certeza.
// ---------------------------------------------------------------------------

class LuxSuccessMark extends StatefulWidget {
  const LuxSuccessMark({super.key, this.size = 72});
  final double size;

  @override
  State<LuxSuccessMark> createState() => _LuxSuccessMarkState();
}

class _LuxSuccessMarkState extends State<LuxSuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (LuxMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Listo',
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            size: Size.square(widget.size),
            painter: _SuccessPainter(_c.value),
          ),
        ),
      );
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // 0–0.55: el círculo se rellena; 0.45–1: el visto se dibuja.
    final ring = LuxMotion.decelerate.transform((t / 0.55).clamp(0, 1));
    final tick =
        LuxMotion.emphasized.transform(((t - 0.45) / 0.55).clamp(0, 1));

    canvas.drawCircle(
      c,
      r * (0.86 + 0.14 * ring),
      Paint()..color = LuxColors.sapphire.withValues(alpha: ring),
    );

    if (tick <= 0) return;
    final path = Path()
      ..moveTo(c.dx - r * 0.34, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.08, c.dy + r * 0.27)
      ..lineTo(c.dx + r * 0.36, c.dy - r * 0.24);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * tick),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SuccessPainter old) => old.t != t;
}

/// Confirma una acción importante con el visto animado y una frase.
/// Se cierra sola a los ~1,8 s (o al tocar).
Future<void> showLuxSuccess(
  BuildContext context, {
  required String title,
  String? message,
}) {
  LuxHaptics.success();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: LuxColors.bg.withValues(alpha: 0.88),
    transitionDuration: LuxMotion.of(context, LuxMotion.base),
    pageBuilder: (ctx, _, __) {
      Future<void>.delayed(const Duration(milliseconds: 1800), () {
        if (ctx.mounted && Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
      });
      return Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(LuxSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LuxSuccessMark(),
                  const SizedBox(height: LuxSpacing.lg),
                  LuxFadeIn(
                    delay: const Duration(milliseconds: 380),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: LuxTypography.displayMedium.copyWith(fontSize: 30),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: LuxSpacing.sm),
                    LuxFadeIn(
                      delay: const Duration(milliseconds: 460),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: LuxTypography.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: LuxMotion.decelerate),
      child: child,
    ),
  );
}
