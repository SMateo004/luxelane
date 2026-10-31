import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_home_screen.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_queue_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

/// B1, app del chófer: el inicio, el viaje activo y la tarjeta de una
/// solicitud salen en inglés y en portugués, no en español.
class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

final _now = DateTime.now();

final _user = User(
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

final _profile = DriverProfile(
  userId: 'd',
  licenseNumber: 'LP-1',
  licenseExpiry: _now.add(const Duration(days: 400)),
  vehicleId: 'v',
  documentsVerified: true,
  rating: 4.9,
  totalRides: 12,
  isAvailable: true,
);

Booking _active() => Booking(
      id: 'b1',
      riderId: 'r',
      origin: const Place(
        name: 'Hotel Europa',
        address: 'Calle Tiahuanacu 64',
        lat: -16.5,
        lng: -68.1,
      ),
      destination: const Place(
        name: 'Aeropuerto El Alto',
        address: 'Aeropuerto El Alto',
        lat: -16.51,
        lng: -68.19,
      ),
      scheduledAt: _now.add(const Duration(minutes: 20)),
      vehicleClass: VehicleClass.business,
      serviceType: ServiceType.oneWay,
      status: BookingStatus.driverArriving,
      estimatedPrice: 120,
      createdAt: _now,
      updatedAt: _now,
    );

DriverLoaded _state({
  List<Booking> bookings = const [],
  List<OpenRequest> requests = const [],
}) =>
    DriverLoaded(
      user: _user,
      profile: _profile,
      isAvailable: true,
      bookings: bookings,
      pendingRequests: requests,
      vehicleClass: VehicleClass.business,
    );

Future<void> _pump(WidgetTester t, Locale locale, Widget home, DriverLoaded s) {
  final driver = _MockDriverBloc();
  when(() => driver.state).thenReturn(s);
  final auth = _MockAuthBloc();
  when(() => auth.state).thenReturn(const AuthUnauthenticated());
  t.view.physicalSize = const Size(390, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  return t.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<DriverBloc>.value(value: driver),
        BlocProvider<AuthBloc>.value(value: auth),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: home,
      ),
    ),
  );
}

void main() {
  final cases = {
    const Locale('en'): (
      online: 'You are online.',
      searching: 'Looking for ${VehicleClass.business.label} trips',
      netEarnings: 'Net earnings',
      rating: 'Rating',
      arriving: 'On the way to pickup.',
      navigate: 'Navigate to pickup',
      slide: 'I have arrived',
      release: "I can't do this trip",
      pickup: 'PICKUP',
      available: 'AVAILABLE TO YOU',
      accept: 'Accept trip',
      from: 'from El Alto',
    ),
    const Locale('pt'): (
      online: 'Você está online.',
      searching: 'Procurando viagens de ${VehicleClass.business.label}',
      netEarnings: 'Ganhos líquidos',
      rating: 'Avaliação',
      arriving: 'A caminho do embarque.',
      navigate: 'Navegar até o embarque',
      slide: 'Cheguei',
      release: 'Não posso fazer esta viagem',
      pickup: 'EMBARQUE',
      available: 'DISPONÍVEIS PARA VOCÊ',
      accept: 'Aceitar viagem',
      from: 'saindo de El Alto',
    ),
  };

  for (final MapEntry(key: locale, value: x) in cases.entries) {
    group('app del chófer en ${locale.languageCode}', () {
      setUp(() => L10n.use(locale));
      tearDown(() => L10n.use(const Locale('es')));

      testWidgets('inicio en línea', (t) async {
        await _pump(t, locale, const DriverHomeScreen(), _state());
        await t.pump(const Duration(milliseconds: 600));
        expect(find.text(x.online), findsOneWidget);
        expect(find.text(x.searching), findsOneWidget);
        expect(find.text(x.netEarnings), findsOneWidget);
        expect(find.text(x.rating), findsOneWidget);
        expect(find.text('Estás en línea.'), findsNothing);
        expect(find.textContaining('Buscando viajes'), findsNothing);
        expect(find.text('Ganancias netas'), findsNothing);
      });

      testWidgets('viaje activo de camino a la recogida', (t) async {
        await _pump(
          t,
          locale,
          const DriverHomeScreen(),
          _state(bookings: [_active()]),
        );
        await t.pump(const Duration(milliseconds: 600));
        expect(find.text(x.arriving), findsOneWidget);
        expect(find.text(x.navigate), findsOneWidget);
        expect(find.text(x.slide), findsOneWidget);
        expect(find.text(x.release), findsOneWidget);
        expect(find.text(x.pickup), findsOneWidget);
        expect(find.text('En camino a la recogida.'), findsNothing);
        expect(find.text('Navegar a la recogida'), findsNothing);
        expect(find.text('He llegado'), findsNothing);
        expect(find.text('RECOGIDA'), findsNothing);
      });

      testWidgets('tarjeta de una solicitud', (t) async {
        final request = OpenRequest(
          id: 'q1',
          vehicleClass: VehicleClass.business,
          serviceType: ServiceType.oneWay,
          scheduledAt: _now.add(const Duration(days: 2)),
          estimatedPrice: 150,
          pickupArea: 'El Alto',
          dropoffArea: 'La Paz',
          tripKm: 12,
        );
        await _pump(
          t,
          locale,
          const DriverQueueScreen(),
          _state(requests: [request]),
        );
        await t.pump(const Duration(milliseconds: 600));
        expect(find.text(x.available), findsOneWidget);
        expect(find.text(x.accept), findsOneWidget);
        expect(find.textContaining(x.from), findsOneWidget);
        expect(find.text('DISPONIBLES PARA TI'), findsNothing);
        expect(find.text('Aceptar viaje'), findsNothing);
        expect(find.textContaining('desde El Alto'), findsNothing);
      });
    });
  }
}
