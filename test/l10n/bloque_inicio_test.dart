import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/services/maps_service.dart';
import 'package:luxelane/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:luxelane/features/business/presentation/pages/business_page.dart';
import 'package:luxelane/features/home/presentation/pages/home_screen.dart';
import 'package:luxelane/features/services/presentation/pages/airport_transfer_page.dart';
import 'package:luxelane/l10n/l10n.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Bloque inicio (B1): el inicio de la app, una página de servicio y la de
/// empresas se ven en inglés y en portugués, sin el español de antes.
void main() {
  late _MockAuthBloc auth;

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<MapsService>(MapsService());
    auth = _MockAuthBloc();
    whenListen(auth, const Stream<AuthState>.empty(),
        initialState: const AuthUnauthenticated());
  });

  tearDown(() => L10n.use(const Locale('es')));

  Future<void> open(WidgetTester t, Locale locale, Widget page,
      {Size size = const Size(599, 1000)}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp(
          locale: locale,
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: page,
        ),
      ),
    );
    await t.pump(const Duration(seconds: 2));
  }

  final cases = {
    const Locale('en'): (
      home: ['See vehicles and prices', 'Schedule', 'Where are you going?'],
      airport: [
        'Three steps.',
        'Book in 2 minutes',
        'Can I cancel my booking?'
      ],
      business: ['Your name', 'Work email', 'Send request'],
    ),
    const Locale('pt'): (
      home: ['Ver veículos e preços', 'Agendar', 'Para onde você vai?'],
      airport: [
        'Três passos.',
        'Reserve em 2 minutos',
        'Posso cancelar minha reserva?',
      ],
      business: ['Seu nome', 'E-mail corporativo', 'Enviar solicitação'],
    ),
  };
  const spanish = (
    home: ['Ver vehículos y precios', 'Programar', '¿A dónde vas?'],
    airport: [
      'Tres pasos.',
      'Reserva en 2 minutos',
      '¿Puedo cancelar mi reserva?',
    ],
    business: ['Tu nombre', 'Correo de trabajo', 'Enviar solicitud'],
  );

  Finder seen(String s) => find.textContaining(s, findRichText: true);

  for (final entry in cases.entries) {
    final code = entry.key.languageCode;
    final want = entry.value;
    group(code, () {
      setUp(() => L10n.use(entry.key));

      testWidgets('inicio en $code', (t) async {
        await open(t, entry.key, const HomeScreen());
        for (final s in want.home) {
          expect(seen(s), findsWidgets, reason: s);
        }
        for (final s in spanish.home) {
          expect(seen(s), findsNothing, reason: s);
        }
        expect(
            kLocationUnavailableMessage,
            code == 'en'
                ? contains('Allow location access')
                : contains('Permita'));
      });

      testWidgets('inicio web en $code', (t) async {
        await open(t, entry.key, const HomeScreen(),
            size: const Size(1280, 900));
        final web = code == 'en'
            ? ['Your chauffeur awaits you.', 'SEE PRICES', 'One way']
            : ['Seu motorista espera por você.', 'VER PREÇOS', 'Só ida'];
        for (final s in web) {
          expect(seen(s), findsWidgets, reason: s);
        }
        for (final s in ['Tu chófer te espera.', 'VER PRECIOS', 'Solo ida']) {
          expect(seen(s), findsNothing, reason: s);
        }
      });

      testWidgets('traslado al aeropuerto en $code', (t) async {
        await open(t, entry.key, const AirportTransferPage(),
            size: const Size(1280, 900));
        for (final s in want.airport) {
          expect(seen(s), findsWidgets, reason: s);
        }
        for (final s in spanish.airport) {
          expect(seen(s), findsNothing, reason: s);
        }
      });

      testWidgets('empresas en $code', (t) async {
        await open(t, entry.key, const BusinessPage(),
            size: const Size(1280, 1400));
        for (final s in want.business) {
          expect(seen(s), findsWidgets, reason: s);
        }
        for (final s in spanish.business) {
          expect(seen(s), findsNothing, reason: s);
        }
        await t.tap(find.text('1–10'));
        await t.pumpAndSettle();
        expect(
            seen(code == 'en' ? 'More than 200' : 'Mais de 200'), findsWidgets);
        expect(seen('Más de 200'), findsNothing);
      });
    });
  }
}
