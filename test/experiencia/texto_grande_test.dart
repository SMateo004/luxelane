import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/widgets/components.dart';
import 'package:luxelane/features/incidents/presentation/widgets/sos_button.dart';
import 'package:luxelane/features/ride/presentation/widgets/pickup_code_card.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Mock implements TripFlowRepository {}

/// E8: con la letra del sistema al 200 % se recortaban el SOS («SO»), los
/// dígitos del código y las acciones del chófer, y los títulos grandes se
/// partían a media palabra.
void main() {
  Future<void> pump(WidgetTester t, Widget child) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  RenderParagraph paragraph(WidgetTester t, String text) =>
      t.renderObject<RenderParagraph>(find.text(text));

  /// El texto entra entero en una línea y dentro de [box].
  void whole(WidgetTester t, String text, Finder box) {
    final p = paragraph(t, text);
    expect(
      p.getMaxIntrinsicWidth(double.infinity) <= p.size.width + 0.5,
      isTrue,
      reason: '«$text» no cabe en una línea',
    );
    final r = t.getRect(find.text(text));
    final b = t.getRect(box);
    expect(
      r.top >= b.top - 0.5 && r.bottom <= b.bottom + 0.5,
      isTrue,
      reason: '«$text» $r se sale de $b',
    );
  }

  testWidgets('SOS: se lee entero', (t) async {
    await pump(t, Center(child: SosButton(onActivated: () {})));
    whole(t, 'SOS', find.byKey(const ValueKey('sos-button')));
  });

  testWidgets('código de recogida: ningún dígito recortado', (t) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repo();
    when(() => repo.getPickupCode('b1')).thenAnswer(
      (_) async => Right(
        PickupCode(code: '2007', expiresAt: DateTime(2026, 10, 20, 19)),
      ),
    );
    await pump(t, PickupCodeCard(bookingId: 'b1', repository: repo));
    for (final d in ['2', '7']) {
      final box = find
          .ancestor(of: find.text(d), matching: find.byType(Container))
          .first;
      whole(t, d, box);
    }
    // Siguen en fila (a 390 px caben los cuatro), no uno por línea.
    expect(t.getRect(find.text('2')).top, t.getRect(find.text('7')).top);
  });

  testWidgets('botón con texto largo: dos líneas, sin «…»', (t) async {
    await pump(
      t,
      LuxButton(label: 'Navegar a la recogida', onPressed: () {}),
    );
    expect(paragraph(t, 'Navegar a la recogida').didExceedMaxLines, isFalse);
  });

  testWidgets('títulos grandes: crecen hasta 1,3× y no más', (t) async {
    late TextScaler scaler;
    await pump(
      t,
      Builder(
        builder: (c) {
          scaler = luxDisplayTextScaler(c);
          return const SizedBox();
        },
      ),
    );
    expect(scaler.scale(10), closeTo(13, 0.001));
  });
}
