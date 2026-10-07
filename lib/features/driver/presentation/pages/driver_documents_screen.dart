import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/driver_documents_repository.dart';
import '../../domain/driver_document.dart';
import '../driver_document_l10n.dart';

/// A file chosen by the chauffeur.
typedef PickedDocument = ({Uint8List bytes, String name, String contentType});

/// Opens the system picker for an image or PDF.
Future<PickedDocument?> pickDocumentFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    withData: true,
  );
  final f = result?.files.singleOrNull;
  final bytes = f?.bytes;
  if (f == null || bytes == null) return null;
  final ext = (f.extension ?? '').toLowerCase();
  return (
    bytes: bytes,
    name: f.name,
    contentType: ext == 'pdf' ? 'application/pdf' : 'image/${ext == 'jpg' ? 'jpeg' : ext}',
  );
}

/// The chauffeur's verification documents: what is missing, in review,
/// approved or expiring, with upload and replace.
class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key, this.repository, this.pickFile, this.pickExpiry, this.now});

  final DriverDocumentsRepository? repository;

  /// Test seams for the file and date pickers.
  final Future<PickedDocument?> Function()? pickFile;
  final Future<DateTime?> Function(BuildContext context, DriverDocType type)? pickExpiry;
  final DateTime? now;

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  late final DriverDocumentsRepository _repo = widget.repository ?? sl<DriverDocumentsRepository>();
  Stream<Map<DriverDocType, DriverDocument>>? _stream;
  String? _uid;
  DriverDocType? _uploading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthBloc>().state;
    final uid = auth is AuthAuthenticated ? auth.user.id : null;
    if (uid != null && uid != _uid) {
      _uid = uid;
      _stream = _repo.watch(uid);
    }
  }

  Future<DateTime?> _defaultExpiryPicker(BuildContext context, DriverDocType type) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      helpText: context.l10n.docExpiryPickerTitle(type.localizedName(context.l10n)),
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 15),
    );
  }

  Future<void> _upload(DriverDocType type) async {
    final l = context.l10n;
    final uid = _uid;
    if (uid == null) return;
    final file = await (widget.pickFile ?? pickDocumentFile)();
    if (file == null || !mounted) return;
    DateTime? expiry;
    if (type.expires) {
      expiry = await (widget.pickExpiry ?? _defaultExpiryPicker)(context, type);
      if (expiry == null || !mounted) return;
    }
    setState(() => _uploading = type);
    final error = await _repo.upload(
      driverId: uid,
      type: type,
      bytes: file.bytes,
      fileName: file.name,
      contentType: file.contentType,
      expiresAt: expiry,
    );
    if (!mounted) return;
    setState(() => _uploading = null);
    showLuxSnackbar(
      context,
      error == null ? l.docUploaded : localizedDocError(l, error),
      isError: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = widget.now ?? DateTime.now();
    return Scaffold(
      backgroundColor: LuxColors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          tooltip: l.commonBack,
          onPressed: () => context.canPop() ? context.pop() : context.go('/driver'),
        ),
        title: Text(l.docTitle),
      ),
      body: StreamBuilder<Map<DriverDocType, DriverDocument>>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: LuxColors.accent));
          }
          final summary = DocumentsSummary(snap.data ?? const {}, now);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(LuxSpacing.lg),
                children: [
                  _SummaryCard(summary: summary),
                  const SizedBox(height: LuxSpacing.lg),
                  for (final d in summary.documents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                      child: _DocumentCard(
                        doc: d,
                        now: now,
                        uploading: _uploading == d.type,
                        onUpload: _uploading == null ? () => _upload(d.type) : null,
                      ),
                    ),
                  const SizedBox(height: LuxSpacing.sm),
                  Text(l.docPrivacyNote, style: LuxTypography.caption),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
  final DocumentsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = summary.documents.length;
    final complete = summary.complete;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(complete ? Icons.verified_rounded : Icons.shield_outlined,
                color: complete ? LuxColors.success : LuxColors.accent),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(
              child: Text(complete ? l.docSummaryVerified : l.docSummaryTitle,
                  style: LuxTypography.titleLarge),
            ),
          ]),
          const SizedBox(height: LuxSpacing.sm),
          Text(
            complete
                ? l.docSummaryVerifiedBody
                : l.docSummaryBody,
            style: LuxTypography.bodyMedium,
          ),
          const SizedBox(height: LuxSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : summary.approved / total,
              minHeight: 6,
              color: complete ? LuxColors.success : LuxColors.accent,
              backgroundColor: LuxColors.white.withOpacity(0.08),
            ),
          ),
          const SizedBox(height: LuxSpacing.sm),
          Text(
            [
              l.docApprovedCount(summary.approved, total),
              if (summary.pending > 0) l.docPendingCount(summary.pending),
              if (summary.toUpload > 0) l.docToUploadCount(summary.toUpload),
            ].join(' · '),
            style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc, required this.now, required this.uploading, required this.onUpload});
  final DriverDocument doc;
  final DateTime now;
  final bool uploading;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = doc.statusAt(now);
    final expiring = doc.expiringSoon(now);
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(doc.type.icon, color: LuxColors.accent),
              const SizedBox(width: LuxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.type.localizedName(l), style: LuxTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(doc.type.localizedHint(l), style: LuxTypography.caption),
                  ],
                ),
              ),
              const SizedBox(width: LuxSpacing.sm),
              DocStatusChip(status: status, expiring: expiring),
            ],
          ),
          if (doc.expiresAt != null) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(
              status == DriverDocStatus.expired
                  ? l.docExpiredOn(DateFormat.yMMMd().format(doc.expiresAt!))
                  : l.docExpiresOn(DateFormat.yMMMd().format(doc.expiresAt!)),
              style: LuxTypography.caption.copyWith(
                  color: expiring || status == DriverDocStatus.expired
                      ? LuxColors.warning
                      : LuxColors.whiteSecondary),
            ),
          ],
          if (status == DriverDocStatus.rejected && (doc.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: LuxSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(LuxSpacing.sm),
              decoration: BoxDecoration(
                color: LuxColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(LuxRadius.sm),
              ),
              child: Text(l.docRejectedReason(doc.rejectionReason!),
                  style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
            ),
          ],
          if (status == DriverDocStatus.pending) ...[
            const SizedBox(height: LuxSpacing.sm),
            Text(l.docPendingHint, style: LuxTypography.caption),
          ],
          const SizedBox(height: LuxSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: uploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: LuxColors.accent),
                  )
                : OutlinedButton.icon(
                    onPressed: onUpload,
                    icon: Icon(status == DriverDocStatus.missing ? Icons.upload_file_rounded : Icons.autorenew_rounded,
                        size: 18),
                    label: Text(status == DriverDocStatus.missing ? l.docUpload : l.docReplace),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Status with icon and label (never color alone).
class DocStatusChip extends StatelessWidget {
  const DocStatusChip({super.key, required this.status, this.expiring = false});
  final DriverDocStatus status;
  final bool expiring;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (IconData icon, Color color, String label) = switch (status) {
      DriverDocStatus.approved when expiring => (Icons.schedule_rounded, LuxColors.warning, l.docStatusExpiring),
      DriverDocStatus.approved => (Icons.check_circle_rounded, LuxColors.success, l.docStatusApproved),
      DriverDocStatus.pending => (Icons.hourglass_top_rounded, LuxColors.info, l.docStatusPending),
      DriverDocStatus.rejected => (Icons.error_outline_rounded, LuxColors.error, l.docStatusRejected),
      DriverDocStatus.expired => (Icons.event_busy_rounded, LuxColors.error, l.docStatusExpired),
      DriverDocStatus.missing => (Icons.radio_button_unchecked_rounded, LuxColors.whiteTertiary, l.docStatusMissing),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: LuxTypography.caption.copyWith(color: LuxColors.white)),
      ]),
    );
  }
}

/// Home banner: what the chauffeur still has to do to receive rides, or
/// which documents expire soon.
class DriverVerificationBanner extends StatelessWidget {
  const DriverVerificationBanner({super.key, required this.driverId, required this.verified, this.repository, this.now});
  final String driverId;
  final bool verified;
  final DriverDocumentsRepository? repository;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (repository == null && !sl.isRegistered<DriverDocumentsRepository>()) return const SizedBox.shrink();
    final repo = repository ?? sl<DriverDocumentsRepository>();
    final l = context.l10n;
    return StreamBuilder<Map<DriverDocType, DriverDocument>>(
      stream: repo.watch(driverId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final s = DocumentsSummary(snap.data!, now ?? DateTime.now());
        final String? message;
        if (!verified) {
          message = s.toUpload > 0 ? l.docBannerToUpload(s.toUpload) : l.docBannerInReview;
        } else if (s.expiringSoon.isNotEmpty) {
          message = l.docBannerExpiring(s.expiringSoon.first.type.localizedName(l));
        } else {
          message = null;
        }
        if (message == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: LuxSpacing.lg),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(LuxRadius.md),
              onTap: () => context.push('/driver/documents'),
              child: LuxCard(
                child: Row(children: [
                  Icon(verified ? Icons.schedule_rounded : Icons.shield_outlined, color: LuxColors.warning),
                  const SizedBox(width: LuxSpacing.md),
                  Expanded(
                    child: Text(message, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: LuxColors.whiteTertiary),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
