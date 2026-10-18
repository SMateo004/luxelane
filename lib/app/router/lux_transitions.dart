import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/lux_motion.dart';

/// Transiciones de página de Luxelane, iguales en las dos apps.

/// Cambio de sección: la nueva vista aparece y sube apenas 12 px, como una
/// hoja que se asienta. La anterior se desvanece debajo.
CustomTransitionPage<void> luxFadeThroughPage(
        Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: LuxMotion.page,
      reverseTransitionDuration: LuxMotion.base,
      transitionsBuilder: (context, animation, secondary, child) {
        if (LuxMotion.reduced(context)) return child;
        final enter =
            CurvedAnimation(parent: animation, curve: LuxMotion.decelerate);
        return FadeTransition(
          opacity: enter,
          child: AnimatedBuilder(
            animation: enter,
            builder: (_, c) => Transform.translate(
              offset: Offset(0, 12 * (1 - enter.value)),
              child: c,
            ),
            child: child,
          ),
        );
      },
    );

/// Avanzar en un flujo (reservar, pagar): entra desde la derecha mientras la
/// anterior se desplaza un poco y se atenúa, como en iOS.
CustomTransitionPage<void> luxPushPage(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: LuxMotion.page,
      reverseTransitionDuration:
          LuxMotion.base + const Duration(milliseconds: 40),
      transitionsBuilder: (context, animation, secondary, child) {
        if (LuxMotion.reduced(context)) return child;
        final enter = CurvedAnimation(
            parent: animation,
            curve: LuxMotion.emphasized,
            reverseCurve: LuxMotion.accelerate);
        final leave =
            CurvedAnimation(parent: secondary, curve: LuxMotion.emphasized);
        return SlideTransition(
          position: Tween(begin: const Offset(-0.25, 0), end: Offset.zero)
              .animate(ReverseAnimation(leave)),
          child: FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.6).animate(leave),
            child: SlideTransition(
              position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(enter),
              child: child,
            ),
          ),
        );
      },
    );

/// Una vista que se abre sobre la actual (viaje activo): sube desde abajo.
CustomTransitionPage<void> luxModalPage(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: LuxMotion.slow,
      reverseTransitionDuration: LuxMotion.base,
      transitionsBuilder: (context, animation, secondary, child) {
        if (LuxMotion.reduced(context)) return child;
        final enter = CurvedAnimation(
            parent: animation,
            curve: LuxMotion.emphasized,
            reverseCurve: LuxMotion.accelerate);
        return SlideTransition(
          position:
              Tween(begin: const Offset(0, 1), end: Offset.zero).animate(enter),
          child: child,
        );
      },
    );
