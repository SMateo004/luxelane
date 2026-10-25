import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/auth/mfa.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/auth/presentation/widgets/reauth_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements AuthRepository {}

class _Challenge implements MfaChallenge {
  final List<String> codes = [];
  @override
  bool get hasTotp => true;
  @override
  Future<Either<Failure, User>> resolve(String code) async {
    codes.add(code);
    return Right(
      User(
        id: 'ana',
        email: 'ana@example.com',
        phone: '',
        displayName: 'Ana',
        role: UserRole.admin,
        createdAt: DateTime(2026),
        isVerified: true,
        isActive: true,
        fcmTokens: const [],
      ),
    );
  }
}

void main() {
  late _Repo repo;
  bool? result;

  setUp(() {
    repo = _Repo();
    result = null;
  });

  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await ReauthDialog.show(context, repository: repo),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
  }

  testWidgets('con contraseña: confirma y devuelve true', (t) async {
    when(() => repo.reauthMethod).thenReturn(ReauthMethod.password);
    when(() => repo.reauthenticate(password: 'secreta1'))
        .thenAnswer((_) async => const Right(null));
    await open(t);
    expect(find.text('Confirma que eres tú'), findsOneWidget);
    await t.enterText(find.byKey(const Key('reauth-password')), 'secreta1');
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(result, isTrue);
    verify(() => repo.reauthenticate(password: 'secreta1')).called(1);
  });

  testWidgets('contraseña incorrecta: lo dice y sigue abierto', (t) async {
    when(() => repo.reauthMethod).thenReturn(ReauthMethod.password);
    when(() => repo.reauthenticate(password: any(named: 'password')))
        .thenAnswer(
      (_) async => Left(AuthFailure(reauthErrorMessage('wrong-password'))),
    );
    await open(t);
    await t.enterText(find.byKey(const Key('reauth-password')), 'mala');
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.text('La contraseña no coincide.'), findsOneWidget);
    expect(result, isNull);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('sin contraseña escrita no llama al servidor', (t) async {
    when(() => repo.reauthMethod).thenReturn(ReauthMethod.password);
    await open(t);
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    verifyNever(() => repo.reauthenticate(password: any(named: 'password')));
  });

  testWidgets('cuenta de Google: botón de Google', (t) async {
    when(() => repo.reauthMethod).thenReturn(ReauthMethod.google);
    when(() => repo.reauthenticate())
        .thenAnswer((_) async => const Right(null));
    await open(t);
    expect(find.byKey(const Key('reauth-password')), findsNothing);
    await t.tap(find.text('Continuar con Google'));
    await t.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('con segundo factor: pide el código y termina', (t) async {
    final challenge = _Challenge();
    when(() => repo.reauthMethod).thenReturn(ReauthMethod.password);
    when(() => repo.reauthenticate(password: 'secreta1'))
        .thenAnswer((_) async => Left(MfaRequiredFailure(challenge)));
    await open(t);
    await t.enterText(find.byKey(const Key('reauth-password')), 'secreta1');
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'Código'), '123456');
    await t.tap(find.text('Entrar'));
    await t.pumpAndSettle();
    expect(challenge.codes, ['123456']);
    expect(result, isTrue);
  });

  test('mensajes de reautenticación sin texto técnico', () {
    expect(
        reauthErrorMessage('invalid-credential'), 'La contraseña no coincide.');
    expect(reauthErrorMessage('too-many-requests'), kTooManyAttemptsMessage);
    expect(
      reauthErrorMessage('algo-raro'),
      'No pudimos confirmar tu identidad. Inténtalo de nuevo.',
    );
  });
}
