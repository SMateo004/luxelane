import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/widgets/lux_focus.dart';

/// Botón de ayuda: se activa manteniéndolo pulsado [holdDuration] (con un
/// anillo que se llena y vibración) para evitar toques accidentales. Con
/// lector de pantalla, un doble toque abre una confirmación.
///
/// La duración la mide un temporizador real, no la animación: «quitar
/// animaciones» del sistema acorta los AnimationController al 5 % (2 s
/// pasarían a 100 ms) y timeDilation los alarga. El anillo solo lo dibuja.
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.onActivated,
    this.holdDuration = const Duration(seconds: 2),
    this.label = 'Ayuda',
    this.size = 52,
  });

  final VoidCallback onActivated;
  final Duration holdDuration;
  final String label;
  final double size;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  /// Solo el anillo (visual).
  late final AnimationController _hold;

  /// Lo que de verdad cuenta los [SosButton.holdDuration].
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: widget.holdDuration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hold.dispose();
    super.dispose();
  }

  void _activate() {
    _timer = null;
    HapticFeedback.heavyImpact();
    _hold.value = 0;
    widget.onActivated();
  }

  void _start() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    _timer = Timer(widget.holdDuration, () {
      if (mounted) _activate();
    });
    _hold.forward(from: 0);
  }

  void _release() {
    // Soltar antes de tiempo no envía nada (aunque aún no haya avanzado
    // ningún fotograma); el anillo vuelve a vacío.
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    _hold.stop();
    if (LuxMotion.reduced(context)) {
      _hold.value = 0;
    } else {
      _hold.animateBack(0, duration: LuxMotion.base);
    }
  }

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Avisar a central?'),
        content: const Text(
          'Central recibirá tu aviso y tu ubicación mientras dure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Avisar a central'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) widget.onActivated();
  }

  @override
  Widget build(BuildContext context) {
    // Con lector de pantalla mantener pulsado es incómodo: un toque pide
    // confirmación.
    final screenReader = MediaQuery.accessibleNavigationOf(context);
    // Con teclado (Tab + Intro) también pide confirmación (E7). Fuera del
    // Semantics con excludeSemantics: dentro, el nodo de foco se perdía y en
    // la web Tab no llegaba al SOS.
    return LuxFocusable(
      onActivate: _confirm,
      radius: widget.size / 2,
      child: Semantics(
        button: true,
        label: '${widget.label} SOS',
        hint: 'Mantén pulsado dos segundos para avisar a central. Con lector '
            'de pantalla, toca dos veces y confirma.',
        onTap: _confirm,
        excludeSemantics: true,
        // Listener y no reconocedores de gestos: un toque largo no compite con
        // otros gestos ni se cancela a mitad.
        child: Listener(
          key: const ValueKey('sos-button'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: screenReader ? null : (_) => _start(),
          onPointerUp: screenReader ? null : (_) => _release(),
          onPointerCancel: screenReader ? null : (_) => _release(),
          child: GestureDetector(
            onTap: screenReader ? _confirm : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: widget.size,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LuxColors.surface,
                          border: Border.all(color: LuxColors.border),
                          boxShadow: luxSoftShadow,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _hold,
                        builder: (_, __) => CircularProgressIndicator(
                          value: _hold.value,
                          strokeWidth: 3,
                          backgroundColor: Colors.transparent,
                          color: LuxColors.error,
                        ),
                      ),
                      // Con la letra grande se reduce dentro del círculo en
                      // vez de quedar «SO» (E8).
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: FittedBox(
                          child: Text(
                            'SOS',
                            style: LuxTypography.titleMedium.copyWith(
                              color: LuxColors.error,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
