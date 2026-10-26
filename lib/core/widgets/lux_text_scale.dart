import 'package:flutter/widgets.dart';

/// Títulos de 30 px o más: ya son texto grande. Con la letra del sistema al
/// 200 % se partían a media palabra («Bienveni / do», E8); crecen hasta 1,3×.
/// El resto del texto sigue la escala del sistema sin límite.
TextScaler luxDisplayTextScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
