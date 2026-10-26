import 'package:flutter/widgets.dart';

import '../../app/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// LuxFocusable — hace alcanzable con teclado una superficie tocable hecha con
// GestureDetector (que no recibe foco): Tab la enfoca, Intro o Espacio la
// activan, y se dibuja un anillo de foco zafiro solo cuando se navega con
// teclado. Sin esto, con Tab no se llegaba a «Iniciar sesión» (E7).
// ---------------------------------------------------------------------------

class LuxFocusable extends StatefulWidget {
  const LuxFocusable({
    super.key,
    required this.onActivate,
    required this.child,
    this.radius = 4,
  });

  /// null: deshabilitada (fuera del orden de foco).
  final VoidCallback? onActivate;
  final Widget child;
  final double radius;

  @override
  State<LuxFocusable> createState() => _LuxFocusableState();
}

class _LuxFocusableState extends State<LuxFocusable> {
  bool _ring = false;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        enabled: widget.onActivate != null,
        onShowFocusHighlight: (v) {
          if (_ring != v) setState(() => _ring = v);
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onActivate?.call();
              return null;
            },
          ),
        },
        child: CustomPaint(
          foregroundPainter: _ring ? _FocusRingPainter(widget.radius) : null,
          child: widget.child,
        ),
      );
}

/// Anillo a 3 px del borde: con un hueco del color del fondo, se ve también
/// sobre un botón zafiro (dibujado encima, del mismo color, no se veía).
class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).inflate(3),
          Radius.circular(radius + 3),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = LuxColors.sapphire,
      );

  @override
  bool shouldRepaint(_FocusRingPainter old) => old.radius != radius;
}
