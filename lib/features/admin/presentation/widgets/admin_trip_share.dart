import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../l10n/l10n.dart';
import '../../data/admin_share_repository.dart';
import '../bloc/admin_bloc.dart';
import 'admin_sections.dart';
import 'admin_shared_widgets.dart';

AdminShareRepository? _repoOf(AdminShareRepository? r) =>
    r ??
    (sl.isRegistered<AdminShareRepository>()
        ? sl<AdminShareRepository>()
        : null);

/// Detalle de la reserva (C3): si tiene enlace de seguimiento activo y
/// revocarlo con motivo (adminRevokeTripShare, MFA y auditoría).
class AdminTripShareCard extends StatefulWidget {
  const AdminTripShareCard(
      {super.key, required this.bookingId, this.repository});
  final String bookingId;
  final AdminShareRepository? repository;

  @override
  State<AdminTripShareCard> createState() => _AdminTripShareCardState();
}

class _AdminTripShareCardState extends State<AdminTripShareCard> {
  AdminShareRepository? get _repo => _repoOf(widget.repository);
  bool? _active;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) return;
    setState(() => _error = null);
    final r = await repo.isShareActive(widget.bookingId);
    if (!mounted) return;
    setState(() => r.fold((f) => _error = f.message, (a) => _active = a));
  }

  Future<void> _revoke() async {
    final repo = _repo!;
    final t = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AdminShareReasonDialog(
        onSubmit: (reason) async =>
            (await repo.revokeShare(widget.bookingId, reason))
                .fold((f) => f.message, (_) => null),
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(t.adminShareRevokeDone)));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_repo == null) return const SizedBox.shrink();
    final t = context.l10n;
    return Column(
      key: const ValueKey('admin-trip-share'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.adminShareTitle, style: LuxTypography.titleMedium),
        const SizedBox(height: LuxSpacing.xs),
        if (_error != null)
          Row(children: [
            Expanded(
                child: Text(t.adminShareLoadFailed,
                    style: LuxTypography.bodyMedium)),
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize: const Size(
                      kMinInteractiveDimension, kMinInteractiveDimension)),
              onPressed: _load,
              child: Text(t.adminShareRetry),
            ),
          ])
        else if (_active == null)
          const LinearProgressIndicator()
        else if (_active!) ...[
          Text(t.adminShareActive, style: LuxTypography.bodyMedium),
          const SizedBox(height: LuxSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('admin-trip-share-revoke'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                    kMinInteractiveDimension, kMinInteractiveDimension),
                foregroundColor: LuxColors.error),
            onPressed: _revoke,
            icon: const Icon(Icons.link_off_rounded),
            label: Text(t.adminShareRevoke),
          ),
        ] else
          Text(t.adminShareNone, style: LuxTypography.bodyMedium),
      ],
    );
  }
}

/// Motivo de 10 a 500 caracteres, como el resto de acciones del admin.
class AdminShareReasonDialog extends StatefulWidget {
  const AdminShareReasonDialog({super.key, required this.onSubmit});

  /// null = hecho; si no, el error para mostrar.
  final Future<String?> Function(String reason) onSubmit;

  @override
  State<AdminShareReasonDialog> createState() => _AdminShareReasonDialogState();
}

class _AdminShareReasonDialogState extends State<AdminShareReasonDialog> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _ok {
    final n = _reason.text.trim().length;
    return n >= 10 && n <= 500;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final e = await widget.onSubmit(_reason.text.trim());
    if (!mounted) return;
    if (e == null) return Navigator.of(context).pop(true);
    setState(() {
      _busy = false;
      _error = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    const tap = Size(kMinInteractiveDimension, kMinInteractiveDimension);
    return AlertDialog(
      title: Text(t.adminShareRevokeTitle),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.adminShareRevokeMessage, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.sm),
            TextField(
              key: const ValueKey('admin-share-reason'),
              controller: _reason,
              enabled: !_busy,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: t.adminShareReason),
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Text(_error!,
                    style: LuxTypography.bodyMedium
                        .copyWith(color: LuxColors.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: tap),
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(t.adminShareCancel),
        ),
        FilledButton(
          key: const ValueKey('admin-share-confirm'),
          style: FilledButton.styleFrom(
              minimumSize: tap, backgroundColor: LuxColors.error),
          onPressed: _busy || !_ok ? null : _submit,
          child: Text(t.adminShareRevoke),
        ),
      ],
    );
  }
}

/// Bandeja de Operaciones (C3): reservas pagadas sin chófer cerca de la hora
/// (las alertas booking_unassigned que crea el servidor según
/// config/ops.unassignedAlertMinutes). Vacía, no ocupa sitio.
class AdminUnassignedInbox extends StatelessWidget {
  const AdminUnassignedInbox({super.key, this.repository, this.onOpen});
  final AdminShareRepository? repository;
  final void Function(String bookingId)? onOpen;

  @override
  Widget build(BuildContext context) {
    final repo = _repoOf(repository);
    if (repo == null) return const SizedBox.shrink();
    return StreamBuilder<List<UnassignedAlert>>(
      stream: repo.watchUnassigned(),
      builder: (context, snap) {
        final alerts = snap.data ?? const [];
        if (alerts.isEmpty) return const SizedBox.shrink();
        final t = context.l10n;
        final bookings =
            context.select<AdminBloc, List<Booking>>((b) => b.state.bookings);
        return Container(
          key: const ValueKey('admin-unassigned-inbox'),
          margin: const EdgeInsets.fromLTRB(
              LuxSpacing.lg, LuxSpacing.md, LuxSpacing.lg, 0),
          padding: const EdgeInsets.all(LuxSpacing.md),
          decoration: BoxDecoration(
            color: LuxColors.surface,
            borderRadius: BorderRadius.circular(LuxRadius.md),
            border: Border.all(color: LuxColors.error),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('${t.adminUnassignedTitle} · ${alerts.length}',
                    style: LuxTypography.titleMedium),
              ),
              for (final a in alerts)
                Builder(builder: (context) {
                  final b =
                      bookings.where((x) => x.id == a.bookingId).firstOrNull;
                  final code = shortId(a.bookingId);
                  final time =
                      b == null ? '—' : LuxFormat.dateTime(b.scheduledAt);
                  return Semantics(
                    button: true,
                    label: t.adminUnassignedOpen(code),
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => (onOpen ??
                          (id) => showBookingDetail(context, id))(a.bookingId),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            minHeight: kMinInteractiveDimension),
                        child: Row(children: [
                          const Icon(Icons.person_search_outlined,
                              size: 18, color: LuxColors.error),
                          const SizedBox(width: LuxSpacing.sm),
                          Expanded(
                              child: Text(t.adminUnassignedRow(code, time),
                                  style: LuxTypography.bodyMedium)),
                          const Icon(Icons.chevron_right_rounded,
                              color: LuxColors.inkTertiary),
                        ]),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
