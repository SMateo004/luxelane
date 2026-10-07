/// Spanish date formatting that does not depend on intl locale data being
/// initialised (the app never calls `initializeDateFormatting`).
abstract class LuxFormat {
  static const _days   = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
                          'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// "Hoy · 18:30", "Mañana · 09:15" or "vie 14 nov · 18:30".
  static String dateTime(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    final label = switch (diff) {
      0 => 'Hoy',
      1 => 'Mañana',
      _ => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}',
    };
    return '$label · ${time(d)}';
  }

  /// Default pickup: at least [ahead] from now, rounded up to the next quarter
  /// hour ("16:30", never "16:22") — small detail, calmer first impression.
  static DateTime nextQuarter({Duration ahead = const Duration(hours: 2), DateTime? from}) {
    final t = (from ?? DateTime.now()).add(ahead);
    final m = ((t.minute + 14) ~/ 15) * 15;
    return DateTime(t.year, t.month, t.day, t.hour).add(Duration(minutes: m));
  }

  /// Time-of-day greeting, used to open the app on a personal note.
  static String greeting([DateTime? at]) {
    final h = (at ?? DateTime.now()).hour;
    if (h >= 5 && h < 12) return 'Buenos días';
    if (h >= 12 && h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
