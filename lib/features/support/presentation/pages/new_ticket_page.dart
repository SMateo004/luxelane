import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/support_repository.dart';
import '../../domain/support_ticket.dart';
import '../support_l10n.dart';
import 'ticket_thread_page.dart';

/// Form to write to the Luxelane team.
class NewTicketPage extends StatefulWidget {
  const NewTicketPage({super.key, required this.repository, this.bookingId, this.initialCategory, this.initialSubject});
  final SupportRepository repository;
  final String? bookingId;

  /// Preselected from the trip's safety sheet.
  final TicketCategory? initialCategory;
  final String? initialSubject;

  @override
  State<NewTicketPage> createState() => _NewTicketPageState();
}

class _NewTicketPageState extends State<NewTicketPage> {
  late TicketCategory? _category =
      widget.initialCategory ?? (widget.bookingId != null ? TicketCategory.trip : null);
  late final _subject = TextEditingController(text: widget.initialSubject ?? '');
  final _message = TextEditingController();
  bool _busy = false;
  bool _tried = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _valid => _category != null && _subject.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

  Future<void> _send() async {
    final l = context.l10n;
    setState(() => _tried = true);
    final auth = context.read<AuthBloc>().state;
    if (!_valid || auth is! AuthAuthenticated) return;
    setState(() => _busy = true);
    try {
      final id = await widget.repository.createTicket(
        user: auth.user,
        category: _category!,
        subject: _subject.text.trim().length > 120 ? _subject.text.trim().substring(0, 120) : _subject.text.trim(),
        message: _message.text.trim().length > 2000 ? _message.text.trim().substring(0, 2000) : _message.text.trim(),
        bookingId: widget.bookingId,
      );
      if (!mounted) return;
      showLuxSnackbar(context, l.supportSent);
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => TicketThreadPage(ticketId: id, repository: widget.repository),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showLuxSnackbar(context, l.supportSendFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: LuxColors.black,
      appBar: AppBar(title: Text(l.supportNewRequest)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            children: [
              if (widget.bookingId != null) ...[
                Row(children: [
                  const Icon(Icons.link_rounded, size: 16, color: LuxColors.accent),
                  const SizedBox(width: LuxSpacing.sm),
                  Expanded(
                    child: Text(l.supportLinkedTrip(widget.bookingId!.substring(0, widget.bookingId!.length.clamp(0, 8)).toUpperCase()),
                        style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
                  ),
                ]),
                const SizedBox(height: LuxSpacing.md),
              ],
              Text(l.supportCategoryQuestion, style: LuxTypography.titleMedium),
              const SizedBox(height: LuxSpacing.sm),
              Wrap(
                spacing: LuxSpacing.sm,
                runSpacing: LuxSpacing.sm,
                children: [
                  for (final c in TicketCategory.values)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 16),
                      label: Text(c.localizedLabel(l)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              if (_tried && _category == null) ...[
                const SizedBox(height: LuxSpacing.xs),
                Text(l.supportPickCategory, style: LuxTypography.caption.copyWith(color: LuxColors.error)),
              ],
              if (_category == TicketCategory.safety) ...[
                const SizedBox(height: LuxSpacing.md),
                Container(
                  padding: const EdgeInsets.all(LuxSpacing.md),
                  decoration: BoxDecoration(
                    color: LuxColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(LuxRadius.sm),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.emergency_outlined, color: LuxColors.warning, size: 18),
                    const SizedBox(width: LuxSpacing.sm),
                    Expanded(
                      child: Text(l.supportSafetyNote,
                          style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: LuxSpacing.lg),
              LuxTextField(
                controller: _subject,
                label: l.supportSubject,
                hint: l.supportSubjectHint,
                onChanged: (_) => _tried ? setState(() {}) : null,
              ),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(
                controller: _message,
                label: l.supportMessage,
                hint: l.supportMessageHint,
                maxLines: 6,
                onChanged: (_) => _tried ? setState(() {}) : null,
              ),
              if (_tried && !_valid && _category != null) ...[
                const SizedBox(height: LuxSpacing.xs),
                Text(l.supportFillFields, style: LuxTypography.caption.copyWith(color: LuxColors.error)),
              ],
              const SizedBox(height: LuxSpacing.lg),
              LuxButton(label: l.supportSend, loading: _busy, onPressed: _busy ? null : _send),
            ],
          ),
        ),
      ),
    );
  }
}
