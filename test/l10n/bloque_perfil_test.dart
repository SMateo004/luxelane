import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart' hide BookingEvent;
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:luxelane/features/trips/presentation/pages/trips_screen.dart';
import 'package:luxelane/l10n/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

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
    ),
  };

  for (final MapEntry(key: locale, value: t) in cases.entries) {
    group('${locale.languageCode}:', () {
      setUp(() async {
        L10n.use(locale);
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
    });
  }
}
