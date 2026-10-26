import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/widgets/components.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_shared_widgets.dart';

/// E9: 47 objetivos táctiles de menos de 48 px (iconos de 36–40, pestañas
/// de 36–39, casillas y botones de 32).
void main() {
  // Como en la web y el escritorio, donde Flutter compacta por omisión: el
  // tema se construye con esa plataforma.
  ThemeData theme() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      return luxTheme;
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
        MaterialApp(
          theme: theme(),
          home: Scaffold(body: Center(child: child)),
        ),
      );

  void atLeast48(WidgetTester t, Finder f) {
    final s = t.getSize(f);
    expect(s.width >= 48 && s.height >= 48, isTrue, reason: '$f mide $s');
  }

  testWidgets('casilla, radio y botón de texto: 48 px', (t) async {
    await pump(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: false, onChanged: (_) {}),
          Radio<int>(value: 1, groupValue: 0, onChanged: (_) {}),
          TextButton(onPressed: () {}, child: const Text('Ver')),
          IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
        ],
      ),
    );
    atLeast48(t, find.byType(Checkbox));
    atLeast48(t, find.byType(Radio<int>));
    atLeast48(t, find.byType(TextButton));
    atLeast48(t, find.byType(IconButton));
  });

  testWidgets('LuxButton de 46 px: el área sube a 48', (t) async {
    await pump(
      t,
      LuxOutlinedButton(
        label: 'El pasajero no aparece',
        height: 46,
        onPressed: () {},
      ),
    );
    expect(t.getSize(find.byType(LuxOutlinedButton)).height >= 48, isTrue);
  });

  testWidgets('control segmentado: cada opción de 48 px', (t) async {
    await pump(
      t,
      SizedBox(
        width: 360,
        child: ServiceTypeTab(selected: ServiceType.oneWay, onChanged: (_) {}),
      ),
    );
    final option = find
        .ancestor(of: find.text('Solo ida'), matching: find.byType(Expanded))
        .first;
    atLeast48(t, option);
  });

  testWidgets('LuxTapArea: 48 px aunque el control se vea de 36', (t) async {
    await pump(
      t,
      const LuxTapArea(child: SizedBox.square(dimension: 36)),
    );
    atLeast48(t, find.byType(LuxTapArea));
    expect(t.getSize(find.byType(SizedBox).last), const Size.square(36));
  });

  testWidgets('pestañas del panel: 48 px', (t) async {
    await pump(
      t,
      SectionChip(label: 'Finanzas', selected: false, onTap: () {}),
    );
    atLeast48(t, find.byType(SectionChip));
  });
}
