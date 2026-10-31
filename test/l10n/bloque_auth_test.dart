import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/login_page.dart';
import 'package:luxelane/features/auth/presentation/pages/register_page.dart';
import 'package:luxelane/features/auth/presentation/pages/verify_email_page.dart';
import 'package:luxelane/features/auth/presentation/widgets/terms_required_dialog.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _Repo extends Mock implements AuthRepository {}

/// Idiomas, bloque auth: inicio de sesión, registro, verificación del
/// correo y términos en inglés y portugués, sin restos del español.
void main() {
  late _MockAuthBloc bloc;

  Future<void> pump(
    WidgetTester t,
    Locale locale,
    Widget page, {
    double width = 590,
  }) async {
    t.view.physicalSize = Size(width, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: luxTheme,
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: BlocProvider<AuthBloc>.value(value: bloc, child: page),
      ),
    );
    await t.pump();
  }

  for (final (code, texts) in [
    (
      'en',
      (
        login: 'Sign in',
        eyebrow: 'WELCOME',
        email: 'Email',
        forgot: 'Forgot your password?',
        google: 'Continue with Google',
        or: 'OR WITH YOUR EMAIL',
        brand: 'Follow your chauffeur in real time',
        register: 'Create account',
        googleRegister: 'Sign up with Google',
        phone: 'Phone (with country code)',
        termsError: 'Accept the Terms and the Privacy Policy to continue',
        verifyTitle: 'Verify your email',
        verifySent: 'We sent a link to ana@example.com.',
        resendIn: 'Resend link (60 s)',
        termsTitle: 'Accept the terms to book',
        verifyOffline: 'No connection. Check your network and try again.',
      ),
    ),
    (
      'pt',
      (
        login: 'Entrar',
        eyebrow: 'BEM-VINDO',
        email: 'E-mail',
        forgot: 'Esqueceu sua senha?',
        google: 'Continuar com o Google',
        or: 'OU COM SEU E-MAIL',
        brand: 'Acompanhe seu motorista em tempo real',
        register: 'Criar conta',
        googleRegister: 'Cadastrar-se com o Google',
        phone: 'Telefone (com código do país)',
        termsError:
            'Aceite os Termos e a Política de Privacidade para continuar',
        verifyTitle: 'Verifique seu e-mail',
        verifySent: 'Enviamos um link para ana@example.com.',
        resendIn: 'Reenviar link (60 s)',
        termsTitle: 'Aceite os termos para reservar',
        verifyOffline: 'Sem conexão. Verifique sua rede e tente novamente.',
      ),
    ),
  ]) {
    group('auth en $code', () {
      final locale = Locale(code);

      setUp(() {
        L10n.use(locale);
        bloc = _MockAuthBloc();
        whenListen(
          bloc,
          const Stream<AuthState>.empty(),
          initialState: const AuthUnauthenticated(),
        );
      });
      tearDown(() => L10n.use(const Locale('es')));

      testWidgets('inicio de sesión (móvil)', (t) async {
        await pump(t, locale, const LoginPage());
        expect(find.text(texts.eyebrow), findsOneWidget);
        expect(find.text(texts.email), findsOneWidget);
        expect(find.text(texts.forgot), findsOneWidget);
        expect(find.text(texts.google), findsOneWidget);
        expect(find.text(texts.or), findsOneWidget);
        expect(find.text(texts.login), findsWidgets);
        expect(find.text('Iniciar sesión'), findsNothing);
        expect(find.text('BIENVENIDO'), findsNothing);
        expect(find.text('Correo electrónico'), findsNothing);
        expect(find.text('Continuar con Google'), findsNothing);
        expect(t.takeException(), isNull);
      });

      testWidgets('inicio de sesión (web): panel de marca', (t) async {
        await pump(t, locale, const LoginPage(), width: 1400);
        expect(find.text(texts.brand), findsOneWidget);
        expect(
          find.text('Seguimiento de tu chófer en tiempo real'),
          findsNothing,
        );
        expect(t.takeException(), isNull);
      });

      testWidgets('registro: campos y error de términos', (t) async {
        await pump(t, locale, const RegisterPage());
        expect(find.text(texts.googleRegister), findsOneWidget);
        expect(find.text(texts.phone), findsOneWidget);
        expect(find.text('Crear cuenta'), findsNothing);
        expect(find.text('Teléfono (con código de país)'), findsNothing);
        final fields = find.byType(TextFormField);
        await t.enterText(fields.at(0), 'Ana Pérez');
        await t.enterText(fields.at(1), 'ana@example.com');
        await t.enterText(fields.at(2), '+59170000000');
        await t.enterText(fields.at(3), 'secreta1');
        await t.tap(find.text(texts.register));
        await t.pump();
        expect(find.text(texts.termsError), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('verificar el correo', (t) async {
        await pump(
          t,
          locale,
          VerifyEmailPage(repository: _Repo(), email: 'ana@example.com'),
        );
        expect(find.text(texts.verifyTitle), findsOneWidget);
        expect(find.text(texts.verifySent), findsOneWidget);
        expect(find.text(texts.resendIn), findsOneWidget);
        expect(find.text('Verifica tu correo'), findsNothing);
        // El temporizador de reenvío se cancela al desmontar.
        await t.pumpWidget(const SizedBox());
      });

      testWidgets('diálogo de términos al reservar', (t) async {
        final repo = _Repo();
        when(() => repo.acceptTerms())
            .thenAnswer((_) async => const Right(null));
        await pump(
          t,
          locale,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    TermsRequiredDialog.show(context, repository: repo),
                child: const Text('abrir'),
              ),
            ),
          ),
        );
        await t.tap(find.text('abrir'));
        await t.pumpAndSettle();
        expect(find.text(texts.termsTitle), findsOneWidget);
        expect(find.text('Acepta los términos para reservar'), findsNothing);
      });

      test('errores del repositorio en el idioma activo', () {
        expect(
          emailVerificationFailureFor('network-request-failed').message,
          texts.verifyOffline,
        );
      });
    });
  }
}
