import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/support_repository.dart';
import '../../domain/support_ticket.dart';
import '../support_l10n.dart';

/// One support conversation, for the customer or (with [asTeam]) for the
/// Luxelane team.
class TicketThreadPage extends StatefulWidget {
  const TicketThreadPage({super.key, required this.ticketId, required this.repository, this.asTeam = false});
  final String ticketId;
  final SupportRepository repository;
  final bool asTeam;

  @override
  State<TicketThreadPage> createState() => _TicketThreadPageState();
}

class _TicketThreadPageState extends State<TicketThreadPage> {
  final _input = TextEditingController();
  late final _ticket = widget.repository.watchTicket(widget.ticketId);
  late final _messages = widget.repository.watchMessages(widget.ticketId);
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _markRead(SupportTicket t) {
    final unread = widget.asTeam ? t.unreadForAdmin : t.unreadForUser;
    if (unread) widget.repository.markRead(t.id, asTeam: widget.asTeam).ignore();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final auth = context.read<AuthBloc>().state;
    if (text.isEmpty || auth is! AuthAuthenticated) return;
    setState(() => _sending = true);
    try {
      await widget.repository.sendMessage(
        ticketId: widget.ticketId,
        author: auth.user,
        text: text.length > 2000 ? text.substring(0, 2000) : text,
        asTeam: widget.asTeam,
      );
      _input.clear();
    } catch (_) {
      if (mounted) showLuxSnackbar(context, context.l10n.supportSendFailed, isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(TicketStatus s, String done) async {
    try {
      await widget.repository.setStatus(widget.ticketId, s);
      if (mounted) showLuxSnackbar(context, done);
    } catch (_) {
      if (mounted) showLuxSnackbar(context, context.l10n.supportSendFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<SupportTicket?>(
      stream: _ticket,
      builder: (context, tSnap) {
        final t = tSnap.data;
        if (t != null) _markRead(t);
        return Scaffold(
          backgroundColor: LuxColors.black,
          appBar: AppBar(
            title: Text(t?.subject ?? l.supportTitle, overflow: TextOverflow.ellipsis),
            actions: [
              if (t != null && t.status != TicketStatus.resolved)
                TextButton(
                  onPressed: () => _setStatus(TicketStatus.resolved, l.supportResolvedDone),
                  child: Text(widget.asTeam ? l.supportResolveTeam : l.supportResolve),
                )
              else if (t != null && widget.asTeam)
                TextButton(
                  onPressed: () => _setStatus(TicketStatus.open, l.supportReopenedDone),
                  child: Text(l.supportReopen),
                ),
            ],
          ),
          body: t == null
              ? const Center(child: CircularProgressIndicator(color: LuxColors.accent))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(children: [
                      _Header(ticket: t, asTeam: widget.asTeam),
                      const LuxDivider(),
                      Expanded(
                        child: StreamBuilder<List<SupportMessage>>(
                          stream: _messages,
                          builder: (context, mSnap) {
                            final msgs = mSnap.data ?? const <SupportMessage>[];
                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(LuxSpacing.md),
                              itemCount: msgs.length,
                              itemBuilder: (_, i) {
                                final m = msgs[msgs.length - 1 - i];
                                // "Mine" is the side the viewer writes from.
                                return _Bubble(message: m, mine: m.fromTeam == widget.asTeam);
                              },
                            );
                          },
                        ),
                      ),
                      if (t.status == TicketStatus.resolved && !widget.asTeam)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(LuxSpacing.md, 0, LuxSpacing.md, LuxSpacing.sm),
                          child: Text(l.supportResolvedHint, textAlign: TextAlign.center, style: LuxTypography.caption),
                        ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(LuxSpacing.md, 0, LuxSpacing.sm, LuxSpacing.md),
                          child: Row(children: [
                            Expanded(
                              child: TextField(
                                controller: _input,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white),
                                decoration: InputDecoration(
                                  hintText: l.supportWriteHint,
                                  filled: true,
                                  fillColor: LuxColors.blackElevated,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(LuxRadius.md),
                                    borderSide: const BorderSide(color: LuxColors.blackBorder),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: LuxSpacing.xs),
                            IconButton(
                              tooltip: l.supportSend,
                              onPressed: _sending ? null : _send,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: LuxColors.accent))
                                  : const Icon(Icons.send_rounded, color: LuxColors.accent),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ticket, required this.asTeam});
  final SupportTicket ticket;
  final bool asTeam;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = ticket;
    return Padding(
      padding: const EdgeInsets.all(LuxSpacing.md),
      child: Row(children: [
        Icon(t.category.icon, color: t.urgent ? LuxColors.warning : LuxColors.accent),
        const SizedBox(width: LuxSpacing.sm),
        Expanded(
          child: Text(
            [
              if (asTeam) l.supportFromUser(t.userName, t.userRole == 'driver' ? l.coreRoleDriver : l.coreRoleRider),
              t.category.localizedLabel(l),
              if (t.urgent) l.supportUrgent,
              if (t.bookingId != null) l.supportTripRef(t.bookingId!.substring(0, t.bookingId!.length.clamp(0, 8)).toUpperCase()),
            ].join(' · '),
            style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary),
          ),
        ),
        TicketStatusChip(status: t.status, forTeam: asTeam),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final SupportMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = message;
    final who = m.fromTeam ? l.supportTeamName : m.authorName;
    final when = m.createdAt == null ? '' : DateFormat.MMMd().add_jm().format(m.createdAt!);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        // Narrower than the screen so each side reads as its own column.
        constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * 0.82).clamp(0, 520)),
        child: Container(
          margin: const EdgeInsets.only(bottom: LuxSpacing.sm),
          padding: const EdgeInsets.all(LuxSpacing.md),
          decoration: BoxDecoration(
            color: mine ? LuxColors.accentSubtle : LuxColors.blackElevated,
            border: Border.all(color: mine ? LuxColors.accent.withOpacity(0.35) : LuxColors.blackBorder),
            borderRadius: BorderRadius.circular(LuxRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text([who, if (when.isNotEmpty) when].join(' · '),
                  style: LuxTypography.caption.copyWith(color: m.fromTeam ? LuxColors.accent : LuxColors.whiteSecondary)),
              const SizedBox(height: 4),
              SelectableText(m.text, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
