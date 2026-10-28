import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';

/// Cancelación del pasajero: el servidor calcula la retención sobre lo
/// pagado con la política de config/ops; la app la muestra solo si es mayor
/// que cero y la manda como aceptada. Si cambió mientras decidía, se vuelve
/// a mostrar. Nada de plazos ni promesas de devolución (pagos, B4).
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
  final preview = quote.fold((f) {
    showLuxSnackbar(context, f.message, isError: true);
    return null;
  }, (q) => q);
  if (preview == null) return false;
  double? fee = preview.fee;

  // Como mucho dos vueltas: si el recargo vuelve a cambiar, se avisa.
  for (var attempt = 0; attempt < 2; attempt++) {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelBookingDialog(
        fee: fee!,
        refund: attempt == 0 ? preview.refund : null,
        feeChanged: attempt > 0,
      ),
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
      'La retención cambió de nuevo. Inténtalo otra vez.',
      isError: true,
    );
  }
  return false;
}

/// Confirma la cancelación con su motivo (lista cerrada) y, si la hay, la
/// retención. Devuelve el motivo elegido o null.
class CancelBookingDialog extends StatefulWidget {
  const CancelBookingDialog({
    super.key,
    required this.fee,
    this.refund,
    this.feeChanged = false,
  });

  /// Retención en bolivianos (0: no se menciona).
  final double fee;

  /// Lo que quedaría pendiente de devolver; null si no se sabe (tras un
  /// cambio de la retención).
  final double? refund;
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
                    '${widget.feeChanged ? 'La retención cambió. ' : ''}'
                    'Según la política de cancelación, si cancelas ahora se '
                    'retienen ${LuxFormat.money(widget.fee)} de lo que '
                    'pagaste.',
                    style: LuxTypography.bodyMedium,
                  ),
                ),
              ),
            if ((widget.refund ?? 0) > 0) ...[
              Text(
                '${LuxFormat.money(widget.refund!)} quedan pendientes de '
                'devolución. Te avisaremos cuando central la registre.',
                key: const Key('cancel-refund'),
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: LuxSpacing.sm),
            ],
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
            hasFee ? 'Cancelar con retención' : 'Cancelar reserva',
            style: const TextStyle(color: LuxColors.error),
          ),
        ),
      ],
    );
  }
}
