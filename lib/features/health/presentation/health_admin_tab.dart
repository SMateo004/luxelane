import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/env.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/client_error_reporter.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../data/health_repository.dart';

/// Admin panel → Salud: the operations monitor's summary (written every
/// 5 minutes by opsWatch) and grouped app errors from the web.
class HealthAdminTab extends StatefulWidget {
  const HealthAdminTab({super.key, this.repository, this.now});
  final HealthRepository? repository;
  final DateTime? now;

  @override
  State<HealthAdminTab> createState() => _HealthAdminTabState();
}

class _HealthAdminTabState extends State<HealthAdminTab> {
  late final HealthRepository _repo = widget.repository ?? sl<HealthRepository>();
  late final Stream<SystemHealth?> _health = _repo.watchHealth();
  late final Stream<List<ClientErrorGroup>> _errors = _repo.watchErrors();
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = widget.now ?? DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      children: [
        SectionHeader(title: l.healthTitle),
        const SizedBox(height: LuxSpacing.sm),
        Text(
          l.healthBuildInfo(AppConfig.isProd ? l.healthEnvProd : l.healthEnvDev, ClientErrorReporter.appVersion),
          style: LuxTypography.caption,
        ),
        const SizedBox(height: LuxSpacing.md),
        StreamBuilder<SystemHealth?>(
          stream: _health,
          builder: (context, snap) {
            final h = snap.data;
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: LuxColors.accent));
            }
            final stale = h == null || h.staleAt(now);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Banner(
                  icon: stale ? Icons.sensors_off_outlined : Icons.sensors_rounded,
                  color: stale ? LuxColors.warning : LuxColors.success,
                  text: stale
                      ? l.healthMonitorStale
                      : l.healthMonitorOk(DateFormat.jm().format(h.checkedAt!)),
                ),
                if (h != null) ...[
                  const SizedBox(height: LuxSpacing.md),
                  LayoutBuilder(builder: (context, c) {
                    final w = c.maxWidth < 560 ? (c.maxWidth - LuxSpacing.md) / 2 : 200.0;
                    Widget tile(IconData icon, String label, int value, {bool alert = false}) => SizedBox(
                          width: w,
                          child: LuxCard(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Icon(icon, size: 18, color: alert ? LuxColors.warning : LuxColors.accent),
                                const SizedBox(width: LuxSpacing.sm),
                                Expanded(
                                  child: Text(label,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
                                ),
                              ]),
                              const SizedBox(height: LuxSpacing.sm),
                              Text(NumberFormat.decimalPattern().format(value),
                                  style: LuxTypography.headlineLarge.copyWith(
                                      color: LuxColors.white, fontFamily: 'Cormorant Garamond', fontSize: 32)),
                              if (alert)
                                Text(l.healthNeedsAttention,
                                    style: LuxTypography.caption.copyWith(color: LuxColors.warning)),
                            ]),
                          ),
                        );
                    return Wrap(spacing: LuxSpacing.md, runSpacing: LuxSpacing.md, children: [
                      tile(Icons.person_pin_circle_outlined, l.healthOnlineDrivers, h.onlineDrivers,
                          alert: h.onlineDrivers == 0 && h.pendingNext2h > 0),
                      tile(Icons.schedule_rounded, l.healthPendingNext2h, h.pendingNext2h),
                      tile(Icons.person_off_outlined, l.healthUnassignedSoon, h.unassignedSoon,
                          alert: h.unassignedSoon > 0),
                      tile(Icons.health_and_safety_outlined, l.healthUrgentTickets, h.urgentTickets,
                          alert: h.urgentTickets > 0),
                      tile(Icons.bug_report_outlined, l.healthErrors24h, h.clientErrors24h),
                    ]);
                  }),
                ],
                const SizedBox(height: LuxSpacing.sm),
                Text(l.healthAlertsNote, style: LuxTypography.caption),
              ],
            );
          },
        ),
        const SizedBox(height: LuxSpacing.xl),
        SectionHeader(
          title: l.healthErrorsTitle,
          trailing: TextButton(
            onPressed: () => setState(() => _showResolved = !_showResolved),
            child: Text(_showResolved ? l.healthHideResolved : l.healthShowResolved),
          ),
        ),
        const SizedBox(height: LuxSpacing.sm),
        Text(l.healthErrorsNote, style: LuxTypography.caption),
        const SizedBox(height: LuxSpacing.md),
        StreamBuilder<List<ClientErrorGroup>>(
          stream: _errors,
          builder: (context, snap) {
            final all = snap.data ?? const <ClientErrorGroup>[];
            final shown = all.where((e) => _showResolved || !e.resolved).toList();
            if (shown.isEmpty) {
              return _Banner(icon: Icons.check_circle_outline_rounded, color: LuxColors.success, text: l.healthNoErrors);
            }
            return Column(children: [
              for (final e in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                  child: _ErrorTile(error: e, onResolved: (v) => _repo.setResolved(e.id, v)),
                ),
            ]);
          },
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: LuxSpacing.md),
          Expanded(child: Text(text, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white))),
        ]),
      );
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.error, required this.onResolved});
  final ClientErrorGroup error;
  final ValueChanged<bool> onResolved;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = error;
    final meta = [
      e.platform.toUpperCase(),
      l.healthOccurrences(e.count),
      if (e.lastSeen != null) l.healthLastSeen(DateFormat.MMMd().add_jm().format(e.lastSeen!)),
      if (e.lastRoute != null) e.lastRoute!,
      if (e.lastAppVersion != null) 'v${e.lastAppVersion}',
    ].join(' · ');
    return LuxCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(e.resolved ? Icons.check_circle_outline_rounded : Icons.bug_report_outlined,
              color: e.resolved ? LuxColors.success : LuxColors.warning),
          iconColor: LuxColors.accent,
          collapsedIconColor: LuxColors.whiteTertiary,
          title: Text(e.message,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
          subtitle: Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: LuxTypography.caption),
          childrenPadding: const EdgeInsets.fromLTRB(LuxSpacing.md, 0, LuxSpacing.md, LuxSpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.stack.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(LuxSpacing.sm),
                decoration: BoxDecoration(
                  color: LuxColors.black,
                  borderRadius: BorderRadius.circular(LuxRadius.sm),
                ),
                child: SelectableText(e.stack,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: LuxColors.whiteSecondary)),
              ),
            const SizedBox(height: LuxSpacing.sm),
            TextButton.icon(
              onPressed: () => onResolved(!e.resolved),
              icon: Icon(e.resolved ? Icons.undo_rounded : Icons.check_rounded, size: 16),
              label: Text(e.resolved ? l.healthReopen : l.healthMarkResolved),
            ),
          ],
        ),
      ),
    );
  }
}
