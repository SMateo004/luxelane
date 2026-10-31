import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Preferencias, B0: el modelo de la app usa las mismas listas cerradas y
/// los mismos nombres que el servidor (functions/src/preferences.ts), y las
/// antiguas ridePreferences ya no se escriben ni se leen de la reserva.
void main() {
  tearDown(() => L10n.use(const Locale('es')));

  const full = TripPreferences(
    languages: [DriverLanguage.es, DriverLanguage.pt],
    temperature: CabinTemperaturePref.cool,
    conversation: ConversationPref.quiet,
    music: MusicStyle.jazz,
    playlistUrl: 'https://music.example.com/l',
    needs: [PracticalNeed.childSeat, PracticalNeed.extraLuggage],
    note: 'Llevo un carrito',
  );

  test('ida y vuelta por JSON con los nombres del servidor', () {
    final json = full.toJson();
    expect(json, {
      'preferredDriverLanguages': ['es', 'pt'],
      'cabinTemperature': 'cool',
      'conversation': 'quiet',
      'musicStyle': 'jazz',
      'playlistUrl': 'https://music.example.com/l',
      'needs': ['child_seat', 'extra_luggage'],
      'note': 'Llevo un carrito',
    });
    expect(TripPreferences.fromJson(json), isNot(full)); // orden fijo de needs
    expect(TripPreferences.fromJson(json).needs,
        [PracticalNeed.extraLuggage, PracticalNeed.childSeat]);
  });

  test('las listas de la app son las del servidor', () {
    final src = File('functions/src/preferences.ts').readAsStringSync();
    List<String> list(String name) {
      final m = RegExp('$name = \\[([^\\]]*)\\]').firstMatch(src)!;
      return RegExp(r"'([a-z_]+)'")
          .allMatches(m.group(1)!)
          .map((x) => x.group(1)!)
          .toList();
    }

    expect(DriverLanguage.values.map((e) => e.name), list('DRIVER_LANGUAGES'));
    expect(CabinTemperaturePref.values.map((e) => e.wire),
        list('CABIN_TEMPERATURES'));
    expect(ConversationPref.values.map((e) => e.wire), list('CONVERSATION'));
    expect(MusicStyle.values.map((e) => e.wire),
        [...list('MUSIC_GENRES'), 'none', 'no_preference']);
    expect(PracticalNeed.values.map((e) => e.wire), list('NEEDS'));
  });

  test('valores fuera de la lista se ignoran; vacío sin datos', () {
    final p = TripPreferences.fromJson({
      'preferredDriverLanguages': ['fr', 'en'],
      'cabinTemperature': 'warm',
      'musicStyle': 'marca',
      'needs': ['valet'],
    });
    expect(p.languages, [DriverLanguage.en]);
    expect(p.temperature, CabinTemperaturePref.noPreference);
    expect(p.music, MusicStyle.noPreference);
    expect(p.needs, isEmpty);
    expect(TripPreferences.fromJson(null).isEmpty, isTrue);
  });

  test('perfil: tripPreferences; sin ellas, las antiguas traducidas', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => {
          'id': 'ana',
          'email': 'a@b.c',
          'displayName': 'Ana',
          'role': 'rider',
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(0),
          ...extra,
        };
    expect(
      User.fromJson(base({'tripPreferences': full.toJson()}))
          .tripPreferences
          .music,
      MusicStyle.jazz,
    );
    final legacy = User.fromJson(base({
      'ridePreferences': {
        'quiet': true,
        'music': false,
        'luggageHelp': true,
        'openDoor': true
      },
    })).tripPreferences;
    expect(
      legacy,
      const TripPreferences(
        conversation: ConversationPref.quiet,
        music: MusicStyle.none,
        needs: [PracticalNeed.luggageAssistance],
      ),
    );
    // toJson (alta) ya no lleva preferencias.
    expect(User.fromJson(base({})).toJson().keys,
        isNot(contains('ridePreferences')));
  });

  test('el perfil ya no manda ridePreferences', () {
    final src =
        File('lib/features/profile/data/repositories/user_repository_impl.dart')
            .readAsStringSync();
    expect(src, isNot(contains("'ridePreferences'")));
    expect(File('lib/core/models/models.dart').readAsStringSync(),
        isNot(contains('riderPreferences')));
  });

  test('resumen en el idioma activo', () {
    expect(full.summary.first, 'Idiomas: Español, Portugués');
    L10n.use(const Locale('en'));
    expect(full.summary, contains('Child seat'));
    expect(full.summary.first, 'Languages: Spanish, Portuguese');
  });

  test('json de las claves en los .arb', () {
    final arb =
        jsonDecode(File('lib/l10n/app_pt.arb').readAsStringSync()) as Map;
    expect(arb['prefsDriverWillSee'], 'Seu motorista verá estas preferências.');
  });
}
