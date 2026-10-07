import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/waiting_policy.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/support_repository.dart';
import '../../domain/support_ticket.dart';
import '../support_l10n.dart';
import 'new_ticket_page.dart';
import 'ticket_thread_page.dart';

/// Help center: answers to common questions, the rider's or chauffeur's
/// requests, and a way to write to the team (optionally about one trip).
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key, this.bookingId, this.repository});

  /// Trip the help is about (from the receipt or the ride screen).
  final String? bookingId;
  final SupportRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? sl<SupportRepository>();
    final l = context.l10n;
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;

    void openNew() => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => NewTicketPage(repository: repo, bookingId: bookingId),
        ));

    return Scaffold(
      backgroundColor: LuxColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          tooltip: l.commonBack,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(l.supportTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            children: [
              LuxCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookingId != null ? l.supportTripHelpTitle : l.supportContactTitle,
                        style: LuxTypography.titleLarge),
                    const SizedBox(height: LuxSpacing.xs),
                    Text(bookingId != null ? l.supportTripHelpBody : l.supportContactBody,
                        style: LuxTypography.bodyMedium),
                    const SizedBox(height: LuxSpacing.md),
                    LuxButton(
                      label: l.supportNewRequest,
                      icon: Icons.edit_outlined,
                      height: 46,
                      onPressed: user == null ? null : openNew,
                    ),
                    const SizedBox(height: LuxSpacing.md),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.emergency_outlined, size: 16, color: LuxColors.warning),
                      const SizedBox(width: LuxSpacing.sm),
                      Expanded(child: Text(l.supportEmergencyNote, style: LuxTypography.caption)),
                    ]),
                  ],
                ),
              ),
              if (user != null)
                StreamBuilder<List<SupportTicket>>(
                  stream: repo.watchMyTickets(user.id),
                  builder: (context, snap) {
                    final tickets = snap.data ?? const <SupportTicket>[];
                    if (tickets.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: LuxSpacing.xl),
                        SectionHeader(title: l.supportMyRequests),
                        const SizedBox(height: LuxSpacing.sm),
                        for (final t in tickets)
                          TicketListTile(
                            ticket: t,
                            unread: t.unreadForUser,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => TicketThreadPage(ticketId: t.id, repository: repo),
                            )),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: LuxSpacing.xl),
              SectionHeader(title: l.supportFaqTitle),
              const SizedBox(height: LuxSpacing.sm),
              for (final (q, a) in _faq(l))
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: LuxSpacing.md),
                    iconColor: LuxColors.accent,
                    collapsedIconColor: LuxColors.whiteTertiary,
                    expandedAlignment: Alignment.centerLeft,
                    title: Text(q, style: LuxTypography.bodyLarge),
                    children: [Text(a, style: LuxTypography.bodyMedium)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Answers reflect what the product actually enforces.
  static List<(String, String)> _faq(AppLocalizations l) => [
        (l.supportFaqCancelQ, l.supportFaqCancelA),
        (l.supportFaqWaitQ, l.supportFaqWaitA(WaitingPolicy.airportFreeMinutes, WaitingPolicy.cityFreeMinutes)),
        (l.supportFaqPayQ, l.supportFaqPayA),
        (l.supportFaqPromoQ, l.supportFaqPromoA),
        (l.supportFaqCorporateQ, l.supportFaqCorporateA),
        (l.supportFaqLostQ, l.supportFaqLostA),
        (l.supportFaqChauffeursQ, l.supportFaqChauffeursA),
      ];
}

class TicketListTile extends StatelessWidget {
  const TicketListTile({
    super.key,
    required this.ticket,
    required this.unread,
    required this.onTap,
    this.forTeam = false,
  });
  final SupportTicket ticket;
  final bool unread;
  final VoidCallback onTap;
  final bool forTeam;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = ticket;
    final when = t.lastMessageAt == null ? '' : DateFormat.MMMd().add_jm().format(t.lastMessageAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(LuxRadius.md),
          onTap: onTap,
          child: LuxCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(t.category.icon, color: t.urgent ? LuxColors.warning : LuxColors.accent),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (unread) ...[
                          Semantics(
                            label: l.supportUnread,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: LuxColors.accent, shape: BoxShape.circle),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(t.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuxTypography.titleMedium.copyWith(
                                  fontWeight: unread ? FontWeight.w700 : FontWeight.w500)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (forTeam) t.userName,
                          t.category.localizedLabel(l),
                          if (t.urgent) l.supportUrgent,
                          if (when.isNotEmpty) when,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxTypography.caption,
                      ),
                      if (t.lastMessagePreview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(t.lastMessagePreview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: LuxTypography.bodyMedium),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: LuxSpacing.sm),
                TicketStatusChip(status: t.status, forTeam: forTeam),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
