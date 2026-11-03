import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/widgets/reauth_dialog.dart';
import '../../data/flights_admin_repository.dart';
import 'admin_shared_widgets.dart';

/// Panel, vuelos (B3): tarjeta «Vuelo» del detalle de una reserva y sus
/// diálogos (fijar datos, quitar el bloqueo manual, «no se presentó»).

/// Botones de al menos 48 px (E9).
const kFlightMinTap = Size(48, 48);

ButtonStyle flightButtonStyle({Color? color}) => OutlinedButton.styleFrom(
      minimumSize: kFlightMinTap,
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.md),
    );

/// El repositorio por omisión: el registrado en el contenedor (tests) o
/// Firebase. Sin Firebase registrado (los tests antiguos del panel) no hay
/// repositorio y no se muestra nada.
FlightsAdminRepository? defaultFlightsRepository() {
  if (sl.isRegistered<FlightsAdminRepository>()) {
    return sl<FlightsAdminRepository>();
  }
  return sl.isRegistered<FirebaseFirestore>() &&
          sl.isRegistered<FirebaseFunctions>()
      ? FirebaseFlightsAdminRepository(firestore: sl(), functions: sl())
      : null;
}

/// «20 nov 2026 · 14:35» en hora de La Paz; «—» sin hora.
String flightTimeText(DateTime? instant) {
  if (instant == null) return '—';
  final w = laPazWall(instant);
  return '${LuxFormat.date(w)} · ${LuxFormat.time(w)}';
}

String flightQualityLabel(FlightDataQuality q) {
  final t = L10n.current;
  return switch (q) {
    FlightDataQuality.ok => t.adminFlightQualityOk,
    FlightDataQuality.stale => t.adminFlightQualityStale,
    FlightDataQuality.none => t.adminFlightQualityNone,
  };
}

String flightSourceLabel(FlightSource? s) {
  final t = L10n.current;
  return switch (s) {
    FlightSource.passenger || null => t.adminFlightSourcePassenger,
    FlightSource.manual => t.adminFlightSourceManual,
    FlightSource.auto => t.adminFlightSourceAuto,
  };
}

Color flightStatusColor(FlightStatus s) => switch (s) {
      FlightStatus.cancelled || FlightStatus.diverted => LuxColors.error,
      FlightStatus.delayed || FlightStatus.unknown => LuxColors.warning,
      FlightStatus.landed => LuxColors.success,
      FlightStatus.scheduled => LuxColors.sapphire,
    };

/// «AA 922» o solo el número si no hay aerolínea.
String flightLabel(FlightInfo f) =>
    [if (f.airline != null) f.airline!, f.flightNumber].join(' ');

/// Si el servidor pidió identificarse de nuevo, se pide aquí (el diálogo de
/// siempre) y la persona repite la acción; si no, el aviso.
Future<void> handleFlightFailure(
  BuildContext context,
  FlightAdminFailure failure,
) async {
  if (failure.needsReauth) {
    await confirmIdentityThenRetry(context);
  } else {
    showLuxSnackbar(context, failure.message, isError: true);
  }
}

/// Elige fecha y hora; recibe y devuelve horas de pared de La Paz.
typedef FlightDateTimePicker = Future<DateTime?> Function(
  BuildContext context,
  DateTime initialWall,
);

Future<DateTime?> defaultFlightDateTimePicker(
  BuildContext context,
  DateTime initialWall,
) async {
  final day = DateTime(initialWall.year, initialWall.month, initialWall.day);
  final date = await showDatePicker(
    context: context,
    initialDate: day,
    firstDate: day.subtract(const Duration(days: 30)),
    lastDate: day.add(const Duration(days: 30)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initialWall.hour, minute: initialWall.minute),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  if (time == null) return null;
  return DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta «Vuelo» del detalle de la reserva: en vivo (bookings/{id}), con
/// quién y cuándo se fijó a mano (admin_logs). Sin vuelo, no ocupa nada.
class AdminFlightCard extends StatefulWidget {
  const AdminFlightCard({
    super.key,
    required this.bookingId,
    this.repository,
    this.picker,
  });

  final String bookingId;

  /// Para los tests; por omisión, Firestore y las callables.
  final FlightsAdminRepository? repository;
  final FlightDateTimePicker? picker;

  @override
  State<AdminFlightCard> createState() => _AdminFlightCardState();
}

class _AdminFlightCardState extends State<AdminFlightCard> {
  late final FlightsAdminRepository? _repo =
      widget.repository ?? defaultFlightsRepository();
  Stream<FlightBooking?>? _stream;
  Either<FlightAdminFailure, FlightManualChange?>? _change;

  @override
  void initState() {
    super.initState();
    _stream = _repo?.watchFlight(widget.bookingId);
    _loadChange();
  }

  Future<void> _loadChange() async {
    final r = await _repo?.lastManualChange(widget.bookingId);
    if (mounted && r != null) setState(() => _change = r);
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) return const SizedBox.shrink();
    return StreamBuilder<FlightBooking?>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            key: const ValueKey('flight-card-error'),
            padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
            child: Text(
              context.l10n.adminFlightLoadError,
              style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error),
            ),
          );
        }
        final b = snap.data;
        if (b == null) return const SizedBox.shrink();
        return _card(context, b);
      },
    );
  }

  Widget _card(BuildContext context, FlightBooking b) {
    final t = context.l10n;
    final f = b.flight;
    final change = _change?.fold((_) => null, (c) => c);
    return Container(
      key: const ValueKey('flight-card'),
      margin: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
      padding: const EdgeInsets.all(LuxSpacing.md),
      decoration: BoxDecoration(
        color: LuxColors.surfaceMuted,
        borderRadius: BorderRadius.circular(LuxRadius.md),
        border: Border.all(
          color: f.status.disrupted ? LuxColors.error : LuxColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(t.adminFlightCardTitle,
                    style: LuxTypography.titleMedium),
              ),
              AdminTag(f.status.label, color: flightStatusColor(f.status)),
              if (f.manualLock)
                AdminTag(t.adminFlightLockTag, color: LuxColors.warning),
            ],
          ),
          const SizedBox(height: LuxSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              f.readyAt == null
                  ? t.adminFlightNoReadyAt
                  : t.adminFlightReadyAt(LuxFormat.time(laPazWall(f.readyAt!))),
              key: const ValueKey('flight-ready-at'),
              style: LuxTypography.titleMedium.copyWith(
                color: LuxColors.sapphire,
              ),
            ),
          ),
          if (f.readyAt != null)
            Text(
              flightTimeText(f.readyAt),
              style: LuxTypography.caption,
            ),
          const SizedBox(height: LuxSpacing.xs),
          AdminInfoRow(label: t.adminFlightAirport, value: f.airportCode),
          AdminInfoRow(label: t.adminFlightAirline, value: f.airline ?? '—'),
          AdminInfoRow(label: t.adminFlightNumber, value: f.flightNumber),
          AdminInfoRow(label: t.adminFlightType, value: f.flightType.label),
          AdminInfoRow(label: t.adminFlightDate, value: f.flightDate),
          if (f.hasCheckedBag != null)
            AdminInfoRow(
              label: t.adminFlightCheckedBag,
              value: f.hasCheckedBag! ? t.adminFlightYes : t.adminFlightNo,
            ),
          AdminInfoRow(
            label: t.adminFlightScheduled,
            value: flightTimeText(f.scheduledArrival),
          ),
          AdminInfoRow(
            label: t.adminFlightEstimated,
            value: flightTimeText(f.estimatedArrival),
          ),
          AdminInfoRow(
            label: t.adminFlightActual,
            value: flightTimeText(f.actualArrival),
          ),
          AdminInfoRow(
            label: t.adminFlightStatus,
            value: f.status.label,
            valueColor: flightStatusColor(f.status),
          ),
          AdminInfoRow(
            label: t.adminFlightQuality,
            value: flightQualityLabel(f.dataQuality),
            valueColor: f.dataQuality == FlightDataQuality.ok
                ? null
                : LuxColors.warning,
          ),
          AdminInfoRow(
            label: t.adminFlightSource,
            value: flightSourceLabel(f.source),
          ),
          AdminInfoRow(
            label: t.adminFlightLastChange,
            value: flightTimeText(f.lastChangeAt),
          ),
          if (f.lastObservedAt != null)
            AdminInfoRow(
              label: t.adminFlightLastObserved,
              value: flightTimeText(f.lastObservedAt),
            ),
          Text(t.adminFlightTimesNote, style: LuxTypography.caption),
          const SizedBox(height: LuxSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                f.manualLock ? Icons.lock_outline : Icons.lock_open_outlined,
                size: 18,
                color: f.manualLock ? LuxColors.warning : LuxColors.inkTertiary,
              ),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(
                  f.manualLock ? t.adminFlightLocked : t.adminFlightUnlocked,
                  key: const ValueKey('flight-lock'),
                  style: LuxTypography.bodyMedium,
                ),
              ),
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: LuxSpacing.xs),
            Text(
              _changeText(context, change),
              key: const ValueKey('flight-change'),
              style: LuxTypography.caption,
            ),
            if (change.reason != null)
              Text(
                t.adminFlightChangeReason(change.reason!),
                style: LuxTypography.caption,
              ),
          ],
          const SizedBox(height: LuxSpacing.md),
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.sm,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('flight-set'),
                style: flightButtonStyle(),
                onPressed: () => _setFlight(b),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(t.adminFlightSetButton),
              ),
              if (f.manualLock)
                OutlinedButton.icon(
                  key: const ValueKey('flight-clear-lock'),
                  style: flightButtonStyle(),
                  onPressed: () => _clearLock(b),
                  icon: const Icon(Icons.lock_open_outlined),
                  label: Text(t.adminFlightClearLockButton),
                ),
              if (b.bookingStatus == BookingStatus.driverArrived)
                OutlinedButton.icon(
                  key: const ValueKey('flight-force-no-show'),
                  style: flightButtonStyle(color: LuxColors.error),
                  onPressed: () => _forceNoShow(b),
                  icon: const Icon(Icons.person_off_outlined),
                  label: Text(t.adminFlightForceNoShowButton),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _changeText(BuildContext context, FlightManualChange c) {
    final t = context.l10n;
    final who = c.adminEmail ?? t.adminFlightAdminUnknown;
    final when = flightTimeText(c.at);
    return c.clearedLock
        ? t.adminFlightLockClearedBy(who, when)
        : t.adminFlightSetBy(who, when);
  }

  Future<void> _done(bool? ok, String message) async {
    if (ok != true || !mounted) return;
    showLuxSnackbar(context, message);
    await _loadChange();
  }

  Future<void> _setFlight(FlightBooking b) async {
    final repo = _repo!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => SetFlightInfoDialog(
        flight: b.flight,
        picker: widget.picker,
        onSubmit: (input) async =>
            (await repo.setFlightInfo(b.bookingId, input))
                .fold((f) => f, (_) => null),
      ),
    );
    await _done(ok, L10n.current.adminFlightSetDone);
  }

  Future<void> _clearLock(FlightBooking b) async {
    final repo = _repo!;
    final t = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => FlightReasonDialog(
        title: t.adminFlightClearLockTitle,
        message: t.adminFlightClearLockMessage,
        confirmLabel: t.adminFlightClearLockConfirm,
        onSubmit: (reason) async =>
            (await repo.clearFlightLock(b.bookingId, reason))
                .fold((f) => f, (_) => null),
      ),
    );
    await _done(ok, t.adminFlightClearLockDone);
  }

  Future<void> _forceNoShow(FlightBooking b) async {
    final repo = _repo!;
    final t = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => FlightReasonDialog(
        title: t.adminFlightForceNoShowTitle,
        message: t.adminFlightForceNoShowMessage(shortId(b.bookingId)),
        confirmLabel: t.adminFlightForceNoShowConfirm,
        destructive: true,
        onSubmit: (reason) async =>
            (await repo.forceNoShow(b.bookingId, reason))
                .fold((f) => f, (_) => null),
      ),
    );
    await _done(ok, t.adminFlightForceNoShowDone);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogos
// ─────────────────────────────────────────────────────────────────────────────

/// Campo de motivo de 10 a 500 caracteres, el mismo en todos los diálogos.
class FlightReasonField extends StatelessWidget {
  const FlightReasonField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final len = controller.text.trim().length;
    return TextField(
      key: const ValueKey('flight-reason'),
      controller: controller,
      enabled: enabled,
      minLines: 2,
      maxLines: 4,
      maxLength: kFlightReasonMax,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: t.adminFlightReasonLabel,
        errorText:
            len > 0 && len < kFlightReasonMin ? t.adminFlightReasonShort : null,
        errorMaxLines: 3,
      ),
    );
  }
}

bool flightReasonOk(String s) {
  final n = s.trim().length;
  return n >= kFlightReasonMin && n <= kFlightReasonMax;
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: LuxSpacing.sm),
        child: Semantics(
          liveRegion: true,
          child: Text(
            text,
            key: const ValueKey('flight-dialog-error'),
            style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error),
          ),
        ),
      );
}

/// Pide un motivo y hace la llamada ([onSubmit]); un fallo se muestra en
/// el propio diálogo sin perder lo escrito. Devuelve true si se completó.
class FlightReasonDialog extends StatefulWidget {
  const FlightReasonDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onSubmit,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;
  final Future<FlightAdminFailure?> Function(String reason) onSubmit;

  @override
  State<FlightReasonDialog> createState() => _FlightReasonDialogState();
}

class _FlightReasonDialogState extends State<FlightReasonDialog> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

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
    final f = await widget.onSubmit(_reason.text.trim());
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
    return AlertDialog(
      key: const ValueKey('flight-reason-dialog'),
      title: Text(widget.title),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.sm),
            FlightReasonField(
              controller: _reason,
              enabled: !_busy,
              onChanged: () => setState(() {}),
            ),
            if (_error != null) _InlineError(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: kFlightMinTap),
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(t.adminFlightCancel),
        ),
        FilledButton(
          key: const ValueKey('flight-reason-confirm'),
          style: FilledButton.styleFrom(
            minimumSize: kFlightMinTap,
            backgroundColor: widget.destructive ? LuxColors.error : null,
          ),
          onPressed: _busy || !flightReasonOk(_reason.text) ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Formulario de adminSetFlightInfo: estado de la lista cerrada, llegada
/// estimada y real (hora de La Paz) y motivo. Con «Aterrizó», la llegada
/// real es obligatoria.
class SetFlightInfoDialog extends StatefulWidget {
  const SetFlightInfoDialog({
    super.key,
    required this.flight,
    required this.onSubmit,
    this.picker,
  });

  final FlightInfo flight;
  final FlightDateTimePicker? picker;
  final Future<FlightAdminFailure?> Function(FlightManualInput input) onSubmit;

  @override
  State<SetFlightInfoDialog> createState() => _SetFlightInfoDialogState();
}

class _SetFlightInfoDialogState extends State<SetFlightInfoDialog> {
  final _reason = TextEditingController();
  late FlightStatus _status = widget.flight.status;
  late DateTime? _estimated = widget.flight.estimatedArrival;
  late DateTime? _actual = widget.flight.actualArrival;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _actualMissing => _status == FlightStatus.landed && _actual == null;
  bool get _valid => flightReasonOk(_reason.text) && !_actualMissing;

  Future<void> _pick(bool actual) async {
    final current = actual ? _actual : _estimated;
    final initial = laPazWall(
      current ?? widget.flight.effectiveArrival ?? DateTime.now().toUtc(),
    );
    final picked =
        await (widget.picker ?? defaultFlightDateTimePicker)(context, initial);
    if (picked == null || !mounted) return;
    final instant = fromLaPazWall(picked);
    setState(() => actual ? _actual = instant : _estimated = instant);
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final f = await widget.onSubmit(
      FlightManualInput(
        status: _status,
        estimatedArrival: _estimated,
        actualArrival: _actual,
        reason: _reason.text.trim(),
      ),
    );
    if (!mounted) return;
    if (f == null) return Navigator.of(context).pop(true);
    setState(() {
      _busy = false;
      _error = f.needsReauth ? null : f.message;
    });
    if (f.needsReauth) await confirmIdentityThenRetry(context);
  }

  Widget _timeField({
    required String keyName,
    required String label,
    required DateTime? value,
    required bool actual,
    String? error,
  }) {
    final t = context.l10n;
    final text = value == null ? t.adminFlightSetNoTime : flightTimeText(value);
    return Padding(
      padding: const EdgeInsets.only(top: LuxSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: LuxTypography.caption),
          const SizedBox(height: LuxSpacing.xs),
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                button: true,
                label: t.adminFlightSetTimeSemantics(label, text),
                excludeSemantics: true,
                child: OutlinedButton.icon(
                  key: ValueKey('flight-set-$keyName'),
                  style: flightButtonStyle(),
                  onPressed: _busy ? null : () => _pick(actual),
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(value == null ? t.adminFlightSetPick : text),
                ),
              ),
              if (value != null)
                TextButton(
                  key: ValueKey('flight-set-$keyName-clear'),
                  style: TextButton.styleFrom(minimumSize: kFlightMinTap),
                  onPressed: _busy
                      ? null
                      : () => setState(
                            () => actual ? _actual = null : _estimated = null,
                          ),
                  child: Text(t.adminFlightSetClearTime),
                ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: LuxSpacing.xs),
              child: Text(
                error,
                key: ValueKey('flight-set-$keyName-error'),
                style: LuxTypography.caption.copyWith(color: LuxColors.error),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AlertDialog(
      key: const ValueKey('flight-set-dialog'),
      title: Text(t.adminFlightSetTitle),
      scrollable: true,
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.adminFlightSetMessage, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            DropdownButtonFormField<FlightStatus>(
              key: const ValueKey('flight-set-status'),
              value: _status,
              isExpanded: true,
              decoration:
                  InputDecoration(labelText: t.adminFlightSetStatusLabel),
              items: [
                for (final s in FlightStatus.values)
                  DropdownMenuItem(
                    value: s,
                    child: Text(s.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged:
                  _busy ? null : (s) => setState(() => _status = s ?? _status),
            ),
            _timeField(
              keyName: 'estimated',
              label: t.adminFlightEstimated,
              value: _estimated,
              actual: false,
            ),
            _timeField(
              keyName: 'actual',
              label: t.adminFlightActual,
              value: _actual,
              actual: true,
              error: _actualMissing ? t.adminFlightSetActualRequired : null,
            ),
            Padding(
              padding: const EdgeInsets.only(top: LuxSpacing.xs),
              child: Text(t.adminFlightTimesNote, style: LuxTypography.caption),
            ),
            const SizedBox(height: LuxSpacing.md),
            FlightReasonField(
              controller: _reason,
              enabled: !_busy,
              onChanged: () => setState(() {}),
            ),
            if (_error != null) _InlineError(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: kFlightMinTap),
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(t.adminFlightCancel),
        ),
        FilledButton(
          key: const ValueKey('flight-set-confirm'),
          style: FilledButton.styleFrom(minimumSize: kFlightMinTap),
          onPressed: _busy || !_valid ? null : _submit,
          child: Text(t.adminFlightSetConfirm),
        ),
      ],
    );
  }
}

/// El detalle de una reserva que el panel no tiene en su lista: solo la
/// tarjeta del vuelo.
Future<void> showFlightBookingDialog(
  BuildContext context,
  String bookingId,
  FlightsAdminRepository repository, {
  FlightDateTimePicker? picker,
}) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        key: const ValueKey('flight-booking-dialog'),
        backgroundColor: LuxColors.surface,
        insetPadding: const EdgeInsets.all(LuxSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(LuxSpacing.lg),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ctx.l10n.adminFlightsBookingTitle(shortId(bookingId)),
                      style: LuxTypography.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: ctx.l10n.adminFlightsClose,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              AdminFlightCard(
                bookingId: bookingId,
                repository: repository,
                picker: picker,
              ),
            ],
          ),
        ),
      ),
    );
