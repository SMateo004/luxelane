import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/enums/enums.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../domain/adjustments.dart';

extension AdjustmentTypeL10n on AdjustmentType {
  String label(AppLocalizations l) => switch (this) {
        AdjustmentType.waiting => l.adjustTypeWaiting,
        AdjustmentType.toll => l.adjustTypeToll,
        AdjustmentType.parking => l.adjustTypeParking,
        AdjustmentType.extraStop => l.adjustTypeExtraStop,
        AdjustmentType.correction => l.adjustTypeCorrection,
      };
}

String localizedAdjustError(AppLocalizations l, String code) => switch (code) {
      'adjust/type' => l.adjustErrorType,
      'adjust/amount' => l.adjustErrorAmount,
      'adjust/below-zero' => l.adjustErrorBelowZero,
      'adjust/note' => l.adjustErrorNote,
      'adjust/status' => l.adjustErrorStatus,
      'adjust/card' => l.adjustErrorCard,
      _ => l.adminActionFailed,
    };

/// "+Bs 15,00" / "−Bs 10,00".
String signedMoney(double v) => '${v < 0 ? '−' : '+'}${LuxMoney.format(v.abs(), cents: true)}';

typedef AdjustSubmit = Future<String?> Function(AdjustmentType type, double amount, String note);

/// Admin → Reservas → "Ajustar precio": an extra charge agreed during the
/// ride (waiting, toll, parking, extra stop) or a correction (±).
class AdjustPriceDialog extends StatefulWidget {
  const AdjustPriceDialog({super.key, required this.booking, required this.onSubmit});
  final Booking booking;

  /// Returns an adjust/* error code, or null when saved.
  final AdjustSubmit onSubmit;

  @override
  State<AdjustPriceDialog> createState() => _AdjustPriceDialogState();
}

class _AdjustPriceDialogState extends State<AdjustPriceDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  AdjustmentType? _type;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_amount.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final l = context.l10n;
    final error = Adjustments.validate(widget.booking, _type, _value, _note.text);
    if (error != null) {
      setState(() => _error = localizedAdjustError(l, error));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.onSubmit(_type!, _value!, _note.text.trim());
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = localizedAdjustError(l, result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = widget.booking;
    final v = _value;
    final correction = _type == AdjustmentType.correction;
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(l.adjustTitle, style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.adjustCurrent(LuxMoney.format(b.paidAmount, cents: true)), style: LuxTypography.bodyMedium),
            for (final a in b.adjustments)
              Text(
                  a.note == null
                      ? l.adjustLine(a.type.label(l), signedMoney(a.amount))
                      : l.adjustLineNote(a.type.label(l), signedMoney(a.amount), a.note!),
                  style: LuxTypography.caption),
            const SizedBox(height: LuxSpacing.md),
            Text(l.adjustWhat, style: LuxTypography.caption),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final t in AdjustmentType.values)
                ChoiceChip(
                  label: Text(t.label(l)),
                  selected: _type == t,
                  selectedColor: LuxColors.accent.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _type = t),
                ),
            ]),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              controller: _amount,
              label: correction ? l.adjustAmountSigned : l.adjustAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))],
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              controller: _note,
              label: correction ? l.adjustNoteRequired : l.adjustNote,
              hint: l.adjustNoteHint,
              maxLines: 2,
            ),
            if (v != null && v != 0) ...[
              const SizedBox(height: LuxSpacing.sm),
              Text(l.adjustNewTotal(LuxMoney.format(Adjustments.totalWith(b, v), cents: true)),
                  style: LuxTypography.titleMedium.copyWith(color: LuxColors.accent)),
            ],
            const SizedBox(height: LuxSpacing.sm),
            Text(l.adjustNote2, style: LuxTypography.caption),
            if (_error != null) ...[
              const SizedBox(height: LuxSpacing.sm),
              Text(_error!, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.commonCancel)),
        TextButton(
          onPressed: _busy ? null : _save,
          child: Text(l.adjustSave, style: const TextStyle(color: LuxColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
