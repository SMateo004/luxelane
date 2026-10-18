part of '../booking_screen.dart';

// Booking pieces beyond the base flow: pay-on-trip notice, corporate
// billing and promo codes.

// ── PAY ON TRIP NOTICE ────────────────────────────────────────────────────────

/// Shown when the rider has no saved card: the fixed price is paid to the
/// chauffeur at the end of the trip (cash or QR).
class _PayOnTripNotice extends StatelessWidget {
  const _PayOnTripNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LD.sphTint,
          borderRadius: BorderRadius.circular(_kMobileRadius),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.payments_outlined, size: 20, color: _kPanelAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.bookingPayOnTripTitle,
                      style: const TextStyle(fontFamily: kSans, fontSize: 13,
                          fontWeight: FontWeight.w600, color: _kTextPrimary)),
                  const SizedBox(height: 4),
                  Text(context.l10n.bookingPayOnTripBody,
                      style: const TextStyle(fontFamily: kSans, fontSize: 12,
                          height: 1.5, color: _kTextSub)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── CORPORATE BILLING ─────────────────────────────────────────────────────────

/// Lets a member of a corporate account bill the ride to the company
/// (monthly invoice, the chauffeur collects nothing) or pay personally.
class _CorporateBillingPanel extends StatelessWidget {
  const _CorporateBillingPanel({
    required this.company,
    required this.billCompany,
    required this.costCenter,
    required this.onBillCompany,
    required this.onCostCenter,
    required this.onReference,
  });

  final Company company;
  final bool billCompany;
  final String? costCenter;
  final ValueChanged<bool> onBillCompany;
  final ValueChanged<String?> onCostCenter;
  final ValueChanged<String> onReference;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget option(bool corporate, IconData icon, String title, String body) {
      final sel = billCompany == corporate;
      return Expanded(
        child: Semantics(
          button: true,
          selected: sel,
          child: GestureDetector(
            onTap: () => onBillCompany(corporate),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? LD.sphTint : _kCardBg,
                borderRadius: BorderRadius.circular(_kMobileRadius),
                border: Border.all(color: sel ? LD.sph : _kBorder, width: sel ? 1.5 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: sel ? _kPanelAccent : _kTextSub),
                  const SizedBox(height: 8),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: kSans, fontSize: 13,
                          fontWeight: FontWeight.w600, color: _kTextPrimary)),
                  const SizedBox(height: 2),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: kSans, fontSize: 11,
                          height: 1.4, color: _kTextTertiary)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.corpBillTo.toUpperCase(),
            style: const TextStyle(fontFamily: kSans, fontSize: 10,
                fontWeight: FontWeight.w700, color: _kTextTertiary, letterSpacing: 2.0)),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              option(true, Icons.business_outlined, company.name, l.corpBillCompanyHint),
              const SizedBox(width: 8),
              option(false, Icons.person_outline, l.corpBillPersonal, l.corpBillPersonalHint),
            ],
          ),
        ),
        if (billCompany) ...[
          if (company.costCenters.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: costCenter,
              isExpanded: true,
              dropdownColor: _kCardBg,
              style: const TextStyle(fontFamily: kSans, fontSize: 13, color: _kTextPrimary),
              decoration: InputDecoration(
                labelText: company.requireCostCenter
                    ? l.corpCostCenterRequired
                    : l.corpCostCenterOptional,
                labelStyle: const TextStyle(fontFamily: kSans, fontSize: 12,
                    color: _kTextSub, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.account_tree_outlined, size: 18, color: _kTextSub),
                filled: true,
                fillColor: _kCardBg,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)), borderSide: BorderSide(color: _kBorder)),
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)), borderSide: BorderSide(color: _kBorder)),
              ),
              items: [
                if (!company.requireCostCenter)
                  DropdownMenuItem<String>(value: null, child: Text(l.corpCostCenterNone)),
                for (final c in company.costCenters)
                  DropdownMenuItem<String>(value: c, child: Text(c)),
              ],
              onChanged: onCostCenter,
            ),
          ],
          const SizedBox(height: 12),
          _LightTextField(
            label: l.corpReference,
            hint: l.corpReferenceHint,
            icon: Icons.tag_rounded,
            onChanged: onReference,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: LD.sphTint,
                borderRadius: BorderRadius.circular(_kMobileRadius),
                border: Border.all(color: _kBorder)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 18, color: _kPanelAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.corpBillCompanyNotice(company.name),
                      style: const TextStyle(fontFamily: kSans, fontSize: 12,
                          height: 1.5, color: _kTextSub)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── PROMO CODE ────────────────────────────────────────────────────────────────

class _PromoCodeField extends StatelessWidget {
  const _PromoCodeField({
    required this.controller,
    required this.applied,
    required this.discount,
    required this.error,
    required this.checking,
    required this.onApply,
    required this.onRemove,
    this.note,
  });

  final TextEditingController controller;
  final String? applied;

  /// Shown under an applied code, e.g. when the Circle discount is larger.
  final String? note;

  /// Previewed discount for the current fare (null while re-checking).
  final double? discount;
  final String? error;
  final bool checking;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (applied != null) {
      final chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: LD.sphTint,
            borderRadius: BorderRadius.circular(_kMobileRadius),
            border: Border.all(color: LD.sph)),
        child: Row(children: [
          const Icon(Icons.local_offer_outlined, size: 18, color: _kPanelAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              discount == null
                  ? l.promoApplied(applied!)
                  : l.promoAppliedWithDiscount(applied!, LuxMoney.format(discount!.round())),
              style: const TextStyle(fontFamily: kSans, fontSize: 13,
                  fontWeight: FontWeight.w600, color: _kTextPrimary),
            ),
          ),
          if (checking)
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPanelAccent))
          else
            IconButton(
              tooltip: l.promoRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18, color: _kTextSub),
              onPressed: onRemove,
            ),
        ]),
      );
      if (note == null) return chip;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        chip,
        const SizedBox(height: 6),
        Text(note!, style: const TextStyle(fontFamily: kSans, fontSize: 12, color: _kTextSub)),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => onApply(),
              style: const TextStyle(fontFamily: kSans, fontSize: 13, color: _kTextPrimary, letterSpacing: 1),
              decoration: InputDecoration(
                labelText: l.promoFieldLabel,
                labelStyle: const TextStyle(fontFamily: kSans, fontSize: 12,
                    color: _kTextSub, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(Icons.local_offer_outlined, size: 18, color: _kTextSub),
                filled: true,
                fillColor: _kCardBg,
                isDense: true,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)), borderSide: BorderSide(color: _kBorder)),
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)), borderSide: BorderSide(color: _kBorder)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(_kMobileRadius)), borderSide: BorderSide(color: _kTextPrimary, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: _kTextPrimary,
                side: const BorderSide(color: _kTextPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kMobileRadius)),
              ),
              onPressed: checking ? null : onApply,
              child: checking
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kTextPrimary))
                  : Text(l.promoApply),
            ),
          ),
        ]),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(localizedBookingError(l, error!),
              style: const TextStyle(fontFamily: kSans, fontSize: 12, color: LuxColors.error)),
        ],
      ],
    );
  }
}
