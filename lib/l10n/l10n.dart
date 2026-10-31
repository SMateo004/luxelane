import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Textos de la app en el idioma activo.
///
/// En widgets: `context.l10n.clave`. Fuera de un widget (blocs, modelos,
/// enums, formateo): `L10n.current.clave`, que las apps actualizan al
/// cambiar de idioma. Sin delegados (tests antiguos, pantallas sueltas) se
/// usa L10n.current, en español por defecto.
abstract final class L10n {
  static AppLocalizations _current = lookupAppLocalizations(const Locale('es'));
  static bool _dates = false;

  static AppLocalizations get current => _current;

  /// Código del idioma activo: es, en o pt.
  static String get code => _current.localeName;

  /// Lo llaman las apps (y los tests) al cambiar de idioma.
  static void use(Locale locale) {
    if (_current.localeName != locale.languageCode) {
      _current = lookupAppLocalizations(Locale(locale.languageCode));
    }
    ensureDateSymbols();
  }

  /// Datos de fechas de intl para es, en y pt (síncrono en la práctica).
  static void ensureDateSymbols() {
    if (_dates) return;
    _dates = true;
    initializeDateFormatting();
  }
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      L10n.current;
}
