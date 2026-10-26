import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/features/home/presentation/pages/home_design.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// E20: contraste por debajo de AA (4,5:1) en texto normal.
void main() {
  const fondos = {
    'bg': LuxColors.bg,
    'surface': LuxColors.surface,
    'surfaceMuted': LuxColors.surfaceMuted,
    'surfaceDeep': LuxColors.surfaceDeep,
    'sapphireTint': LuxColors.sapphireTint,
  };

  for (final (nombre, color) in [
    ('warning', LuxColors.warning),
    ('inkTertiary', LuxColors.inkTertiary),
    ('LD.ink3', LD.ink3),
    // F3.
    ('sapphireLight', LuxColors.sapphireLight),
    ('LD.sphLt', LD.sphLt),
    ('success', LuxColors.success),
  ]) {
    test('$nombre llega a AA sobre los fondos claros', () {
      for (final f in fondos.entries) {
        expect(
          _ratio(color, f.value),
          greaterThanOrEqualTo(4.5),
          reason: '$nombre sobre ${f.key}',
        );
      }
      // Sobre su propio tinte (chips y avisos: 8 % sobre blanco).
      final tinte = Color.alphaBlend(
        color.withValues(alpha: 0.08),
        LuxColors.surface,
      );
      expect(_ratio(color, tinte), greaterThanOrEqualTo(4.5));
    });
  }

  test('blanco sobre warning: AA', () {
    expect(
      _ratio(LuxColors.onAccent, LuxColors.warning),
      greaterThanOrEqualTo(4.5),
    );
  });
}
