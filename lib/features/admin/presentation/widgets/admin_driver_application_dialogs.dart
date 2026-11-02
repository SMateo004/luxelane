import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/widgets/reauth_dialog.dart';
import '../../domain/admin_driver_applications.dart';
import 'admin_shared_widgets.dart';

/// Diálogos del panel de solicitudes de chófer (B2): visor de documentos,
/// rechazo con motivo de lista cerrada, decisión final, autorizar en línea y
/// bitácora de accesos.

/// Botones de al menos 48 px (E9).
const kDrvAppMinTap = Size(48, 48);

ButtonStyle drvAppButtonStyle({Color? color}) => OutlinedButton.styleFrom(
      minimumSize: kDrvAppMinTap,
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.md),
    );

/// Si el servidor pidió identificarse de nuevo, se pide aquí (el diálogo de
/// siempre) y la persona repite la acción.
Future<void> handleDriverAppFailure(
  BuildContext context,
  DriverAppFailure failure,
) async {
  if (failure.needsReauth) {
    await confirmIdentityThenRetry(context);
  } else {
    showLuxSnackbar(context, failure.message, isError: true);
  }
}

/// Abre un enlace en otra pestaña (web) o fuera de la app.
typedef DocLinkLauncher = Future<bool> Function(Uri uri);

Future<bool> _defaultLauncher(Uri uri) => launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

// ─────────────────────────────────────────────────────────────────────────────
// Visor
// ─────────────────────────────────────────────────────────────────────────────

/// Pide la URL firmada (adminGetDocumentUrl) al abrirse. La imagen va con
/// Image.network (sin caché en disco; el objeto ya lleva no-store) y se
/// saca de la caché en memoria al cerrar; el PDF se abre en otra pestaña.
/// La URL nunca se muestra como texto ni se imprime.
class DriverDocumentViewer extends StatefulWidget {
  const DriverDocumentViewer({
    super.key,
    required this.repository,
    required this.driverId,
    required this.type,
    required this.version,
    this.launcher,
  });

  final DriverApplicationsRepository repository;
  final String driverId;
  final DriverDocType type;
  final int version;
  final DocLinkLauncher? launcher;

  static Future<void> show(
    BuildContext context, {
    required DriverApplicationsRepository repository,
    required String driverId,
    required DriverDocType type,
    required int version,
    DocLinkLauncher? launcher,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) => DriverDocumentViewer(
          repository: repository,
          driverId: driverId,
          type: type,
          version: version,
          launcher: launcher,
        ),
      );

  @override
  State<DriverDocumentViewer> createState() => _DriverDocumentViewerState();
}

class _DriverDocumentViewerState extends State<DriverDocumentViewer> {
  DocumentLink? _link;
  DriverAppFailure? _failure;
  bool _pdfFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await widget.repository.documentUrl(widget.driverId, widget.type);
    if (!mounted) return;
    r.fold(
      (f) {
        setState(() => _failure = f);
        if (f.needsReauth) confirmIdentityThenRetry(context);
      },
      (link) => setState(() => _link = link),
    );
  }

  @override
  void dispose() {
    // Fuera de la caché en memoria y del estado al cerrar.
    final link = _link;
    if (link != null && !link.isPdf) NetworkImage(link.url).evict();
    _link = null;
    super.dispose();
  }

  Future<void> _openPdf() async {
    final link = _link;
    if (link == null) return;
    var ok = false;
    try {
      ok = await (widget.launcher ?? _defaultLauncher)(Uri.parse(link.url));
    } catch (_) {
      ok = false;
    }
    if (mounted && !ok) setState(() => _pdfFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      key: const ValueKey('drvapp-viewer'),
      insetPadding: const EdgeInsets.all(LuxSpacing.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.adminDrvAppAccessLogEntry(
                        widget.type.label,
                        '${widget.version}',
                      ),
                      style: LuxTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('drvapp-viewer-close'),
                    tooltip: t.adminDrvAppClose,
                    constraints: BoxConstraints.tight(kDrvAppMinTap),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: LuxSpacing.sm),
              _Notice(
                icon: Icons.timer_outlined,
                text: '${t.adminDrvAppViewerExpiry} '
                    '${t.adminDrvAppViewerLogged}',
              ),
              const SizedBox(height: LuxSpacing.md),
              Flexible(child: _content(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final t = context.l10n;
    final failure = _failure;
    if (failure != null) {
      return _Message(
        key: const ValueKey('drvapp-viewer-error'),
        text: failure.message,
        error: true,
      );
    }
    final link = _link;
    if (link == null) {
      return Semantics(
        liveRegion: true,
        label: t.adminDrvAppViewerLoading,
        child: const Padding(
          padding: EdgeInsets.all(LuxSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (link.isPdf) {
      return SingleChildScrollView(
        child: Column(
          key: const ValueKey('drvapp-viewer-pdf'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: LuxSpacing.xxl,
              color: LuxColors.sapphire,
            ),
            const SizedBox(height: LuxSpacing.sm),
            Text(t.adminDrvAppViewerPdf, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            FilledButton.icon(
              key: const ValueKey('drvapp-viewer-open-pdf'),
              style: FilledButton.styleFrom(minimumSize: kDrvAppMinTap),
              onPressed: _openPdf,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(t.adminDrvAppViewerOpenPdf),
            ),
            if (_pdfFailed) ...[
              const SizedBox(height: LuxSpacing.md),
              _Message(text: t.adminDrvAppViewerPdfError, error: true),
            ],
          ],
        ),
      );
    }
    return InteractiveViewer(
      key: const ValueKey('drvapp-viewer-image'),
      maxScale: 5,
      child: Image.network(
        link.url,
        fit: BoxFit.contain,
        semanticLabel: t.adminDrvAppViewerImageLabel(widget.type.label),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Padding(
                padding: EdgeInsets.all(LuxSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (context, _, __) => _Message(
          key: const ValueKey('drvapp-viewer-image-error'),
          text: t.adminDrvAppViewerImageError,
          error: true,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.sm),
        decoration: BoxDecoration(
          color: LuxColors.sapphireTint,
          borderRadius: BorderRadius.circular(LuxRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: LuxColors.sapphire),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(child: Text(text, style: LuxTypography.bodyMedium)),
          ],
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text, this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: LuxTypography.bodyMedium.copyWith(
              color: error ? LuxColors.error : LuxColors.inkSecondary,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Aprobar / rechazar un documento
// ─────────────────────────────────────────────────────────────────────────────

/// Confirma aprobar un documento. true si se confirmó.
Future<bool> confirmApproveDocument(
  BuildContext context, {
  required DriverDocType type,
  required int version,
}) async {
  final t = context.l10n;
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const ValueKey('drvapp-approve-dialog'),
          title: Text(t.adminDrvAppApproveTitle(type.label)),
          content: Text(
            t.adminDrvAppApproveBody('$version'),
            style: LuxTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: kDrvAppMinTap),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.adminDrvAppCancel),
            ),
            FilledButton(
              key: const ValueKey('drvapp-approve-confirm'),
              style: FilledButton.styleFrom(minimumSize: kDrvAppMinTap),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.adminDrvAppApproveConfirm),
            ),
          ],
        ),
      ) ??
      false;
}

/// Rechazo de un documento: motivo de la lista cerrada (obligatorio) y una
/// nota opcional que verá el chófer. [onSubmit] hace la llamada y devuelve
/// el fallo, que se muestra en el propio diálogo. true si se rechazó.
class RejectDocumentDialog extends StatefulWidget {
  const RejectDocumentDialog({
    super.key,
    required this.type,
    required this.onSubmit,
  });

  final DriverDocType type;
  final Future<DriverAppFailure?> Function(DocRejectReason reason, String note)
      onSubmit;

  static Future<bool> show(
    BuildContext context, {
    required DriverDocType type,
    required Future<DriverAppFailure?> Function(
      DocRejectReason reason,
      String note,
    ) onSubmit,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => RejectDocumentDialog(type: type, onSubmit: onSubmit),
      ) ??
      false;

  @override
  State<RejectDocumentDialog> createState() => _RejectDocumentDialogState();
}

class _RejectDocumentDialogState extends State<RejectDocumentDialog> {
  final _note = TextEditingController();
  DocRejectReason? _reason;
  bool _tried = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    final reason = _reason;
    if (reason == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final f = await widget.onSubmit(reason, _note.text.trim());
    if (!mounted) return;
    if (f == null) return Navigator.of(context).pop(true);
    setState(() {
      _busy = false;
      _error = f.needsReauth ? null : f.message;
    });
    if (f.needsReauth) await confirmIdentityThenRetry(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final missing = _tried && _reason == null;
    return AlertDialog(
      key: const ValueKey('drvapp-reject-dialog'),
      title: Text(t.adminDrvAppRejectTitle(widget.type.label)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<DocRejectReason>(
                key: const ValueKey('drvapp-reject-reason'),
                value: _reason,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: t.adminDrvAppRejectReasonLabel,
                  hintText: t.adminDrvAppRejectReasonHint,
                  errorText: missing ? t.adminDrvAppRejectReasonRequired : null,
                ),
                items: [
                  for (final r in DocRejectReason.values)
                    DropdownMenuItem(
                      value: r,
                      child: Text(r.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _busy ? null : (r) => setState(() => _reason = r),
              ),
              const SizedBox(height: LuxSpacing.md),
              TextField(
                key: const ValueKey('drvapp-reject-note'),
                controller: _note,
                enabled: !_busy,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: t.adminDrvAppRejectNoteLabel,
                ),
              ),
              if (_error != null)
                _Message(
                  key: const ValueKey('drvapp-reject-error'),
                  text: _error!,
                  error: true,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: kDrvAppMinTap),
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(t.adminDrvAppCancel),
        ),
        FilledButton(
          key: const ValueKey('drvapp-reject-confirm'),
          style: FilledButton.styleFrom(
            minimumSize: kDrvAppMinTap,
            backgroundColor: LuxColors.error,
          ),
          onPressed: _busy ? null : _submit,
          child: Text(t.adminDrvAppRejectConfirm),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motivo (decisión final y autorizar en línea)
// ─────────────────────────────────────────────────────────────────────────────

/// Pide un motivo de 10 a 500 caracteres y, si hay [choices], una opción.
/// [onSubmit] hace la llamada; un fallo se muestra en el propio diálogo
/// (p. ej. documents_not_approved) sin perder lo escrito. Devuelve la opción
/// elegida si se completó, null si se canceló.
class DriverAppReasonDialog<T extends Object> extends StatefulWidget {
  const DriverAppReasonDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onSubmit,
    this.choices = const [],
    this.initial,
    this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final List<(T, String)> choices;
  final T? initial;

  /// Qué opciones pintan el botón en rojo.
  final bool Function(T? choice)? destructive;
  final Future<DriverAppFailure?> Function(T? choice, String reason) onSubmit;

  @override
  State<DriverAppReasonDialog<T>> createState() =>
      _DriverAppReasonDialogState<T>();
}

class _DriverAppReasonDialogState<T extends Object>
    extends State<DriverAppReasonDialog<T>> {
  final _reason = TextEditingController();
  T? _choice;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _choice = widget.initial;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int get _len => _reason.text.trim().length;
  bool get _valid =>
      _len >= kDriverAppReasonMin &&
      _len <= kDriverAppReasonMax &&
      (widget.choices.isEmpty || _choice != null);

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final f = await widget.onSubmit(_choice, _reason.text.trim());
    if (!mounted) return;
    if (f == null) {
      return Navigator.of(context).pop(_choice ?? true);
    }
    setState(() {
      _busy = false;
      _error = f.needsReauth ? null : f.message;
    });
    if (f.needsReauth) await confirmIdentityThenRetry(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final short = _len > 0 && _len < kDriverAppReasonMin;
    final red = widget.destructive?.call(_choice) ?? false;
    return AlertDialog(
      key: const ValueKey('drvapp-reason-dialog'),
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.message, style: LuxTypography.bodyMedium),
              if (widget.choices.isNotEmpty) ...[
                const SizedBox(height: LuxSpacing.sm),
                for (final (value, label) in widget.choices)
                  RadioListTile<T>(
                    key: ValueKey(
                      'drvapp-choice-${value is DriverAppDecision ? value.wire : value}',
                    ),
                    value: value,
                    groupValue: _choice,
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: LuxTypography.bodyMedium),
                    onChanged:
                        _busy ? null : (v) => setState(() => _choice = v),
                  ),
              ],
              const SizedBox(height: LuxSpacing.sm),
              TextField(
                key: const ValueKey('drvapp-reason-field'),
                controller: _reason,
                enabled: !_busy,
                autofocus: widget.choices.isEmpty,
                minLines: 2,
                maxLines: 4,
                maxLength: kDriverAppReasonMax,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: t.adminDrvAppDecisionReasonLabel,
                  hintText: t.adminDrvAppDecisionReasonHint(
                    '$kDriverAppReasonMin',
                    '$kDriverAppReasonMax',
                  ),
                  errorText: short
                      ? t.adminDrvAppDecisionReasonShort('$kDriverAppReasonMin')
                      : null,
                ),
              ),
              if (_error != null)
                _Message(
                  key: const ValueKey('drvapp-reason-error'),
                  text: _error!,
                  error: true,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: kDrvAppMinTap),
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(t.adminDrvAppCancel),
        ),
        FilledButton(
          key: const ValueKey('drvapp-reason-confirm'),
          style: FilledButton.styleFrom(
            minimumSize: kDrvAppMinTap,
            backgroundColor: red ? LuxColors.error : LuxColors.sapphire,
          ),
          onPressed: _busy || !_valid ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Decisión final (adminDecideApplication). La opción elegida, o null.
Future<DriverAppDecision?> showDriverAppDecisionDialog(
  BuildContext context, {
  required Future<DriverAppFailure?> Function(
    DriverAppDecision decision,
    String reason,
  ) onSubmit,
}) {
  final t = context.l10n;
  return showDialog<Object>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DriverAppReasonDialog<DriverAppDecision>(
      title: t.adminDrvAppDecisionTitle,
      message: t.adminDrvAppDecisionBody,
      confirmLabel: t.adminDrvAppDecisionConfirm,
      choices: [
        (DriverAppDecision.approve, t.adminDrvAppDecisionApprove),
        (DriverAppDecision.needsChanges, t.adminDrvAppDecisionNeedsChanges),
        (DriverAppDecision.reject, t.adminDrvAppDecisionReject),
      ],
      destructive: (c) => c == DriverAppDecision.reject,
      onSubmit: (c, reason) => onSubmit(c!, reason),
    ),
  ).then((v) => v is DriverAppDecision ? v : null);
}

/// Autorizar en línea con documentos vencidos (adminAllowDriverOnline).
/// true si se autorizó.
Future<bool> showAllowOnlineDialog(
  BuildContext context, {
  required String name,
  required Future<DriverAppFailure?> Function(String reason) onSubmit,
}) {
  final t = context.l10n;
  return showDialog<Object>(
    context: context,
    barrierDismissible: false,
    builder: (_) => DriverAppReasonDialog<bool>(
      title: t.adminDrvAppAllowOnlineTitle,
      message: t.adminDrvAppAllowOnlineBody(name),
      confirmLabel: t.adminDrvAppAllowOnlineConfirm,
      onSubmit: (_, reason) => onSubmit(reason),
    ),
  ).then((v) => v != null);
}

// ─────────────────────────────────────────────────────────────────────────────
// Bitácora de accesos
// ─────────────────────────────────────────────────────────────────────────────

/// Quién abrió cada documento de la solicitud y cuándo. Nunca la URL ni la
/// ruta (tampoco están en driverDocAccessLogs).
class DocAccessLogDialog extends StatefulWidget {
  const DocAccessLogDialog({
    super.key,
    required this.repository,
    required this.driverId,
  });

  final DriverApplicationsRepository repository;
  final String driverId;

  static Future<void> show(
    BuildContext context, {
    required DriverApplicationsRepository repository,
    required String driverId,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) =>
            DocAccessLogDialog(repository: repository, driverId: driverId),
      );

  @override
  State<DocAccessLogDialog> createState() => _DocAccessLogDialogState();
}

class _DocAccessLogDialogState extends State<DocAccessLogDialog> {
  late Future<Either<DriverAppFailure, List<DocAccessEntry>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.accessLog(widget.driverId);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      key: const ValueKey('drvapp-access-log'),
      insetPadding: const EdgeInsets.all(LuxSpacing.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.adminDrvAppAccessLog,
                      style: LuxTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: t.adminDrvAppClose,
                    constraints: BoxConstraints.tight(kDrvAppMinTap),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(t.adminDrvAppAccessLogHint, style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.sm),
              Flexible(
                child: FutureBuilder<
                    Either<DriverAppFailure, List<DocAccessEntry>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(LuxSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return snap.data!.fold(
                      (f) => _Message(
                        key: const ValueKey('drvapp-access-log-error'),
                        text: '${t.adminDrvAppAccessLogError} ${f.message}',
                        error: true,
                      ),
                      (items) => items.isEmpty
                          ? _Message(
                              key: const ValueKey('drvapp-access-log-empty'),
                              text: t.adminDrvAppAccessLogEmpty,
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const LuxDivider(),
                              itemBuilder: (context, i) =>
                                  _AccessRow(entry: items[i]),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.entry});
  final DocAccessEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final who =
        entry.adminEmail ?? t.adminDrvAppUnknownAdmin(shortId(entry.adminId));
    final doc = entry.type?.label ?? entry.typeWire ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility_outlined, color: LuxColors.sapphire),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.adminDrvAppAccessLogEntry(doc, '${entry.version ?? '–'}'),
                  style: LuxTypography.titleMedium,
                ),
                Text(
                  t.adminDrvAppAccessLogWho(
                    who,
                    entry.at == null ? '–' : adminDate(entry.at!),
                  ),
                  style: LuxTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
