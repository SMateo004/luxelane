import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/l10n.dart';

/// Idioma de las apps del pasajero y del chófer: español (base), inglés y
/// portugués de Brasil (pt). Sin los delegados de Material los textos del
/// sistema salían en inglés («Sun, Oct 25», E11).
/// Título de las dos apps: el mismo de web/index.html y del manifest (E26;
/// antes «Luxelane Driver» en inglés y «luxelane» en el manifest).
const kAppTitle =
    'Luxelane — Servicio de chófer ejecutivo'; // i18n-ignore: título de index.html y del manifest (titulo_test); en la app, commonAppTitle

/// Lo que elige el usuario en el perfil. `system`: el del teléfono.
enum LocaleChoice { system, es, en, pt }

abstract final class LuxLocale {
  /// Idioma por defecto y de lo que no se traduce (panel de admin, páginas
  /// legales).
  static const fallback = Locale('es');
  static const supportedLocales = [Locale('es'), Locale('en'), Locale('pt')];
  static const codes = ['es', 'en', 'pt'];

  /// Nombre de cada idioma en su propia lengua: igual en los tres idiomas.
  static const endonyms = {
    'es': 'Español', // i18n-ignore: nombre del idioma en su lengua
    'en': 'English', // i18n-ignore: nombre del idioma en su lengua
    'pt': 'Português', // i18n-ignore: nombre del idioma en su lengua
  };

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

/// Subárbol siempre en español (el panel de admin, decisión 3): textos de
/// Material, context.l10n y L10n.current, aunque la app esté en otro idioma.
class LuxSpanishOnly extends StatelessWidget {
  const LuxSpanishOnly({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    L10n.use(LuxLocale.fallback);
    return Localizations.override(
      context: context,
      locale: LuxLocale.fallback,
      child: child,
    );
  }
}
