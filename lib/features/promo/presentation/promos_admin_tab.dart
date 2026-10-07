import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/enums/enums.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../data/promo_repository.dart';
import '../domain/promo_code.dart';

String localizedPromoAdminError(AppLocalizations l, String code) => switch (code) {
      PromoAdminErrorCodes.badCode => l.promoAdminErrorCode,
      PromoAdminErrorCodes.badValue => l.promoAdminErrorValue,
      PromoAdminErrorCodes.badDates => l.promoAdminErrorDates,
      PromoAdminErrorCodes.exists => l.promoAdminErrorExists,
      _ => l.adminActionFailed,
    };

/// "20 %" / "Bs 50" (+ cap).
String promoValueLabel(AppLocalizations l, PromoCode p) {
  final v = p.type == PromoType.percent
      ? '${NumberFormat.decimalPattern().format(p.value)} %'
      : LuxMoney.format(p.value);
  return p.type == PromoType.percent && p.maxDiscount > 0
      ? l.promoAdminValueCapped(v, LuxMoney.format(p.maxDiscount))
      : v;
}

/// Admin panel → Promociones: create, edit and pause promo codes and see
/// how much each one has been used.
class PromosAdminTab extends StatelessWidget {
  const PromosAdminTab({super.key, this.repository, this.now});
  final PromoRepository? repository;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? sl<PromoRepository>();
    final l = context.l10n;
    final t = now ?? DateTime.now();
    return StreamBuilder<List<PromoCode>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        final promos = snap.data ?? const <PromoCode>[];
        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            SectionHeader(title: l.promoAdminTitle),
            const SizedBox(height: LuxSpacing.sm),
            Text(l.promoAdminIntro, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: LuxButton(
                label: l.promoAdminCreate,
                icon: Icons.add_rounded,
                width: 220,
                height: 44,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PromoEditDialog(repo: repo),
                ),
              ),
            ),
            const SizedBox(height: LuxSpacing.lg),
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
              const Center(child: CircularProgressIndicator(color: LuxColors.accent))
            else if (promos.isEmpty)
              EmptyState(icon: Icons.local_offer_outlined, message: l.promoAdminEmpty)
            else
              for (final p in promos) _PromoTile(promo: p, repo: repo, now: t),
          ],
        );
      },
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({required this.promo, required this.repo, required this.now});
  final PromoCode promo;
  final PromoRepository repo;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = promo;
    final state = !p.active
        ? l.promoAdminPaused
        : p.expiredAt(now)
            ? l.promoAdminExpired
            : p.exhausted()
                ? l.promoAdminExhausted
                : l.promoAdminActive;
    final usage = p.maxRedemptions > 0
        ? l.promoAdminUsageOf(p.redemptions, p.maxRedemptions)
        : l.promoAdminUsage(p.redemptions);
    final meta = [
      promoValueLabel(l, p),
      usage,
      if (p.validUntil != null) l.promoAdminUntil(DateFormat.yMMMd().format(p.validUntil!)),
      if (p.firstRideOnly) l.promoAdminFirstRide,
      if (p.minFare > 0) l.promoAdminMinFare(LuxMoney.format(p.minFare)),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
      child: LuxCard(
        child: Row(children: [
          const Icon(Icons.local_offer_outlined, color: LuxColors.accent),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: LuxSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(p.code, style: LuxTypography.titleMedium.copyWith(letterSpacing: 1)),
                  Text(state, style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
                ]),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(p.description, overflow: TextOverflow.ellipsis, style: LuxTypography.bodyMedium),
                ],
                const SizedBox(height: 2),
                Text(meta, style: LuxTypography.caption),
              ],
            ),
          ),
          Tooltip(
            message: p.active ? l.promoAdminPause : l.promoAdminResume,
            child: Switch(
              value: p.active,
              activeColor: LuxColors.accent,
              onChanged: (v) async {
                final e = await repo.save(p.copyWith(active: v), create: false);
                if (context.mounted && e != null) {
                  showLuxSnackbar(context, localizedPromoAdminError(l, e), isError: true);
                }
              },
            ),
          ),
          IconButton(
            tooltip: l.promoAdminEdit,
            icon: const Icon(Icons.edit_outlined, color: LuxColors.whiteSecondary),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PromoEditDialog(repo: repo, initial: p),
            ),
          ),
        ]),
      ),
    );
  }
}

class PromoEditDialog extends StatefulWidget {
  const PromoEditDialog({super.key, required this.repo, this.initial});
  final PromoRepository repo;
  final PromoCode? initial;

  @override
  State<PromoEditDialog> createState() => _PromoEditDialogState();
}

class _PromoEditDialogState extends State<PromoEditDialog> {
  late final PromoCode? _i = widget.initial;
  late final _code = TextEditingController(text: _i?.code ?? '');
  late final _desc = TextEditingController(text: _i?.description ?? '');
  late final _value = TextEditingController(text: _num(_i?.value));
  late final _cap = TextEditingController(text: _num(_i?.maxDiscount));
  late final _minFare = TextEditingController(text: _num(_i?.minFare));
  late final _maxUses = TextEditingController(text: _num(_i?.maxRedemptions.toDouble()));
  late final _perUser = TextEditingController(text: '${_i?.perUserLimit ?? 1}');
  late PromoType _type = _i?.type ?? PromoType.percent;
  late DateTime? _from = _i?.validFrom;
  late DateTime? _until = _i?.validUntil;
  late bool _firstRide = _i?.firstRideOnly ?? false;
  late Set<VehicleClass> _classes = {...?_i?.vehicleClasses};
  bool _busy = false;
  String? _error;

  static String _num(double? v) =>
      v == null || v == 0 ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void dispose() {
    for (final c in [_code, _desc, _value, _cap, _minFare, _maxUses, _perUser]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _pickDate(bool from) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _until) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        // Valid through the end of the chosen day.
        _until = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    final promo = PromoCode(
      code: _code.text.trim().toUpperCase(),
      type: _type,
      value: _d(_value),
      description: _desc.text.trim(),
      maxDiscount: _type == PromoType.percent ? _d(_cap) : 0,
      minFare: _d(_minFare),
      validFrom: _from,
      validUntil: _until,
      maxRedemptions: _d(_maxUses).toInt(),
      redemptions: _i?.redemptions ?? 0,
      perUserLimit: _d(_perUser).toInt().clamp(1, 100),
      firstRideOnly: _firstRide,
      vehicleClasses: _classes.toList(),
      active: _i?.active ?? true,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    final e = await widget.repo.save(promo, create: _i == null);
    if (!mounted) return;
    if (e == null) {
      Navigator.of(context).pop();
      showLuxSnackbar(context, l.promoAdminSaved);
    } else {
      setState(() {
        _busy = false;
        _error = localizedPromoAdminError(l, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    Widget dateButton(bool from) {
      final d = from ? _from : _until;
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        onPressed: () => _pickDate(from),
        icon: const Icon(Icons.event_outlined, size: 16),
        label: Text(d == null
            ? (from ? l.promoAdminFromAny : l.promoAdminUntilAny)
            : (from
                ? l.promoAdminFrom(DateFormat.yMMMd().format(d))
                : l.promoAdminUntil(DateFormat.yMMMd().format(d)))),
      );
    }

    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(_i == null ? l.promoAdminCreate : l.promoAdminEditTitle(_i.code), style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LuxTextField(
                controller: _code,
                label: l.promoAdminCode,
                hint: l.promoAdminCodeHint,
                readOnly: _i != null,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                  LengthLimitingTextInputFormatter(20),
                ],
              ),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(controller: _desc, label: l.promoAdminDescription, hint: l.promoAdminDescriptionHint),
              const SizedBox(height: LuxSpacing.md),
              Wrap(spacing: LuxSpacing.sm, children: [
                ChoiceChip(
                  label: Text(l.promoAdminPercent),
                  selected: _type == PromoType.percent,
                  onSelected: (_) => setState(() => _type = PromoType.percent),
                ),
                ChoiceChip(
                  label: Text(l.promoAdminFixed),
                  selected: _type == PromoType.fixed,
                  onSelected: (_) => setState(() => _type = PromoType.fixed),
                ),
              ]),
              const SizedBox(height: LuxSpacing.md),
              Row(children: [
                Expanded(
                  child: LuxTextField(
                    controller: _value,
                    label: _type == PromoType.percent ? l.promoAdminValuePercent : l.promoAdminValueFixed,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: digits,
                  ),
                ),
                if (_type == PromoType.percent) ...[
                  const SizedBox(width: LuxSpacing.sm),
                  Expanded(
                    child: LuxTextField(
                      controller: _cap,
                      label: l.promoAdminCap,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: digits,
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: LuxSpacing.md),
              Row(children: [
                Expanded(
                  child: LuxTextField(
                    controller: _maxUses,
                    label: l.promoAdminMaxUses,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(
                  child: LuxTextField(
                    controller: _perUser,
                    label: l.promoAdminPerUser,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ]),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(
                controller: _minFare,
                label: l.promoAdminMinFareLabel,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: digits,
              ),
              const SizedBox(height: LuxSpacing.md),
              Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.sm, children: [dateButton(true), dateButton(false)]),
              const SizedBox(height: LuxSpacing.md),
              Text(l.promoAdminClasses, style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.xs),
              Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.sm, children: [
                for (final c in VehicleClass.values)
                  FilterChip(
                    label: Text(c.localizedLabel(l)),
                    selected: _classes.contains(c),
                    onSelected: (v) => setState(() => _classes = v ? ({..._classes, c}) : (_classes..remove(c))),
                  ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: LuxColors.accent,
                value: _firstRide,
                onChanged: (v) => setState(() => _firstRide = v),
                title: Text(l.promoAdminFirstRideSwitch, style: LuxTypography.bodyLarge),
              ),
              if (_error != null) ...[
                const SizedBox(height: LuxSpacing.sm),
                Text(_error!, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.commonCancel)),
        TextButton(
          onPressed: _busy ? null : _save,
          child: Text(l.promoAdminSave,
              style: const TextStyle(color: LuxColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
