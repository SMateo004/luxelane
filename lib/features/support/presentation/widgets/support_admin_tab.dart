import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../admin/presentation/widgets/admin_shared_widgets.dart';
import '../../data/support_repository.dart';
import '../../domain/support_ticket.dart';
import '../pages/help_center_page.dart' show TicketListTile;
import '../pages/ticket_thread_page.dart';

enum _Filter { pending, answered, resolved, all }

/// Admin panel → Soporte: the queue of requests, safety reports first.
class SupportAdminTab extends StatefulWidget {
  const SupportAdminTab({super.key, this.repository});
  final SupportRepository? repository;

  @override
  State<SupportAdminTab> createState() => _SupportAdminTabState();
}

class _SupportAdminTabState extends State<SupportAdminTab> {
  late final SupportRepository _repo = widget.repository ?? sl<SupportRepository>();
  late final Stream<List<SupportTicket>> _stream = _repo.watchAllTickets();
  _Filter _filter = _Filter.pending;

  bool _matches(SupportTicket t) => switch (_filter) {
        _Filter.pending => t.status == TicketStatus.open,
        _Filter.answered => t.status == TicketStatus.answered,
        _Filter.resolved => t.status == TicketStatus.resolved,
        _Filter.all => true,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<List<SupportTicket>>(
      stream: _stream,
      builder: (context, snap) {
        final all = snap.data ?? const <SupportTicket>[];
        final pending = all.where((t) => t.status == TicketStatus.open).length;
        final urgent = all.where((t) => t.status == TicketStatus.open && t.urgent).length;
        final shown = sortForQueue(all.where(_matches));
        String label(_Filter f) => switch (f) {
              _Filter.pending => l.supportFilterPending(pending),
              _Filter.answered => l.supportFilterAnswered,
              _Filter.resolved => l.supportFilterResolved,
              _Filter.all => l.adminFilterAll,
            };
        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            SectionHeader(title: l.supportAdminTitle),
            if (urgent > 0) ...[
              const SizedBox(height: LuxSpacing.md),
              LuxCard(
                child: Row(children: [
                  const Icon(Icons.health_and_safety_outlined, color: LuxColors.warning),
                  const SizedBox(width: LuxSpacing.md),
                  Expanded(
                    child: Text(l.supportUrgentBanner(urgent),
                        style: const TextStyle(color: LuxColors.warning, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: LuxSpacing.md),
            Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.sm, children: [
              for (final f in _Filter.values)
                SectionChip(label: label(f), selected: _filter == f, onTap: () => setState(() => _filter = f)),
            ]),
            const SizedBox(height: LuxSpacing.lg),
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
              const Center(child: CircularProgressIndicator(color: LuxColors.accent))
            else if (shown.isEmpty)
              EmptyState(icon: Icons.support_agent_outlined, message: l.supportAdminEmpty)
            else
              for (final t in shown)
                TicketListTile(
                  ticket: t,
                  unread: t.unreadForAdmin,
                  forTeam: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => TicketThreadPage(ticketId: t.id, repository: _repo, asTeam: true),
                  )),
                ),
          ],
        );
      },
    );
  }
}
