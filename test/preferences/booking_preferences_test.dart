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
import 'package:luxelane/features/booking/presentation/widgets/trip_preferences_step.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _Repo extends Mock implements BookingRepository {}

class _Auth extends Mock implements AuthRepository {}

class _Prefs extends Mock implements PreferencesRepository {}

class _NoRoute extends MapsService {
  @override
  Future<RouteInfo?> getRoute({
    required Place origin,
    required Place destination,
  }) async =>
      null;
}

// Personas y lugares de PRUEBA, ficticios.
const _origin =
    Place(name: 'Origen (prueba)', address: 'A', lat: -17.78, lng: -63.18);
const _dest =
    Place(name: 'Destino (prueba)', address: 'B', lat: -17.76, lng: -63.19);

const _profilePrefs = TripPreferences(
  conversation: ConversationPref.quiet,
  music: MusicStyle.jazz,
);

User _user([TripPreferences prefs = _profilePrefs]) => User(
      id: 'ana',
      email: 'ana@example.com',
      phone: '+59170000000',
      displayName: 'Ana',
      role: UserRole.rider,
      createdAt: DateTime(2025),
      isVerified: true,
      isActive: true,
      fcmTokens: const [],
      tripPreferences: prefs,
    );

Booking _booking() => Booking(
      id: '',
      riderId: 'ana',
      origin: _origin,
      destination: _dest,
      scheduledAt: DateTime.utc(2030),
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: BookingStatus.pending,
      estimatedPrice: 0,
      createdAt: DateTime(2030),
      updatedAt: DateTime(2030),
    );

BookingCreateRequested _request({TripPreferences? preferences}) =>
    BookingCreateRequested(
      origin: _origin,
      destination: _dest,
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      scheduledAt: DateTime.utc(2030),
      riderId: 'ana',
      estimatedPrice: 53,
      quotedPrice: 53,
      requestId: '3f2b1c9e-8d7a-4b6c-9e5f-1a2b3c4d5e6f',
      preferences: preferences,
    );

/// Preferencias, B1: las de este viaje al reservar. Sin tocar el paso no
/// se manda nada (el servidor copia las del perfil); si se cambian, van en
/// createBooking.preferences.
void main() {
  setUpAll(() {
    registerFallbackValue(_booking());
    registerFallbackValue(const BookingCancelRequested(bookingId: ''));
  });
  tearDown(() => L10n.use(const Locale('es')));

  group('createBooking.preferences', () {
    test('sin cambiar: no van; cambiadas: toJson; nunca al cotizar', () {
      expect(bookingRequestData(_booking()).containsKey('preferences'), false);
      const trip = TripPreferences(
        languages: [DriverLanguage.pt],
        needs: [PracticalNeed.boardingAssistance],
        note: 'Hola',
      );
      final b = _booking().withRequestedPreferences(trip);
      expect(bookingRequestData(b)['preferences'], trip.toJson());
      expect(bookingRequestData(b, quote: true).containsKey('preferences'),
          isFalse);
    });

    test('errores de las preferencias del viaje, sin texto técnico', () {
      expect(
        bookingFailureFor('invalid-argument', {
          'reason': 'playlist_not_allowed',
          'fields': ['playlistUrl'],
        }).message,
        L10n.current.prefsErrorPlaylist,
      );
      expect(
        bookingFailureFor('invalid-argument', {
          'reason': 'invalid_request',
          'fields': ['preferences.note'],
        }).message,
        'Revisa la nota: hasta 200 caracteres y sin enlaces.',
      );
      // Otro dato mal formado sigue con su mensaje de siempre.
      expect(
        bookingFailureFor('invalid-argument', {
          'reason': 'invalid_request',
          'fields': ['origin'],
        }).message,
        L10n.current.bookingErrorInvalidRequest,
      );
    });

    late _Repo repo;
    setUp(() {
      repo = _Repo();
      when(() => repo.createBooking(any(),
              quotedPrice: any(named: 'quotedPrice'),
              requestId: any(named: 'requestId')))
          .thenAnswer((_) async => Right(_booking()));
    });

    Booking sent() => verify(() => repo.createBooking(captureAny(),
        quotedPrice: any(named: 'quotedPrice'),
        requestId: any(named: 'requestId'))).captured.single as Booking;

    blocTest<BookingBloc, BookingState>(
      'el bloc pasa las del viaje a createBooking',
      build: () => BookingBloc(bookingRepository: repo),
      act: (b) => b.add(
          _request(preferences: const TripPreferences(music: MusicStyle.none))),
      verify: (_) => expect(sent().requestedPreferences,
          const TripPreferences(music: MusicStyle.none)),
    );

    blocTest<BookingBloc, BookingState>(
      'sin cambiarlas no manda nada',
      build: () => BookingBloc(bookingRepository: repo),
      act: (b) => b.add(_request()),
      verify: (_) => expect(sent().requestedPreferences, isNull),
    );

    test('con el precio nuevo se conservan', () {
      const p = TripPreferences(temperature: CabinTemperaturePref.cool);
      expect(_request(preferences: p).withQuotedPrice(60).preferences, p);
    });
  });

  group('paso «Preferencias de este viaje»', () {
    Future<List<TripPreferences?>> pumpStep(
      WidgetTester t, {
      Locale locale = const Locale('es'),
      TripPreferences profile = _profilePrefs,
      TripPreferences? trip,
    }) async {
      L10n.use(locale);
      t.view.physicalSize = const Size(420, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final changes = <TripPreferences?>[];
      final prefs = _Prefs();
      when(() => prefs.options())
          .thenAnswer((_) async => PreferenceOptions.none);
      await t.pumpWidget(MaterialApp(
        theme: luxTheme,
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TripPreferencesStep(
              profile: profile,
              trip: trip,
              repository: prefs,
              onChanged: (p) => setState(() {
                changes.add(p);
                trip = p;
              }),
            ),
          ),
        ),
      ));
      await t.pumpAndSettle();
      return changes;
    }

    testWidgets('precarga las del perfil y Omitir no cambia nada', (t) async {
      final changes = await pumpStep(t);
      expect(find.text('Preferencias de este viaje'), findsOneWidget);
      expect(find.text('Prefiero silencio · Jazz'), findsOneWidget);
      expect(find.text('Las de tu perfil.'), findsOneWidget);
      await t.tap(find.text('Cambiar para este viaje'));
      await t.pumpAndSettle();
      // El editor llega con las del perfil elegidas.
      expect(
        t
            .widget<ChoiceChip>(
                find.widgetWithText(ChoiceChip, 'Prefiero silencio'))
            .selected,
        isTrue,
      );
      await t.tap(find.text('Omitir'));
      await t.pumpAndSettle();
      expect(changes, isEmpty);
      expect(find.text('Las de tu perfil.'), findsOneWidget);
    });

    testWidgets('cambiarlas: solo para este viaje y se puede volver',
        (t) async {
      final changes = await pumpStep(t);
      await t.tap(find.text('Cambiar para este viaje'));
      await t.pumpAndSettle();
      await t.tap(find.text('Me gusta conversar'));
      await t.pump();
      await t.tap(find.text('Usar en este viaje'));
      await t.pumpAndSettle();
      expect(changes, [
        const TripPreferences(
          conversation: ConversationPref.chatty,
          music: MusicStyle.jazz,
        ),
      ]);
      expect(find.text('Me gusta conversar · Jazz'), findsOneWidget);
      expect(find.text('Cambiadas solo para este viaje.'), findsOneWidget);
      await t.tap(find.text('Usar las de mi perfil'));
      await t.pumpAndSettle();
      expect(changes.last, isNull);
      expect(find.text('Las de tu perfil.'), findsOneWidget);
    });

    testWidgets('dejarlas como en el perfil no manda nada', (t) async {
      final changes = await pumpStep(t);
      await t.tap(find.text('Cambiar para este viaje'));
      await t.pumpAndSettle();
      await t.tap(find.text('Usar en este viaje'));
      await t.pumpAndSettle();
      expect(changes, [null]);
    });

    testWidgets('sin preferencias en el perfil: texto sobrio', (t) async {
      await pumpStep(t, profile: TripPreferences.empty);
      expect(find.text('Sin preferencias para este viaje.'), findsOneWidget);
      expect(find.text('Las de tu perfil.'), findsNothing);
    });

    for (final (locale, title, edit, fromProfile, skip) in [
      (
        const Locale('en'),
        'Preferences for this trip',
        'Change for this trip',
        'From your profile.',
        'Skip',
      ),
      (
        const Locale('pt'),
        'Preferências desta viagem',
        'Alterar para esta viagem',
        'As do seu perfil.',
        'Pular',
      ),
    ]) {
      testWidgets('en ${locale.languageCode}', (t) async {
        await pumpStep(t, locale: locale);
        expect(find.text(title), findsOneWidget);
        expect(find.text(fromProfile), findsOneWidget);
        expect(find.text('Preferencias de este viaje'), findsNothing);
        await t.tap(find.text(edit));
        await t.pumpAndSettle();
        expect(find.text(skip), findsOneWidget);
        expect(find.text('Omitir'), findsNothing);
      });
    }
  });

  group('en la reserva', () {
    late _Repo repo;
    late _MockBookingBloc bookingBloc;

    setUp(() async {
      await sl.reset();
      repo = _Repo();
      when(() => repo.quoteBooking(any()))
          .thenAnswer((_) async => const Right(BookingQuote(price: 53)));
      sl.registerSingleton<BookingRepository>(repo);
      sl.registerSingleton<MapsService>(_NoRoute());
      final auth = _Auth();
      when(() => auth.needsEmailVerification).thenReturn(false);
      sl.registerSingleton<AuthRepository>(auth);
      final prefs = _Prefs();
      when(() => prefs.options())
          .thenAnswer((_) async => PreferenceOptions.none);
      sl.registerSingleton<PreferencesRepository>(prefs);
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
    tearDown(sl.reset);

    Future<void> open(WidgetTester t, {ProfileState? profile}) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final authBloc = _MockAuthBloc();
      whenListen(authBloc, const Stream<AuthState>.empty(),
          initialState: AuthAuthenticated(_user()));
      bookingBloc = _MockBookingBloc();
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
      final profileBloc = _MockProfileBloc();
      if (profile != null) {
        whenListen(profileBloc, const Stream<ProfileState>.empty(),
            initialState: profile);
      }
      await t.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<BookingBloc>.value(value: bookingBloc),
            if (profile != null)
              BlocProvider<ProfileBloc>.value(value: profileBloc),
          ],
          child: MaterialApp.router(theme: luxTheme, routerConfig: router),
        ),
      );
      await t.pump(const Duration(milliseconds: 700));
      await t.pump();
      // Paso 2: detalles.
      await t.tap(find.text('Continuar'));
      await t.pumpAndSettle();
    }

    Future<BookingCreateRequested> confirm(WidgetTester t) async {
      await t.tap(find.text('Continuar'));
      await t.pumpAndSettle();
      await t.tap(find.text('Continuar al pago'));
      await t.pump();
      return verify(() => bookingBloc.add(captureAny())).captured.single
          as BookingCreateRequested;
    }

    Future<void> showStep(WidgetTester t) =>
        t.scrollUntilVisible(find.text('Cambiar para este viaje'), 200,
            scrollable: find.byType(Scrollable).first);

    testWidgets('sin tocar el paso la reserva sale igual, sin preferencias',
        (t) async {
      await open(t);
      await showStep(t);
      expect(find.text('Prefiero silencio · Jazz'), findsOneWidget);
      expect(find.text('Las de tu perfil.'), findsOneWidget);
      final e = await confirm(t);
      expect(e.preferences, isNull);
      expect(e.quotedPrice, 53);
    });

    testWidgets('cambiadas: van en la misma solicitud', (t) async {
      await open(t);
      await showStep(t);
      await t.tap(find.text('Cambiar para este viaje'));
      await t.pumpAndSettle();
      await t.tap(find.text('Inglés'));
      await t.pump();
      await t.tap(find.text('Usar en este viaje'));
      await t.pumpAndSettle();
      final e = await confirm(t);
      expect(
        e.preferences,
        const TripPreferences(
          languages: [DriverLanguage.en],
          conversation: ConversationPref.quiet,
          music: MusicStyle.jazz,
        ),
      );
    });

    testWidgets('precarga las del ProfileBloc si ya las guardó', (t) async {
      await open(
        t,
        profile: ProfileLoaded(
          user: _user(const TripPreferences(music: MusicStyle.classical)),
        ),
      );
      await showStep(t);
      expect(find.text('Clásica'), findsOneWidget);
      expect(find.text('Prefiero silencio · Jazz'), findsNothing);
    });
  });
}
