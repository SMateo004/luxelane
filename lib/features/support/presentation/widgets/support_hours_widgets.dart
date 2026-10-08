import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/support_hours_repository.dart';
import '../../domain/support_hours.dart';

SupportHoursRepository? _resolve(SupportHoursRepository? r) =>
    r ?? (sl.isRegistered<SupportHoursRepository>() ? sl<SupportHoursRepository>() : null);

/// Short weekday name in the current locale (1 = Monday).
String weekdayShort(int d) => DateFormat.E().format(DateTime(2024, 1, d)); // 1 Jan 2024 was a Monday

String _time(AppLocalizations l, int minutes) => minutes >= 1440
    ? l.supportHoursMidnight
    : DateFormat.jm().format(DateTime(2024, 1, 1).add(Duration(minutes: minutes)));

/// "lun–vie, 8:00–20:00 (hora de Bolivia)".
String supportHoursSummary(AppLocalizations l, SupportHours h) {
  if (h.always) return l.supportHoursAlways;
  final days = h.days.length == 7
      ? l.supportHoursEveryDay
      : h.dayRanges
          .map((r) => r.$1 == r.$2 ? weekdayShort(r.$1) : '${weekdayShort(r.$1)}–${weekdayShort(r.$2)}')
          .join(', ');
  final times = h.allDay ? l.supportHours24h : '${_time(l, h.openMin)}–${_time(l, h.closeMin)}';
  return l.supportHoursSummary(days, times);
}

/// Help center: the team's hours and whether it's answering now. Hidden
/// until an admin sets the hours.
class SupportHoursLine extends StatelessWidget {
  const SupportHoursLine({super.key, this.repository, this.now});
  final SupportHoursRepository? repository;

  /// Current UTC time (tests).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final repo = _resolve(repository);
    if (repo == null) return const SizedBox.shrink();
    final l = context.l10n;
    return StreamBuilder<SupportHours?>(
      stream: repo.watch(),
      builder: (context, snap) {
        final h = snap.data;
        if (h == null) return const SizedBox.shrink();
        final bolivia = SupportHours.boliviaTime(now ?? DateTime.now().toUtc());
        final open = h.isOpenAt(bolivia);
        final next = h.nextOpening(bolivia);
        final status = open
            ? l.supportHoursOpenNow
            : next == null
                ? null
                : l.supportHoursClosedUntil(
                    next.day == bolivia.day ? _time(l, next.hour * 60 + next.minute) : '${weekdayShort(next.weekday)} ${_time(l, next.hour * 60 + next.minute)}');
        return Padding(
          padding: const EdgeInsets.only(top: LuxSpacing.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.schedule_outlined, size: 16, color: LuxColors.accent),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(supportHoursSummary(l, h), style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
                if (status != null && !h.always)
                  Text(status,
                      style: LuxTypography.caption.copyWith(color: open ? LuxColors.success : LuxColors.whiteSecondary)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

/// Admin → Soporte: set or clear the team's hours.
class SupportHoursAdminCard extends StatelessWidget {
  const SupportHoursAdminCard({super.key, this.repository});
  final SupportHoursRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = _resolve(repository);
    if (repo == null) return const SizedBox.shrink();
    final l = context.l10n;
    return StreamBuilder<SupportHours?>(
      stream: repo.watch(),
      builder: (context, snap) {
        final h = snap.data;
        return Padding(
          padding: const EdgeInsets.only(top: LuxSpacing.md),
          child: LuxCard(
            child: Row(children: [
              const Icon(Icons.schedule_outlined, color: LuxColors.accent),
              const SizedBox(width: LuxSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.supportHoursTitle, style: LuxTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(h == null ? l.supportHoursUnset : supportHoursSummary(l, h), style: LuxTypography.caption),
                ]),
              ),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => SupportHoursDialog(repo: repo, initial: h),
                ),
                child: Text(h == null ? l.supportHoursSet : l.supportHoursEdit,
                    style: const TextStyle(color: LuxColors.accent)),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class SupportHoursDialog extends StatefulWidget {
  const SupportHoursDialog({super.key, required this.repo, this.initial});
  final SupportHoursRepository repo;
  final SupportHours? initial;

  @override
  State<SupportHoursDialog> createState() => _SupportHoursDialogState();
}

class _SupportHoursDialogState extends State<SupportHoursDialog> {
  late Set<int> _days = {...widget.initial?.days ?? const {1, 2, 3, 4, 5}};
  late bool _allDay = widget.initial?.allDay ?? false;
  late int _open = widget.initial?.openMin ?? 8 * 60;
  late int _close = widget.initial?.closeMin ?? 20 * 60;
  bool _busy = false;
  String? _error;

  Future<void> _pick(bool open) async {
    final current = open ? _open : _close;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (current ~/ 60) % 24, minute: current % 60),
    );
    if (t == null) return;
    setState(() {
      final m = t.hour * 60 + t.minute;
      if (open) {
        _open = m;
      } else {
        _close = m == 0 ? 1440 : m; // 00:00 as closing = midnight
      }
    });
  }

  Future<void> _save(SupportHours? hours) async {
    final l = context.l10n;
    if (hours != null) {
      final e = SupportHours.validate(hours.days, hours.openMin, hours.closeMin);
      if (e != null) {
        setState(() => _error = e == 'support-hours/days' ? l.supportHoursErrorDays : l.supportHoursErrorTimes);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.save(hours);
      if (!mounted) return;
      Navigator.of(context).pop();
      showLuxSnackbar(context, l.supportHoursSaved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.adminActionFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hours = SupportHours(days: _days, openMin: _allDay ? 0 : _open, closeMin: _allDay ? 1440 : _close);
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(l.supportHoursTitle, style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.supportHoursIntro, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(weekdayShort(d)),
                  selected: _days.contains(d),
                  selectedColor: LuxColors.accent.withValues(alpha: 0.25),
                  onSelected: (v) => setState(() => _days = v ? ({..._days, d}) : (_days.toSet()..remove(d))),
                ),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: LuxColors.accent,
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
              title: Text(l.supportHours24h, style: LuxTypography.bodyLarge),
            ),
            if (!_allDay)
              Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.sm, children: [
                OutlinedButton.icon(
                  onPressed: () => _pick(true),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: Text(l.supportHoursOpensAt(_time(l, _open))),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pick(false),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(l.supportHoursClosesAt(_time(l, _close))),
                ),
              ]),
            const SizedBox(height: LuxSpacing.md),
            Text(supportHoursSummary(l, hours), style: LuxTypography.caption),
            if (_error != null) ...[
              const SizedBox(height: LuxSpacing.sm),
              Text(_error!, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error)),
            ],
          ]),
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: _busy ? null : () => _save(null),
            child: Text(l.supportHoursClear, style: const TextStyle(color: LuxColors.error)),
          ),
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.commonCancel)),
        TextButton(
          onPressed: _busy ? null : () => _save(hours),
          child: Text(l.supportHoursSave, style: const TextStyle(color: LuxColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
