import 'package:flutter/widgets.dart';

/// Títulos de 30 px o más: ya son texto grande. Con la letra del sistema al
/// 200 % se partían a media palabra («Bienveni / do», E8); crecen hasta 1,3×.
/// El resto del texto sigue la escala del sistema sin límite.
TextScaler luxDisplayTextScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

/// Líneas de un texto que el diseño acorta con «…» a [lines]. Con la letra
/// del sistema al 130 % o más se permite el doble: en inglés y portugués,
/// al 200 %, «3 h at your disposal» o «Continuar com o Google» se cortaban
/// (B4). A tamaño normal no cambia nada.
int luxMaxLines(BuildContext context, int lines) =>
    MediaQuery.textScalerOf(context).scale(1) >= 1.3 ? lines * 2 : lines;
