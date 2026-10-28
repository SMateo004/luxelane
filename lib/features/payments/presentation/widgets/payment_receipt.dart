import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/booking_payment.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';

String _bs(int cents) => LuxFormat.money(BookingPayment.bs(cents));

/// Texto del método en el comprobante.
String receiptMethodLabel(String? m) => switch (m) {
      PayMethod.manualQr => 'QR o transferencia',
      PayMethod.card => 'Tarjeta',
      _ => '—',
    };

/// La reserva espera el pago: importe y acceso a la pantalla de pago.
class PaymentPendingCard extends StatelessWidget {
  const PaymentPendingCard({
    super.key,
    required this.payment,
    required this.onPay,
  });

  final BookingPayment payment;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                payment.reported ? 'Esperando confirmación' : 'Pago pendiente',
                style: LuxTypography.titleMedium,
              ),
              const SizedBox(height: LuxSpacing.xs),
              Text(
                payment.reported
                    ? 'Avisaste que pagaste ${_bs(payment.amountDue)}. '
                        'Central lo está revisando.'
                    : 'Paga ${_bs(payment.amountDue)} para que busquemos '
                        'a tu chófer.',
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: LuxSpacing.md),
              LuxButton(
                label: payment.reported ? 'Ver el pago' : 'Pagar ahora',
                onPressed: onPay,
              ),
            ],
          ),
        ),
      );
}

/// Comprobante del pago y de su devolución (B1). No es una factura y así
/// se dice. La devolución solo se da por hecha cuando el servidor la
/// registró (B4).
///
/// [collapsed]: durante el viaje en curso se muestra plegado (título e
/// importe) para no desplazar al chófer ni el código de recogida (E40).
class PaymentReceiptCard extends StatefulWidget {
  const PaymentReceiptCard({
    super.key,
    required this.payment,
    this.collapsed = false,
  });

  final BookingPayment payment;
  final bool collapsed;

  @override
  State<PaymentReceiptCard> createState() => _PaymentReceiptCardState();
}

class _PaymentReceiptCardState extends State<PaymentReceiptCard> {
  late bool _open = !widget.collapsed;

  @override
  void didUpdateWidget(PaymentReceiptCard old) {
    super.didUpdateWidget(old);
    if (old.collapsed != widget.collapsed) _open = !widget.collapsed;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: const Text(
              'Comprobante de pago',
              style: LuxTypography.titleMedium,
            ),
          ),
        ),
        if (widget.collapsed) ...[
          Text(
            _bs(p.amountPaid),
            style: LuxTypography.bodyMedium.copyWith(
              color: LuxColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            key: const ValueKey('payment-receipt-toggle'),
            tooltip: _open ? 'Ocultar comprobante' : 'Ver comprobante',
            icon: Icon(
              _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            onPressed: () => setState(() => _open = !_open),
          ),
        ],
      ],
    );
    if (!_open) {
      return Semantics(
        container: true,
        child: LuxCard(
          key: const ValueKey('payment-receipt'),
          padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md,
            LuxSpacing.xs,
            LuxSpacing.xs,
            LuxSpacing.xs,
          ),
          child: header,
        ),
      );
    }
    return Semantics(
      container: true,
      child: LuxCard(
        key: const ValueKey('payment-receipt'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Text(
              'Este comprobante no es una factura.',
              style:
                  LuxTypography.caption.copyWith(color: LuxColors.inkTertiary),
            ),
            const SizedBox(height: LuxSpacing.sm),
            _Row('Pagado', _bs(p.amountPaid)),
            if (p.paidAt != null) _Row('Fecha', LuxFormat.dateTime(p.paidAt!)),
            _Row('Método', receiptMethodLabel(p.method)),
            if (p.paymentRef != null) _Row('Referencia', p.paymentRef!),
            if (p.amountRetained > 0)
              _Row('Retención por cancelación', _bs(p.amountRetained)),
            if (p.status == BookingPaymentStatus.refundPending &&
                p.refundDue > 0) ...[
              _Row('Devolución pendiente', _bs(p.refundDue)),
              const _Note(
                'Central la registrará y te avisaremos cuando quede hecha.',
              ),
            ],
            if (p.amountRefunded > 0) ...[
              _Row('Devuelto', _bs(p.amountRefunded)),
              const _Note(
                'Te devolvemos el dinero al método con el que pagaste.',
              ),
            ],
            // H3: el saldo se muestra tal cual; lo gestiona central. Sin
            // promesas de contacto ni plazos.
            if (p.balanceDue > 0) ...[
              _Row('Saldo pendiente', _bs(p.balanceDue)),
              const _Note(
                  'El importe final del viaje fue mayor que lo pagado.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: LuxTypography.bodyMedium),
            ),
            const SizedBox(width: LuxSpacing.sm),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: LuxTypography.bodyMedium.copyWith(
                  color: LuxColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: LuxSpacing.xs),
        child: Text(
          text,
          style: LuxTypography.caption.copyWith(color: LuxColors.inkTertiary),
        ),
      );
}
