// Los StreamController se cierran con addTearDown dentro de pump().
// ignore_for_file: close_sinks

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/lux_locale.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/core/repositories/repositories.dart';
import 'package:luxelane/features/driver/presentation/widgets/driver_preferences_card.dart';
import 'package:luxelane/l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';

class _Prefs extends Mock implements PreferencesRepository {}

/// Preferencias, B0c: el chófer lee bookings/{id}/driverView/preferences.
/// Fuera de la ventana las reglas deniegan y el flujo da null: no se ve nada.
void main() {
  const prefs = TripPreferences(
    languages: [DriverLanguage.en],
    conversation: ConversationPref.quiet,
    music: MusicStyle.jazz,
    needs: [PracticalNeed.childSeat],
    note: 'Llevo un carrito de bebé y una maleta grande que no cabe atrás.',
    playlistUrl: 'https://music.example.com/lista',
  );

  tearDown(() => L10n.use(const Locale('es')));

  Future<StreamController<TripPreferences?>> pump(
    WidgetTester t, {
    Locale locale = const Locale('es'),
    ExternalLauncher? launch,
  }) async {
    L10n.use(locale);
    final repo = _Prefs();
    final ctrl = StreamController<TripPreferences?>();
    addTearDown(ctrl.close);
    when(() => repo.watchBookingPreferences('b1'))
        .thenAnswer((_) => ctrl.stream);
    await t.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: LuxLocale.supportedLocales,
        localizationsDelegates: LuxLocale.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverPreferencesCard(
              bookingId: 'b1',
              repository: repo,
              launch: launch ?? (_) async => true,
            ),
          ),
        ),
      ),
    );
    return ctrl;
  }

  testWidgets('muestra la copia de la reserva con la nota completa', (t) async {
    final ctrl = await pump(t);
    ctrl.add(prefs);
    await t.pumpAndSettle();
    expect(find.text('Preferencias del pasajero'), findsOneWidget);
    expect(find.text('Inglés'), findsOneWidget);
    expect(find.text('Prefiero silencio'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('Silla infantil'), findsOneWidget);
    expect(find.text(prefs.note!), findsOneWidget);
    // La URL nunca se muestra ni se previsualiza: solo el botón.
    expect(find.textContaining('music.example.com'), findsNothing);
    expect(find.text('Abrir lista'), findsOneWidget);
  });

  testWidgets('fuera de la ventana (null) o vacía: no se ve nada', (t) async {
    final ctrl = await pump(t);
    ctrl.add(null);
    await t.pumpAndSettle();
    expect(find.text('Preferencias del pasajero'), findsNothing);
    ctrl.add(TripPreferences.empty);
    await t.pumpAndSettle();
    expect(find.text('Preferencias del pasajero'), findsNothing);
  });

  testWidgets('abrir la lista: aviso antes, se abre fuera solo al confirmar',
      (t) async {
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
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(opened, isEmpty);
    await t.tap(find.text('Abrir lista'));
    await t.pumpAndSettle();
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    expect(opened, [Uri.parse('https://music.example.com/lista')]);
  });

  testWidgets('en portugués, con su botón de 48 px', (t) async {
    final ctrl = await pump(t, locale: const Locale('pt'));
    ctrl.add(prefs);
    await t.pumpAndSettle();
    expect(find.text('Preferências do passageiro'), findsOneWidget);
    expect(find.text('Cadeirinha infantil'), findsOneWidget);
    expect(
        t
            .getSize(find.ancestor(
              of: find.text('Abrir playlist'),
              matching: find.byWidgetPredicate((w) => w is TextButton),
            ))
            .height,
        greaterThanOrEqualTo(48));
  });
}
