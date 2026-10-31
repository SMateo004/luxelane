import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/utils/lux_format.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Idiomas, decisión 5: importes y fechas según el idioma, con «Bs» delante.
void main() {
  tearDown(() => L10n.use(const Locale('es')));

  test('importes: la misma cifra en los tres idiomas', () {
    expect(LuxFormat.money(1234.5, locale: 'es'), 'Bs 1.234,50');
    expect(LuxFormat.money(1234.5, locale: 'pt'), 'Bs 1.234,50');
    expect(LuxFormat.money(1234.5, locale: 'en'), 'Bs 1,234.50');
    expect(LuxFormat.money(86, locale: 'en'), 'Bs 86');
    expect(LuxFormat.money(-0.5, locale: 'en'), '-Bs 0.50');
  });

  test('«1.234,50» no se lee distinto en inglés', () {
    double read(String s, String decimal) {
      final digits = s.replaceAll(RegExp(r'^-?Bs '), '');
      final group = decimal == ',' ? '.' : ',';
      return double.parse(
          digits.replaceAll(group, '').replaceAll(decimal, '.'));
    }

    for (final v in [1234.5, 1000000.0, 0.05, 999.99, 1234.0]) {
      expect(read(LuxFormat.money(v, locale: 'es'), ','), closeTo(v, 0.001));
      expect(read(LuxFormat.money(v, locale: 'pt'), ','), closeTo(v, 0.001));
      expect(read(LuxFormat.money(v, locale: 'en'), '.'), closeTo(v, 0.001));
    }
    // La forma española leída con la convención inglesa sería otra cifra.
    expect(read('Bs 1.234,50', '.'), isNot(closeTo(1234.5, 0.001)));
  });

  test('el idioma activo manda si no se indica otro', () {
    L10n.use(const Locale('en'));
    expect(LuxFormat.money(1234.5), 'Bs 1,234.50');
    expect(LuxFormat.greeting(DateTime(2026, 1, 1, 9)), 'Good morning');
    L10n.use(const Locale('pt'));
    expect(LuxFormat.greeting(DateTime(2026, 1, 1, 20)), 'Boa noite');
  });

  test('fechas y horas por idioma', () {
    final now = DateTime(2026, 11, 10, 8);
    final d = DateTime(2026, 11, 14, 18, 30);
    expect(LuxFormat.dateTime(d, now: now, locale: 'es'),
        startsWith('sáb 14 nov'));
    expect(
        LuxFormat.dateTime(d, now: now, locale: 'en'), 'Sat 14 Nov · 6:30 PM');
    expect(LuxFormat.dateTime(d, now: now, locale: 'pt'), contains('14'));
    expect(
        LuxFormat.dateTime(DateTime(2026, 11, 10, 9, 15),
            now: now, locale: 'en'),
        'Today · 9:15 AM');
    expect(
        LuxFormat.dateTime(DateTime(2026, 11, 11, 9, 15),
            now: now, locale: 'pt'),
        'Amanhã · 09:15');
    expect(LuxFormat.time(d, locale: 'es'), '18:30');
  });
}
