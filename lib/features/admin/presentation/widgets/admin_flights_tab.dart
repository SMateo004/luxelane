import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/service_area.dart' show FlightType;
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/widgets/reauth_dialog.dart';
import '../../data/flights_admin_repository.dart';
import 'admin_flight_card.dart';
import 'admin_shared_widgets.dart';

/// Abre el detalle de una reserva desde la bandeja. Por omisión, solo la
/// tarjeta del vuelo ([showFlightBookingDialog]).
typedef FlightBookingOpener = Future<void> Function(
  BuildContext context,
  String bookingId,
  FlightsAdminRepository repository,
);

/// Sección «Vuelos» (B3): bandeja de vuelos por revisar y editor de
/// aeropuertos con sus puntos de recogida.
class FlightsTab extends StatefulWidget {
  const FlightsTab({
    super.key,
    this.repository,
    this.onOpenBooking,
    this.picker,
  });

  /// Para los tests; por omisión, Firestore y las callables.
  final FlightsAdminRepository? repository;
  final FlightBookingOpener? onOpenBooking;
  final FlightDateTimePicker? picker;

  @override
  State<FlightsTab> createState() => _FlightsTabState();
}

enum _View { inbox, airports }

class _FlightsTabState extends State<FlightsTab> {
  late final FlightsAdminRepository? _repo =
      widget.repository ?? defaultFlightsRepository();
  _View _view = _View.inbox;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final repo = _repo;
    if (repo == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                key: const ValueKey('flights-view-inbox'),
                label: t.adminFlightsTabInbox,
                selected: _view == _View.inbox,
                onTap: () => setState(() => _view = _View.inbox),
              ),
              SectionChip(
                key: const ValueKey('flights-view-airports'),
                label: t.adminFlightsTabAirports,
                selected: _view == _View.airports,
                onTap: () => setState(() => _view = _View.airports),
              ),
            ],
          ),
        ),
        Expanded(
          child: _view == _View.inbox
              ? FlightInboxView(
                  repository: repo,
                  onOpen: (ctx, id) => (widget.onOpenBooking ??
                      (c, i, r) => showFlightBookingDialog(
                            c,
                            i,
                            r,
                            picker: widget.picker,
                          ))(ctx, id, repo),
                )
              : AirportsView(repository: repo),
        ),
      ],
    );
  }
}

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
                    key: const ValueKey('flights-retry'),
                    style: flightButtonStyle(),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.l10n.adminFlightsRetry),
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

String flightInboxKindLabel(FlightInboxKind k) {
  final t = L10n.current;
  return switch (k) {
    FlightInboxKind.toVerify => t.adminFlightsInboxToVerify,
    FlightInboxKind.noData => t.adminFlightsInboxNoData,
    FlightInboxKind.disrupted => t.adminFlightsInboxDisrupted,
  };
}

String _emptyLabel(FlightInboxKind k) {
  final t = L10n.current;
  return switch (k) {
    FlightInboxKind.toVerify => t.adminFlightsInboxEmptyToVerify,
    FlightInboxKind.noData => t.adminFlightsInboxEmptyNoData,
    FlightInboxKind.disrupted => t.adminFlightsInboxEmptyDisrupted,
  };
}

class FlightInboxView extends StatefulWidget {
  const FlightInboxView({
    super.key,
    required this.repository,
    required this.onOpen,
  });

  final FlightsAdminRepository repository;
  final Future<void> Function(BuildContext context, String bookingId) onOpen;

  @override
  State<FlightInboxView> createState() => _FlightInboxViewState();
}

class _FlightInboxViewState extends State<FlightInboxView> {
  FlightInboxKind _kind = FlightInboxKind.toVerify;
  Either<FlightAdminFailure, FlightInbox>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _data = null);
    final r = await widget.repository.inbox();
    if (!mounted) return;
    setState(() => _data = r);
    r.fold((f) {
      if (f.needsReauth) confirmIdentityThenRetry(context);
    }, (_) {});
  }

  Future<void> _open(String id) async {
    await widget.onOpen(context, id);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final data = _data;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return data.fold(
      (f) => _StateMessage(
        key: const ValueKey('flights-inbox-error'),
        icon: Icons.cloud_off_rounded,
        title: t.adminFlightsInboxError,
        subtitle: f.message,
        onRetry: _load,
      ),
      (inbox) {
        final rows = _kind.pick(inbox.items);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LuxSpacing.md,
                LuxSpacing.sm,
                LuxSpacing.md,
                0,
              ),
              child: Wrap(
                spacing: LuxSpacing.sm,
                runSpacing: LuxSpacing.xs,
                children: [
                  for (final k in FlightInboxKind.values)
                    ChoiceChip(
                      key: ValueKey('flights-kind-${k.name}'),
                      label: Text(
                        '${flightInboxKindLabel(k)} · '
                        '${k.pick(inbox.items).length}',
                      ),
                      selected: _kind == k,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                ],
              ),
            ),
            if (inbox.truncated)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LuxSpacing.md,
                  LuxSpacing.sm,
                  LuxSpacing.md,
                  0,
                ),
                child: Text(
                  t.adminFlightsInboxTruncated('$kFlightInboxLimit'),
                  key: const ValueKey('flights-inbox-truncated'),
                  style: LuxTypography.caption.copyWith(
                    color: LuxColors.warning,
                  ),
                ),
              ),
            Expanded(
              child: rows.isEmpty
                  ? _StateMessage(
                      key: const ValueKey('flights-inbox-empty'),
                      icon: Icons.flight_land_rounded,
                      title: _emptyLabel(_kind),
                      subtitle: t.adminFlightsInboxEmptyHint,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LuxSpacing.md,
                          vertical: LuxSpacing.sm,
                        ),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const LuxDivider(),
                        itemBuilder: (_, i) => FlightInboxRow(
                          item: rows[i],
                          onTap: () => _open(rows[i].bookingId),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class FlightInboxRow extends StatelessWidget {
  const FlightInboxRow({super.key, required this.item, required this.onTap});

  final FlightBooking item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final f = item.flight;
    final code = shortId(item.bookingId);
    final flight = '${f.airportCode} · ${flightLabel(f)}';
    final ready = f.readyAt == null
        ? t.adminFlightsRowNoReadyAt
        : t.adminFlightsRowReadyAt(flightTimeText(f.readyAt));
    final route = [
      if (item.origin != null) item.origin!,
      if (item.destination != null) item.destination!,
    ].join(' → ');
    return Semantics(
      button: true,
      label: '${t.adminFlightsRowSemantics(code, flight, f.status.label)}. '
          '$ready',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('flights-row-${item.bookingId}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: LuxSpacing.sm,
                        runSpacing: LuxSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('#$code', style: LuxTypography.titleMedium),
                          AdminTag(
                            f.status.label,
                            color: flightStatusColor(f.status),
                          ),
                          if (f.manualLock)
                            AdminTag(
                              t.adminFlightLockTag,
                              color: LuxColors.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: LuxSpacing.xs),
                      Text(flight, style: LuxTypography.bodyMedium),
                      if (route.isNotEmpty)
                        Text(
                          route,
                          style: LuxTypography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        ready,
                        style: LuxTypography.caption.copyWith(
                          color: LuxColors.sapphire,
                          fontWeight: FontWeight.w600,
                        ),
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
// Aeropuertos
// ─────────────────────────────────────────────────────────────────────────────

class AirportsView extends StatefulWidget {
  const AirportsView({super.key, required this.repository});

  final FlightsAdminRepository repository;

  @override
  State<AirportsView> createState() => _AirportsViewState();
}

class _AirportsViewState extends State<AirportsView> {
  Either<FlightAdminFailure, List<Airport>>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _data = null);
    final r = await widget.repository.airports();
    if (mounted) setState(() => _data = r);
  }

  Future<void> _edit(Airport? airport) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AirportEditorDialog(
        airport: airport,
        onSubmit: (input) async =>
            (await widget.repository.upsertAirport(input))
                .fold((f) => f, (_) => null),
      ),
    );
    if (ok != true || !mounted) return;
    showLuxSnackbar(context, context.l10n.adminAirportSaved);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final data = _data;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final add = Padding(
      padding: const EdgeInsets.fromLTRB(
        LuxSpacing.md,
        LuxSpacing.sm,
        LuxSpacing.md,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          key: const ValueKey('airport-add'),
          style: FilledButton.styleFrom(minimumSize: kFlightMinTap),
          onPressed: () => _edit(null),
          icon: const Icon(Icons.add_rounded),
          label: Text(t.adminAirportsAdd),
        ),
      ),
    );
    return data.fold(
      (f) => _StateMessage(
        key: const ValueKey('airports-error'),
        icon: Icons.cloud_off_rounded,
        title: t.adminAirportsError,
        subtitle: f.message,
        onRetry: _load,
      ),
      (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          add,
          Expanded(
            child: list.isEmpty
                ? _StateMessage(
                    key: const ValueKey('airports-empty'),
                    icon: Icons.local_airport_outlined,
                    title: t.adminAirportsEmpty,
                    subtitle: t.adminAirportsEmptyHint,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuxSpacing.md,
                      vertical: LuxSpacing.sm,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const LuxDivider(),
                    itemBuilder: (_, i) => _AirportRow(
                      airport: list[i],
                      onTap: () => _edit(list[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AirportRow extends StatelessWidget {
  const _AirportRow({required this.airport, required this.onTap});

  final Airport airport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Semantics(
      button: true,
      label: t.adminAirportEditSemantics(airport.code),
      child: InkWell(
        key: ValueKey('airport-row-${airport.code}'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${airport.code} · ${airport.name}',
                        style: LuxTypography.titleMedium,
                      ),
                      if (airport.city.isNotEmpty)
                        Text(airport.city, style: LuxTypography.caption),
                      const SizedBox(height: LuxSpacing.xs),
                      Wrap(
                        spacing: LuxSpacing.sm,
                        runSpacing: LuxSpacing.xs,
                        children: [
                          for (final type in FlightType.values)
                            AdminTag(
                              airport.pointFor(type) == null
                                  ? t.adminAirportPointMissing(type.label)
                                  : t.adminAirportPointSet(type.label),
                              color: airport.pointFor(type) == null
                                  ? LuxColors.warning
                                  : LuxColors.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: LuxColors.inkTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un punto de recogida en el editor.
class _PointForm {
  _PointForm(PickupPoint? p)
      : existed = p != null,
        enabled = p != null,
        name = TextEditingController(text: p?.name ?? ''),
        instructions = TextEditingController(text: p?.instructions ?? ''),
        lat = TextEditingController(text: p == null ? '' : '${p.lat}'),
        lng = TextEditingController(text: p == null ? '' : '${p.lng}');

  /// El aeropuerto ya tenía este punto: quitarlo manda null.
  final bool existed;
  bool enabled;
  final TextEditingController name, instructions, lat, lng;

  PickupPointChange change() {
    if (!enabled) {
      return existed ? const RemovePickupPoint() : const KeepPickupPoint();
    }
    return SetPickupPoint(
      PickupPoint(
        name: name.text.trim(),
        instructions: instructions.text.trim(),
        lat: PickupPointRules.parse(lat.text)!,
        lng: PickupPointRules.parse(lng.text)!,
      ),
    );
  }

  void dispose() {
    for (final c in [name, instructions, lat, lng]) {
      c.dispose();
    }
  }
}

/// Crea o cambia un aeropuerto (adminUpsertAirport): código de 3 letras
/// (fijo una vez creado), nombre, ciudad y los puntos nacional e
/// internacional, con las mismas reglas que el servidor. Devuelve true si
/// se guardó.
class AirportEditorDialog extends StatefulWidget {
  const AirportEditorDialog({super.key, this.airport, required this.onSubmit});

  final Airport? airport;
  final Future<FlightAdminFailure?> Function(AirportInput input) onSubmit;

  @override
  State<AirportEditorDialog> createState() => _AirportEditorDialogState();
}

class _AirportEditorDialogState extends State<AirportEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.airport?.code ?? '');
  late final _name = TextEditingController(text: widget.airport?.name ?? '');
  late final _city = TextEditingController(text: widget.airport?.city ?? '');
  final _reason = TextEditingController();
  late final Map<FlightType, _PointForm> _points = {
    for (final t in FlightType.values)
      t: _PointForm(widget.airport?.pointFor(t)),
  };
  bool _tried = false;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.airport == null;

  @override
  void dispose() {
    for (final c in [_code, _name, _city, _reason]) {
      c.dispose();
    }
    for (final p in _points.values) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _tried = true;
      _error = null;
    });
    final t = context.l10n;
    final ok = _form.currentState?.validate() ?? false;
    if (!ok || !flightReasonOk(_reason.text)) {
      setState(() => _error = t.adminAirportFixErrors);
      return;
    }
    setState(() => _busy = true);
    final f = await widget.onSubmit(
      AirportInput(
        code: _code.text.trim(),
        name: _name.text,
        city: _city.text,
        points: {for (final e in _points.entries) e.key: e.value.change()},
        reason: _reason.text,
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

  String? _len(String? v, int min, int max, String message) {
    final n = (v ?? '').trim().length;
    return n < min || n > max ? message : null;
  }

  Widget _field(
    TextEditingController c, {
    required String keyName,
    required String label,
    String? Function(String?)? validator,
    bool enabled = true,
    String? helper,
    int maxLines = 1,
    TextInputType? keyboard,
  }) =>
      Padding(
        padding: const EdgeInsets.only(top: LuxSpacing.sm),
        child: TextFormField(
          key: ValueKey(keyName),
          controller: c,
          enabled: enabled && !_busy,
          maxLines: maxLines,
          minLines: 1,
          keyboardType: keyboard,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            helperMaxLines: 3,
            errorMaxLines: 3,
          ),
        ),
      );

  Widget _point(FlightType type) {
    final t = context.l10n;
    final p = _points[type]!;
    final k = 'airport-${type.name}';
    const coords = TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    );
    return Container(
      key: ValueKey(k),
      margin: const EdgeInsets.only(top: LuxSpacing.md),
      padding: const EdgeInsets.all(LuxSpacing.md),
      decoration: BoxDecoration(
        color: LuxColors.surfaceMuted,
        borderRadius: BorderRadius.circular(LuxRadius.md),
        border: Border.all(color: LuxColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              t.adminAirportPointTitle(type.label),
              style: LuxTypography.titleMedium,
            ),
          ),
          if (!p.enabled) ...[
            const SizedBox(height: LuxSpacing.xs),
            Text(
              p.existed
                  ? t.adminAirportPointWillRemove
                  : t.adminAirportPointNone,
              style: LuxTypography.bodyMedium,
            ),
            const SizedBox(height: LuxSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: ValueKey('$k-add'),
                style: flightButtonStyle(),
                onPressed:
                    _busy ? null : () => setState(() => p.enabled = true),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(t.adminAirportPointAdd),
              ),
            ),
          ] else ...[
            _field(
              p.name,
              keyName: '$k-name',
              label: t.adminAirportPointName,
              validator: (v) => _len(v, 1, 80, t.adminAirportPointNameInvalid),
            ),
            _field(
              p.instructions,
              keyName: '$k-instructions',
              label: t.adminAirportPointInstructions,
              maxLines: 3,
              validator: (v) =>
                  _len(v, 0, 500, t.adminAirportPointInstructionsInvalid),
            ),
            _field(
              p.lat,
              keyName: '$k-lat',
              label: t.adminAirportLat,
              keyboard: coords,
              validator: (v) {
                final lat = PickupPointRules.parse(v ?? '');
                if (!PickupPointRules.latOk(lat)) {
                  return t.adminAirportLatInvalid;
                }
                final lng = PickupPointRules.parse(p.lng.text);
                return PickupPointRules.notZero(lat, lng)
                    ? null
                    : t.adminAirportZeroInvalid;
              },
            ),
            _field(
              p.lng,
              keyName: '$k-lng',
              label: t.adminAirportLng,
              keyboard: coords,
              validator: (v) =>
                  PickupPointRules.lngOk(PickupPointRules.parse(v ?? ''))
                      ? null
                      : t.adminAirportLngInvalid,
            ),
            const SizedBox(height: LuxSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: ValueKey('$k-remove'),
                style: flightButtonStyle(color: LuxColors.error),
                onPressed:
                    _busy ? null : () => setState(() => p.enabled = false),
                icon: const Icon(Icons.wrong_location_outlined),
                label: Text(t.adminAirportPointRemove),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AlertDialog(
      key: const ValueKey('airport-editor'),
      title: Text(
        _isNew
            ? t.adminAirportNewTitle
            : t.adminAirportEditTitle(widget.airport!.code),
      ),
      scrollable: true,
      content: SizedBox(
        width: 560,
        child: Form(
          key: _form,
          autovalidateMode:
              _tried ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                _code,
                keyName: 'airport-code',
                label: t.adminAirportCode,
                enabled: _isNew,
                helper: _isNew ? null : t.adminAirportCodeLocked,
                validator: (v) => kAirportCodePattern.hasMatch((v ?? '').trim())
                    ? null
                    : t.adminAirportCodeInvalid,
              ),
              _field(
                _name,
                keyName: 'airport-name',
                label: t.adminAirportName,
                validator: (v) => _len(v, 2, 120, t.adminAirportNameInvalid),
              ),
              _field(
                _city,
                keyName: 'airport-city',
                label: t.adminAirportCity,
                validator: (v) => _len(v, 2, 80, t.adminAirportCityInvalid),
              ),
              Padding(
                padding: const EdgeInsets.only(top: LuxSpacing.sm),
                child:
                    Text(t.adminAirportTimeZone, style: LuxTypography.caption),
              ),
              for (final type in FlightType.values) _point(type),
              const SizedBox(height: LuxSpacing.md),
              FlightReasonField(
                controller: _reason,
                enabled: !_busy,
                onChanged: () => setState(() {}),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: LuxSpacing.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      key: const ValueKey('airport-error'),
                      style: LuxTypography.bodyMedium.copyWith(
                        color: LuxColors.error,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: kFlightMinTap),
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(t.adminFlightCancel),
        ),
        FilledButton(
          key: const ValueKey('airport-save'),
          style: FilledButton.styleFrom(minimumSize: kFlightMinTap),
          onPressed: _busy || !flightReasonOk(_reason.text) ? null : _submit,
          child: Text(t.adminAirportSave),
        ),
      ],
    );
  }
}
