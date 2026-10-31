import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/booking_form_data.dart';
import 'package:luxelane/core/models/models.dart' hide BookingEvent;
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/services/pricing_catalog.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:luxelane/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

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

// Lugares de PRUEBA, ficticios.
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

/// Idiomas, bloque reserva: el asistente de reserva (pasos, resumen y
/// diálogo del invitado) y los errores del repositorio salen en inglés y
/// en portugués, sin restos del español.
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
    when(() => repo.quoteBooking(any()))
        .thenAnswer((_) async => const Right(BookingQuote(price: 53)));
  });

  tearDown(() => L10n.use(const Locale('es')));

  Future<void> open(WidgetTester t, Locale locale) async {
    L10n.use(locale);
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final authBloc = _MockAuthBloc();
    whenListen(authBloc, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(_user));
    final bookingBloc = _MockBookingBloc();
    whenListen(bookingBloc, const Stream<BookingState>.empty(),
        initialState: const BookingInitial());
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
        ],
        child: MaterialApp.router(
          theme: luxTheme,
          routerConfig: router,
          locale: locale,
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
        ),
      ),
    );
    await t.pump();
  }

  /// Recorre los tres pasos del asistente y abre el diálogo del invitado.
  Future<void> walk(
    WidgetTester t, {
    required Locale locale,
    required String step1,
    required String chooseExperience,
    required String estimatedPrice,
    required String continueLabel,
    required String tripDetails,
    required String passengers,
    required String specialRequests,
    required String summary,
    required String continueToPayment,
    required String forGuest,
    required String addGuest,
    required String guestIntroStart,
    required String mr,
  }) async {
    await open(t, locale);
    expect(find.text(step1), findsOneWidget);
    expect(find.text(chooseExperience), findsOneWidget);
    expect(find.text(estimatedPrice), findsOneWidget);
    expect(find.text('PASO 1 DE 3'), findsNothing);
    expect(find.text('Elige tu experiencia'), findsNothing);
    expect(find.text('PRECIO ESTIMADO'), findsNothing);

    await t.tap(find.text(continueLabel));
    await t.pumpAndSettle();
    expect(find.text(tripDetails), findsOneWidget);
    expect(find.text(passengers), findsOneWidget);
    expect(find.text(specialRequests), findsOneWidget);
    expect(find.text('DETALLES DEL VIAJE'), findsNothing);
    expect(find.text('Pasajeros'), findsNothing);

    await t.tap(find.text(continueLabel));
    await t.pumpAndSettle();
    expect(find.text(summary), findsOneWidget);
    expect(find.text(continueToPayment), findsOneWidget);
    expect(find.text('RESUMEN DE RESERVA'), findsNothing);
    expect(find.text('Continuar al pago'), findsNothing);

    await t.scrollUntilVisible(find.text(forGuest), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Reservar para un invitado'), findsNothing);
    await t.tap(find.text(forGuest));
    await t.pumpAndSettle();
    expect(find.text(addGuest), findsOneWidget);
    expect(find.textContaining(guestIntroStart), findsOneWidget);
    expect(find.text(mr), findsOneWidget);
    expect(find.text('Añadir nuevo invitado'), findsNothing);
    expect(find.text('Tratamiento'), findsNothing);
  }

  testWidgets('en inglés: pasos, resumen e invitado', (t) async {
    await walk(
      t,
      locale: const Locale('en'),
      step1: 'STEP 1 OF 3',
      chooseExperience: 'Choose your experience',
      estimatedPrice: 'ESTIMATED PRICE',
      continueLabel: 'Continue',
      tripDetails: 'TRIP DETAILS',
      passengers: 'Passengers',
      specialRequests: 'Special requests',
      summary: 'BOOKING SUMMARY',
      continueToPayment: 'Continue to payment',
      forGuest: 'Book for a guest',
      addGuest: 'Add a new guest',
      guestIntroStart: 'Enter the details of the person who will travel.',
      mr: 'Mr.',
    );
  });

  testWidgets('en portugués: pasos, resumen e invitado', (t) async {
    await walk(
      t,
      locale: const Locale('pt'),
      step1: 'ETAPA 1 DE 3',
      chooseExperience: 'Escolha sua experiência',
      estimatedPrice: 'PREÇO ESTIMADO',
      continueLabel: 'Continuar',
      tripDetails: 'DETALHES DA VIAGEM',
      passengers: 'Passageiros',
      specialRequests: 'Solicitações especiais',
      summary: 'RESUMO DA RESERVA',
      continueToPayment: 'Continuar para o pagamento',
      forGuest: 'Reservar para um convidado',
      addGuest: 'Adicionar novo convidado',
      guestIntroStart: 'Informe os dados da pessoa que vai viajar.',
      mr: 'Sr.',
    );
  });

  test('los errores del servidor al reservar y cancelar, en en y pt', () {
    L10n.use(const Locale('en'));
    expect(
      bookingFailureFor('failed-precondition', {'reason': 'out_of_area'})
          .message,
      'For now we only offer trips within the pickup city.',
    );
    expect(
      cancelFailureFor('failed-precondition', {'reason': 'not_owner'}).message,
      'We could not find this booking in your account.',
    );
    expect(formatPriceOrQuote(null), 'Quoted when you book');
    L10n.use(const Locale('pt'));
    expect(
      bookingFailureFor('failed-precondition', {'reason': 'past_pickup'})
          .message,
      'O horário de embarque já passou. Escolha um novo horário.',
    );
    expect(formatPriceOrQuote(70, from: true), 'a partir de Bs 70');
  });
}
