import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:luxelane/features/auth/presentation/pages/verify_email_page.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements AuthRepository {}

void main() {
  late _Repo repo;
  late int done;

  setUp(() {
    repo = _Repo();
    done = 0;
  });

  Future<void> pump(WidgetTester t, {int maxResends = 5}) async {
    await t.pumpWidget(MaterialApp(
      home: VerifyEmailPage(
        repository: repo,
        email: 'ana@example.com',
        cooldown: const Duration(seconds: 2),
        maxResends: maxResends,
        onDone: () => done++,
      ),
    ));
  }

  testWidgets('muestra el correo y espera antes del primer reenvío', (t) async {
    await pump(t);
    expect(find.textContaining('ana@example.com'), findsOneWidget);
    expect(find.text('Reenviar enlace (2 s)'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    expect(find.text('Reenviar enlace'), findsOneWidget);
  });

  testWidgets('verificado: avisa y termina', (t) async {
    when(() => repo.refreshEmailVerification())
        .thenAnswer((_) async => const Right(true));
    await pump(t);
    await t.tap(find.text('Ya lo verifiqué'));
    await t.pumpAndSettle();
    expect(done, 1);
  });

  testWidgets('aún sin verificar: lo explica', (t) async {
    when(() => repo.refreshEmailVerification())
        .thenAnswer((_) async => const Right(false));
    await pump(t);
    await t.tap(find.text('Ya lo verifiqué'));
    await t.pump();
    expect(find.textContaining('Aún no vemos el correo verificado'),
        findsOneWidget);
    expect(done, 0);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('sin red: mensaje claro', (t) async {
    when(() => repo.refreshEmailVerification()).thenAnswer((_) async =>
        Left(emailVerificationFailureFor('network-request-failed')));
    await pump(t);
    await t.tap(find.text('Ya lo verifiqué'));
    await t.pump();
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('reenvío con límite por visita y espera entre envíos', (t) async {
    when(() => repo.sendVerificationEmail())
        .thenAnswer((_) async => const Right(null));
    await pump(t, maxResends: 2);
    for (var i = 0; i < 2; i++) {
      await t.pump(const Duration(seconds: 3));
      await t.tap(find.text('Reenviar enlace'));
      await t.pump();
      expect(find.text('Te enviamos un enlace nuevo.'), findsOneWidget);
    }
    await t.pump(const Duration(seconds: 3));
    expect(find.text('Límite de reenvíos alcanzado'), findsOneWidget);
    verify(() => repo.sendVerificationEmail()).called(2);
  });

  testWidgets('demasiados envíos: lo dice y espera', (t) async {
    when(() => repo.sendVerificationEmail()).thenAnswer(
        (_) async => Left(emailVerificationFailureFor('too-many-requests')));
    await pump(t);
    await t.pump(const Duration(seconds: 3));
    await t.tap(find.text('Reenviar enlace'));
    await t.pump();
    expect(find.textContaining('Espera unos minutos'), findsOneWidget);
    expect(find.text('Reenviar enlace (2 s)'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  test('el servidor rechaza reservar sin correo verificado', () {
    expect(
      bookingFailureFor('failed-precondition',
          {'code': 'failed_precondition', 'reason': 'email_not_verified'}),
      isA<EmailNotVerifiedFailure>(),
    );
  });

  test('errores de Auth al verificar', () {
    expect(emailVerificationFailureFor('too-many-requests').issue,
        EmailVerificationIssue.tooManyRequests);
    expect(emailVerificationFailureFor('network-request-failed').issue,
        EmailVerificationIssue.network);
    expect(emailVerificationFailureFor('expired-action-code').issue,
        EmailVerificationIssue.other);
  });
}
