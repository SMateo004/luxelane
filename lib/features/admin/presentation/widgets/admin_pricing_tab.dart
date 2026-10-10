import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/admin_bloc.dart';
import 'admin_shared_widgets.dart';

/// Tarifas por tipo de servicio y clase de vehículo.
///
/// Lo que se guarda aquí va a `/pricingRules` y la app del pasajero lo aplica
/// al instante (PricingCatalog): precios de la web, del selector de vehículo
/// y el importe con el que se crea la reserva.
class PricingTab extends StatelessWidget {
  const PricingTab({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminBloc, AdminState>(builder: (context, state) {
        final custom = VehicleClass.values
            .expand((vc) => ServiceType.values.map((st) => (vc, st)))
            .where((p) => state.hasCustomRule(p.$1, p.$2))
            .length;
        final disabled = VehicleClass.values
            .expand((vc) => ServiceType.values.map((st) => (vc, st)))
            .where((p) => !state.effectiveRule(p.$1, p.$2).isActive)
            .length;
        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            const SectionHeader(title: 'Tarifas por servicio'),
            const SizedBox(height: LuxSpacing.sm),
            const Text(
              'Cada combinación de servicio y clase tiene su propia tarifa. '
              'Los cambios se aplican al instante en la web y la app: precios '
              'mostrados e importe de las nuevas reservas. Las reservas ya '
              'creadas conservan su precio.',
              style: LuxTypography.caption,
            ),
            const SizedBox(height: LuxSpacing.md),
            Wrap(
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [
                AdminTag('$custom personalizadas', color: LuxColors.sapphire),
                AdminTag(
                    '${VehicleClass.values.length * ServiceType.values.length - custom} de fábrica',
                    color: LuxColors.inkTertiary),
                if (disabled > 0)
                  AdminTag('$disabled desactivadas', color: LuxColors.warning),
                if (state.isMaintenanceMode)
                  const AdminTag('Reservas en pausa (mantenimiento)',
                      color: LuxColors.error),
              ],
            ),
            for (final st in ServiceType.values) ...[
              const SizedBox(height: LuxSpacing.xl),
              Text(st.label, style: LuxTypography.titleLarge),
              Text(st.description, style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.md),
              for (final vc in VehicleClass.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                  child: _PricingCard(
                    key: ValueKey(PricingRule.idFor(vc, st)),
                    rule: state.effectiveRule(vc, st),
                    isCustom: state.hasCustomRule(vc, st),
                    updatedBy: () {
                      final by = state.effectiveRule(vc, st).updatedBy;
                      return by == null ? null : state.userName(by);
                    }(),
                  ),
                ),
            ],
          ],
        );
      });
}

class _PricingCard extends StatefulWidget {
  const _PricingCard({
    super.key,
    required this.rule,
    required this.isCustom,
    this.updatedBy,
  });
  final PricingRule rule;
  final bool isCustom;
  final String? updatedBy;

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _expanded = false;
  late final _base = TextEditingController();
  late final _perKm = TextEditingController();
  late final _perHour = TextEditingController();
  late final _min = TextEditingController();
  late bool _active;
  final _simKm = TextEditingController(text: '25');
  final _simHours = TextEditingController(text: '3');

  bool get _hourly => widget.rule.serviceType == ServiceType.byTheHour;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  static double? _parse(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  void _load(PricingRule r) {
    _base.text = _fmt(r.basePriceUsd);
    _perKm.text = _fmt(r.pricePerKmUsd);
    _perHour.text = _fmt(r.pricePerHourUsd);
    _min.text = _fmt(r.minimumPriceUsd);
    _active = r.isActive;
  }

  /// Tarifa con lo escrito en el formulario (null si algún campo no es número).
  PricingRule? get _draft {
    final base = _parse(_base.text);
    final km = _parse(_perKm.text);
    final hour = _parse(_perHour.text);
    final min = _parse(_min.text);
    if (base == null || km == null || hour == null || min == null) {
      return null;
    }
    return widget.rule.copyWith(
      basePriceUsd: base,
      pricePerKmUsd: km,
      pricePerHourUsd: hour,
      minimumPriceUsd: min,
      isActive: _active,
    );
  }

  bool get _dirty {
    final d = _draft;
    return d == null || !d.sameFareAs(widget.rule);
  }

  @override
  void initState() {
    super.initState();
    _load(widget.rule);
  }

  @override
  void didUpdateWidget(covariant _PricingCard old) {
    super.didUpdateWidget(old);
    // Si llega una tarifa nueva (otro admin, o tras guardar) y no hay edición
    // en curso, el formulario refleja lo que está vigente.
    if (!widget.rule.sameFareAs(old.rule) && !_dirtyAgainst(old.rule)) {
      _load(widget.rule);
    }
  }

  bool _dirtyAgainst(PricingRule r) {
    final d = _draft;
    return d == null || !d.sameFareAs(r);
  }

  @override
  void dispose() {
    for (final c in [_base, _perKm, _perHour, _min, _simKm, _simHours]) {
      c.dispose();
    }
    super.dispose();
  }

  String _summary(PricingRule r) => _hourly
      ? '${r.basePriceUsd > 0 ? '${bs(r.basePriceUsd, short: true)} + ' : ''}'
          '${bs(r.pricePerHourUsd, short: true)}/h · mín. ${bs(r.minimumPriceUsd, short: true)}'
      : '${bs(r.basePriceUsd, short: true)} + ${bs(r.pricePerKmUsd)}/km · '
          'mín. ${bs(r.minimumPriceUsd, short: true)}';

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final errors = draft.validate();
    if (errors.isNotEmpty) {
      showLuxSnackbar(context, errors.join('. '), isError: true);
      return;
    }
    final old = widget.rule;
    final ok = await confirmAdminAction(
      context,
      title: 'Guardar tarifa',
      message: '${old.vehicleClass.label} · ${old.serviceType.label}\n\n'
          'Antes: ${_summary(old)}${old.isActive ? '' : ' (desactivada)'}\n'
          'Ahora: ${_summary(draft)}${draft.isActive ? '' : ' (desactivada)'}\n\n'
          'Se aplica de inmediato a las nuevas reservas.',
      confirmLabel: 'Guardar',
    );
    if (ok == null || !mounted) return;
    context.read<AdminBloc>().add(AdminUpdatePricingRequested(draft));
  }

  Future<void> _reset() async {
    final ok = await confirmAdminAction(
      context,
      title: 'Restablecer tarifa',
      message: 'Se eliminará la tarifa personalizada y se volverá a la de '
          'fábrica: ${_summary(PricingRule.fallback(widget.rule.vehicleClass, widget.rule.serviceType))}.',
      confirmLabel: 'Restablecer',
      destructive: true,
    );
    if (ok == null || !mounted) return;
    context.read<AdminBloc>().add(AdminResetPricingRequested(widget.rule));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rule;
    final draft = _draft;
    final narrow = MediaQuery.sizeOf(context).width < 640;

    final fields = <Widget>[
      _PriceField(label: 'Tarifa base', controller: _base, onChanged: _touch),
      if (!_hourly)
        _PriceField(label: 'Por km', controller: _perKm, onChanged: _touch),
      if (_hourly)
        _PriceField(label: 'Por hora', controller: _perHour, onChanged: _touch),
      _PriceField(label: 'Mínimo', controller: _min, onChanged: _touch),
    ];

    final simValue =
        _hourly ? int.tryParse(_simHours.text) ?? 0 : _parse(_simKm.text) ?? 0;
    final simPrice = draft == null
        ? null
        : _hourly
            ? draft.estimate(hours: simValue.toInt())
            : draft.estimate(km: simValue.toDouble());

    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: LuxSpacing.sm,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(r.vehicleClass.label,
                              style: LuxTypography.titleMedium),
                          if (widget.isCustom)
                            const AdminTag('Personalizada',
                                color: LuxColors.sapphire)
                          else
                            const AdminTag('De fábrica',
                                color: LuxColors.inkTertiary),
                          if (!r.isActive)
                            const AdminTag('Desactivada',
                                color: LuxColors.warning),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_summary(r),
                          style: LuxTypography.bodyMedium
                              .copyWith(color: LuxColors.inkSecondary)),
                      if (widget.isCustom && r.updatedAt != null)
                        Text(
                          'Actualizada ${adminDate(r.updatedAt!)}'
                          '${widget.updatedBy != null ? ' por ${widget.updatedBy}' : ''}',
                          style: LuxTypography.caption,
                        ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: LuxColors.inkTertiary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: LuxSpacing.md),
            const LuxDivider(),
            const SizedBox(height: LuxSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _active,
              activeColor: LuxColors.sapphire,
              title: const Text('Disponible para reservar',
                  style: LuxTypography.bodyMedium),
              subtitle: const Text(
                  'Si se desactiva, los pasajeros no pueden reservar esta clase '
                  'con este servicio.',
                  style: LuxTypography.caption),
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: LuxSpacing.sm),
            if (narrow)
              Column(
                children: [
                  for (final f in fields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                      child: f,
                    ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    if (i > 0) const SizedBox(width: LuxSpacing.sm),
                    Expanded(child: fields[i]),
                  ],
                ],
              ),
            if (draft != null && draft.validate().isNotEmpty) ...[
              const SizedBox(height: LuxSpacing.sm),
              Text(draft.validate().join('. '),
                  style:
                      LuxTypography.caption.copyWith(color: LuxColors.error)),
            ],
            if (draft == null) ...[
              const SizedBox(height: LuxSpacing.sm),
              Text('Revisa los importes: solo números',
                  style:
                      LuxTypography.caption.copyWith(color: LuxColors.error)),
            ],
            const SizedBox(height: LuxSpacing.md),
            // ── Simulador ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(LuxSpacing.md),
              decoration: BoxDecoration(
                color: LuxColors.bg,
                borderRadius: BorderRadius.circular(LuxRadius.sm),
                border: Border.all(color: LuxColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined,
                      size: 18, color: LuxColors.inkTertiary),
                  const SizedBox(width: LuxSpacing.sm),
                  const Flexible(
                    child: Text('Simular',
                        overflow: TextOverflow.ellipsis,
                        style: LuxTypography.caption),
                  ),
                  const SizedBox(width: LuxSpacing.sm),
                  SizedBox(
                    width: 84,
                    child: TextField(
                      controller: _hourly ? _simHours : _simKm,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: LuxTypography.bodyMedium,
                      onChanged: (_) => setState(() {}),
                      decoration: adminInputDecoration(
                          suffixText: _hourly ? 'h' : 'km'),
                    ),
                  ),
                  const SizedBox(width: LuxSpacing.md),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(simPrice == null ? '—' : bs(simPrice),
                            style: LuxTypography.titleMedium
                                .copyWith(color: LuxColors.sapphire)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuxSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: LuxSpacing.sm,
              runSpacing: LuxSpacing.sm,
              children: [
                if (widget.isCustom)
                  AdminActionButton(
                    label: 'Restablecer a fábrica',
                    icon: Icons.restart_alt_rounded,
                    color: LuxColors.warning,
                    onTap: _reset,
                  ),
                if (_dirty)
                  AdminActionButton(
                    label: 'Descartar cambios',
                    color: LuxColors.inkSecondary,
                    onTap: () => setState(() => _load(widget.rule)),
                  ),
                AdminActionButton(
                  label: 'Guardar tarifa',
                  icon: Icons.save_outlined,
                  filled: true,
                  onTap: _dirty && draft != null && draft.validate().isEmpty
                      ? _save
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _touch(String _) => setState(() {});
}

class _PriceField extends StatelessWidget {
  const _PriceField(
      {required this.label, required this.controller, required this.onChanged});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LuxTypography.caption),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: LuxTypography.bodyMedium,
            decoration: adminInputDecoration(prefixText: 'Bs '),
          ),
        ],
      );
}
