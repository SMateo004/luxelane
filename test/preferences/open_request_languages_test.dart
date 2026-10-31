import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:luxelane/features/driver/presentation/pages/driver_queue_screen.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverBloc extends MockBloc<DriverEvent, DriverState>
    implements DriverBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Preferencias, B2: antes de aceptar, el chófer ve solo los idiomas que
/// prefiere el pasajero (openRequests.preferredDriverLanguages, sin datos
/// personales). El resto de preferencias, nunca en la solicitud.
void main() {
  tearDown(() => L10n.use(const Locale('es')));

  test('OpenRequest lee los idiomas de la lista cerrada', () {
    final r = OpenRequest.fromJson('q1', {
      'vehicleClass': 'business',
      'serviceType': 'oneWay',
      'preferredDriverLanguages': ['pt', 'fr', 'es'],
      // Aunque llegara, la solicitud no tiene dónde guardar una nota.
      'note': 'Llevo un carrito',
    });
    expect(r.preferredDriverLanguages, [DriverLanguage.es, DriverLanguage.pt]);
    expect(r.languagesSummary, 'Idiomas: Español, Portugués');
    expect(OpenRequest.fromJson('q2', {}).languagesSummary, isNull);
  });

  Future<void> pump(WidgetTester t, Locale locale, OpenRequest request) {
    L10n.use(locale);
    final driver = _MockDriverBloc();
    when(() => driver.state).thenReturn(DriverLoaded(
      user: User(
        id: 'd',
        email: 'd@example.com',
        phone: '',
        displayName: 'Luis',
        role: UserRole.driver,
        createdAt: DateTime(2026),
        isVerified: true,
        isActive: true,
        fcmTokens: const [],
      ),
      profile: DriverProfile(
        userId: 'd',
        licenseNumber: 'LP-1',
        licenseExpiry: DateTime(2030),
        vehicleId: 'v',
        documentsVerified: true,
        rating: 4.9,
        totalRides: 12,
        isAvailable: true,
      ),
      isAvailable: true,
      bookings: const [],
      pendingRequests: [request],
      vehicleClass: VehicleClass.business,
    ));
    final auth = _MockAuthBloc();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    t.view.physicalSize = const Size(390, 1200);
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
          home: const DriverQueueScreen(),
        ),
      ),
    );
  }

  OpenRequest request(List<DriverLanguage> langs) => OpenRequest(
        id: 'q1',
        vehicleClass: VehicleClass.business,
        serviceType: ServiceType.oneWay,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        estimatedPrice: 150,
        pickupArea: 'El Alto',
        dropoffArea: 'La Paz',
        preferredDriverLanguages: langs,
      );

  testWidgets('la tarjeta de la solicitud muestra los idiomas', (t) async {
    await pump(t, const Locale('es'), request([DriverLanguage.en]));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Idiomas: Inglés'), findsOneWidget);
  });

  testWidgets('en inglés y sin idiomas: nada que mostrar', (t) async {
    await pump(
        t, const Locale('en'), request([DriverLanguage.es, DriverLanguage.pt]));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Languages: Spanish, Portuguese'), findsOneWidget);
    await pump(t, const Locale('en'), request(const []));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Languages:'), findsNothing);
  });
}
