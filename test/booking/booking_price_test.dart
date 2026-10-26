import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/booking_form_data.dart';
import 'package:luxelane/core/models/models.dart' hide BookingEvent;
import 'package:luxelane/core/models/place_model.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/services/pricing_catalog.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_screen.dart';
import 'package:luxelane/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _MockPaymentBloc extends MockBloc<PaymentEvent, PaymentState>
    implements PaymentBloc {}

class _Repo extends Mock implements BookingRepository {}

class _Auth extends Mock implements AuthRepository {}

class _NoRoute extends MapsService {
  @override
  Future<RouteInfo?> getRoute({
    required Place origin,
    required Place destination,
  }) async =>
      null;
}

// Lugares y tarifas de PRUEBA, ficticios.
const _origin =
    Place(name: 'Origen (prueba)', address: 'A', lat: -17.78, lng: -63.18);
const _dest =
    Place(name: 'Destino (prueba)', address: 'B', lat: -17.76, lng: -63.19);

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

/// E35 y E36: el precio de la barra es el del servidor; sin él, «estimado»;
/// si la cotización falla, el error se ve junto al precio y se reintenta.
void main() {
  late _Repo repo;

  setUpAll(() => registerFallbackValue(
        Booking(
          id: '',
          riderId: '',
          origin: _origin,
          destination: _dest,
          scheduledAt: DateTime(2030),
          vehicleClass: VehicleClass.business,
          serviceType: ServiceType.oneWay,
          status: BookingStatus.pending,
          estimatedPrice: 0,
          createdAt: DateTime(2030),
          updatedAt: DateTime(2030),
        ),
      ));

  setUp(() async {
    await sl.reset();
    repo = _Repo();
    sl.registerSingleton<BookingRepository>(repo);
    sl.registerSingleton<MapsService>(_NoRoute());
    final auth = _Auth();
    when(() => auth.needsEmailVerification).thenReturn(false);
    sl.registerSingleton<AuthRepository>(auth);
    PricingCatalog.instance.setRules([
      for (final st in ServiceType.values)
        PricingRule(
          id: 'business_${st.name}',
          vehicleClass: VehicleClass.business,
          serviceType: st,
          basePriceUsd: 10,
          pricePerKmUsd: 2,
          pricePerHourUsd: 30,
          minimumPriceUsd: 20,
        ),
    ]);
    PricingCatalog.instance.setMaintenanceMode(false);
  });

  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final authBloc = _MockAuthBloc();
    whenListen(authBloc, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(_user));
    final bookingBloc = _MockBookingBloc();
    whenListen(bookingBloc, const Stream<BookingState>.empty(),
        initialState: const BookingInitial());
    final paymentBloc = _MockPaymentBloc();
    whenListen(paymentBloc, const Stream<PaymentState>.empty(),
        initialState: const PaymentInitial());
    final router = GoRouter(
      initialLocation: '/booking',
      initialExtra: BookingFormData(
        origin: _origin,
        destination: _dest,
        serviceType: ServiceType.oneWay,
        scheduledAt: DateTime.now().add(const Duration(hours: 3)),
        routeDistanceKm: 21,
      ),
      routes: [
        GoRoute(path: '/booking', builder: (_, __) => const BookingScreen()),
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      ],
    );
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<BookingBloc>.value(value: bookingBloc),
          BlocProvider<PaymentBloc>.value(value: paymentBloc),
        ],
        child: MaterialApp.router(theme: luxTheme, routerConfig: router),
      ),
    );
    await t.pump();
  }

  testWidgets('estimado mientras no hay cotización; luego el del servidor',
      (t) async {
    when(() => repo.quoteBooking(any()))
        .thenAnswer((_) async => const Right(BookingQuote(price: 53)));
    await open(t);
    // Estimación local: 10 + 21 × 2 = 52, marcada como estimada.
    expect(find.text('PRECIO ESTIMADO'), findsOneWidget);
    expect(find.text('PRECIO FINAL'), findsNothing);
    await t.pump(const Duration(milliseconds: 700));
    await t.pump();
    expect(find.text('PRECIO FINAL'), findsOneWidget);
    expect(find.textContaining('53'), findsWidgets);
    verify(() => repo.quoteBooking(any())).called(1);
  });

  testWidgets('si la cotización falla: error junto al precio y reintento',
      (t) async {
    when(() => repo.quoteBooking(any())).thenAnswer((_) async =>
        const Left(ServerFailure('No pudimos calcular el precio (prueba).')));
    await open(t);
    await t.pump(const Duration(milliseconds: 700));
    await t.pump();
    expect(
        find.text('No pudimos calcular el precio (prueba).'), findsOneWidget);
    expect(find.text('PRECIO ESTIMADO'), findsOneWidget);
    when(() => repo.quoteBooking(any()))
        .thenAnswer((_) async => const Right(BookingQuote(price: 53)));
    await t.tap(find.text('Reintentar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 700));
    await t.pump();
    verify(() => repo.quoteBooking(any())).called(2);
    expect(find.text('No pudimos calcular el precio (prueba).'), findsNothing);
    expect(find.text('PRECIO FINAL'), findsOneWidget);
  });

  testWidgets('E39: el asistente móvil también reserva para un invitado',
      (t) async {
    when(() => repo.quoteBooking(any()))
        .thenAnswer((_) async => const Right(BookingQuote(price: 53)));
    await open(t);
    // Paso 3 (confirmar): vehículo → detalles (sin aeropuerto) → resumen.
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Reservar para un invitado'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Reservar para mí'), findsOneWidget);
    await t.tap(find.text('Reservar para un invitado'));
    await t.pumpAndSettle();
    expect(find.text('Añadir nuevo invitado'), findsOneWidget);
  });
}
