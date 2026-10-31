import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';

import '../../l10n/l10n.dart';

/// Importes, fechas y saludos en el idioma activo (L10n.code), con intl.
abstract class LuxFormat {
  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Importe en bolivianos, igual en toda la app: «Bs» delante y la cifra
  /// con los separadores del idioma. Español y portugués «Bs 1.234,50»,
  /// inglés «Bs 1,234.50»: la misma cifra, sin cambiar de sentido
  /// (decisión 5). Entero sin decimales («Bs 1.234»). E21.
  static String money(num amount, {String? locale}) {
    final symbols =
        numberFormatSymbols[locale ?? L10n.code] ?? numberFormatSymbols['es']!;
    final cents = (amount * 100).round();
    final abs = cents.abs();
    final whole = (abs ~/ 100).toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => symbols.GROUP_SEP as String,
        );
    final rest = abs % 100;
    final decimals = rest == 0 ? '' : '${symbols.DECIMAL_SEP}${_two(rest)}';
    // Espacio que no se parte: «Bs» y la cifra nunca quedan en dos líneas.
    return '${cents < 0 ? '-' : ''}Bs $whole$decimals';
  }

  /// «18:30» en español y portugués; «6:30 PM» en inglés.
  static String time(DateTime d, {String? locale}) {
    final l = locale ?? L10n.code;
    L10n.ensureDateSymbols();
    return l == 'en'
        ? DateFormat('h:mm a', 'en').format(d)
        : DateFormat('HH:mm', l).format(d);
  }

  /// «Hoy · 18:30», «Mañana · 09:15» o «vie 14 nov · 18:30» (en el idioma
  /// activo: «Fri 14 Nov», «sex. 14 nov.»).
  static String dateTime(DateTime d, {DateTime? now, String? locale}) {
    final l = locale ?? L10n.code;
    final t = locale == null ? L10n.current : lookupAppLocalizations(Locale(l));
    L10n.ensureDateSymbols();
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    final label = switch (diff) {
      0 => t.formatToday,
      1 => t.formatTomorrow,
      _ => DateFormat('EEE d MMM', l).format(d),
    };
    return '$label · ${time(d, locale: l)}';
  }

  /// Default pickup: at least [ahead] from now, rounded up to the next quarter
  /// hour ("16:30", never "16:22") — small detail, calmer first impression.
  static DateTime nextQuarter({
    Duration ahead = const Duration(hours: 2),
    DateTime? from,
  }) {
    final t = (from ?? DateTime.now()).add(ahead);
    final m = ((t.minute + 14) ~/ 15) * 15;
    return DateTime(t.year, t.month, t.day, t.hour).add(Duration(minutes: m));
  }

  /// Time-of-day greeting, used to open the app on a personal note.
  static String greeting([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    final t = L10n.current;
    if (h >= 5 && h < 12) return t.greetingMorning;
    if (h >= 12 && h < 19) return t.greetingAfternoon;
    return t.greetingEvening;
  }
}
