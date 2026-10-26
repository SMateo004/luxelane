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

/// Área táctil de al menos 48×48 alrededor de un control que a la vista es
/// más pequeño (avatar de 36, círculos de 40): el control se ve igual y el
/// dedo tiene 48 px (E9). Va dentro del detector de toques, que debe ser
/// opaco para recibir los toques del margen.
class LuxTapArea extends StatelessWidget {
  const LuxTapArea({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      );
}
