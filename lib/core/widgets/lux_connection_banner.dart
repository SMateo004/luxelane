import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Aviso global de «sin conexión» encima de cualquier pantalla. Antes, sin
/// red, viajes, perfil, panel y chófer mostraban datos en caché sin
/// decirlo (E12). Aparece tras [delay] sin conexión (no parpadea al
/// arrancar) y se va en cuanto vuelve.
class LuxConnectionBanner extends StatefulWidget {
  const LuxConnectionBanner({
    super.key,
    required this.online,
    required this.child,
    this.delay = const Duration(seconds: 2),
  });

  final Stream<bool> online;
  final Widget child;
  final Duration delay;

  @override
  State<LuxConnectionBanner> createState() => _LuxConnectionBannerState();
}

class _LuxConnectionBannerState extends State<LuxConnectionBanner> {
  StreamSubscription<bool>? _sub;
  Timer? _timer;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.online.listen(_onStatus);
  }

  void _onStatus(bool online) {
    _timer?.cancel();
    if (online) {
      if (_offline) setState(() => _offline = false);
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _offline = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return widget.child;
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          child: Material(
            color: LuxColors.ink,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuxSpacing.md,
                  vertical: LuxSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 18,
                      color: LuxColors.onAccent,
                    ),
                    const SizedBox(width: LuxSpacing.sm),
                    Expanded(
                      child: Text(
                        'Sin conexión. Lo que ves puede no estar al día.',
                        style: LuxTypography.bodyMedium.copyWith(
                          color: LuxColors.onAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
