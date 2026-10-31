import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/locale_controller.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/error/failures.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/locale_sync.dart';
import 'package:luxelane/core/widgets/components.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxelane/features/profile/presentation/pages/preferences_screen.dart';
import 'package:luxelane/features/profile/presentation/pages/profile_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _Users extends Mock implements UserRepository {}

class _Bookings extends Mock implements BookingRepository {}

class _Prefs extends Mock implements PreferencesRepository {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

// Personas de PRUEBA, ficticias.
User _user({
  UserRole role = UserRole.rider,
  TripPreferences prefs = TripPreferences.empty,
}) =>
    User(
      id: 'ana',
      email: 'ana@example.com',
      phone: '+59170000000',
      displayName: 'Ana',
      role: role,
      createdAt: DateTime(2025),
      isVerified: true,
      isActive: true,
      fcmTokens: const [],
      tripPreferences: prefs,
    );

/// Preferencias, B1: la pantalla del perfil del pasajero para su chófer.
void main() {
  setUpAll(() {
    registerFallbackValue(TripPreferences.empty);
    registerFallbackValue(_user());
  });
  tearDown(() async {
    L10n.use(const Locale('es'));
    await sl.reset();
  });

  Widget app(Locale locale, Widget home) => MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: home,
      );

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(800, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  group('entrada en el perfil', () {
    Future<void> pumpProfile(WidgetTester t, User user) async {
      tall(t);
      sl.registerSingleton<LocaleSync>(LocaleSync(
        controller: LocaleController(),
        deviceLocales: () => [const Locale('es')],
        save: (_, __) async => null,
      ));
      final auth = _MockAuthBloc();
      whenListen(auth, const Stream<AuthState>.empty(),
          initialState: AuthAuthenticated(user));
      final profile = _MockProfileBloc();
      whenListen(profile, const Stream<ProfileState>.empty(),
          initialState: ProfileLoaded(user: user));
      await t.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: auth,
          child: app(
            const Locale('es'),
            BlocProvider<ProfileBloc>.value(
              value: profile,
              child: const ProfileScreen(),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('pasajero: la fila con el resumen de lo guardado', (t) async {
      await pumpProfile(
        t,
        _user(
          prefs: const TripPreferences(
            conversation: ConversationPref.quiet,
            music: MusicStyle.jazz,
            note: 'No sale en el resumen',
          ),
        ),
      );
      expect(find.text('Preferencias para tu chófer'), findsOneWidget);
      expect(find.text('Prefiero silencio · Jazz'), findsOneWidget);
      expect(find.textContaining('No sale en el resumen'), findsNothing);
    });

    testWidgets('pasajero sin preferencias: un texto sobrio', (t) async {
      await pumpProfile(t, _user());
      expect(find.text('Sin preferencias todavía'), findsOneWidget);
    });

    testWidgets('el chófer no tiene esta sección', (t) async {
      await pumpProfile(t, _user(role: UserRole.driver));
      expect(find.text('Preferencias para tu chófer'), findsNothing);
      expect(find.text('Sin preferencias todavía'), findsNothing);
    });
  });

  group('pantalla de preferencias', () {
    late _Prefs prefs;
    late ProfileBloc bloc;

    Future<void> pump(
      WidgetTester t, {
      Locale locale = const Locale('es'),
      TripPreferences saved = TripPreferences.empty,
      PreferenceOptions options = PreferenceOptions.none,
    }) async {
      tall(t);
      L10n.use(locale);
      final users = _Users();
      final bookings = _Bookings();
      prefs = _Prefs();
      when(() => users.getUserById('ana'))
          .thenAnswer((_) async => Right(_user(prefs: saved)));
      when(() => bookings.getBookingsByRider('ana'))
          .thenAnswer((_) async => const Right([]));
      when(() => prefs.options()).thenAnswer((_) async => options);
      bloc = ProfileBloc(
        userRepository: users,
        bookingRepository: bookings,
        preferencesRepository: prefs,
      );
      addTearDown(bloc.close);
      bloc.add(const ProfileLoadRequested(userId: 'ana'));
      await bloc.stream.firstWhere((s) => s is ProfileLoaded);
      await t.pumpWidget(
        app(
          locale,
          BlocProvider<ProfileBloc>.value(
            value: bloc,
            child: PreferencesScreen(repository: prefs),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    bool saveEnabled(WidgetTester t, String label) =>
        t.widget<LuxButton>(find.widgetWithText(LuxButton, label)).onPressed !=
        null;

    testWidgets('vacía: invita a añadirlas y Guardar espera un cambio',
        (t) async {
      await pump(t);
      expect(find.text('Preferencias'), findsOneWidget);
      expect(
        find.text('Aún no tienes preferencias. Añade las que quieras que tu '
            'chófer conozca.'),
        findsOneWidget,
      );
      expect(find.text('Tu chófer verá estas preferencias.'), findsOneWidget);
      expect(find.text('Solo tu chófer asignado lo verá.'), findsOneWidget);
      expect(
        find.text('No escribas datos sensibles: claves, tarjetas ni datos '
            'de salud.'),
        findsOneWidget,
      );
      expect(find.text('0/200'), findsOneWidget);
      expect(find.text('Sin música'), findsOneWidget);
      // Temperatura, conversación y música.
      expect(find.text('Sin preferencia'), findsNWidgets(3));
      // Sin lista admitida no se ofrece el campo.
      expect(find.byKey(const ValueKey('prefs-playlist')), findsNothing);
      expect(saveEnabled(t, 'Guardar'), isFalse);
    });

    testWidgets('guardar: manda lo elegido y confirma sin promesas', (t) async {
      await pump(t);
      when(() => prefs.save(any())).thenAnswer(
        (i) async => Right(i.positionalArguments.first as TripPreferences),
      );
      await t.tap(find.text('Inglés'));
      await t.pump();
      await t.tap(find.text('Prefiero silencio'));
      await t.pump();
      await t.tap(find.text('Silla de ruedas plegable'));
      await t.pump();
      await t.enterText(
          find.byKey(const ValueKey('prefs-note')), '  Espero en la puerta ');
      await t.pump();
      expect(find.text('22/200'), findsOneWidget);
      expect(find.textContaining('Aún no tienes'), findsNothing);
      expect(saveEnabled(t, 'Guardar'), isTrue);

      await t.tap(find.text('Guardar'));
      await t.pumpAndSettle();

      verify(() => prefs.save(const TripPreferences(
            languages: [DriverLanguage.en],
            conversation: ConversationPref.quiet,
            needs: [PracticalNeed.foldingWheelchair],
            note: 'Espero en la puerta',
          ))).called(1);
      expect(find.text('Preferencias guardadas.'), findsOneWidget);
      // Lo guardado ya es lo vigente: no hay nada nuevo que guardar.
      expect(saveEnabled(t, 'Guardar'), isFalse);
    });

    testWidgets('si falla, se ve el motivo y lo escrito sigue ahí', (t) async {
      await pump(t);
      when(() => prefs.save(any())).thenAnswer((_) async => const Left(
          ServerFailure(
              'Revisa la nota: hasta 200 caracteres y sin enlaces.')));
      await t.enterText(
          find.byKey(const ValueKey('prefs-note')), 'mira www.example.com');
      await t.pump();
      await t.tap(find.text('Guardar'));
      await t.pumpAndSettle();
      expect(find.text('Revisa la nota: hasta 200 caracteres y sin enlaces.'),
          findsOneWidget);
      expect(find.text('mira www.example.com'), findsOneWidget);
      expect(saveEnabled(t, 'Guardar'), isTrue);
    });

    testWidgets('lista de música: solo si se ofrece y con https', (t) async {
      await pump(t, options: const PreferenceOptions(playlistEnabled: true));
      when(() => prefs.save(any())).thenAnswer(
        (i) async => Right(i.positionalArguments.first as TripPreferences),
      );
      final field = find.byKey(const ValueKey('prefs-playlist'));
      expect(field, findsOneWidget);
      await t.enterText(field, 'http://music.example.com/lista');
      await t.pump();
      expect(find.text('El enlace debe empezar por https://'), findsOneWidget);
      expect(saveEnabled(t, 'Guardar'), isFalse);

      await t.enterText(field, 'https://music.example.com/lista');
      await t.pump();
      expect(find.text('El enlace debe empezar por https://'), findsNothing);
      await t.tap(find.text('Guardar'));
      await t.pumpAndSettle();
      verify(() => prefs.save(const TripPreferences(
            playlistUrl: 'https://music.example.com/lista',
          ))).called(1);
    });

    testWidgets('precarga lo guardado', (t) async {
      await pump(
        t,
        saved: const TripPreferences(
          music: MusicStyle.none,
          needs: [PracticalNeed.childSeat],
          note: 'Hola',
        ),
      );
      bool selected(String label) =>
          t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label)).selected;
      bool filtered(String label) =>
          t.widget<FilterChip>(find.widgetWithText(FilterChip, label)).selected;
      expect(selected('Sin música'), isTrue);
      expect(selected('Jazz'), isFalse);
      expect(filtered('Silla infantil'), isTrue);
      expect(find.text('Hola'), findsOneWidget);
      expect(find.textContaining('Aún no tienes'), findsNothing);
    });

    for (final (locale, t) in [
      (
        const Locale('en'),
        (
          title: 'Preferences',
          save: 'Save',
          empty: 'You have no preferences yet. Add any you would like your '
              'chauffeur to know.',
          willSee: 'Your chauffeur will see these preferences.',
          private: 'Only your assigned chauffeur will see this.',
          quiet: 'I prefer quiet',
          saved: 'Preferences saved.',
        )
      ),
      (
        const Locale('pt'),
        (
          title: 'Preferências',
          save: 'Salvar',
          empty: 'Você ainda não tem preferências. Adicione as que quiser que '
              'seu motorista conheça.',
          willSee: 'Seu motorista verá estas preferências.',
          private: 'Só o seu motorista designado verá isto.',
          quiet: 'Prefiro silêncio',
          saved: 'Preferências salvas.',
        )
      ),
    ]) {
      testWidgets('en ${locale.languageCode}', (tester) async {
        await pump(tester, locale: locale);
        when(() => prefs.save(any())).thenAnswer(
          (i) async => Right(i.positionalArguments.first as TripPreferences),
        );
        expect(find.text(t.title), findsOneWidget);
        expect(find.text(t.empty), findsOneWidget);
        expect(find.text(t.willSee), findsOneWidget);
        expect(find.text(t.private), findsOneWidget);
        expect(find.text('Guardar'), findsNothing);
        expect(find.textContaining('Aún no tienes'), findsNothing);
        await tester.tap(find.text(t.quiet));
        await tester.pump();
        await tester.tap(find.text(t.save));
        await tester.pumpAndSettle();
        expect(find.text(t.saved), findsOneWidget);
      });
    }
  });
}
