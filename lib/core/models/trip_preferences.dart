import '../../l10n/l10n.dart';

/// Preferencias del pasajero para su chófer: las mismas listas cerradas que
/// valida el servidor (functions/src/preferences.ts). El perfil las guarda
/// con updatePreferences; cada reserva lleva su copia en
/// bookings/{id}/driverView/preferences. Son un deseo, no una garantía.

/// Idiomas del chófer que puede preferir el pasajero.
enum DriverLanguage {
  es,
  en,
  pt;

  String get label => switch (this) {
        DriverLanguage.es => L10n.current.prefsLanguageEs,
        DriverLanguage.en => L10n.current.prefsLanguageEn,
        DriverLanguage.pt => L10n.current.prefsLanguagePt,
      };
}

enum CabinTemperaturePref {
  cool('cool'),
  mild('mild'),
  noPreference('no_preference');

  const CabinTemperaturePref(this.wire);
  final String wire;

  String get label => switch (this) {
        CabinTemperaturePref.cool => L10n.current.prefsTemperatureCool,
        CabinTemperaturePref.mild => L10n.current.prefsTemperatureMild,
        CabinTemperaturePref.noPreference => L10n.current.prefsNoPreference,
      };
}

enum ConversationPref {
  chatty('chatty'),
  quiet('quiet'),
  noPreference('no_preference');

  const ConversationPref(this.wire);
  final String wire;

  String get label => switch (this) {
        ConversationPref.chatty => L10n.current.prefsConversationChatty,
        ConversationPref.quiet => L10n.current.prefsConversationQuiet,
        ConversationPref.noPreference => L10n.current.prefsNoPreference,
      };
}

/// Estilos genéricos, sin artistas ni marcas.
enum MusicStyle {
  classical('classical'),
  jazz('jazz'),
  instrumental('instrumental'),
  pop('pop'),
  rock('rock'),
  latin('latin'),
  electronic('electronic'),
  folk('folk'),
  none('none'),
  noPreference('no_preference');

  const MusicStyle(this.wire);
  final String wire;

  String get label => switch (this) {
        MusicStyle.classical => L10n.current.prefsMusicClassical,
        MusicStyle.jazz => L10n.current.prefsMusicJazz,
        MusicStyle.instrumental => L10n.current.prefsMusicInstrumental,
        MusicStyle.pop => L10n.current.prefsMusicPop,
        MusicStyle.rock => L10n.current.prefsMusicRock,
        MusicStyle.latin => L10n.current.prefsMusicLatin,
        MusicStyle.electronic => L10n.current.prefsMusicElectronic,
        MusicStyle.folk => L10n.current.prefsMusicFolk,
        MusicStyle.none => L10n.current.prefsMusicNone,
        MusicStyle.noPreference => L10n.current.prefsNoPreference,
      };
}

/// Necesidades prácticas. [private]: pueden ser datos personales (salud);
/// la interfaz avisa de que solo las ve el chófer asignado.
enum PracticalNeed {
  extraLuggage('extra_luggage'),
  luggageAssistance('luggage_assistance'),
  childSeat('child_seat'),
  boosterSeat('booster_seat'),
  boardingAssistance('boarding_assistance', private: true),
  foldingWheelchair('folding_wheelchair', private: true),
  petInCarrier('pet_in_carrier');

  const PracticalNeed(this.wire, {this.private = false});
  final String wire;
  final bool private;

  String get label => switch (this) {
        PracticalNeed.extraLuggage => L10n.current.prefsNeedExtraLuggage,
        PracticalNeed.luggageAssistance =>
          L10n.current.prefsNeedLuggageAssistance,
        PracticalNeed.childSeat => L10n.current.prefsNeedChildSeat,
        PracticalNeed.boosterSeat => L10n.current.prefsNeedBoosterSeat,
        PracticalNeed.boardingAssistance =>
          L10n.current.prefsNeedBoardingAssistance,
        PracticalNeed.foldingWheelchair =>
          L10n.current.prefsNeedFoldingWheelchair,
        PracticalNeed.petInCarrier => L10n.current.prefsNeedPetInCarrier,
      };
}

T _byWire<T extends Enum>(
        List<T> values, Object? raw, String Function(T) wire, T fallback) =>
    values.where((v) => wire(v) == raw).firstOrNull ?? fallback;

class TripPreferences {
  const TripPreferences({
    this.languages = const [],
    this.temperature = CabinTemperaturePref.noPreference,
    this.conversation = ConversationPref.noPreference,
    this.music = MusicStyle.noPreference,
    this.playlistUrl,
    this.needs = const [],
    this.note,
  });

  static const empty = TripPreferences();

  /// Máximo de caracteres de la nota (el servidor también lo comprueba).
  static const noteMax = 200;

  final List<DriverLanguage> languages;
  final CabinTemperaturePref temperature;
  final ConversationPref conversation;
  final MusicStyle music;
  final String? playlistUrl;
  final List<PracticalNeed> needs;
  final String? note;

  bool get isEmpty =>
      languages.isEmpty &&
      needs.isEmpty &&
      (note == null || note!.isEmpty) &&
      (playlistUrl == null || playlistUrl!.isEmpty) &&
      temperature == CabinTemperaturePref.noPreference &&
      conversation == ConversationPref.noPreference &&
      music == MusicStyle.noPreference;

  /// Resumen corto en el idioma activo (sin la nota ni la lista).
  List<String> get summary => [
        if (languages.isNotEmpty)
          L10n.current.prefsLanguagesSummary(
            languages.map((l) => l.label).join(', '),
          ),
        if (temperature != CabinTemperaturePref.noPreference) temperature.label,
        if (conversation != ConversationPref.noPreference) conversation.label,
        if (music != MusicStyle.noPreference) music.label,
        for (final n in needs) n.label,
      ];

  /// Lee tripPreferences del perfil o una copia driverView; ignora valores
  /// fuera de las listas.
  factory TripPreferences.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    List<T> list<T extends Enum>(
        String key, List<T> values, String Function(T) wire) {
      final v = raw[key];
      if (v is! List) return const [];
      return values.where((e) => v.contains(wire(e))).toList();
    }

    final note = raw['note'];
    final url = raw['playlistUrl'];
    return TripPreferences(
      languages: list(
          'preferredDriverLanguages', DriverLanguage.values, (e) => e.name),
      temperature: _byWire(CabinTemperaturePref.values, raw['cabinTemperature'],
          (e) => e.wire, CabinTemperaturePref.noPreference),
      conversation: _byWire(ConversationPref.values, raw['conversation'],
          (e) => e.wire, ConversationPref.noPreference),
      music: _byWire(MusicStyle.values, raw['musicStyle'], (e) => e.wire,
          MusicStyle.noPreference),
      playlistUrl: url is String && url.isNotEmpty ? url : null,
      needs: list('needs', PracticalNeed.values, (e) => e.wire),
      note: note is String && note.isNotEmpty ? note : null,
    );
  }

  /// Lo que se manda a updatePreferences y a createBooking.preferences.
  Map<String, dynamic> toJson() => {
        'preferredDriverLanguages': [for (final l in languages) l.name],
        'cabinTemperature': temperature.wire,
        'conversation': conversation.wire,
        'musicStyle': music.wire,
        if (playlistUrl != null && playlistUrl!.isNotEmpty)
          'playlistUrl': playlistUrl,
        'needs': [for (final n in needs) n.wire],
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };

  TripPreferences copyWith({
    List<DriverLanguage>? languages,
    CabinTemperaturePref? temperature,
    ConversationPref? conversation,
    MusicStyle? music,
    String? playlistUrl,
    bool clearPlaylist = false,
    List<PracticalNeed>? needs,
    String? note,
    bool clearNote = false,
  }) =>
      TripPreferences(
        languages: languages ?? this.languages,
        temperature: temperature ?? this.temperature,
        conversation: conversation ?? this.conversation,
        music: music ?? this.music,
        playlistUrl: clearPlaylist ? null : (playlistUrl ?? this.playlistUrl),
        needs: needs ?? this.needs,
        note: clearNote ? null : (note ?? this.note),
      );

  @override
  bool operator ==(Object other) =>
      other is TripPreferences &&
      _sameList(other.languages, languages) &&
      other.temperature == temperature &&
      other.conversation == conversation &&
      other.music == music &&
      other.playlistUrl == playlistUrl &&
      _sameList(other.needs, needs) &&
      other.note == note;

  @override
  int get hashCode => Object.hash(Object.hashAll(languages), temperature,
      conversation, music, playlistUrl, Object.hashAll(needs), note);
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Lo que la app necesita para ofrecer los campos (getPreferenceOptions).
class PreferenceOptions {
  const PreferenceOptions({this.playlistEnabled = false, this.noteMax = 200});

  final bool playlistEnabled;
  final int noteMax;

  static const none = PreferenceOptions();
}
