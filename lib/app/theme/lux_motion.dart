import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Movimiento de Luxelane: pocas duraciones y curvas, siempre las mismas.
/// Todo entra decelerando (rápido al principio, suave al llegar) y nada
/// rebota: la calma es parte de la marca.
abstract class LuxMotion {
  /// Respuesta táctil inmediata (presionar, alternar).
  static const fast = Duration(milliseconds: 120);

  /// Cambios de estado dentro de un componente.
  static const base = Duration(milliseconds: 220);

  /// Elementos que entran o salen de la pantalla.
  static const slow = Duration(milliseconds: 360);

  /// Cambio de página.
  static const page = Duration(milliseconds: 320);

  /// Retraso entre elementos de una lista que entran en cascada.
  static const stagger = Duration(milliseconds: 45);

  /// Curva principal: arranque decidido y llegada muy suave.
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// Entradas: decelera hasta detenerse.
  static const decelerate = Cubic(0.05, 0.7, 0.1, 1);

  /// Salidas: acelera para despejar la vista.
  static const accelerate = Cubic(0.3, 0, 0.8, 0.15);

  /// Escala al presionar un elemento.
  static const pressedScale = 0.97;

  /// Respeta "reducir movimiento" del sistema.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d] o cero si el usuario pidió reducir el movimiento.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Háptica discreta: confirma sin distraer. En web no hace nada.
abstract class LuxHaptics {
  /// Tocar un control (botón, tarjeta, opción).
  static void tap() {
    if (!kIsWeb) HapticFeedback.selectionClick();
  }

  /// Una decisión importante (reservar, pagar, aceptar).
  static void confirm() {
    if (!kIsWeb) HapticFeedback.mediumImpact();
  }

  /// Algo salió bien (reserva confirmada, tarjeta guardada).
  static void success() {
    if (kIsWeb) return;
    HapticFeedback.lightImpact();
    Future<void>.delayed(
        const Duration(milliseconds: 90), HapticFeedback.lightImpact);
  }

  /// Algo requiere atención.
  static void warning() {
    if (!kIsWeb) HapticFeedback.heavyImpact();
  }
}
