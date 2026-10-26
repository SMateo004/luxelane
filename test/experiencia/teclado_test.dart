import 'dart:ui' show SemanticsFlag;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/widgets/components.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/register_page.dart';
import 'package:luxelane/features/incidents/presentation/widgets/sos_button.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// E7: con teclado no se llegaba a «Iniciar sesión», «Crear cuenta», el SOS
/// ni «Cancelar reserva» (botones hechos con GestureDetector, sin foco).
void main() {
  Widget app(Widget child) => MaterialApp(
        theme: luxTheme,
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('LuxButton: Tab lo enfoca e Intro lo pulsa', (t) async {
    var taps = 0;
    await t.pumpWidget(
      app(LuxButton(label: 'Iniciar sesión', onPressed: () => taps++)),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(taps, 1);
  });

  testWidgets('con teclado se dibuja el anillo de foco', (t) async {
    await t.pumpWidget(app(LuxButton(label: 'Entrar', onPressed: () {})));
    final ring = find.descendant(
      of: find.byType(LuxFocusable),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter != null,
      ),
    );
    expect(ring, findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(ring, findsOneWidget);
  });

  testWidgets('un LuxButton deshabilitado no toma el foco', (t) async {
    var taps = 0;
    await t.pumpWidget(
      app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LuxButton(label: 'Cargando', onPressed: null),
            LuxButton(label: 'Crear cuenta', onPressed: () => taps++),
          ],
        ),
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(taps, 1);
  });

  testWidgets('LuxPressable: Tab y Espacio', (t) async {
    var taps = 0;
    await t.pumpWidget(
      app(LuxPressable(onTap: () => taps++, child: const Text('Fila'))),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(taps, 1);
  });

  testWidgets('SOS: con teclado pide confirmación y avisa', (t) async {
    var avisos = 0;
    await t.pumpWidget(app(SosButton(onActivated: () => avisos++)));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(find.text('¿Avisar a central?'), findsOneWidget);
    await t.tap(find.text('Avisar a central'));
    await t.pumpAndSettle();
    expect(avisos, 1);
  });

  testWidgets('SOS: su nodo de accesibilidad es enfocable (Tab en la web)', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(app(SosButton(onActivated: () {})));
    final node = t.getSemantics(find.bySemanticsLabel('Ayuda SOS'));
    expect(
      node.getSemanticsData().hasFlag(SemanticsFlag.isFocusable),
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('registro: la casilla de términos tiene nombre', (t) async {
    final bloc = _MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthUnauthenticated(),
    );
    t.view.physicalSize = const Size(590, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      MaterialApp(
        theme: luxTheme,
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const RegisterPage(),
        ),
      ),
    );
    expect(
      t.getSemantics(find.byKey(const Key('terms-checkbox'))),
      matchesSemantics(
        label: 'Acepto los Términos y la Política de privacidad',
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });
}
