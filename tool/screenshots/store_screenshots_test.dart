// Store screenshots from the real screens, with demo data.
//
//   ./scripts/store_screenshots.sh
//
// Renders each screen at the exact sizes Google Play (1080×1920) and the
// App Store (6.9", 1320×2868) ask for, in es/en/pt, with the bundled brand
// fonts, into docs/store/screenshots/<app>/<locale>/. Screens that need a live map
// aren't included: take those on a phone.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/config/brand_fonts.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/booking/presentation/pages/booking_confirmed_page.dart';
import 'package:luxelane/features/booking/presentation/pages/ride_type_page.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_earnings_screen.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_queue_screen.dart';
import 'package:luxelane/features/trips/presentation/pages/receipt_page.dart';
import 'package:luxelane/l10n/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState> implements DriverBloc {}

final _outDir = Platform.environment['OUT_DIR'] ?? 'docs/store/screenshots';

const _sizes = {
  'play': (Size(360, 640), 3.0), // 1080×1920
  'ios69': (Size(440, 956), 3.0), // 1320×2868
};

Future<void> _loadFonts() async {
  Future<void> family(String name, Iterable<Future<ByteData>> files) async {
    final loader = FontLoader(name);
    files.forEach(loader.addFont);
    await loader.load();
  }

  ByteData file(String path) => ByteData.view(File(path).readAsBytesSync().buffer);
  Iterable<Future<ByteData>> bundled(String prefix) => Directory('assets/google_fonts')
      .listSync()
      .map((e) => e.path)
      .where((p) => p.split('/').last.startsWith(prefix) && p.endsWith('.ttf'))
      .map((p) => Future.value(file(p)));

  // Tests don't load pubspec fonts by themselves: register the bundled
  // brand fonts, plus Roboto and the Material icons from the Flutter SDK.
  final material = '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts';
  await family('Montserrat', bundled('Montserrat-'));
  await family('Cormorant Garamond', bundled('CormorantGaramond-'));
  await family('Roboto', ['Regular', 'Medium', 'Bold'].map((w) => Future.value(file('$material/Roboto-$w.ttf'))));
  await family('MaterialIcons', [Future.value(file('$material/MaterialIcons-Regular.otf'))]);

  // google_fonts (used by the theme) finds the same files in the assets.
  GoogleFonts.config.allowRuntimeFetching = false;
  await BrandFonts.preload();
}

// ── Demo data ───────────────────────────────────────────────────────────────

final _now = DateTime.now();
const _hotel = Place(address: 'Hotel Los Tajibos, Av. San Martín', lat: -17.7631, lng: -63.1957);
const _airport = Place(address: 'Aeropuerto Internacional Viru Viru', lat: -17.6448, lng: -63.1354);
const _equipetrol = Place(address: 'Equipetrol Norte, calle 9', lat: -17.7555, lng: -63.1990);
const _centro = Place(address: 'Plaza 24 de Septiembre', lat: -17.7834, lng: -63.1822);
const _urubo = Place(address: 'Urubó Village', lat: -17.7700, lng: -63.2520);

Booking _booking(String id, Place from, Place to, DateTime at, VehicleClass vc, double price,
        {BookingStatus status = BookingStatus.pending, String? flight, int pax = 1, int bags = 0, double? finalPrice}) =>
    Booking(
      id: id,
      riderId: 'rider',
      driverId: status == BookingStatus.pending ? null : 'driver',
      origin: from,
      destination: to,
      scheduledAt: at,
      vehicleClass: vc,
      serviceType: ServiceType.oneWay,
      status: status,
      estimatedPrice: price,
      finalPrice: finalPrice,
      createdAt: at.subtract(const Duration(days: 1)),
      updatedAt: at,
      flightNumber: flight,
      passengerCount: pax,
      luggageCount: bags,
      paymentMethod: 'cash',
      chauffeur: status == BookingStatus.pending
          ? null
          : const Chauffeur(
              driverId: 'driver',
              name: 'Carlos Méndez',
              vehicle: 'Mercedes-Benz Clase E',
              vehicleColor: 'Negro',
              plate: '4821-KTN',
              rating: 4.9,
              ratingCount: 212,
            ),
    );

final _driverUser = User(
  id: 'driver',
  email: 'carlos@example.com',
  phone: '',
  displayName: 'Carlos Méndez',
  role: UserRole.driver,
  createdAt: DateTime(2026),
  isVerified: true,
  isActive: true,
  fcmTokens: const [],
);

final _driverProfile = DriverProfile(
  userId: 'driver',
  licenseNumber: 'L1',
  licenseExpiry: DateTime(2030),
  vehicleId: 'v1',
  documentsVerified: true,
  rating: 4.9,
  totalRides: 212,
  isAvailable: true,
);

DateTime _at(int days, int h, int m) => DateTime(_now.year, _now.month, _now.day + days, h, m);

// ── Screens ────────────────────────────────────────────────────────────────

typedef _Screen = ({String app, String name, Widget Function() build});

AuthBloc _authBloc() {
  final bloc = _MockAuthBloc();
  whenListen(bloc, const Stream<AuthState>.empty(), initialState: AuthAuthenticated(_driverUser));
  return bloc;
}

DriverBloc _driverBloc(DriverState s) {
  final bloc = _MockDriverBloc();
  whenListen(bloc, const Stream<DriverState>.empty(), initialState: s);
  return bloc;
}

final List<_Screen> _screens = [
  (app: 'rider', name: '2_servicios', build: () => const RideTypePage()),
  (
    app: 'rider',
    name: '1_reserva_confirmada',
    build: () => BookingConfirmedPage(
          bookingId: 'LX7K2M9Q',
          booking: _booking('lx7k2m9qab', _airport, _hotel, _at(1, 9, 30),
              VehicleClass.business, 210, flight: 'OB 760', pax: 2, bags: 3),
        ),
  ),
  (
    app: 'rider',
    name: '3_recibo',
    build: () => ReceiptPage(
          bookingId: 'r8h3n2kp',
          booking: _booking('r8h3n2kpqa', _equipetrol, _airport, _at(-2, 6, 30), VehicleClass.firstClass, 290,
              status: BookingStatus.completed, finalPrice: 290, flight: 'AA 922', bags: 2),
        ),
  ),
  (
    app: 'driver',
    name: '1_viajes_disponibles',
    build: () => BlocProvider<DriverBloc>.value(
          value: _driverBloc(DriverLoaded(
            user: _driverUser,
            profile: _driverProfile,
            isAvailable: true,
            bookings: [
              _booking('c1', _hotel, _airport, _at(0, 18, 15), VehicleClass.business, 210,
                  status: BookingStatus.confirmed, flight: 'OB 761'),
            ],
            pendingRequests: [
              _booking('p1', _centro, _airport, _at(0, 15, 30), VehicleClass.business, 190, flight: 'LA 2491'),
              _booking('p2', _urubo, _equipetrol, _at(1, 9, 0), VehicleClass.business, 120),
            ],
          )),
          child: const DriverQueueScreen(),
        ),
  ),
  (
    app: 'driver',
    name: '2_ganancias',
    build: () => BlocProvider<DriverBloc>.value(
          value: _driverBloc(DriverLoaded(
            user: _driverUser,
            profile: _driverProfile,
            isAvailable: true,
            bookings: [
              for (final (i, b) in [
                (_airport, _hotel, 210.0),
                (_equipetrol, _airport, 190.0),
                (_centro, _urubo, 150.0),
                (_hotel, _centro, 90.0),
                (_airport, _equipetrol, 200.0),
              ].indexed)
                _booking('e$i', b.$1, b.$2, _at(-i, 8 + i * 2, 10), VehicleClass.business, b.$3,
                    status: BookingStatus.completed, finalPrice: b.$3),
            ],
          )),
          child: const DriverEarningsScreen(),
        ),
  ),
];

Future<void> _shoot(WidgetTester tester, _Screen s, Locale locale, String size) async {
  final (logical, dpr) = _sizes[size]!;
  tester.view.physicalSize = logical * dpr;
  tester.view.devicePixelRatio = dpr;
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(
    key: key,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: luxTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      builder: (context, child) => IntlLocaleSync(child: child!),
      home: BlocProvider<AuthBloc>.value(value: _authBloc(), child: s.build()),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 2));
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_outDir/${s.app}/${locale.languageCode}/${size}_${s.name}.png')..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _loadFonts();
  });

  for (final locale in supportedAppLocales) {
    for (final s in _screens) {
      for (final size in _sizes.keys) {
        testWidgets('${s.app} ${locale.languageCode} $size ${s.name}', (tester) async {
          addTearDown(tester.view.reset);
          await _shoot(tester, s, locale, size);
        });
      }
    }
  }
}
