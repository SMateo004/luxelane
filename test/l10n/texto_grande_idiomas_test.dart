import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luxelane/app/locale_controller.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/booking_form_data.dart';
import 'package:luxelane/core/models/booking_payment.dart';
import 'package:luxelane/core/models/models.dart' hide BookingEvent;
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/locale_sync.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/core/services/pricing_catalog.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/auth/presentation/pages/login_page.dart';
import 'package:luxelane/features/auth/presentation/pages/register_page.dart';
import 'package:luxelane/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_screen.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_home_screen.dart';
import 'package:luxelane/features/home/presentation/pages/home_screen.dart';
import 'package:luxelane/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:luxelane/features/payments/presentation/bloc/booking_payment_cubit.dart';
import 'package:luxelane/features/payments/presentation/pages/booking_payment_screen.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxelane/features/profile/presentation/pages/profile_screen.dart';
import 'package:luxelane/features/ride/presentation/pages/ride_screen.dart';
import 'package:luxelane/features/trips/presentation/pages/trips_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

class _MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class _Bookings extends Mock implements BookingRepository {}

class _Auth extends Mock implements AuthRepository {}

class _Trips extends Mock implements TripFlowRepository {}

class _Incidents extends Mock implements IncidentRepository {}

class _NoRoute extends MapsService {
  @override
  Future<RouteInfo?> getRoute({
    required Place origin,
    required Place destination,
  }) async =>
      null;
}

class _Payments implements BookingPaymentRepository {
  final ctrl = StreamController<BookingPayment?>.broadcast();

  Future<void> dispose() => ctrl.close();

  @override
  Stream<BookingPayment?> watch(String bookingId) => ctrl.stream;

  @override
  Future<Either<Failure, PaymentStart>> start(
    String bookingId,
    String method,
  ) async =>
      const Right(
        PaymentStart(
          method: PayMethod.manualQr,
          amountDue: 123450,
          paymentRef: 'LX7K2M',
          instructions: ManualInstructions(
            holderName: 'Titular ficticio',
            bankName: 'Banco ficticio',
            accountNumber: '000-ficticia',
            note: 'Nota ficticia del admin',
          ),
        ),
      );

  @override
  Future<Either<Failure, void>> markSent(
    String bookingId, {
    String? operationNumber,
  }) async =>
      const Right(null);
}

// Personas, lugares e importes de PRUEBA, ficticios.
final _now = DateTime.now();

final _rider = User(
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

final _driverUser = User(
  id: 'd',
  email: 'd@example.com',
  phone: '',
  displayName: 'Luis Pérez',
  role: UserRole.driver,
  createdAt: _now,
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

final _driverProfile = DriverProfile(
  userId: 'd',
  licenseNumber: 'LP-1',
  licenseExpiry: _now.add(const Duration(days: 400)),
  vehicleId: 'v',
  documentsVerified: true,
  rating: 4.9,
  totalRides: 12,
  isAvailable: true,
);

const _origin = Place(
  name: 'Hotel Europa (prueba)',
  address: 'Calle Tiahuanacu 64',
  lat: -16.5,
  lng: -68.1,
);
const _dest = Place(
  name: 'Aeropuerto El Alto (prueba)',
  address: 'Aeropuerto El Alto',
  lat: -16.51,
  lng: -68.19,
);

Booking _booking(
  String id,
  BookingStatus status, {
  ServiceType type = ServiceType.oneWay,
  String riderId = 'ana',
  DriverInfo? driver,
}) =>
    Booking(
      id: id,
      riderId: riderId,
      origin: _origin,
      destination: _dest,
      scheduledAt: _now.add(const Duration(minutes: 20)),
      vehicleClass: VehicleClass.business,
      serviceType: type,
      status: status,
      estimatedPrice: 120,
      hours: type == ServiceType.byTheHour ? 3 : null,
      createdAt: _now,
      updatedAt: _now,
      driverInfo: driver,
      riderPreferences: const RidePreferences(quiet: true, luggageHelp: true),
    );

/// Textos que el diseño acorta a propósito con «…», por pantalla: por qué
/// y qué párrafos cubre (textos en el idioma activo).
typedef _Ellipsis = ({String why, bool Function(RenderParagraph p) covers});

String _text(RenderParagraph p) => p.text.toPlainText();

final _ellipsisAllowed = <String, List<_Ellipsis>>{
  'registro': [
    (
      why: 'Etiqueta de un campo vacío: Material (InputDecorator) la deja en '
          'una línea. Al tocar el campo sube, se achica a 0,75× y se lee '
          'entera (el test lo comprueba).',
      covers: (p) => {
            L10n.current.authNameLabel,
            L10n.current.authEmailLabel,
            L10n.current.authPhoneLabel,
            L10n.current.authPasswordLabel,
          }.contains(_text(p)),
    ),
  ],
  'reserva': [
    (
      why: 'Nombre y descripción en las tarjetas del carrusel de vehículos: '
          'ancho fijo y las no elegidas son un adelanto. El nombre entero '
          'sigue en «Detalles del vehículo» (el test lo comprueba).',
      covers: (p) => VehicleClass.values
          .any((vc) => _text(p) == vc.label || _text(p) == vc.description),
    ),
  ],
  'Mis viajes': [
    (
      why: 'Fecha y lugar de recogida de la tarjeta: con la letra grande '
          'tiene dos líneas y la fecha y la hora se leen enteras; el lugar, '
          'de largo libre, puede acortarse y se ve entero al abrir el viaje.',
      covers: (p) => _text(p).contains(_origin.name) && (p.maxLines ?? 0) >= 2,
    ),
  ],
};

/// El error y el widget que lo causó (la línea del código).
String _describe(FlutterErrorDetails e) {
  final where = RegExp(r'file://\S*/((?:lib|test)/\S+)')
      .firstMatch(e.toString())
      ?.group(1);
  return '${e.exceptionAsString().split('\n').first} ${where ?? ''}'.trim();
}

/// Roboto del SDK de Flutter con los nombres de las fuentes de la app.
/// Sin esto los tests dibujan con FlutterTest, que da a cada letra un
/// cuadrado de 1 em: casi el doble de ancho que Montserrat, y la prueba
/// marcaría como cortado texto que en el teléfono cabe.
Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  final dir = Directory(
    root != null
        ? '$root/bin/cache/artifacts/material_fonts'
        // flutter_tester está en bin/cache/artifacts/engine/<plataforma>.
        : '${File(Platform.resolvedExecutable).parent.parent.parent.path}'
            '/material_fonts',
  );
  for (final family in [
    LuxTypography.sansFamily,
    LuxTypography.serifFamily,
    'Roboto', // i18n-ignore: nombre de fuente
  ]) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'Bold']) {
      final f = File('${dir.path}/Roboto-$w.ttf');
      expect(f.existsSync(), isTrue, reason: 'falta ${f.path}');
      loader.addFont(
        f.readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  }
}

/// B4 (idiomas): con la letra al 200 % y los textos de inglés y portugués,
/// más largos que los del español, las diez pantallas principales no
/// desbordan ni cortan texto en un móvil de 390 × 844.
void main() {
  setUpAll(() async {
    await _loadFonts();
    registerFallbackValue(_rider);
    registerFallbackValue(_booking('x', BookingStatus.pending));
  });

  late _Payments payments;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    payments = _Payments();
    final bookings = _Bookings();
    final ride = _booking('b1', BookingStatus.driverArrived,
        driver: const DriverInfo(
          name: 'Luis Pérez',
          vehicle: 'Toyota Camry · Negro',
          plate: 'ABC123',
          rating: 4.9,
        ));
    when(() => bookings.watchBooking(any()))
        .thenAnswer((_) => Stream.value(ride));
    when(() => bookings.watchDriverPhone(any()))
        .thenAnswer((_) => Stream.value('+59170000001'));
    when(() => bookings.watchDriverLocation(any()))
        .thenAnswer((_) => const Stream.empty());
    when(() => bookings.watchBookingsByRider(any()))
        .thenAnswer((_) => Stream.value(const []));
    when(() => bookings.quoteBooking(any()))
        .thenAnswer((_) async => const Right(BookingQuote(price: 53)));
    sl.registerSingleton<BookingRepository>(bookings);
    sl.registerSingleton<MapsService>(_NoRoute());
    final auth = _Auth();
    when(() => auth.needsEmailVerification).thenReturn(false);
    sl.registerSingleton<AuthRepository>(auth);
    final trips = _Trips();
    when(() => trips.getPickupCode(any())).thenAnswer(
      (_) async => Right(PickupCode(code: '4207', expiresAt: _now)),
    );
    sl.registerSingleton<TripFlowRepository>(trips);
    final incidents = _Incidents();
    when(() => incidents.watchMine(any(), any()))
        .thenAnswer((_) => Stream.value(null));
    sl.registerSingleton<IncidentRepository>(incidents);
    sl.registerSingleton<BookingPaymentRepository>(payments);
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

  tearDown(() async {
    await payments.dispose();
    L10n.use(const Locale('es'));
    await sl.reset();
  });

  AuthBloc authBloc(AuthState state) {
    final bloc = _MockAuthBloc();
    whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);
    return bloc;
  }

  NotificationBloc inbox() {
    final bloc = _MockNotificationBloc();
    whenListen(
      bloc,
      const Stream<NotificationState>.empty(),
      initialState: const NotificationLoaded(notifications: [], unreadCount: 3),
    );
    return bloc;
  }

  DriverBloc driverBloc(List<Booking> bookings) {
    final bloc = _MockDriverBloc();
    whenListen(
      bloc,
      const Stream<DriverState>.empty(),
      initialState: DriverLoaded(
        user: _driverUser,
        profile: _driverProfile,
        isAvailable: true,
        bookings: bookings,
        vehicleClass: VehicleClass.business,
      ),
    );
    return bloc;
  }

  /// Monta [home] (o el [router]) a 390 × 844 con la letra al 200 %.
  /// Devuelve los errores que el framework informó al montar.
  Future<List<FlutterErrorDetails>> mount(
    WidgetTester t,
    Locale locale, {
    Widget? home,
    GoRouter? router,
    List<BlocProvider> providers = const [],
    Duration? settle,
    Future<void> Function()? after,
  }) async {
    L10n.use(locale);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    Widget big(BuildContext c, Widget? child) => MediaQuery(
          data:
              MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        );
    final Widget app = router != null
        ? MaterialApp.router(
            theme: luxTheme,
            routerConfig: router,
            locale: locale,
            supportedLocales: LuxLocale.supportedLocales,
            localizationsDelegates: LuxLocale.delegates,
            builder: big,
          )
        : MaterialApp(
            theme: luxTheme,
            locale: locale,
            supportedLocales: LuxLocale.supportedLocales,
            localizationsDelegates: LuxLocale.delegates,
            builder: big,
            home: home,
          );
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await t.pumpWidget(
        providers.isEmpty
            ? app
            : MultiBlocProvider(providers: providers, child: app),
      );
      if (settle != null) {
        await t.pump(settle);
        await t.pump(settle);
      } else {
        await t.pumpAndSettle();
      }
      if (after != null) await after();
    } finally {
      FlutterError.onError = previous;
    }
    return errors;
  }

  /// Ningún error de layout y ningún texto visible cortado.
  void expectWhole(
    WidgetTester t,
    List<FlutterErrorDetails> errors, {
    String? screen,
  }) {
    final allowed = _ellipsisAllowed[screen] ?? const [];
    expect(
      errors.map(_describe).toList(),
      isEmpty,
      reason: 'errores de layout',
    );
    expect(t.takeException(), isNull);
    final view = Offset.zero & const Size(390, 844);
    final cut = <String>[];
    for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
      if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
      final box = p.localToGlobal(Offset.zero) & p.size;
      if (!box.overlaps(view)) continue;
      final text = p.text.toPlainText();
      if (allowed.any((e) => e.covers(p))) continue;
      if (p.didExceedMaxLines) {
        cut.add('«$text» (más líneas que maxLines)');
      } else if (!p.softWrap &&
          p.getMaxIntrinsicWidth(double.infinity) > p.size.width + 0.5) {
        cut.add('«$text» (no cabe a lo ancho)');
      }
    }
    expect(cut, isEmpty, reason: 'textos cortados');
  }

  for (final locale in const [Locale('en'), Locale('pt')]) {
    final code = locale.languageCode;
    group('letra al 200 % en $code:', () {
      testWidgets('1 inicio de sesión', (t) async {
        final errors = await mount(
          t,
          locale,
          home: const LoginPage(),
          providers: [
            BlocProvider<AuthBloc>.value(
              value: authBloc(const AuthUnauthenticated()),
            ),
          ],
        );
        expectWhole(t, errors);
      });

      testWidgets('2 registro', (t) async {
        final errors = await mount(
          t,
          locale,
          home: const RegisterPage(),
          providers: [
            BlocProvider<AuthBloc>.value(
              value: authBloc(const AuthUnauthenticated()),
            ),
          ],
        );
        expectWhole(t, errors, screen: 'registro');
        // La etiqueta más larga, al tocar el campo, se lee entera.
        final phone = L10n.current.authPhoneLabel;
        await t.tap(find.widgetWithText(TextFormField, phone));
        await t.pumpAndSettle();
        final label = t
            .renderObjectList<RenderParagraph>(find.text(phone))
            .where((p) => p.hasSize && !p.size.isEmpty);
        expect(label, isNotEmpty);
        expect(label.any((p) => p.didExceedMaxLines), isFalse, reason: phone);
      });

      testWidgets('3 inicio del pasajero (móvil)', (t) async {
        final errors = await mount(
          t,
          locale,
          home: const HomeScreen(),
          providers: [
            BlocProvider<AuthBloc>.value(
                value: authBloc(AuthAuthenticated(_rider))),
            BlocProvider<NotificationBloc>.value(value: inbox()),
          ],
          settle: const Duration(seconds: 2),
        );
        expectWhole(t, errors);
      });

      testWidgets('4 reserva: elegir la experiencia', (t) async {
        final bookings = _MockBookingBloc();
        whenListen(bookings, const Stream<BookingState>.empty(),
            initialState: const BookingInitial());
        final router = GoRouter(
          initialLocation: '/booking',
          initialExtra: BookingFormData(
            origin: _origin,
            destination: _dest,
            serviceType: ServiceType.oneWay,
            scheduledAt: _now.add(const Duration(hours: 3)),
            routeDistanceKm: 21,
          ),
          routes: [
            GoRoute(
                path: '/booking', builder: (_, __) => const BookingScreen()),
            GoRoute(path: '/', builder: (_, __) => const SizedBox()),
          ],
        );
        final errors = await mount(
          t,
          locale,
          router: router,
          providers: [
            BlocProvider<AuthBloc>.value(
                value: authBloc(AuthAuthenticated(_rider))),
            BlocProvider<BookingBloc>.value(value: bookings),
          ],
        );
        expectWhole(t, errors, screen: 'reserva');
        // El nombre de la clase elegida se lee entero en algún sitio.
        final name = t
            .renderObjectList<RenderParagraph>(
                find.text(VehicleClass.business.label))
            .where((p) => p.hasSize && !p.size.isEmpty);
        expect(name.any((p) => !p.didExceedMaxLines), isTrue);
      });

      testWidgets('5 pago manual', (t) async {
        final cubit = BookingPaymentCubit(
          repository: payments,
          bookingId: 'b1',
          isWeb: false,
        );
        addTearDown(cubit.close);
        final errors = await mount(
          t,
          locale,
          home: BlocProvider.value(
            value: cubit,
            child: const BookingPaymentView(bookingId: 'b1'),
          ),
          // Hasta que llega el pago se ve un indicador que no se detiene.
          settle: const Duration(milliseconds: 100),
          after: () async {
            payments.ctrl.add(
              BookingPayment.fromJson('b1', {
                'paymentStatus': 'awaiting_payment',
                'paymentMethod': 'manual_qr',
                'amountDue': 123450,
                'amountPaid': 0,
                'paymentRef': 'LX7K2M',
                'methodsOffered': ['manual_qr'],
                'paymentDeadline': _now
                    .add(const Duration(minutes: 30))
                    .millisecondsSinceEpoch,
              }),
            );
            await t.pumpAndSettle();
          },
        );
        expectWhole(t, errors);
      });

      testWidgets('6 viaje: código de recogida y SOS', (t) async {
        final errors = await mount(
          t,
          locale,
          home: const RideScreen(rideId: 'b1'),
          settle: const Duration(seconds: 2),
        );
        expect(find.text('SOS'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expectWhole(t, errors);
      });

      testWidgets('7 Mis viajes', (t) async {
        final bookings = _MockBookingBloc();
        whenListen(bookings, const Stream<BookingState>.empty(),
            initialState: BookingTripsLoaded([
              _booking('b1', BookingStatus.pending,
                  type: ServiceType.byTheHour),
              _booking('b2', BookingStatus.completed),
            ]));
        sl.registerFactory<BookingBloc>(() => bookings);
        final errors = await mount(
          t,
          locale,
          home: const TripsScreen(),
          providers: [
            BlocProvider<AuthBloc>.value(
                value: authBloc(AuthAuthenticated(_rider))),
          ],
        );
        expectWhole(t, errors, screen: 'Mis viajes');
      });

      testWidgets('8 perfil', (t) async {
        sl.registerSingleton<LocaleSync>(LocaleSync(
          controller: LocaleController(),
          deviceLocales: () => [locale],
          save: (_, __) async => null,
        ));
        final profile = _MockProfileBloc();
        whenListen(profile, const Stream<ProfileState>.empty(),
            initialState: ProfileLoaded(user: _rider, totalRides: 3));
        final errors = await mount(
          t,
          locale,
          home: BlocProvider<ProfileBloc>.value(
            value: profile,
            child: const ProfileScreen(),
          ),
          providers: [
            BlocProvider<AuthBloc>.value(
                value: authBloc(AuthAuthenticated(_rider))),
          ],
        );
        expectWhole(t, errors);
      });

      testWidgets('9 inicio del chófer', (t) async {
        final errors = await mount(
          t,
          locale,
          home: const DriverHomeScreen(),
          providers: [
            BlocProvider<DriverBloc>.value(value: driverBloc(const [])),
            BlocProvider<AuthBloc>.value(
              value: authBloc(const AuthUnauthenticated()),
            ),
          ],
          settle: const Duration(milliseconds: 600),
        );
        expectWhole(t, errors);
      });

      testWidgets('10 viaje activo del chófer', (t) async {
        final errors = await mount(
          t,
          locale,
          home: const DriverHomeScreen(),
          providers: [
            BlocProvider<DriverBloc>.value(
              value: driverBloc([
                _booking('b1', BookingStatus.driverArriving, riderId: 'r'),
              ]),
            ),
            BlocProvider<AuthBloc>.value(
              value: authBloc(const AuthUnauthenticated()),
            ),
          ],
          settle: const Duration(milliseconds: 600),
        );
        expectWhole(t, errors);
      });
    });
  }
}
