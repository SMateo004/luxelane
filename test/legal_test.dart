import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/legal.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/register_page.dart';
import 'package:luxelane/features/legal/presentation/pages/legal_content.dart';
import 'package:luxelane/features/legal/presentation/pages/legal_pages.dart';

import 'helpers/l10n.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _withAuth(Widget child, AuthState state) {
  final bloc = MockAuthBloc();
  whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);
  return BlocProvider<AuthBloc>.value(value: bloc, child: localizedApp(child));
}

const _es = Locale('es');
const _en = Locale('en');
const _pt = Locale('pt');

String _body(LegalDocument d) => d.sections.expand((s) => s.paragraphs).join(' ');

void main() {
  testWidgets('privacy policy renders every section and the draft banner', (tester) async {
    await tester.pumpWidget(localizedApp(LegalPage.privacy()));
    expect(find.text('Política de privacidad'), findsWidgets);
    expect(find.textContaining('Borrador'), LegalInfo.isDraft ? findsOneWidget : findsNothing);
    expect(find.textContaining('Última actualización: 7 de octubre de 2026'), findsOneWidget);
    for (final s in privacyPolicyFor(_es).sections.take(3)) {
      await tester.scrollUntilVisible(find.text(s.title), 300);
      expect(find.text(s.title), findsOneWidget);
    }
  });

  testWidgets('privacy policy renders in English', (tester) async {
    await tester.pumpWidget(localizedApp(LegalPage.privacy(), locale: _en));
    expect(find.text('Privacy policy'), findsWidgets);
    expect(find.textContaining('Draft'), LegalInfo.isDraft ? findsOneWidget : findsNothing);
    expect(find.text('Last updated: October 7, 2026'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('3. Who we share it with'), 300);
    expect(find.text('3. Who we share it with'), findsOneWidget);
  });

  testWidgets('privacy policy renders in Portuguese', (tester) async {
    await tester.pumpWidget(localizedApp(LegalPage.privacy(), locale: _pt));
    expect(find.text('Política de privacidade'), findsWidgets);
    expect(find.textContaining('Rascunho'), LegalInfo.isDraft ? findsOneWidget : findsNothing);
    expect(find.text('Última atualização: 7 de outubro de 2026'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('3. Com quem os compartilhamos'), 300);
    expect(find.text('3. Com quem os compartilhamos'), findsOneWidget);
  });

  testWidgets('terms page follows the active language', (tester) async {
    await tester.pumpWidget(localizedApp(LegalPage.terms(), locale: _en));
    expect(find.text('Terms and conditions'), findsWidgets);
    await tester.pumpWidget(localizedApp(LegalPage.terms(), locale: _pt));
    await tester.pumpAndSettle();
    expect(find.text('Termos e condições'), findsWidgets);
  });

  test('unsupported languages fall back to English documents', () {
    expect(privacyPolicyFor(const Locale('fr')).title, 'Privacy policy');
    expect(termsOfServiceFor(const Locale('de')).title, 'Terms and conditions');
  });

  test('privacy policy discloses location and data sharing', () {
    final text = _body(privacyPolicyFor(_es));
    expect(text, contains('ubicación'));
    expect(text, contains('segundo plano'));
    expect(text, contains('Eliminar cuenta'));
    expect(text, contains('Google'));
    expect(_body(privacyPolicyFor(_en)), allOf(contains('background'), contains('Delete account'), contains('Google')));
    expect(
        _body(privacyPolicyFor(_pt)), allOf(contains('segundo plano'), contains('Excluir conta'), contains('Google')));
  });

  test('translations say the Spanish version prevails; Spanish does not', () {
    for (final doc in [privacyPolicyFor(_en), termsOfServiceFor(_en)]) {
      expect(doc.intro, contains('the Spanish version prevails'));
    }
    for (final doc in [privacyPolicyFor(_pt), termsOfServiceFor(_pt)]) {
      expect(doc.intro, contains('prevalece a versão em espanhol'));
    }
    for (final doc in [privacyPolicyFor(_es), termsOfServiceFor(_es)]) {
      expect(doc.intro, isNot(contains('prevalece')));
    }
  });

  test('every document has the same sections in all languages', () {
    for (final docFor in [privacyPolicyFor, termsOfServiceFor]) {
      final es = docFor(_es);
      for (final l in [_en, _pt]) {
        final d = docFor(l);
        expect(d.sections.length, es.sections.length);
        for (var i = 0; i < es.sections.length; i++) {
          expect(d.sections[i].paragraphs.length, es.sections[i].paragraphs.length,
              reason: '${l.languageCode} §${i + 1}');
          final esNotes = es.sections[i].paragraphs.where((p) => p.startsWith('[')).length;
          expect(d.sections[i].paragraphs.where((p) => p.startsWith('[')).length, esNotes,
              reason: 'bracketed decision notes must be kept (${l.languageCode} §${i + 1})');
        }
      }
    }
  });

  test('terms state the agreed waiting time and cancellation window', () {
    final es = _body(termsOfServiceFor(_es));
    expect(es, contains('60 minutos'));
    expect(es, contains('15 minutos'));
    expect(es, contains('1 hora antes'));
    final en = _body(termsOfServiceFor(_en));
    expect(en, contains('60 minutes'));
    expect(en, contains('15 minutes'));
    expect(en, contains('1 hour before'));
    final pt = _body(termsOfServiceFor(_pt));
    expect(pt, contains('60 minutos'));
    expect(pt, contains('15 minutos'));
    expect(pt, contains('1 hora antes'));
  });

  testWidgets('delete account asks guests to sign in first', (tester) async {
    await tester.pumpWidget(_withAuth(const DeleteAccountPage(), const AuthUnauthenticated()));
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('ELIMINAR MI CUENTA'), findsNothing);
  });

  testWidgets('delete account page is localized (English)', (tester) async {
    final bloc = MockAuthBloc();
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthUnauthenticated());
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(value: bloc, child: localizedApp(const DeleteAccountPage(), locale: _en)),
    );
    expect(find.text('Delete your account'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });

  testWidgets('registration requires accepting the terms', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bloc = MockAuthBloc();
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: const AuthUnauthenticated());
    await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(value: bloc, child: localizedApp(const RegisterPage())));
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Gutiérrez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), '+59170000000');
    await tester.enterText(find.byType(TextFormField).at(3), 'secreto123');
    await tester.tap(find.text('CREAR CUENTA'));
    await tester.pump();
    expect(find.text('Debes aceptar los términos y la política de privacidad'), findsOneWidget);
  });
}
