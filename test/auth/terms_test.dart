import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/error/function_errors.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/register_page.dart';
import 'package:luxelane/features/auth/presentation/widgets/terms_required_dialog.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _Repo extends Mock implements AuthRepository {}

void main() {
  setUpAll(() => registerFallbackValue(const LogoutRequested()));

  group('registro: casilla de términos (decisión 7)', () {
    late _MockAuthBloc bloc;

    setUp(() {
      bloc = _MockAuthBloc();
      whenListen(
        bloc,
        const Stream<AuthState>.empty(),
        initialState: const AuthUnauthenticated(),
      );
    });

    Future<void> fill(WidgetTester t) async {
      t.view.physicalSize = const Size(590, 2000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: luxTheme,
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const RegisterPage(),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      await t.enterText(fields.at(0), 'Ana Pérez');
      await t.enterText(fields.at(1), 'ana@example.com');
      await t.enterText(fields.at(2), '+59170000000');
      await t.enterText(fields.at(3), 'secreta1');
    }

    testWidgets('sin marcarla no se crea la cuenta', (t) async {
      await fill(t);
      await t.tap(find.text('Crear cuenta'));
      await t.pump();
      expect(
        find.text(
          'Acepta los Términos y la Política de privacidad para continuar',
        ),
        findsOneWidget,
      );
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('marcada, se registra', (t) async {
      await fill(t);
      await t.tap(find.byKey(const Key('terms-checkbox')));
      await t.tap(find.text('Crear cuenta'));
      await t.pump();
      verify(
        () => bloc.add(
          const RegisterRequested(
            email: 'ana@example.com',
            password: 'secreta1',
            phone: '+59170000000',
            displayName: 'Ana Pérez',
            role: UserRole.rider,
          ),
        ),
      ).called(1);
    });
  });

  test('createBooking terms_required se traduce en TermsRequiredFailure', () {
    expect(
      bookingFailureFor('failed-precondition', {'reason': 'terms_required'}),
      isA<TermsRequiredFailure>(),
    );
  });

  test('acceptTerms: versión cambiada a mitad de lectura', () {
    expect(
      acceptTermsErrorMessage('failed-precondition', {
        'reason': 'terms_outdated',
      }),
      contains('se acaban de actualizar'),
    );
  });

  group('TermsRequiredDialog', () {
    late _Repo repo;
    bool? result;

    setUp(() {
      repo = _Repo();
      result = null;
    });

    Future<void> open(WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: luxTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result =
                    await TermsRequiredDialog.show(context, repository: repo),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
    }

    testWidgets('«Acepto» lo anota en el servidor', (t) async {
      when(() => repo.acceptTerms()).thenAnswer((_) async => const Right(null));
      await open(t);
      await t.tap(find.text('Acepto'));
      await t.pumpAndSettle();
      expect(result, isTrue);
      verify(() => repo.acceptTerms()).called(1);
      expect(find.text('Listo. Ya puedes reservar.'), findsOneWidget);
    });

    testWidgets('si falla, lo dice y sigue abierto', (t) async {
      when(() => repo.acceptTerms()).thenAnswer(
        (_) async => const Left(ServerFailure('No pudimos registrar.')),
      );
      await open(t);
      await t.tap(find.text('Acepto'));
      await t.pumpAndSettle();
      expect(find.text('No pudimos registrar.'), findsOneWidget);
      await t.tap(find.text('Ahora no'));
      await t.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}
