/// Team support hours (config/support), in Bolivia time (UTC−4, no DST).
/// Unset means the app doesn't show any hours.
class SupportHours {
  const SupportHours({required this.days, required this.openMin, required this.closeMin});

  /// Weekdays the team answers, 1 = Monday … 7 = Sunday.
  final Set<int> days;

  /// Minutes from midnight; closeMin 1440 = until midnight.
  final int openMin;
  final int closeMin;

  static const boliviaOffset = Duration(hours: -4);

  bool get allDay => openMin == 0 && closeMin == 1440;
  bool get always => allDay && days.length == 7;

  /// Bolivia wall-clock time for [utc].
  static DateTime boliviaTime(DateTime utc) {
    final b = utc.toUtc().add(boliviaOffset);
    return DateTime(b.year, b.month, b.day, b.hour, b.minute);
  }

  bool isOpenAt(DateTime bolivia) {
    if (!days.contains(bolivia.weekday)) return false;
    final m = bolivia.hour * 60 + bolivia.minute;
    return m >= openMin && m < closeMin;
  }

  /// Next opening (Bolivia wall-clock), or null if open now or never.
  DateTime? nextOpening(DateTime bolivia) {
    if (days.isEmpty || isOpenAt(bolivia)) return null;
    final today = DateTime(bolivia.year, bolivia.month, bolivia.day);
    for (var i = 0; i <= 7; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      if (!days.contains(day.weekday)) continue;
      final opens = day.add(Duration(minutes: openMin));
      if (opens.isAfter(bolivia)) return opens;
    }
    return null;
  }

  /// Weekdays as ranges: {1,2,3,4,5,7} → [(1,5),(7,7)].
  List<(int, int)> get dayRanges {
    final sorted = days.toList()..sort();
    final out = <(int, int)>[];
    for (final d in sorted) {
      if (out.isNotEmpty && out.last.$2 == d - 1) {
        out[out.length - 1] = (out.last.$1, d);
      } else {
        out.add((d, d));
      }
    }
    return out;
  }

  static String? validate(Set<int> days, int openMin, int closeMin) {
    if (days.isEmpty || days.any((d) => d < 1 || d > 7)) return 'support-hours/days';
    if (openMin < 0 || closeMin > 1440 || openMin >= closeMin) return 'support-hours/times';
    return null;
  }

  static SupportHours? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final days = (j['days'] as List? ?? const []).whereType<num>().map((d) => d.toInt()).toSet();
    final open = (j['openMin'] as num?)?.toInt();
    final close = (j['closeMin'] as num?)?.toInt();
    if (open == null || close == null || validate(days, open, close) != null) return null;
    return SupportHours(days: days, openMin: open, closeMin: close);
  }

  Map<String, dynamic> toJson() => {'days': (days.toList()..sort()), 'openMin': openMin, 'closeMin': closeMin};
}
