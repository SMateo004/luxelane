import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';

/// Cancelación del pasajero (Parte B): el servidor calcula el recargo con la
/// política de config/ops; la app lo muestra solo si es mayor que cero y lo
/// manda como aceptado. Si cambió mientras decidía, se vuelve a mostrar.
/// Devuelve true si quedó cancelada.
///
/// [onConfirmed] se llama al confirmar en el diálogo, justo antes de pedir
/// la cancelación: hasta entonces la pantalla no debe decir «Cancelando…»
/// (E29).
Future<bool> runCancelBookingFlow(
  BuildContext context,
  BookingRepository repository,
  String bookingId, {
  VoidCallback? onConfirmed,
}) async {
  final quote = await repository.previewCancellation(bookingId);
  if (!context.mounted) return false;
  var fee = quote.fold((f) {
    showLuxSnackbar(context, f.message, isError: true);
    return null;
  }, (q) => q.fee);
  if (fee == null) return false;

  // Como mucho dos vueltas: si el recargo vuelve a cambiar, se avisa.
  for (var attempt = 0; attempt < 2; attempt++) {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelBookingDialog(fee: fee!, feeChanged: attempt > 0),
    );
    if (reason == null || !context.mounted) return false;
    onConfirmed?.call();
    final result = await repository.cancelBooking(
      bookingId,
      reason: reason,
      acceptedFee: fee!,
    );
    if (!context.mounted) return false;
    final failure = result.fold((f) => f, (_) => null);
    if (failure == null) {
      showLuxSnackbar(context, 'Reserva cancelada');
      return true;
    }
    if (failure is! CancellationFeeChangedFailure) {
      showLuxSnackbar(context, failure.message, isError: true);
      return false;
    }
    fee = failure.fee;
  }
  if (context.mounted) {
    showLuxSnackbar(
      context,
      'El recargo cambió de nuevo. Inténtalo otra vez.',
      isError: true,
    );
  }
  return false;
}

/// Confirma la cancelación con su motivo (lista cerrada) y, si lo hay, el
/// recargo. Devuelve el motivo elegido o null.
class CancelBookingDialog extends StatefulWidget {
  const CancelBookingDialog({
    super.key,
    required this.fee,
    this.feeChanged = false,
  });

  final double fee;
  final bool feeChanged;

  @override
  State<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  String _reason = 'other';

  @override
  Widget build(BuildContext context) {
    final hasFee = widget.fee > 0;
    return AlertDialog(
      backgroundColor: LuxColors.surface,
      title: const Text('Cancelar reserva', style: LuxTypography.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasFee)
              Semantics(
                liveRegion: true,
                child: Container(
                  key: const Key('cancel-fee'),
                  padding: const EdgeInsets.all(LuxSpacing.sm),
                  margin: const EdgeInsets.only(bottom: LuxSpacing.md),
                  decoration: BoxDecoration(
                    color: LuxColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(LuxRadius.md),
                  ),
                  child: Text(
                    '${widget.feeChanged ? 'El recargo cambió. ' : ''}'
                    'Según la política de cancelación, cancelar ahora tiene '
                    'un recargo de ${LuxFormat.money(widget.fee)}.',
                    style: LuxTypography.bodyMedium,
                  ),
                ),
              ),
            const Text(
              'Tu chófer quedará libre y, si pagaste con tarjeta, se liberará '
              'la retención.',
              style: LuxTypography.bodyMedium,
            ),
            const SizedBox(height: LuxSpacing.sm),
            const Text('Motivo', style: LuxTypography.labelLarge),
            for (final e in kRiderCancelReasons.entries)
              RadioListTile<String>(
                value: e.key,
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v ?? 'other'),
                title: Text(e.value, style: LuxTypography.bodyMedium),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        TextButton(
          key: const Key('confirm-cancel'),
          onPressed: () => Navigator.pop(context, _reason),
          child: Text(
            hasFee ? 'Cancelar con recargo' : 'Cancelar reserva',
            style: const TextStyle(color: LuxColors.error),
          ),
        ),
      ],
    );
  }
}
