import 'package:flutter/material.dart';

import '../../app/theme/lux_motion.dart';
import '../../features/home/presentation/pages/home_design.dart';
import 'lux_focus.dart';

/// Botones de Luxelane: superficies planas y silenciosas. Sin degradados ni
/// brillos; la profundidad la da una sola sombra difusa del color del botón,
/// y al presionar el botón se hunde (escala y sombra se recogen).
enum LuxRaisedVariant {
  /// Acción principal: zafiro sólido. Una por pantalla.
  primary,

  /// Acción alternativa: blanco con filete.
  secondary,

  /// Acción discreta: solo texto, sin caja.
  ghost,

  /// Acción destructiva (cancelar un viaje, eliminar).
  danger,
}

const _danger = Color(0xFFB83A3A);

Color _fill(LuxRaisedVariant v, bool pressed) => switch (v) {
      LuxRaisedVariant.primary => pressed ? LD.sphDim : LD.sph,
      LuxRaisedVariant.secondary => pressed ? LD.bg2 : Colors.white,
      LuxRaisedVariant.ghost => pressed ? LD.sphTint : Colors.transparent,
      LuxRaisedVariant.danger => pressed ? const Color(0xFF962E2E) : _danger,
    };

/// Color del texto e iconos sobre cada variante.
Color luxButtonForeground(LuxRaisedVariant v) => switch (v) {
      LuxRaisedVariant.primary || LuxRaisedVariant.danger => Colors.white,
      LuxRaisedVariant.secondary => LD.ink,
      LuxRaisedVariant.ghost => LD.sph,
    };

/// Decoración común a botones y superficies seleccionadas.
BoxDecoration luxRaisedDecoration({
  LuxRaisedVariant variant = LuxRaisedVariant.primary,
  bool pressed = false,
  bool enabled = true,
  double radius = 12,
}) {
  final solid =
      variant == LuxRaisedVariant.primary || variant == LuxRaisedVariant.danger;
  final fill = _fill(variant, pressed);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: enabled ? fill : fill.withValues(alpha: solid ? 0.38 : 0.6),
    border: variant == LuxRaisedVariant.secondary
        ? Border.all(color: pressed ? LD.ink3 : LD.border)
        : null,
    boxShadow: !enabled || pressed || variant == LuxRaisedVariant.ghost
        ? const []
        : [
            BoxShadow(
              color: (solid ? fill : LD.ink).withValues(
                alpha: solid ? 0.24 : 0.06,
              ),
              blurRadius: solid ? 20 : 12,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
  );
}

class LuxRaisedButton extends StatefulWidget {
  const LuxRaisedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LuxRaisedVariant.primary,
    this.loading = false,
    this.icon,
    this.height = 52,
    this.expand = true,
    this.radius = 4,
    this.uppercase = true,
    this.fontSize = 11.5,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final LuxRaisedVariant variant;
  final bool loading;
  final IconData? icon;

  /// Icono al final (p. ej. una flecha que invita a avanzar).
  final IconData? trailingIcon;
  final double height;
  final bool expand;
  final double radius;
  final bool uppercase;
  final double fontSize;

  @override
  State<LuxRaisedButton> createState() => _LuxRaisedButtonState();
}

class _LuxRaisedButtonState extends State<LuxRaisedButton> {
  bool _pressed = false;
  bool _hover = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _activate() {
    if (widget.variant == LuxRaisedVariant.primary) {
      LuxHaptics.confirm();
    } else {
      LuxHaptics.tap();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final fg = luxButtonForeground(widget.variant);
    final text = widget.uppercase ? widget.label.toUpperCase() : widget.label;
    final duration = LuxMotion.of(context, LuxMotion.fast);

    final label = Row(
      key: const ValueKey('label'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            text,
            // Dos líneas: con la letra al 200 % las acciones del chófer se
            // cortaban («Navegar a la reco…», E8). El botón crece.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kSans,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: widget.uppercase ? 1.8 : 0.2,
              color: fg,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 10),
          Icon(widget.trailingIcon, size: 18, color: fg),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: LuxFocusable(
        onActivate: _enabled ? _activate : null,
        radius: widget.radius,
        child: MouseRegion(
          cursor:
              _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() {
            _hover = false;
            _pressed = false;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _enabled ? (_) => _setPressed(true) : null,
            onTapCancel: () => _setPressed(false),
            onTapUp: _enabled
                ? (_) {
                    _setPressed(false);
                    _activate();
                  }
                : null,
            child: AnimatedScale(
              scale: _pressed ? LuxMotion.pressedScale : 1,
              duration: duration,
              curve: LuxMotion.emphasized,
              child: AnimatedContainer(
                duration: duration,
                curve: LuxMotion.emphasized,
                constraints: BoxConstraints(minHeight: widget.height),
                width: widget.expand ? double.infinity : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                transform: Matrix4.translationValues(
                  0,
                  _hover && _enabled && !_pressed ? -1 : 0,
                  0,
                ),
                decoration: luxRaisedDecoration(
                  variant: widget.variant,
                  pressed: _pressed,
                  enabled: _enabled || widget.loading,
                  radius: widget.radius,
                ),
                child: Center(
                  widthFactor: widget.expand ? null : 1,
                  child: AnimatedSwitcher(
                    duration: LuxMotion.of(context, LuxMotion.base),
                    switchInCurve: LuxMotion.decelerate,
                    switchOutCurve: LuxMotion.accelerate,
                    child: widget.loading
                        ? LuxLoadingDots(
                            key: const ValueKey('loading'),
                            color: fg,
                          )
                        : label,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tres puntos que respiran: espera tranquila dentro de un botón, en lugar
/// de una rueda que gira.
class LuxLoadingDots extends StatefulWidget {
  const LuxLoadingDots({super.key, this.color = Colors.white, this.size = 6});
  final Color color;
  final double size;

  @override
  State<LuxLoadingDots> createState() => _LuxLoadingDotsState();
}

class _LuxLoadingDotsState extends State<LuxLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando',
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              // Cada punto se enciende con un pequeño desfase.
              final t = (_c.value - i * 0.18) % 1.0;
              final wave = t < 0.5 ? t * 2 : (1 - t) * 2;
              final eased = Curves.easeInOut.transform(wave);
              return Container(
                width: widget.size,
                height: widget.size,
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.45),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.35 + 0.65 * eased),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      );
}
