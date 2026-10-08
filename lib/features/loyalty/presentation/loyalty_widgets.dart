import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../data/loyalty_repository.dart';
import '../domain/loyalty.dart';

extension LoyaltyTierIdL10n on LoyaltyTierId {
  String localizedName(AppLocalizations l) => switch (this) {
        LoyaltyTierId.silver => l.loyaltySilver,
        LoyaltyTierId.gold => l.loyaltyGold,
        LoyaltyTierId.platinum => l.loyaltyPlatinum,
      };
}

/// Localized tier name for a stored tier id (null when unknown or absent).
String? loyaltyTierName(AppLocalizations l, String? raw) => tierIdFrom(raw)?.localizedName(l);

String _pct(double v) => NumberFormat.decimalPattern().format(v);

String localizedLoyaltyError(AppLocalizations l, String code) => switch (code) {
      'loyalty/thresholds-order' => l.loyaltyErrorThresholds,
      'loyalty/discounts-order' => l.loyaltyErrorDiscounts,
      'loyalty/discount-range' => l.loyaltyErrorRange,
      _ => l.loyaltyErrorMinRides,
    };

/// Admin panel → Fidelidad: turn the program on and set each tier's
/// threshold (rides in 12 months) and discount. Off until enabled.
class LoyaltyAdminTab extends StatefulWidget {
  const LoyaltyAdminTab({super.key, this.repository});
  final LoyaltyRepository? repository;

  @override
  State<LoyaltyAdminTab> createState() => _LoyaltyAdminTabState();
}

class _LoyaltyAdminTabState extends State<LoyaltyAdminTab> {
  late final LoyaltyRepository _repo = widget.repository ?? sl<LoyaltyRepository>();
  final _rides = {for (final t in LoyaltyTierId.values) t: TextEditingController()};
  final _discounts = {for (final t in LoyaltyTierId.values) t: TextEditingController()};
  bool _enabled = false;
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo.watchConfig().first.then((c) {
      if (!mounted) return;
      setState(() {
        _enabled = c.enabled;
        for (final t in c.tiers) {
          _rides[t.id]!.text = '${t.minRides}';
          _discounts[t.id]!.text = _pct(t.discountPct);
        }
        _loaded = true;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    for (final c in [..._rides.values, ..._discounts.values]) {
      c.dispose();
    }
    super.dispose();
  }

  List<LoyaltyTier> get _tiers => [
        for (final t in LoyaltyTierId.values)
          LoyaltyTier(
            id: t,
            minRides: int.tryParse(_rides[t]!.text.trim()) ?? 0,
            discountPct: double.tryParse(_discounts[t]!.text.trim().replaceAll(',', '.')) ?? -1,
          ),
      ];

  Future<void> _save() async {
    final l = context.l10n;
    final tiers = _tiers;
    final error = _enabled ? Loyalty.configError(tiers) : null;
    if (error != null) {
      setState(() => _error = localizedLoyaltyError(l, error));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.saveConfig(
        enabled: _enabled,
        tiers: _enabled ? tiers : tiers.where((t) => t.minRides > 0 && t.discountPct >= 0).toList(),
      );
      if (mounted) showLuxSnackbar(context, l.loyaltySaved);
    } catch (_) {
      if (mounted) showLuxSnackbar(context, l.adminActionFailed, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!_loaded) return const Center(child: CircularProgressIndicator(color: LuxColors.accent));
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      children: [
        SectionHeader(title: l.loyaltyAdminTitle),
        const SizedBox(height: LuxSpacing.sm),
        Text(l.loyaltyAdminIntro, style: LuxTypography.bodyMedium),
        const SizedBox(height: LuxSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: LuxColors.accent,
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
          title: Text(l.loyaltyEnable, style: LuxTypography.bodyLarge),
          subtitle: Text(_enabled ? l.loyaltyEnabledHint : l.loyaltyDisabledHint, style: LuxTypography.caption),
        ),
        const SizedBox(height: LuxSpacing.md),
        for (final t in LoyaltyTierId.values)
          Padding(
            padding: const EdgeInsets.only(bottom: LuxSpacing.md),
            child: LuxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.localizedName(l), style: LuxTypography.titleMedium),
                const SizedBox(height: LuxSpacing.md),
                Row(children: [
                  Expanded(
                    child: LuxTextField(
                      controller: _rides[t],
                      label: l.loyaltyMinRides,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: LuxSpacing.sm),
                  Expanded(
                    child: LuxTextField(
                      controller: _discounts[t],
                      label: l.loyaltyDiscountPct,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: digits,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        Text(l.loyaltyRulesNote, style: LuxTypography.caption),
        if (_error != null) ...[
          const SizedBox(height: LuxSpacing.sm),
          Text(_error!, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error)),
        ],
        const SizedBox(height: LuxSpacing.lg),
        LuxButton(label: l.loyaltySave, loading: _busy, onPressed: _busy ? null : _save),
      ],
    );
  }
}

/// Profile card: tier, rides in 12 months and progress to the next tier.
/// Hidden while the program is off.
class LoyaltyProfileCard extends StatefulWidget {
  const LoyaltyProfileCard({super.key, this.repository});
  final LoyaltyRepository? repository;

  @override
  State<LoyaltyProfileCard> createState() => _LoyaltyProfileCardState();
}

class _LoyaltyProfileCardState extends State<LoyaltyProfileCard> {
  Future<LoyaltyStatus>? _status;

  @override
  void initState() {
    super.initState();
    final repo = widget.repository ?? (sl.isRegistered<LoyaltyRepository>() ? sl<LoyaltyRepository>() : null);
    _status = repo?.myStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<LoyaltyStatus>(
      future: _status,
      builder: (context, snap) {
        final s = snap.data;
        if (s == null || !s.enabled) return const SizedBox.shrink();
        final tier = s.tier;
        final next = s.next;
        return Padding(
          padding: const EdgeInsets.only(top: LuxSpacing.xl),
          child: LuxCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.workspace_premium_outlined, color: LuxColors.accent),
                const SizedBox(width: LuxSpacing.sm),
                Expanded(child: Text(l.loyaltyProgramName, style: LuxTypography.titleMedium)),
                Text(tier == null ? l.loyaltyMember : tier.id.localizedName(l),
                    style: LuxTypography.titleMedium.copyWith(color: LuxColors.accent)),
              ]),
              const SizedBox(height: LuxSpacing.sm),
              Text(
                tier == null || tier.discountPct <= 0
                    ? l.loyaltyNoBenefitYet
                    : l.loyaltyBenefit(_pct(tier.discountPct)),
                style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white),
              ),
              const SizedBox(height: LuxSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.progress,
                  minHeight: 6,
                  color: LuxColors.accent,
                  backgroundColor: LuxColors.white.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              Text(
                next == null
                    ? l.loyaltyTopTier(s.rides)
                    : l.loyaltyToNext(s.ridesToNext, next.id.localizedName(l), _pct(next.discountPct)),
                style: LuxTypography.caption,
              ),
              const SizedBox(height: 2),
              Text(l.loyaltyHowItWorks, style: LuxTypography.caption),
            ]),
          ),
        );
      },
    );
  }
}
