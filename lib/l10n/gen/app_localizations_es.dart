// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String languageSystemDetail(String language) {
    return 'Usa el idioma del teléfono: $language';
  }

  @override
  String get languageSaveError =>
      'No se pudo guardar el idioma en tu cuenta. Se usará en este dispositivo.';
}
