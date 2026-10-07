import 'package:flutter/material.dart';
import 'package:luxelane/l10n/l10n.dart';

/// MaterialApp with the app's localization setup, pinned to [locale].
Widget localizedApp(Widget home, {Locale locale = const Locale('es'), ThemeData? theme}) => MaterialApp(
      locale: locale,
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      builder: (context, child) => IntlLocaleSync(child: child!),
      home: home,
    );
