import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/driver_documents_repository.dart';
import '../../domain/driver_document.dart';
import '../driver_document_l10n.dart';
import 'driver_documents_screen.dart' show DocStatusChip;

/// Admin review of one chauffeur's documents: open each file, approve it
/// (confirming its expiry date) or reject it with a reason. Verification is
/// recomputed by the backend from the result.
class DriverDocumentsReviewPage extends StatelessWidget {
  const DriverDocumentsReviewPage({
    super.key,
    required this.driverId,
    required this.driverName,
    this.repository,
    this.openUrl,
    this.now,
  });

  final String driverId;
  final String driverName;
  final DriverDocumentsRepository? repository;

  /// Test seam for opening a file link.
  final Future<void> Function(String url)? openUrl;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? sl<DriverDocumentsRepository>();
    final l = context.l10n;
    return Scaffold(
      backgroundColor: LuxColors.black,
      appBar: AppBar(
        title: Text(l.docReviewTitle(driverName), overflow: TextOverflow.ellipsis),
      ),
      body: StreamBuilder<Map<DriverDocType, DriverDocument>>(
        stream: repo.watch(driverId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: LuxColors.accent));
          }
          final t = now ?? DateTime.now();
          final summary = DocumentsSummary(snap.data!, t);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(LuxSpacing.lg),
                children: [
                  Text(
                    summary.complete ? l.docReviewAllApproved : l.docApprovedCount(summary.approved, summary.documents.length),
                    style: LuxTypography.bodyMedium,
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  for (final d in summary.documents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                      child: _ReviewCard(
                        doc: d,
                        now: t,
                        repo: repo,
                        driverId: driverId,
                        openUrl: openUrl ?? (u) => launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({
    required this.doc,
    required this.now,
    required this.repo,
    required this.driverId,
    required this.openUrl,
  });
  final DriverDocument doc;
  final DateTime now;
  final DriverDocumentsRepository repo;
  final String driverId;
  final Future<void> Function(String url) openUrl;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action, String success) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final l = context.l10n;
    showLuxSnackbar(context, error == null ? success : localizedDocError(l, error), isError: error != null);
  }

  Future<void> _open() async {
    final l = context.l10n;
    final url = await widget.repo.downloadUrl(widget.doc.storagePath!);
    if (!mounted) return;
    if (url == null) {
      showLuxSnackbar(context, l.docErrorFailed, isError: true);
      return;
    }
    await widget.openUrl(url);
  }

  Future<void> _approve() async {
    final l = context.l10n;
    final doc = widget.doc;
    DateTime? expiry = doc.expiresAt;
    if (doc.type.expires) {
      final now = DateTime.now();
      expiry = await showDatePicker(
        context: context,
        helpText: l.docReviewConfirmExpiry,
        initialDate: expiry != null && expiry.isAfter(now) ? expiry : now.add(const Duration(days: 365)),
        firstDate: now.add(const Duration(days: 1)),
        lastDate: DateTime(now.year + 15),
      );
      if (expiry == null || !mounted) return;
    }
    await _run(
      () => widget.repo.review(driverId: widget.driverId, type: doc.type, approve: true, expiresAt: expiry),
      l.docReviewApproved,
    );
  }

  Future<void> _reject() async {
    final l = context.l10n;
    final reason = await showDialog<String>(context: context, builder: (_) => const _RejectDialog());
    if (reason == null || !mounted) return;
    if (reason.isEmpty) {
      showLuxSnackbar(context, l.docErrorReasonRequired, isError: true);
      return;
    }
    await _run(
      () => widget.repo.review(driverId: widget.driverId, type: widget.doc.type, approve: false, reason: reason),
      l.docReviewRejected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = widget.doc;
    final status = d.statusAt(widget.now);
    final hasFile = d.storagePath != null;
    final details = [
      if (d.fileName != null) d.fileName!,
      if (d.uploadedAt != null) l.docUploadedOn(DateFormat.yMMMd().format(d.uploadedAt!)),
      if (d.expiresAt != null) l.docExpiresOn(DateFormat.yMMMd().format(d.expiresAt!)),
    ].join(' · ');
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(d.type.icon, color: LuxColors.accent),
            const SizedBox(width: LuxSpacing.md),
            Expanded(child: Text(d.type.localizedName(l), style: LuxTypography.titleMedium)),
            DocStatusChip(status: status, expiring: d.expiringSoon(widget.now)),
          ]),
          if (details.isNotEmpty) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(details, style: LuxTypography.caption),
          ],
          if (status == DriverDocStatus.rejected && (d.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: LuxSpacing.xs),
            Text(l.docRejectedReason(d.rejectionReason!),
                style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
          ],
          if (hasFile) ...[
            const SizedBox(height: LuxSpacing.md),
            _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: LuxColors.accent),
                  )
                : Wrap(
                    spacing: LuxSpacing.sm,
                    runSpacing: LuxSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        // The app theme makes outlined buttons full width.
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: _open,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(l.docReviewOpen),
                      ),
                      if (status != DriverDocStatus.approved)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              backgroundColor: LuxColors.accent, foregroundColor: LuxColors.onAccent),
                          onPressed: _approve,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(l.docReviewApprove),
                        ),
                      if (status != DriverDocStatus.rejected)
                        TextButton.icon(
                          onPressed: _reject,
                          icon: const Icon(Icons.close_rounded, size: 16, color: LuxColors.error),
                          label: Text(l.docReviewReject, style: const TextStyle(color: LuxColors.error)),
                        ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

/// Owns its text controller so it outlives the closing animation.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(l.docReviewRejectTitle, style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 420,
        child: LuxTextField(
          controller: _controller,
          label: l.docReviewRejectReason,
          hint: l.docReviewRejectReasonHint,
          maxLines: 3,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l.docReviewReject, style: const TextStyle(color: LuxColors.error)),
        ),
      ],
    );
  }
}
