import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Idioma de las apps: español. Sin estos delegados los textos de Material
/// salían en inglés («Sun, Oct 25», «October 2026», «S M T W T F S», E11).
/// Título de las dos apps: el mismo de web/index.html y del manifest (E26;
/// antes «Luxelane Driver» en inglés y «luxelane» en el manifest).
const kAppTitle = 'Luxelane — Servicio de chófer ejecutivo';

abstract final class LuxLocale {
  static const locale = Locale('es');
  static const supportedLocales = [locale];
  static const delegates = <LocalizationsDelegate<Object>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
