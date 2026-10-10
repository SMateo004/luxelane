import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/home/presentation/pages/home_design.dart';

/// Luxelane buttons: a light, believable relief — a soft top light, a crisp
/// contact shadow and a long diffuse one. Never glossy, never "bubbly".
enum LuxRaisedVariant { primary, secondary }

/// Decoration shared by every raised surface (buttons, selected tiles).
BoxDecoration luxRaisedDecoration({
  LuxRaisedVariant variant = LuxRaisedVariant.primary,
  bool pressed = false,
  bool enabled = true,
  double radius = 4,
}) {
  final primary = variant == LuxRaisedVariant.primary;
  final top = primary ? const Color(0xFF2A62A3) : Colors.white;
  final bottom = primary ? const Color(0xFF17457A) : const Color(0xFFF1F4FA);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: enabled
          ? (pressed ? [bottom, top] : [top, bottom])
          : [top.withValues(alpha: 0.55), bottom.withValues(alpha: 0.55)],
    ),
    border: Border.all(
      color: primary ? const Color(0xFF123A66) : LD.border,
      width: 1,
    ),
    boxShadow: !enabled
        ? const []
        : pressed
            ? [
                BoxShadow(
                  color: LD.ink.withValues(alpha: 0.16),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                // contact shadow
                BoxShadow(
                  color: LD.ink.withValues(alpha: primary ? 0.22 : 0.10),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                // diffuse lift
                BoxShadow(
                  color: (primary ? LD.sph : LD.ink)
                      .withValues(alpha: primary ? 0.26 : 0.08),
                  blurRadius: 18,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
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
  });

  final String label;
  final VoidCallback? onPressed;
  final LuxRaisedVariant variant;
  final bool loading;
  final IconData? icon;
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

  @override
  Widget build(BuildContext context) {
    final primary = widget.variant == LuxRaisedVariant.primary;
    final fg = primary ? Colors.white : LD.ink;
    final text = widget.uppercase ? widget.label.toUpperCase() : widget.label;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: _enabled
              ? (_) {
                  setState(() => _pressed = false);
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            transform: Matrix4.translationValues(
                0, _pressed ? 1.5 : (_hover && _enabled ? -1 : 0), 0),
            decoration: luxRaisedDecoration(
              variant: widget.variant,
              pressed: _pressed,
              enabled: _enabled || widget.loading,
              radius: widget.radius,
            ),
            child: Center(
              widthFactor: widget.expand ? null : 1,
              child: widget.loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.6, color: fg),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 16, color: fg),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kSans,
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: widget.uppercase ? 1.8 : 0.3,
                              color: fg,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
