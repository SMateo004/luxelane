import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:luxelane/app/theme/lux_tokens.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Mirrors the production MaterialApp: no fixed locale, device-driven.
Widget _deviceDrivenApp() => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      localeListResolutionCallback: resolveAppLocale,
      builder: (context, child) => IntlLocaleSync(child: child!),
      home: Builder(
        builder: (context) => Column(
          children: [
            Text(context.l10n.commonRetry),
            Text(LuxMoney.format(1250)),
            Text(DateFormat.MMMM().format(DateTime(2026, 10, 7))),
          ],
        ),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  group('resolveAppLocale', () {
    const supported = supportedAppLocales;

    test('matches by language, ignoring region', () {
      expect(resolveAppLocale(const [Locale('es', 'BO')], supported), const Locale('es'));
      expect(resolveAppLocale(const [Locale('pt', 'BR')], supported), const Locale('pt'));
      expect(resolveAppLocale(const [Locale('en', 'GB')], supported), const Locale('en'));
    });

    test('honours the order of the device preferences', () {
      expect(resolveAppLocale(const [Locale('fr'), Locale('pt'), Locale('es')], supported), const Locale('pt'));
    });

    test('falls back to English for unsupported languages', () {
      expect(resolveAppLocale(const [Locale('de'), Locale('fr')], supported), const Locale('en'));
      expect(resolveAppLocale(null, supported), const Locale('en'));
    });
  });

  testWidgets('UI, numbers and dates follow the device language live', (tester) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    tester.platformDispatcher.localesTestValue = const [Locale('es', 'BO')];
    await tester.pumpWidget(_deviceDrivenApp());
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Bs 1.250'), findsOneWidget);
    expect(find.text('octubre'), findsOneWidget);

    // The user switches the phone to English: no restart needed.
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Bs 1,250'), findsOneWidget);
    expect(find.text('October'), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('outubro'), findsOneWidget);

    // Unsupported device language → English.
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE')];
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });

  test('every language has every message, with the same placeholders', () {
    Map<String, dynamic> load(String l) =>
        jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync()) as Map<String, dynamic>;
    final es = load('es');
    final keys = es.keys.where((k) => !k.startsWith('@')).toSet();
    final placeholder = RegExp(r'\{(\w+)[,}]');
    for (final l in ['en', 'pt']) {
      final other = load(l);
      final otherKeys = other.keys.where((k) => !k.startsWith('@')).toSet();
      expect(otherKeys, keys, reason: 'app_$l.arb keys differ from app_es.arb');
      for (final k in keys.where((k) => k != '@@locale')) {
        final a = placeholder.allMatches(es[k] as String).map((m) => m[1]).toSet();
        final b = placeholder.allMatches(other[k] as String).map((m) => m[1]).toSet();
        expect(b, a, reason: 'Placeholders differ for "$k" in $l');
      }
    }
  });
}
