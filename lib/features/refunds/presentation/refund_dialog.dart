import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../domain/refund.dart';

extension RefundMethodL10n on RefundMethod {
  String label(AppLocalizations l) => switch (this) {
        RefundMethod.qr => l.refundMethodQr,
        RefundMethod.transfer => l.refundMethodTransfer,
        RefundMethod.cash => l.refundMethodCash,
        RefundMethod.invoiceCredit => l.refundMethodInvoiceCredit,
      };
}

String localizedRefundError(AppLocalizations l, String code) => switch (code) {
      'refund/amount' => l.refundErrorAmount,
      'refund/too-much' => l.refundErrorTooMuch,
      'refund/method' => l.refundErrorMethod,
      'refund/reason' => l.refundErrorReason,
      'refund/not-completed' => l.refundErrorNotCompleted,
      'refund/card' => l.refundErrorCard,
      _ => l.adminActionFailed,
    };

typedef RefundSubmit = Future<String?> Function(double amount, RefundMethod method, String reason);

/// Admin → Reservas → "Registrar reembolso": amount (up to what's left),
/// how it was paid back and why. The money itself moves outside the app.
class RefundDialog extends StatefulWidget {
  const RefundDialog({super.key, required this.booking, required this.onSubmit});
  final Booking booking;

  /// Returns a refund/* error code, or null when recorded.
  final RefundSubmit onSubmit;

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  late final double _max = Refunds.refundable(widget.booking);
  late final _amount = TextEditingController(text: _fmt(_max));
  final _reason = TextEditingController();
  late RefundMethod? _method = Refunds.methodsFor(widget.booking).length == 1 ? Refunds.methodsFor(widget.booking).first : null;
  bool _busy = false;
  String? _error;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final error = Refunds.validate(widget.booking, amount, _method, _reason.text);
    if (error != null) {
      setState(() => _error = localizedRefundError(l, error));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.onSubmit(amount!, _method!, _reason.text.trim());
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = localizedRefundError(l, result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = widget.booking;
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(l.refundTitle, style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              b.refundedAmount > 0
                  ? l.refundPaidAndRefunded(LuxMoney.format(b.paidAmount, cents: true),
                      LuxMoney.format(b.refundedAmount, cents: true))
                  : l.refundPaid(LuxMoney.format(b.paidAmount, cents: true)),
              style: LuxTypography.bodyMedium,
            ),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(
              controller: _amount,
              label: l.refundAmount(LuxMoney.format(_max, cents: true)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            ),
            const SizedBox(height: LuxSpacing.md),
            Text(l.refundHow, style: LuxTypography.caption),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final m in Refunds.methodsFor(b))
                ChoiceChip(
                  label: Text(m.label(l)),
                  selected: _method == m,
                  selectedColor: LuxColors.accent.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _method = m),
                ),
            ]),
            const SizedBox(height: LuxSpacing.md),
            LuxTextField(controller: _reason, label: l.refundReason, hint: l.refundReasonHint, maxLines: 2),
            const SizedBox(height: LuxSpacing.sm),
            Text(l.refundNote, style: LuxTypography.caption),
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
          child: Text(l.refundSave, style: const TextStyle(color: LuxColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
