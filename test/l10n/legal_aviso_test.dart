import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/legal/presentation/pages/legal_page.dart';
import 'package:luxelane/l10n/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Idiomas, B2: las páginas legales siguen en español; en inglés o
/// portugués llevan un aviso traducido y el contenido no cambia.
void main() {
  tearDown(() => L10n.use(const Locale('es')));

  Future<void> pump(WidgetTester t, Locale locale) async {
    final auth = _MockAuthBloc();
    whenListen(auth, const Stream<AuthState>.empty(),
        initialState: const AuthUnauthenticated());
    L10n.use(locale);
    t.view.physicalSize = const Size(390, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: BlocProvider<AuthBloc>.value(
          value: auth,
          child: const LegalPage(doc: LegalDoc.terms),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('en inglés: aviso en inglés y términos en español', (t) async {
    await pump(t, const Locale('en'));
    expect(find.text('This document is currently available in Spanish only.'),
        findsOneWidget);
    expect(find.text('Términos y condiciones'), findsWidgets);
    expect(find.text('1. Quiénes somos'), findsOneWidget);
  });

  testWidgets('en portugués: aviso en portugués', (t) async {
    await pump(t, const Locale('pt'));
    expect(
        find.text(
            'No momento, este documento está disponível apenas em espanhol.'),
        findsOneWidget);
    expect(find.text('1. Quiénes somos'), findsOneWidget);
  });

  testWidgets('en español: sin aviso', (t) async {
    await pump(t, const Locale('es'));
    expect(find.textContaining('disponible en español'), findsNothing);
    expect(find.text('1. Quiénes somos'), findsOneWidget);
  });
}
