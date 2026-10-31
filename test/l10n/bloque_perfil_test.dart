import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/locale_controller.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart' hide BookingEvent;
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/core/services/locale_sync.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:luxelane/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:luxelane/features/profile/presentation/pages/profile_screen.dart';
import 'package:luxelane/features/profile/presentation/widgets/driver_documents_group.dart';
import 'package:luxelane/features/trips/presentation/pages/trips_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _Users extends Mock implements UserRepository {}

class _Bookings extends Mock implements BookingRepository {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

// Personas, lugares e importes de PRUEBA, ficticios.
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

const _origin =
    Place(name: 'Origen (prueba)', address: 'A', lat: -17.78, lng: -63.18);
const _dest =
    Place(name: 'Destino (prueba)', address: 'B', lat: -17.76, lng: -63.19);

DriverProfile _driverProfile() => DriverProfile.fromJson({
      'userId': 'asig',
      'licenseNumber': 'LIC-1',
      'licenseExpiry': Timestamp.fromDate(DateTime(2030, 5)),
      'vehicleId': 'v_asig',
      'documentsVerified': true,
      'rating': 5,
      'totalRides': 3,
      'isAvailable': true,
    });

const _vehicle = Vehicle(
  id: 'v_asig',
  driverId: 'asig',
  make: 'Toyota',
  model: 'Camry',
  year: 2022,
  plate: 'ABC123',
  vehicleClass: VehicleClass.business,
  color: 'Negro',
  capacity: 3,
  isActive: true,
);

Booking _booking(String id, BookingStatus status, ServiceType type) => Booking(
      id: id,
      riderId: 'ana',
      origin: _origin,
      destination: _dest,
      scheduledAt: DateTime(2030, 3, 4, 18, 30),
      vehicleClass: VehicleClass.business,
      serviceType: type,
      status: status,
      estimatedPrice: 120,
      hours: type == ServiceType.byTheHour ? 3 : null,
      createdAt: DateTime(2030),
      updatedAt: DateTime(2030),
    );

/// Mis viajes, perfil y bandeja de avisos en inglés y en portugués: el
/// texto sale del .arb del idioma, no el español fijo.
void main() {
  setUpAll(() => registerFallbackValue(_user));

  Widget app(Locale locale, Widget home, {AuthBloc? auth}) {
    final child = MaterialApp(
      locale: locale,
      supportedLocales: LuxLocale.supportedLocales,
      localizationsDelegates: LuxLocale.delegates,
      home: home,
    );
    return auth == null
        ? child
        : BlocProvider<AuthBloc>.value(value: auth, child: child);
  }

  AuthBloc authBloc() {
    final bloc = _MockAuthBloc();
    whenListen(bloc, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(_user));
    return bloc;
  }

  final cases = {
    const Locale('en'): (
      title: 'My trips',
      upcoming: 'Upcoming',
      past: 'Past',
      hourly: '3 h at your disposal',
      view: 'View booking',
      rate: 'Rate trip',
      empty: 'Book now',
      from: 'from',
      profile: 'Profile',
      style: 'YOUR TRAVEL STYLE',
      quiet: 'Quiet ride',
      header: 'Member since 2025 · 3 trips',
      signOut: 'Sign out',
      delete: 'Delete account',
      editTitle: 'Edit profile',
      save: 'Save changes',
      licence: 'Licence',
      licenceDetail: 'LIC-1 · expires 05/2030',
      vehicle: 'Business Class · plate ABC123',
      colour: 'Colour',
      updated: 'Profile updated',
    ),
    const Locale('pt'): (
      title: 'Minhas viagens',
      upcoming: 'Próximas',
      past: 'Anteriores',
      hourly: '3 h à disposição',
      view: 'Ver reserva',
      rate: 'Avaliar viagem',
      empty: 'Reservar agora',
      from: 'de',
      profile: 'Perfil',
      style: 'SEU ESTILO DE VIAGEM',
      quiet: 'Viagem em silêncio',
      header: 'Membro desde 2025 · 3 viagens',
      signOut: 'Sair',
      delete: 'Excluir conta',
      editTitle: 'Editar perfil',
      save: 'Salvar alterações',
      licence: 'Habilitação',
      licenceDetail: 'LIC-1 · vence 05/2030',
      vehicle: 'Business Class · placa ABC123',
      colour: 'Cor',
      updated: 'Perfil atualizado',
    ),
  };

  for (final MapEntry(key: locale, value: t) in cases.entries) {
    group('${locale.languageCode}:', () {
      setUp(() async {
        L10n.use(locale);
        SharedPreferences.setMockInitialValues({});
        await sl.reset();
      });
      tearDown(() async {
        L10n.use(const Locale('es'));
        await sl.reset();
      });

      testWidgets('Mis viajes', (tester) async {
        final bookings = _MockBookingBloc();
        whenListen(bookings, const Stream<BookingState>.empty(),
            initialState: BookingTripsLoaded([
              _booking('b1', BookingStatus.pending, ServiceType.byTheHour),
              _booking('b2', BookingStatus.completed, ServiceType.oneWay),
            ]));
        sl.registerFactory<BookingBloc>(() => bookings);
        await tester
            .pumpWidget(app(locale, const TripsScreen(), auth: authBloc()));
        await tester.pumpAndSettle();

        expect(find.text(t.title), findsOneWidget);
        // SectionHeader los muestra en mayúsculas.
        expect(find.text(t.upcoming.toUpperCase()), findsOneWidget);
        expect(find.text(t.past.toUpperCase()), findsOneWidget);
        expect(find.text('PRÓXIMOS'), findsNothing);
        expect(find.text(t.hourly), findsOneWidget);
        expect(find.text(t.view), findsOneWidget);
        expect(find.text(t.rate), findsOneWidget);
        expect(find.textContaining(' · ${t.from} Origen'), findsNWidgets(2));
        expect(find.text('Mis viajes'), findsNothing);
        expect(find.text('Calificar viaje'), findsNothing);
        expect(find.textContaining('a disposición'), findsNothing);
      });

      testWidgets('Mis viajes vacío', (tester) async {
        final bookings = _MockBookingBloc();
        whenListen(bookings, const Stream<BookingState>.empty(),
            initialState: const BookingTripsLoaded([]));
        sl.registerFactory<BookingBloc>(() => bookings);
        await tester
            .pumpWidget(app(locale, const TripsScreen(), auth: authBloc()));
        await tester.pumpAndSettle();
        expect(find.text(t.empty), findsOneWidget);
        expect(find.text('Reservar ahora'), findsNothing);
      });

      testWidgets('perfil y preferencias', (tester) async {
        tester.view.physicalSize = const Size(800, 3000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        sl.registerSingleton<LocaleSync>(LocaleSync(
          controller: LocaleController(),
          deviceLocales: () => [locale],
          save: (_, __) async => null,
        ));
        final profile = _MockProfileBloc();
        whenListen(profile, const Stream<ProfileState>.empty(),
            initialState: ProfileLoaded(user: _user, totalRides: 3));
        await tester.pumpWidget(app(
          locale,
          BlocProvider<ProfileBloc>.value(
            value: profile,
            child: const ProfileScreen(),
          ),
          auth: authBloc(),
        ));
        await tester.pumpAndSettle();

        expect(find.text(t.profile), findsOneWidget);
        expect(find.text(t.style), findsOneWidget);
        expect(find.text(t.quiet), findsOneWidget);
        expect(find.text(t.header), findsOneWidget);
        expect(find.text(t.signOut), findsOneWidget);
        expect(find.text(t.delete), findsOneWidget);
        expect(find.text('Viaje en silencio'), findsNothing);
        expect(find.text('Cerrar sesión'), findsNothing);
        expect(find.textContaining('Miembro desde'), findsNothing);

        await tester.tap(
            find.text(locale.languageCode == 'en' ? 'Edit' : 'Editar').first);
        await tester.pumpAndSettle();
        expect(find.text(t.editTitle), findsOneWidget);
        expect(find.text(t.save), findsOneWidget);
        expect(find.text('Guardar cambios'), findsNothing);
      });

      testWidgets('licencia y vehículo del chófer', (tester) async {
        await tester.pumpWidget(app(
          locale,
          Scaffold(
            body: DriverDocumentsGroup(
              profile: _driverProfile(),
              vehicle: _vehicle,
              onEditColor: () {},
            ),
          ),
        ));
        expect(find.text(t.licence), findsOneWidget);
        expect(find.text(t.licenceDetail), findsOneWidget);
        expect(find.text(t.vehicle), findsOneWidget);
        expect(find.text(t.colour), findsOneWidget);
        expect(find.textContaining('vence 05/2030'),
            locale.languageCode == 'pt' ? findsOneWidget : findsNothing);
        expect(find.text('Licencia'), findsNothing);
      });

      test('el aviso de guardado del ProfileBloc', () async {
        final users = _Users();
        final bookings = _Bookings();
        when(() => users.getUserById('ana'))
            .thenAnswer((_) async => Right(_user));
        when(() => users.updateUser(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => bookings.getBookingsByRider('ana'))
            .thenAnswer((_) async => const Right([]));
        final bloc =
            ProfileBloc(userRepository: users, bookingRepository: bookings);
        addTearDown(bloc.close);
        bloc.add(const ProfileLoadRequested(userId: 'ana'));
        await bloc.stream.firstWhere((s) => s is ProfileLoaded);
        bloc.add(ProfileUpdateRequested(user: _user));
        final saved = await bloc.stream
            .firstWhere((s) => s is ProfileLoaded && s.message != null);
        expect((saved as ProfileLoaded).message, t.updated);
      });
    });
  }
}
