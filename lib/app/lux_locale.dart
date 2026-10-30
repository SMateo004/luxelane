import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/gen/app_localizations.dart';

/// Idioma de las apps del pasajero y del chófer: español (base), inglés y
/// portugués de Brasil (pt). Sin los delegados de Material los textos del
/// sistema salían en inglés («Sun, Oct 25», E11).
/// Título de las dos apps: el mismo de web/index.html y del manifest (E26;
/// antes «Luxelane Driver» en inglés y «luxelane» en el manifest).
const kAppTitle = 'Luxelane — Servicio de chófer ejecutivo';

/// Lo que elige el usuario en el perfil. `system`: el del teléfono.
enum LocaleChoice { system, es, en, pt }

abstract final class LuxLocale {
  /// Idioma por defecto y de lo que no se traduce (panel de admin, páginas
  /// legales).
  static const fallback = Locale('es');
  static const supportedLocales = [Locale('es'), Locale('en'), Locale('pt')];
  static const codes = ['es', 'en', 'pt'];

  /// Nombre de cada idioma en su propia lengua: igual en los tres idiomas.
  static const endonyms = {'es': 'Español', 'en': 'English', 'pt': 'Português'};

  static const delegates = <LocalizationsDelegate<Object>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// El primer idioma del teléfono que sea es, en o pt; si ninguno, español.
  /// pt-PT también resuelve a pt (portugués de Brasil por defecto).
  static Locale fromDevice(List<Locale>? device) {
    for (final l in device ?? const <Locale>[]) {
      if (codes.contains(l.languageCode)) return Locale(l.languageCode);
    }
    return fallback;
  }

  /// El idioma que se usa: la elección del perfil o, con `system`, el del
  /// teléfono.
  static Locale resolve(LocaleChoice choice, List<Locale>? device) =>
      choice == LocaleChoice.system ? fromDevice(device) : Locale(choice.name);

  static LocaleChoice choiceOf(String? code) => LocaleChoice.values
      .firstWhere((c) => c.name == code, orElse: () => LocaleChoice.system);

  /// Para MaterialApp.localeListResolutionCallback.
  static Locale resolveList(List<Locale>? device, Iterable<Locale> _) =>
      fromDevice(device);
}
