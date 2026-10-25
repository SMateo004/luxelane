import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/auth/mfa.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/pages/mfa_enroll_page.dart';
import 'package:luxelane/features/auth/presentation/pages/mfa_sign_in_page.dart';
import 'package:luxelane/features/auth/presentation/widgets/mfa_reminder_banner.dart';
import 'package:mocktail/mocktail.dart';

class _Service extends Mock implements MfaService {}

class _Challenge implements MfaChallenge {
  _Challenge(this.result, {this.hasTotp = true});
  final Either<Failure, User> result;
  final List<String> codes = [];
  @override
  final bool hasTotp;
  @override
  Future<Either<Failure, User>> resolve(String code) async {
    codes.add(code);
    return result;
  }
}

final _user = User(
  id: 'luis',
  email: 'luis@example.com',
  phone: '',
  displayName: 'Luis',
  role: UserRole.driver,
  createdAt: DateTime(2026),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

final _enrollment = TotpEnrollment(
  secretKey: 'JBSWY3DPEHPK3PXP',
  qrCodeUrl: 'otpauth://totp/Luxelane:luis@example.com?secret=JBSWY3DPEHPK3PXP',
  deadline: DateTime.now().add(const Duration(minutes: 10)),
);

void main() {
  setUpAll(() => registerFallbackValue(_enrollment));

  group('segundo paso al iniciar sesión', () {
    Future<(_Challenge, List<User>)> pump(
        WidgetTester t, Either<Failure, User> r) async {
      final c = _Challenge(r);
      final ok = <User>[];
      await t.pumpWidget(MaterialApp(
        home: MfaSignInPage(challenge: c, onSignedIn: ok.add, onCancel: () {}),
      ));
      return (c, ok);
    }

    testWidgets('código correcto: entra', (t) async {
      final (c, ok) = await pump(t, Right(_user));
      await t.enterText(find.byKey(const ValueKey('mfa-code')), '123456');
      await t.tap(find.text('Entrar'));
      await t.pump();
      expect(c.codes, ['123456']);
      expect(ok.single.id, 'luis');
    });

    testWidgets('código incorrecto: mensaje y vuelve a pedirlo', (t) async {
      final (_, ok) = await pump(
          t, Left(AuthFailure(mfaErrorMessage('invalid-verification-code'))));
      await t.enterText(find.byKey(const ValueKey('mfa-code')), '000000');
      await t.tap(find.text('Entrar'));
      await t.pump();
      expect(find.textContaining('Código incorrecto'), findsOneWidget);
      expect(ok, isEmpty);
    });

    testWidgets('cuenta sin app autenticadora: lo explica y no deja enviar',
        (t) async {
      await t.pumpWidget(MaterialApp(
        home: MfaSignInPage(
          challenge: _Challenge(Right(_user), hasTotp: false),
          onSignedIn: (_) {},
          onCancel: () {},
        ),
      ));
      expect(find.textContaining('no tiene una app autenticadora'),
          findsOneWidget);
    });

    testWidgets('menos de 6 cifras: no llama al servidor', (t) async {
      final (c, _) = await pump(t, Right(_user));
      await t.enterText(find.byKey(const ValueKey('mfa-code')), '12');
      await t.tap(find.text('Entrar'));
      await t.pump();
      expect(find.text('Escribe las 6 cifras del código.'), findsOneWidget);
      expect(c.codes, isEmpty);
    });
  });

  group('alta de la app autenticadora', () {
    late _Service svc;
    setUp(() {
      svc = _Service();
      when(() => svc.canOpenInAuthenticator).thenReturn(false);
      when(() =>
              svc.startTotpEnrollment(accountName: any(named: 'accountName')))
          .thenAnswer((_) async => _enrollment);
    });

    Future<void> pump(WidgetTester t) {
      // Pantalla alta: todo el alta cabe sin desplazar.
      t.view.physicalSize = const Size(800, 2000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      return t.pumpWidget(MaterialApp(
        home: MfaEnrollPage(accountName: 'luis@example.com', service: svc),
      ));
    }

    testWidgets('muestra el QR y oculta la clave salvo que se pida', (t) async {
      await pump(t);
      await t.tap(find.text('Empezar'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('mfa-qr')), findsOneWidget);
      expect(find.textContaining('JBSWY3DPEHPK3PXP'), findsNothing);
      await t.tap(find.text('Mostrar clave'));
      await t.pump();
      expect(find.textContaining('JBSWY3DPEHPK3PXP'), findsOneWidget);
    });

    testWidgets('código correcto: queda activada', (t) async {
      when(() => svc.finishTotpEnrollment(any(), '654321'))
          .thenAnswer((_) async {});
      await pump(t);
      await t.tap(find.text('Empezar'));
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey('mfa-enroll-code')), '654321');
      await t.tap(find.text('Activar'));
      await t.pumpAndSettle();
      expect(find.textContaining('Listo.'), findsOneWidget);
      expect(find.byKey(const ValueKey('mfa-qr')), findsNothing);
    });

    testWidgets('código incorrecto: lo dice', (t) async {
      when(() => svc.finishTotpEnrollment(any(), any())).thenThrow(
          fb.FirebaseAuthException(code: 'invalid-verification-code'));
      await pump(t);
      await t.tap(find.text('Empezar'));
      await t.pumpAndSettle();
      await t.enterText(
          find.byKey(const ValueKey('mfa-enroll-code')), '111111');
      await t.tap(find.text('Activar'));
      await t.pumpAndSettle();
      expect(find.textContaining('Código incorrecto'), findsOneWidget);
    });

    testWidgets('sin correo verificado o sin TOTP activado en el proyecto',
        (t) async {
      when(() =>
              svc.startTotpEnrollment(accountName: any(named: 'accountName')))
          .thenThrow(fb.FirebaseAuthException(code: 'unverified-email'));
      await pump(t);
      await t.tap(find.text('Empezar'));
      await t.pumpAndSettle();
      expect(find.textContaining('Verifica tu correo'), findsOneWidget);
    });
  });

  group('aviso de fase 1', () {
    testWidgets('sin segundo factor: se muestra', (t) async {
      final svc = _Service();
      when(() => svc.hasSecondFactor()).thenAnswer((_) async => false);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: MfaReminderBanner(accountName: 'x', service: svc)),
      ));
      await t.pump();
      expect(find.byKey(const ValueKey('mfa-reminder')), findsOneWidget);
    });

    testWidgets('con segundo factor: no se muestra', (t) async {
      final svc = _Service();
      when(() => svc.hasSecondFactor()).thenAnswer((_) async => true);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: MfaReminderBanner(accountName: 'x', service: svc)),
      ));
      await t.pump();
      expect(find.byKey(const ValueKey('mfa-reminder')), findsNothing);
    });
  });

  test('el servidor pide el segundo factor: mensaje claro', () {
    expect(
      functionErrorMessage('unauthenticated', {'reason': 'mfa_required'}),
      kMfaRequiredMessage,
    );
  });
}
