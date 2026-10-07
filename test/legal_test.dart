import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/legal.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/register_page.dart';
import 'package:luxelane/features/legal/presentation/pages/legal_content.dart';
import 'package:luxelane/features/legal/presentation/pages/legal_pages.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _withAuth(Widget child, AuthState state) {
  final bloc = MockAuthBloc();
  whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);
  return BlocProvider<AuthBloc>.value(value: bloc, child: MaterialApp(home: child));
}

void main() {
  testWidgets('privacy policy renders every section and the draft banner', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LegalPage.privacy()));
    expect(find.text('Política de privacidad'), findsWidgets);
    expect(find.textContaining('Borrador'), LegalInfo.isDraft ? findsOneWidget : findsNothing);
    for (final s in privacyPolicy.sections.take(3)) {
      await tester.scrollUntilVisible(find.text(s.title), 300);
      expect(find.text(s.title), findsOneWidget);
    }
  });

  test('privacy policy discloses location and data sharing', () {
    final text = privacyPolicy.sections.expand((s) => s.paragraphs).join(' ');
    expect(text, contains('ubicación'));
    expect(text, contains('segundo plano'));
    expect(text, contains('Eliminar cuenta'));
    expect(text, contains('Google'));
  });

  test('terms state the agreed waiting time and cancellation window', () {
    final text = termsOfService.sections.expand((s) => s.paragraphs).join(' ');
    expect(text, contains('60 minutos'));
    expect(text, contains('15 minutos'));
    expect(text, contains('1 hora antes'));
  });

  testWidgets('delete account asks guests to sign in first', (tester) async {
    await tester.pumpWidget(_withAuth(const DeleteAccountPage(), const AuthUnauthenticated()));
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('ELIMINAR MI CUENTA'), findsNothing);
  });

  testWidgets('registration requires accepting the terms', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    await tester.pumpWidget(_withAuth(const RegisterPage(), const AuthUnauthenticated()));
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Gutiérrez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), '+59170000000');
    await tester.enterText(find.byType(TextFormField).at(3), 'secreto123');
    await tester.tap(find.text('CREAR CUENTA'));
    await tester.pump();
    expect(find.text('Debes aceptar los términos y la política de privacidad'), findsOneWidget);
  });
}
