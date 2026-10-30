import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:luxelane/features/payments/presentation/pages/payment_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockPaymentBloc extends MockBloc<PaymentEvent, PaymentState>
    implements PaymentBloc {}

class _Payments extends Mock implements PaymentRepository {}

final _user = User(
  id: 'ana',
  email: 'ana@example.com',
  phone: '+59170000000',
  displayName: 'Ana',
  role: UserRole.rider,
  createdAt: DateTime(2025),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

/// E42: sin tarjeta usable para pagar (ningún CardPaymentPresenter), la
/// pantalla no ofrece agregar tarjetas ni promete pagar con ellas.
void main() {
  late _Payments payments;

  setUp(() async {
    await sl.reset();
    payments = _Payments();
    when(() => payments.ensureStripeCustomer())
        .thenAnswer((_) async => const Left(PaymentFailure('sin perfil')));
    sl.registerSingleton<PaymentRepository>(payments);
  });

  Future<void> pump(WidgetTester t, {bool? cardsEnabled}) async {
    final auth = _MockAuthBloc();
    whenListen(auth, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(_user));
    final bloc = _MockPaymentBloc();
    whenListen(bloc, const Stream<PaymentState>.empty(),
        initialState: const PaymentInitial());
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<PaymentBloc>.value(value: bloc),
        ],
        child: MaterialApp(home: PaymentScreen(cardsEnabled: cardsEnabled)),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('sin tarjeta usable: ni «Agregar tarjeta» ni la promesa',
      (t) async {
    await pump(t);
    expect(find.text('Agregar tarjeta'), findsNothing);
    expect(find.byTooltip('Agregar tarjeta'), findsNothing);
    expect(find.text('Paga sin pensarlo.'), findsNothing);
    expect(find.textContaining('Stripe'), findsNothing);
    expect(
        find.text('Cada reserva se paga en su paso de pago.'), findsOneWidget);
    // Ni siquiera se consulta el perfil de pagos con tarjeta.
    verifyNever(() => payments.ensureStripeCustomer());
  });

  testWidgets('con un proveedor de tarjeta registrado, vuelve a aparecer',
      (t) async {
    await pump(t, cardsEnabled: true);
    expect(find.text('Paga sin pensarlo.'), findsOneWidget);
    expect(find.byTooltip('Agregar tarjeta'), findsOneWidget);
  });
}
