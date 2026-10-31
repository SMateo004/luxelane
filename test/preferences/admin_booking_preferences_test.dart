// Los StreamController se cierran con addTearDown.
// ignore_for_file: close_sinks

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/di/injection.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_booking_preferences.dart';
import 'package:luxelane/features/admin/presentation/widgets/admin_sections.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_preferences_card.dart'
    show ExternalLauncher;
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _Prefs extends Mock implements PreferencesRepository {}

class _Bloc extends MockBloc<AdminEvent, AdminState> implements AdminBloc {}

/// B3: el detalle de una reserva en el panel muestra sus preferencias (la
/// copia bookings/{id}/driverView/preferences). Siempre en español.
void main() {
  const prefs = TripPreferences(
    languages: [DriverLanguage.en, DriverLanguage.pt],
    conversation: ConversationPref.quiet,
    music: MusicStyle.jazz,
    needs: [PracticalNeed.childSeat],
    note: 'Llevo un carrito de bebé y una maleta grande que no cabe atrás.',
    playlistUrl: 'https://music.example.com/lista',
  );

  tearDown(() => L10n.use(const Locale('es')));

  StreamController<TripPreferences?> stubRepo(_Prefs repo) {
    // Broadcast: si nada escucha (sin el cambio), cerrarlo no se queda
    // esperando.
    final ctrl = StreamController<TripPreferences?>.broadcast();
    addTearDown(ctrl.close);
    when(() => repo.watchBookingPreferences('b1'))
        .thenAnswer((_) => ctrl.stream);
    return ctrl;
  }

  /// Como en el router: la app en [locale] y el panel envuelto en
  /// LuxSpanishOnly.
  Future<StreamController<TripPreferences?>> pump(
    WidgetTester t, {
    Locale locale = const Locale('es'),
    ExternalLauncher? launch,
  }) async {
    L10n.use(locale);
    final repo = _Prefs();
    final ctrl = stubRepo(repo);
    await t.pumpWidget(
      MaterialApp(
        theme: luxTheme,
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: LuxSpanishOnly(
          child: Scaffold(
            body: SingleChildScrollView(
              child: AdminBookingPreferences(
                bookingId: 'b1',
                repository: repo,
                launch: launch ?? (_) async => true,
              ),
            ),
          ),
        ),
      ),
    );
    return ctrl;
  }

  testWidgets('con preferencias: valores y nota, nunca la URL', (t) async {
    final ctrl = await pump(t);
    ctrl.add(prefs);
    await t.pumpAndSettle();
    expect(find.text('Preferencias del pasajero'), findsOneWidget);
    expect(find.text('Inglés, Portugués'), findsOneWidget);
    expect(find.text('Prefiero silencio'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('Silla infantil'), findsOneWidget);
    expect(find.text(prefs.note!), findsOneWidget);
    expect(find.textContaining('music.example.com'), findsNothing);
    expect(find.text('Sin preferencias para este viaje'), findsNothing);
  });

  testWidgets('sin preferencias (sin copia o vacía): texto sobrio', (t) async {
    final ctrl = await pump(t);
    ctrl.add(null);
    await t.pumpAndSettle();
    expect(find.text('Sin preferencias para este viaje'), findsOneWidget);
    expect(find.text('Preferencias del pasajero'), findsNothing);
    ctrl.add(TripPreferences.empty);
    await t.pumpAndSettle();
    expect(find.text('Sin preferencias para este viaje'), findsOneWidget);
  });

  testWidgets('la lista se abre fuera de la app, con aviso previo', (t) async {
    final opened = <Uri>[];
    final ctrl = await pump(t, launch: (u) async {
      opened.add(u);
      return true;
    });
    ctrl.add(prefs);
    await t.pumpAndSettle();
    await t.tap(find.text('Abrir lista'));
    await t.pumpAndSettle();
    expect(find.text('Abrir fuera de la app'), findsOneWidget);
    expect(opened, isEmpty);
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    expect(opened, [Uri.parse('https://music.example.com/lista')]);
  });

  for (final code in ['en', 'pt']) {
    testWidgets('en español aunque la app esté en $code', (t) async {
      final ctrl = await pump(t, locale: Locale(code));
      ctrl.add(prefs);
      await t.pumpAndSettle();
      expect(find.text('Preferencias del pasajero'), findsOneWidget);
      expect(find.text('Prefiero silencio'), findsOneWidget);
      expect(find.text('Abrir lista'), findsOneWidget);
      expect(find.text('Passenger preferences'), findsNothing);
      expect(find.text('Preferências do passageiro'), findsNothing);

      ctrl.add(null);
      await t.pumpAndSettle();
      expect(find.text('Sin preferencias para este viaje'), findsOneWidget);
    });
  }

  group('detalle de la reserva', () {
    late _Prefs repo;
    late _Bloc bloc;

    setUp(() {
      repo = _Prefs();
      sl.registerSingleton<PreferencesRepository>(repo);
      bloc = _Bloc();
      final booking = Booking.fromJson({
        'id': 'b1',
        'riderId': 'ana',
        'origin': {
          'address': 'A',
          'coordinates': const GeoPoint(-17.78, -63.18),
        },
        'destination': {
          'address': 'B',
          'coordinates': const GeoPoint(-17.64, -63.13),
        },
        'status': 'confirmed',
        'estimatedPrice': 100,
      });
      whenListen(bloc, const Stream<AdminState>.empty(),
          initialState: AdminState(bookings: [booking]));
      when(() => bloc.bookingEvents('b1'))
          .thenAnswer((_) => const Stream.empty());
    });
    tearDown(() => sl.unregister<PreferencesRepository>());

    testWidgets('el panel abre el detalle con las preferencias, en español',
        (t) async {
      t.view.physicalSize = const Size(1200, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final ctrl = stubRepo(repo);
      L10n.use(const Locale('en'));
      await t.pumpWidget(
        MaterialApp(
          theme: luxTheme,
          locale: const Locale('en'),
          supportedLocales: LuxLocale.supportedLocales,
          localizationsDelegates: LuxLocale.delegates,
          home: LuxSpanishOnly(
            child: BlocProvider<AdminBloc>.value(
              value: bloc,
              child: Scaffold(
                body: Builder(
                  builder: (c) => TextButton(
                    onPressed: () => showBookingDetail(c, 'b1'),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pump();
      ctrl.add(prefs);
      await t.pumpAndSettle();
      expect(find.text('Preferencias del pasajero'), findsOneWidget);
      expect(find.text(prefs.note!), findsOneWidget);
      expect(find.textContaining('music.example.com'), findsNothing);
      ctrl.add(null);
      await t.pumpAndSettle();
      expect(find.text('Sin preferencias para este viaje'), findsOneWidget);
    });
  });
}
