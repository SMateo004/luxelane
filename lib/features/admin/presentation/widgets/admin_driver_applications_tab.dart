import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/driver_applications_repository.dart';
import '../../domain/admin_driver_applications.dart';
import 'admin_driver_application_dialogs.dart';
import 'admin_shared_widgets.dart';

/// Solicitudes de chófer (B2): bandeja por estado, detalle con datos,
/// vehículo y documentos, revisión por documento, decisión final, bitácora
/// de accesos y vencimientos próximos.
class DriverApplicationsTab extends StatefulWidget {
  const DriverApplicationsTab({super.key, this.repository, this.launcher});

  /// Para los tests; por omisión, Firestore y las callables.
  final DriverApplicationsRepository? repository;
  final DocLinkLauncher? launcher;

  @override
  State<DriverApplicationsTab> createState() => _DriverApplicationsTabState();
}

enum _View { inbox, expiries }

class _DriverApplicationsTabState extends State<DriverApplicationsTab> {
  late final DriverApplicationsRepository _repo = widget.repository ??
      FirebaseDriverApplicationsRepository(firestore: sl(), functions: sl());
  _View _view = _View.inbox;
  DriverAppStatus _status = DriverAppStatus.submitted;
  String? _open;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final open = _open;
    if (open != null) {
      return DriverApplicationDetailView(
        key: ValueKey('drvapp-detail-$open'),
        repository: _repo,
        driverId: open,
        launcher: widget.launcher,
        onBack: () => setState(() => _open = null),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dos pestañas: en Wrap, con texto grande pasan a otra línea en vez
        // de quedar fuera de la pantalla.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md,
            LuxSpacing.md,
            LuxSpacing.md,
            0,
          ),
          child: Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.sm,
            children: [
              SectionChip(
                key: const ValueKey('drvapp-view-inbox'),
                label: t.adminDrvAppTabInbox,
                selected: _view == _View.inbox,
                onTap: () => setState(() => _view = _View.inbox),
              ),
              SectionChip(
                key: const ValueKey('drvapp-view-expiries'),
                label: t.adminDrvAppTabExpiries,
                selected: _view == _View.expiries,
                onTap: () => setState(() => _view = _View.expiries),
              ),
            ],
          ),
        ),
        Expanded(
          child: _view == _View.inbox
              ? DriverAppInboxView(
                  repository: _repo,
                  status: _status,
                  onStatus: (s) => setState(() => _status = s),
                  onOpen: (id) => setState(() => _open = id),
                )
              : DocExpiriesView(
                  repository: _repo,
                  onOpen: (id) => setState(() => _open = id),
                ),
        ),
      ],
    );
  }
}

String _nameOf(BuildContext context, String? name, String? email) =>
    name ?? email ?? context.l10n.adminDrvAppNoName;

Color appStatusColor(DriverAppStatus s) => switch (s) {
      DriverAppStatus.approved => LuxColors.success,
      DriverAppStatus.rejected => LuxColors.error,
      DriverAppStatus.needsChanges => LuxColors.warning,
      DriverAppStatus.submitted ||
      DriverAppStatus.inReview =>
        LuxColors.sapphire,
      DriverAppStatus.draft => LuxColors.inkTertiary,
    };

Color docStatusColor(DriverDocStatus s) => switch (s) {
      DriverDocStatus.approved => LuxColors.success,
      DriverDocStatus.rejected || DriverDocStatus.expired => LuxColors.error,
      DriverDocStatus.uploaded => LuxColors.sapphire,
      DriverDocStatus.pendingUpload => LuxColors.inkTertiary,
    };

/// Estados en la bandeja: primero lo que espera revisión.
const _inboxStatuses = [
  DriverAppStatus.submitted,
  DriverAppStatus.inReview,
  DriverAppStatus.needsChanges,
  DriverAppStatus.approved,
  DriverAppStatus.rejected,
  DriverAppStatus.draft,
];

/// Mensaje centrado con reintento (errores) o sin él (vacío).
class _StateMessage extends StatelessWidget {
  const _StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: LuxSpacing.xl,
                  color: onRetry != null ? LuxColors.error : LuxColors.sapphire,
                ),
                const SizedBox(height: LuxSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: LuxTypography.titleLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: LuxSpacing.sm),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: LuxTypography.bodyMedium,
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: LuxSpacing.md),
                  OutlinedButton.icon(
                    key: const ValueKey('drvapp-retry'),
                    style: drvAppButtonStyle(),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.adminDrvAppRetry),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bandeja
// ─────────────────────────────────────────────────────────────────────────────

class DriverAppInboxView extends StatefulWidget {
  const DriverAppInboxView({
    super.key,
    required this.repository,
    required this.status,
    required this.onStatus,
    required this.onOpen,
  });

  final DriverApplicationsRepository repository;
  final DriverAppStatus status;
  final ValueChanged<DriverAppStatus> onStatus;
  final ValueChanged<String> onOpen;

  @override
  State<DriverAppInboxView> createState() => _DriverAppInboxViewState();
}

class _DriverAppInboxViewState extends State<DriverAppInboxView> {
  bool _loading = true;
  DriverAppInbox? _inbox;
  DriverAppFailure? _failure;
  int _req = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DriverAppInboxView old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _load();
  }

  Future<void> _load() async {
    final req = ++_req;
    setState(() {
      _loading = true;
      _failure = null;
    });
    final r = await widget.repository.inbox(widget.status);
    if (!mounted || req != _req) return;
    setState(() {
      _loading = false;
      r.fold((f) {
        _failure = f;
        _inbox = null;
      }, (i) => _inbox = i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: t.adminDrvAppStatusFilter,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: LuxSpacing.md,
              vertical: LuxSpacing.sm,
            ),
            child: Row(
              children: [
                for (final s in _inboxStatuses)
                  Padding(
                    padding: const EdgeInsets.only(right: LuxSpacing.sm),
                    child: SectionChip(
                      key: ValueKey('drvapp-status-${s.wire}'),
                      label: s.label,
                      selected: widget.status == s,
                      onTap: () => widget.onStatus(s),
                    ),
                  ),
                IconButton(
                  key: const ValueKey('drvapp-inbox-reload'),
                  tooltip: t.adminDrvAppReload,
                  constraints: BoxConstraints.tight(kDrvAppMinTap),
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final t = context.l10n;
    if (_loading) return const LuxSkeletonList(count: 3);
    final failure = _failure;
    if (failure != null) {
      return _StateMessage(
        key: const ValueKey('drvapp-inbox-error'),
        icon: Icons.cloud_off_rounded,
        title: t.adminDrvAppInboxError,
        subtitle: failure.message,
        onRetry: _load,
      );
    }
    final inbox = _inbox!;
    if (inbox.items.isEmpty) {
      return _StateMessage(
        key: const ValueKey('drvapp-inbox-empty'),
        icon: Icons.inbox_outlined,
        title: t.adminDrvAppInboxEmpty,
        subtitle: t.adminDrvAppInboxEmptyHint,
      );
    }
    return ListView(
      key: const ValueKey('drvapp-inbox-list'),
      padding: const EdgeInsets.all(LuxSpacing.md),
      children: [
        if (inbox.truncated)
          Padding(
            padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
            child: Text(
              t.adminDrvAppInboxTruncated('$kDriverAppInboxLimit'),
              style: LuxTypography.caption,
            ),
          ),
        for (final a in inbox.items)
          _InboxRow(app: a, onOpen: () => widget.onOpen(a.driverId)),
      ],
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.app, required this.onOpen});
  final DriverAppSummary app;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final name = _nameOf(context, app.name, app.email);
    final when = app.submittedAt != null
        ? t.adminDrvAppSubmittedAt(adminDate(app.submittedAt!))
        : app.updatedAt != null
            ? t.adminDrvAppUpdatedAt(adminDate(app.updatedAt!))
            : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
      child: Semantics(
        button: true,
        label: t.adminDrvAppOpen(name),
        excludeSemantics: true,
        child: LuxCard(
          key: ValueKey('drvapp-row-${app.driverId}'),
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: LuxColors.sapphire),
                const SizedBox(width: LuxSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: LuxTypography.titleMedium),
                      if (app.email != null && app.name != null)
                        Text(app.email!, style: LuxTypography.caption),
                      const SizedBox(height: LuxSpacing.xs),
                      Wrap(
                        spacing: LuxSpacing.sm,
                        runSpacing: LuxSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AdminTag(
                            app.status.label,
                            color: appStatusColor(app.status),
                          ),
                          if (when != null)
                            Text(when, style: LuxTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: LuxColors.inkTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detalle
// ─────────────────────────────────────────────────────────────────────────────

class DriverApplicationDetailView extends StatefulWidget {
  const DriverApplicationDetailView({
    super.key,
    required this.repository,
    required this.driverId,
    required this.onBack,
    this.launcher,
  });

  final DriverApplicationsRepository repository;
  final String driverId;
  final VoidCallback onBack;
  final DocLinkLauncher? launcher;

  @override
  State<DriverApplicationDetailView> createState() =>
      _DriverApplicationDetailViewState();
}

class _DriverApplicationDetailViewState
    extends State<DriverApplicationDetailView> {
  bool _loading = true;
  DriverAppDetail? _detail;
  DriverAppFailure? _failure;

  /// Documento con una revisión en curso.
  DriverDocType? _busy;

  DriverApplicationsRepository get _repo => widget.repository;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _detail == null;
      _failure = null;
    });
    final r = await _repo.detail(widget.driverId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      r.fold((f) => _failure = f, (d) => _detail = d);
    });
  }

  Future<void> _approve(DriverDocRow row) async {
    if (!await confirmApproveDocument(
      context,
      type: row.type,
      version: row.version,
    )) {
      return;
    }
    setState(() => _busy = row.type);
    final r = await _repo.reviewDocument(
      driverId: widget.driverId,
      type: row.type,
      version: row.version,
      approve: true,
    );
    if (!mounted) return;
    setState(() => _busy = null);
    await r.fold(
      (f) => handleDriverAppFailure(context, f),
      (_) async {
        showLuxSnackbar(context, context.l10n.adminDrvAppDocApproved);
        await _load();
      },
    );
  }

  Future<void> _reject(DriverDocRow row) async {
    final done = await RejectDocumentDialog.show(
      context,
      type: row.type,
      onSubmit: (reason, note) async {
        final r = await _repo.reviewDocument(
          driverId: widget.driverId,
          type: row.type,
          version: row.version,
          approve: false,
          rejectReason: reason,
          note: note,
        );
        return r.fold((f) => f, (_) => null);
      },
    );
    if (!mounted || !done) return;
    showLuxSnackbar(context, context.l10n.adminDrvAppDocRejected);
    await _load();
  }

  Future<void> _decide() async {
    final d = await showDriverAppDecisionDialog(
      context,
      onSubmit: (decision, reason) async {
        final r = await _repo.decide(
          driverId: widget.driverId,
          decision: decision,
          reason: reason,
        );
        return r.fold((f) => f, (_) => null);
      },
    );
    if (!mounted || d == null) return;
    showLuxSnackbar(
      context,
      context.l10n.adminDrvAppDecisionDone(d.result.label),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final back = Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const ValueKey('drvapp-back'),
        style: TextButton.styleFrom(minimumSize: kDrvAppMinTap),
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(t.adminDrvAppBack),
      ),
    );
    if (_loading) {
      return Column(
        children: [
          Padding(padding: const EdgeInsets.all(LuxSpacing.sm), child: back),
          const Expanded(child: LuxSkeletonList(count: 3)),
        ],
      );
    }
    final detail = _detail;
    if (detail == null) {
      return Column(
        children: [
          Padding(padding: const EdgeInsets.all(LuxSpacing.sm), child: back),
          Expanded(
            child: _StateMessage(
              key: const ValueKey('drvapp-detail-error'),
              icon: Icons.cloud_off_rounded,
              title: t.adminDrvAppDetailError,
              subtitle: _failure?.message,
              onRetry: _load,
            ),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final personal = _PersonalCard(personal: detail.personal);
        final vehicle = _VehicleCard(detail: detail);
        return ListView(
          key: const ValueKey('drvapp-detail'),
          padding: const EdgeInsets.all(LuxSpacing.md),
          children: [
            back,
            const SizedBox(height: LuxSpacing.sm),
            _Header(
              detail: detail,
              onDecide: _decide,
              onAccessLog: () => DocAccessLogDialog.show(
                context,
                repository: _repo,
                driverId: widget.driverId,
              ),
            ),
            if (!detail.requirementsConfigured) ...[
              const SizedBox(height: LuxSpacing.md),
              const _RequirementsMissingBanner(),
            ],
            const SizedBox(height: LuxSpacing.md),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: personal),
                    const SizedBox(width: LuxSpacing.md),
                    Expanded(child: vehicle),
                  ],
                ),
              )
            else ...[
              personal,
              const SizedBox(height: LuxSpacing.md),
              vehicle,
            ],
            const SizedBox(height: LuxSpacing.lg),
            SectionHeader(title: t.adminDrvAppDocsTitle),
            const SizedBox(height: LuxSpacing.sm),
            for (final row in detail.rows)
              _DocRowCard(
                row: row,
                busy: _busy == row.type,
                onView: () => DriverDocumentViewer.show(
                  context,
                  repository: _repo,
                  driverId: widget.driverId,
                  type: row.type,
                  version: row.version,
                  launcher: widget.launcher,
                ),
                onApprove: () => _approve(row),
                onReject: () => _reject(row),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.detail,
    required this.onDecide,
    required this.onAccessLog,
  });

  final DriverAppDetail detail;
  final VoidCallback onDecide;
  final VoidCallback onAccessLog;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nameOf(context, detail.name, detail.email),
            style: LuxTypography.headlineMedium,
          ),
          if (detail.email != null)
            Text(detail.email!, style: LuxTypography.bodyMedium),
          const SizedBox(height: LuxSpacing.sm),
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminTag(
                detail.status.label,
                color: appStatusColor(detail.status),
              ),
              if (detail.submittedAt != null)
                Text(
                  t.adminDrvAppSubmittedAt(adminDate(detail.submittedAt!)),
                  style: LuxTypography.caption,
                ),
              if (detail.docsBlocked)
                AdminTag(t.adminDrvAppBlocked, color: LuxColors.error),
            ],
          ),
          if (detail.pendingVehicleId != null) ...[
            const SizedBox(height: LuxSpacing.xs),
            Text(t.adminDrvAppPendingVehicle, style: LuxTypography.caption),
          ],
          const SizedBox(height: LuxSpacing.md),
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.sm,
            children: [
              FilledButton.icon(
                key: const ValueKey('drvapp-decide'),
                style: FilledButton.styleFrom(minimumSize: kDrvAppMinTap),
                onPressed: detail.decidable ? onDecide : null,
                icon: const Icon(Icons.gavel_rounded),
                label: Text(t.adminDrvAppDecide),
              ),
              OutlinedButton.icon(
                key: const ValueKey('drvapp-access-log-open'),
                style: drvAppButtonStyle(),
                onPressed: onAccessLog,
                icon: const Icon(Icons.history_rounded),
                label: Text(t.adminDrvAppAccessLog),
              ),
            ],
          ),
          if (!detail.decidable) ...[
            const SizedBox(height: LuxSpacing.xs),
            Text(
              t.adminDrvAppDecisionNotDecidable,
              style: LuxTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _RequirementsMissingBanner extends StatelessWidget {
  const _RequirementsMissingBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Semantics(
      key: const ValueKey('drvapp-requirements-missing'),
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: LuxColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          border: Border.all(color: LuxColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: LuxColors.error),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.adminDrvAppRequirementsMissing,
                    style: LuxTypography.titleMedium.copyWith(
                      color: LuxColors.error,
                    ),
                  ),
                  const SizedBox(height: LuxSpacing.xs),
                  Text(
                    t.adminDrvAppRequirementsMissingBody,
                    style: LuxTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);
  final String label;
  final String value;

  /// Etiqueta arriba y valor debajo: con texto grande no se corta.
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LuxSpacing.xs),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: LuxTypography.caption),
              Text(value, style: LuxTypography.titleMedium),
            ],
          ),
        ),
      );
}

class _PersonalCard extends StatelessWidget {
  const _PersonalCard({required this.personal});
  final DriverPersonalData? personal;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final p = personal;
    return LuxCard(
      key: const ValueKey('drvapp-personal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminDrvAppPersonalTitle, style: LuxTypography.titleLarge),
          const SizedBox(height: LuxSpacing.sm),
          if (p == null)
            Text(t.adminDrvAppPersonalMissing, style: LuxTypography.bodyMedium)
          else ...[
            _Field(t.adminDrvAppFullName, p.fullName),
            _Field(t.adminDrvAppNationalId, p.nationalIdNumber),
            _Field(t.adminDrvAppLicenseNumber, p.licenseNumber),
            _Field(
              t.adminDrvAppLicenseExpiry,
              DateFormat('dd/MM/yyyy').format(p.licenseExpiry),
            ),
          ],
        ],
      ),
    );
  }
}

String _classLabel(String wire) =>
    VehicleClass.values.where((c) => c.name == wire).firstOrNull?.label ?? wire;

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.detail});
  final DriverAppDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final v = detail.vehicle;
    return LuxCard(
      key: const ValueKey('drvapp-vehicle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminDrvAppVehicleTitle, style: LuxTypography.titleLarge),
          const SizedBox(height: LuxSpacing.sm),
          if (v == null)
            Text(t.adminDrvAppVehicleMissing, style: LuxTypography.bodyMedium)
          else ...[
            _Field(t.adminDrvAppMake, v.make),
            _Field(t.adminDrvAppModel, v.model),
            _Field(t.adminDrvAppYear, '${v.year}'),
            _Field(t.adminDrvAppColor, v.colorLabel),
            _Field(t.adminDrvAppPlate, v.plate),
            _Field(t.adminDrvAppBodyType, v.bodyType.label),
            _Field(t.adminDrvAppPassengers, '${v.passengers}'),
            _Field(t.adminDrvAppClass, _classLabel(v.vehicleClass)),
          ],
        ],
      ),
    );
  }
}

class _DocRowCard extends StatelessWidget {
  const _DocRowCard({
    required this.row,
    required this.busy,
    required this.onView,
    required this.onApprove,
    required this.onReject,
  });

  final DriverDocRow row;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final doc = row.document;
    final req = row.requirement;
    final exp = doc?.expiresAt;
    final label = row.type.label;
    final facts = <String>[
      req == null
          ? t.adminDrvAppNotRequested
          : req.required
              ? t.adminDrvAppRequired
              : t.adminDrvAppOptional,
      if (row.version > 0) t.adminDrvAppDocVersion('${row.version}'),
      if (exp != null)
        exp.isBefore(DateTime.now())
            ? t.adminDrvAppDocExpired(DateFormat('dd/MM/yyyy').format(exp))
            : t.adminDrvAppDocExpires(DateFormat('dd/MM/yyyy').format(exp))
      else if ((req?.expires ?? false) && row.version > 0)
        t.adminDrvAppDocExpiryMissing,
    ];
    return Padding(
      key: ValueKey('drvapp-doc-${row.type.wire}'),
      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
      child: LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(label, style: LuxTypography.titleMedium),
                AdminTag(
                  row.version == 0 && doc == null
                      ? t.adminDrvAppDocNotUploaded
                      : row.status.label,
                  color: docStatusColor(row.status),
                ),
              ],
            ),
            const SizedBox(height: LuxSpacing.xs),
            Text(facts.join(' · '), style: LuxTypography.caption),
            if (row.status == DriverDocStatus.rejected &&
                doc?.rejectReason != null)
              Text(
                t.adminDrvAppDocRejectReason(doc!.rejectReason!.label),
                style: LuxTypography.caption.copyWith(color: LuxColors.error),
              ),
            if (row.status == DriverDocStatus.rejected &&
                doc?.rejectNote != null)
              Text(
                t.adminDrvAppDocNote(doc!.rejectNote!),
                style: LuxTypography.caption,
              ),
            const SizedBox(height: LuxSpacing.sm),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [
                Semantics(
                  label: t.adminDrvAppViewDocLabel(label),
                  button: true,
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    key: ValueKey('drvapp-view-${row.type.wire}'),
                    style: drvAppButtonStyle(),
                    onPressed: row.viewable ? onView : null,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(t.adminDrvAppViewDoc),
                  ),
                ),
                Semantics(
                  label: t.adminDrvAppApproveDocLabel(label),
                  button: true,
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    key: ValueKey('drvapp-approve-${row.type.wire}'),
                    style: drvAppButtonStyle(color: LuxColors.success),
                    onPressed: !busy && row.canApprove ? onApprove : null,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(t.adminDrvAppApproveDoc),
                  ),
                ),
                Semantics(
                  label: t.adminDrvAppRejectDocLabel(label),
                  button: true,
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    key: ValueKey('drvapp-reject-${row.type.wire}'),
                    style: drvAppButtonStyle(color: LuxColors.error),
                    onPressed: !busy && row.canReject ? onReject : null,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(t.adminDrvAppRejectDoc),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vencimientos próximos
// ─────────────────────────────────────────────────────────────────────────────

const kExpiryPeriods = [7, 30, 90];

class DocExpiriesView extends StatefulWidget {
  const DocExpiriesView({
    super.key,
    required this.repository,
    required this.onOpen,
  });

  final DriverApplicationsRepository repository;
  final ValueChanged<String> onOpen;

  @override
  State<DocExpiriesView> createState() => _DocExpiriesViewState();
}

class _DocExpiriesViewState extends State<DocExpiriesView> {
  int _days = 30;
  bool _loading = true;
  DocExpiries? _data;
  DriverAppFailure? _failure;
  int _req = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final req = ++_req;
    setState(() {
      _loading = true;
      _failure = null;
    });
    final r = await widget.repository.expiries(_days);
    if (!mounted || req != _req) return;
    setState(() {
      _loading = false;
      r.fold((f) {
        _failure = f;
        _data = null;
      }, (d) => _data = d);
    });
  }

  Future<void> _allow(DocExpiryItem item) async {
    final ok = await showAllowOnlineDialog(
      context,
      name: _nameOf(context, item.name, item.email),
      onSubmit: (reason) async {
        final r = await widget.repository.allowOnline(
          driverId: item.driverId,
          reason: reason,
        );
        return r.fold((f) => f, (_) => null);
      },
    );
    if (!mounted || !ok) return;
    showLuxSnackbar(context, context.l10n.adminDrvAppAllowOnlineDone);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: LuxSpacing.md,
            vertical: LuxSpacing.sm,
          ),
          child: Row(
            children: [
              for (final d in kExpiryPeriods)
                Padding(
                  padding: const EdgeInsets.only(right: LuxSpacing.sm),
                  child: SectionChip(
                    key: ValueKey('drvapp-days-$d'),
                    label: t.adminDrvAppExpiriesPeriod('$d'),
                    selected: _days == d,
                    onTap: () {
                      if (_days == d) return;
                      _days = d;
                      _load();
                    },
                  ),
                ),
              IconButton(
                key: const ValueKey('drvapp-expiries-reload'),
                tooltip: t.adminDrvAppReload,
                constraints: BoxConstraints.tight(kDrvAppMinTap),
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loading ? null : _load,
              ),
            ],
          ),
        ),
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final t = context.l10n;
    if (_loading) return const LuxSkeletonList(count: 3);
    final failure = _failure;
    if (failure != null) {
      return _StateMessage(
        key: const ValueKey('drvapp-expiries-error'),
        icon: Icons.cloud_off_rounded,
        title: t.adminDrvAppExpiriesError,
        subtitle: failure.message,
        onRetry: _load,
      );
    }
    final data = _data!;
    if (data.items.isEmpty) {
      return _StateMessage(
        key: const ValueKey('drvapp-expiries-empty'),
        icon: Icons.event_available_outlined,
        title: t.adminDrvAppExpiriesEmpty('$_days'),
      );
    }
    return ListView(
      key: const ValueKey('drvapp-expiries-list'),
      padding: const EdgeInsets.all(LuxSpacing.md),
      children: [
        if (data.truncated)
          Padding(
            padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
            child: Text(
              t.adminDrvAppExpiriesTruncated('${data.items.length}'),
              style: LuxTypography.caption,
            ),
          ),
        for (final item in data.items)
          _ExpiryRow(
            item: item,
            onOpen: () => widget.onOpen(item.driverId),
            onAllow: () => _allow(item),
          ),
      ],
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({
    required this.item,
    required this.onOpen,
    required this.onAllow,
  });

  final DocExpiryItem item;
  final VoidCallback onOpen;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final name = _nameOf(context, item.name, item.email);
    final date = DateFormat('dd/MM/yyyy').format(item.expiresAt);
    final past = item.expiresAt.isBefore(DateTime.now());
    return Padding(
      key: ValueKey('drvapp-expiry-${item.driverId}-${item.type?.wire}'),
      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
      child: LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: LuxTypography.titleMedium),
            if (item.email != null && item.name != null)
              Text(item.email!, style: LuxTypography.caption),
            const SizedBox(height: LuxSpacing.xs),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  item.type?.label ?? '',
                  style: LuxTypography.bodyMedium,
                ),
                AdminTag(item.status.label, color: docStatusColor(item.status)),
                Text(
                  past
                      ? t.adminDrvAppDocExpired(date)
                      : t.adminDrvAppDocExpires(date),
                  style: LuxTypography.caption.copyWith(
                    color: past ? LuxColors.error : LuxColors.inkSecondary,
                  ),
                ),
                if (item.docsBlocked)
                  AdminTag(t.adminDrvAppBlocked, color: LuxColors.error),
              ],
            ),
            const SizedBox(height: LuxSpacing.sm),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [
                Semantics(
                  label: t.adminDrvAppOpen(name),
                  button: true,
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    key: ValueKey('drvapp-expiry-open-${item.driverId}'),
                    style: drvAppButtonStyle(),
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(t.adminDrvAppOpenShort),
                  ),
                ),
                if (item.docsBlocked)
                  Semantics(
                    label: t.adminDrvAppAllowOnlineLabel(name),
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton.icon(
                      key: ValueKey('drvapp-allow-${item.driverId}'),
                      style: FilledButton.styleFrom(minimumSize: kDrvAppMinTap),
                      onPressed: onAllow,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: Text(t.adminDrvAppAllowOnline),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
