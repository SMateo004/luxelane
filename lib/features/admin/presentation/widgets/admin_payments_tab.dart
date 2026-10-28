import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/error/function_errors.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/widgets/reauth_dialog.dart';
import '../../domain/admin_payments.dart';
import '../../domain/repositories/admin_repository.dart'
    show kAdminReasonMinLength;
import '../bloc/admin_payments_cubit.dart';
import 'admin_shared_widgets.dart';

String _bsCents(int cents) => bs(cents / 100);

String _methodLabel(String? m) => switch (m) {
      'manual_qr' => 'QR o transferencia',
      'card' => 'Tarjeta',
      _ => 'Sin elegir',
    };

String _statusLabel(String s) => switch (s) {
      'awaiting_payment' => 'Pendiente de pago',
      'paid' => 'Pagado',
      'refund_pending' => 'Devolución pendiente',
      'refunded' => 'Devuelto',
      'partially_refunded' => 'Devuelto en parte',
      'failed' => 'Rechazado',
      'expired' => 'Vencido',
      _ => s,
    };

/// Pagos (B3): «ya pagué» por confirmar, pendientes, devoluciones y saldos.
/// Confirmar, rechazar y registrar devoluciones piden motivo y pasan por
/// las callables con segundo factor; si la sesión es antigua, se vuelve a
/// pedir la identidad.
class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            AdminPaymentsCubit(sl<AdminPaymentsRepository>())..load(),
        child: const PaymentsView(),
      );
}

class PaymentsView extends StatelessWidget {
  const PaymentsView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AdminPaymentsCubit, AdminPaymentsState>(
        listenWhen: (a, b) => a.seq != b.seq,
        listener: (context, s) {
          if (s.error == kReauthRequiredMessage) {
            confirmIdentityThenRetry(context);
          } else if (s.message != null) {
            showLuxSnackbar(context, s.message!);
          } else if (s.error != null && s.items.isNotEmpty) {
            showLuxSnackbar(context, s.error!, isError: true);
          }
        },
        builder: (context, s) {
          final cubit = context.read<AdminPaymentsCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  LuxSpacing.lg,
                  LuxSpacing.md,
                  LuxSpacing.lg,
                  LuxSpacing.sm,
                ),
                child: Row(
                  children: [
                    for (final k in PaymentInboxKind.values)
                      Padding(
                        padding: const EdgeInsets.only(right: LuxSpacing.sm),
                        child: SectionChip(
                          label: k.label,
                          selected: s.kind == k,
                          onTap: () => cubit.load(k),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Recargar',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: s.loading ? null : cubit.load,
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, s)),
            ],
          );
        },
      );

  Widget _body(BuildContext context, AdminPaymentsState s) {
    if (s.loading) return const LuxSkeletonList(count: 3);
    if (s.error != null && s.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(LuxSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  s.error!,
                  style: LuxTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: LuxSpacing.md),
              LuxOutlinedButton(
                label: 'Reintentar',
                width: 200,
                onPressed: () => context.read<AdminPaymentsCubit>().load(),
              ),
            ],
          ),
        ),
      );
    }
    if (s.items.isEmpty) {
      return AdminEmpty(
        icon: Icons.task_alt_rounded,
        title: 'Nada pendiente',
        subtitle: _emptyText(s.kind),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      itemCount: s.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: LuxSpacing.md),
      itemBuilder: (_, i) => PaymentInboxTile(
        item: s.items[i],
        kind: s.kind,
        busy: s.busyId == s.items[i].bookingId,
      ),
    );
  }

  static String _emptyText(PaymentInboxKind k) => switch (k) {
        PaymentInboxKind.reported =>
          'Aquí aparecen los avisos «ya pagué» de los pasajeros.',
        PaymentInboxKind.awaiting =>
          'Reservas creadas que aún esperan el pago.',
        PaymentInboxKind.refunds => 'Devoluciones por registrar.',
        PaymentInboxKind.balances =>
          'Viajes cuyo importe final superó lo pagado.',
      };
}

class PaymentInboxTile extends StatelessWidget {
  const PaymentInboxTile({
    super.key,
    required this.item,
    required this.kind,
    this.busy = false,
  });

  final PaymentInboxItem item;
  final PaymentInboxKind kind;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final cls = VehicleClass.values
        .where((v) => v.name == i.vehicleClass)
        .map((v) => v.label)
        .firstOrNull;
    final facts = <(String, String)>[
      ('Referencia', i.paymentRef ?? '—'),
      ('Estado', _statusLabel(i.paymentStatus)),
      ('Método', _methodLabel(i.paymentMethod)),
      ('Importe', _bsCents(i.amountDue)),
      if (i.amountPaid > 0) ('Pagado', _bsCents(i.amountPaid)),
      if (i.amountRetained > 0) ('Retenido', _bsCents(i.amountRetained)),
      if (i.refundDue > 0) ('Por devolver', _bsCents(i.refundDue)),
      if (i.balanceDue > 0) ('Saldo pendiente', _bsCents(i.balanceDue)),
      if (i.paymentDeadline != null) ('Plazo', adminDate(i.paymentDeadline!)),
      if (i.riderReportedAt != null)
        ('Avisó «ya pagué»', adminDate(i.riderReportedAt!)),
      if (i.riderOperationNumber != null)
        ('N.º de operación del pasajero', i.riderOperationNumber!),
      if (i.scheduledAt != null) ('Recogida', adminDate(i.scheduledAt!)),
      if (cls != null) ('Clase', cls),
      if (i.pickupArea != null) ('Zona', i.pickupArea!),
    ];
    return Semantics(
      container: true,
      label: 'Reserva ${shortId(i.bookingId)}',
      child: LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reserva #${shortId(i.bookingId)}',
              style: LuxTypography.titleMedium,
            ),
            const SizedBox(height: LuxSpacing.sm),
            Wrap(
              spacing: LuxSpacing.lg,
              runSpacing: LuxSpacing.sm,
              children: [
                for (final (k, v) in facts)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(k, style: LuxTypography.caption),
                        Text(
                          v,
                          style: LuxTypography.bodyMedium.copyWith(
                            color: LuxColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: LuxSpacing.md),
            if (busy)
              const LinearProgressIndicator()
            else
              Wrap(
                spacing: LuxSpacing.sm,
                runSpacing: LuxSpacing.sm,
                children: _actions(context),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final cubit = context.read<AdminPaymentsCubit>();
    switch (kind) {
      case PaymentInboxKind.reported:
      case PaymentInboxKind.awaiting:
        return [
          _Action(
            label: 'Confirmar pago',
            icon: Icons.check_circle_outline_rounded,
            filled: true,
            onTap: () async {
              final r = await showDialog<_ConfirmData>(
                context: context,
                builder: (_) => ConfirmPaymentDialog(item: item),
              );
              if (r == null) return;
              await cubit.confirm(
                item,
                amountReceived: r.amount,
                operationNumber: r.operation,
                reason: r.reason,
              );
            },
          ),
          if (kind == PaymentInboxKind.reported)
            _Action(
              label: 'Rechazar',
              icon: Icons.block_rounded,
              destructive: true,
              onTap: () async {
                final reason = await confirmAdminAction(
                  context,
                  title: 'Rechazar pago',
                  message: 'Úsalo si el ingreso de la referencia '
                      '${item.paymentRef ?? ''} no llegó. Se avisa al '
                      'pasajero y puede volver a pagar.',
                  confirmLabel: 'Rechazar',
                  reasonLabel: 'Motivo (queda en la auditoría)',
                  destructive: true,
                );
                if (reason == null) return;
                await cubit.reject(item, reason: reason);
              },
            ),
        ];
      case PaymentInboxKind.refunds:
        if (item.pendingRefunds.isEmpty) {
          return [
            const Text(
              'Sin asientos pendientes; recarga la bandeja.',
              style: LuxTypography.caption,
            ),
          ];
        }
        return [
          for (final e in item.pendingRefunds)
            _Action(
              label: e.byCard
                  ? 'Devolver ${_bsCents(e.amount)} con el proveedor'
                  : 'Registrar devolución de ${_bsCents(e.amount)}',
              icon: Icons.undo_rounded,
              filled: true,
              onTap: () async {
                final r = await showDialog<_RefundData>(
                  context: context,
                  builder: (_) => RecordRefundDialog(item: item, entry: e),
                );
                if (r == null) return;
                await cubit.recordRefund(
                  item,
                  e,
                  reason: r.reason,
                  externalRef: r.externalRef,
                );
              },
            ),
        ];
      case PaymentInboxKind.balances:
        return [
          _Action(
            label: 'Cobrar saldo',
            icon: Icons.point_of_sale_outlined,
            filled: true,
            onTap: () async {
              final r = await showDialog<_CollectData>(
                context: context,
                builder: (_) => CollectBalanceDialog(item: item),
              );
              if (r == null) return;
              await cubit.collectBalance(
                item,
                amount: r.amount,
                operationNumber: r.operation,
                method: r.method,
                reason: r.reason,
              );
            },
          ),
        ];
    }
  }
}

/// Botón del panel de pagos: 48 px de alto (tacto y accesibilidad).
class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? LuxColors.error : LuxColors.sapphire;
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.md),
        ),
      ),
    );
    return filled
        ? FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: style.copyWith(
              backgroundColor: WidgetStatePropertyAll(color),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18, color: color),
            label: Text(
              label,
              style: LuxTypography.labelLarge.copyWith(color: color),
            ),
            style: style,
          );
  }
}

// ── Diálogos ────────────────────────────────────────────────────────────────

typedef _ConfirmData = ({double amount, String operation, String reason});
typedef _RefundData = ({String reason, String? externalRef});
typedef _CollectData = ({
  double amount,
  String operation,
  String method,
  String reason,
});

final _opFormat =
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ._/-]'));

/// Confirmar un pago manual: importe recibido (debe ser el exacto), número
/// de operación del banco (no se puede usar dos veces) y motivo.
class ConfirmPaymentDialog extends StatefulWidget {
  const ConfirmPaymentDialog({super.key, required this.item});
  final PaymentInboxItem item;

  @override
  State<ConfirmPaymentDialog> createState() => _ConfirmPaymentDialogState();
}

class _ConfirmPaymentDialogState extends State<ConfirmPaymentDialog> {
  late final _amount = TextEditingController(
    text: (widget.item.amountDue / 100).toStringAsFixed(2),
  );
  late final _op =
      TextEditingController(text: widget.item.riderOperationNumber ?? '');
  final _why = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _op.dispose();
    _why.dispose();
    super.dispose();
  }

  double? get _amountValue =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final amount = _amountValue;
    final exact =
        amount != null && (amount * 100).round() == widget.item.amountDue;
    final ok = exact &&
        _op.text.trim().isNotEmpty &&
        _why.text.trim().length >= kAdminReasonMinLength;
    return AlertDialog(
      title: const Text(
        'Confirmar pago',
        style: LuxTypography.titleLarge,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Referencia ${widget.item.paymentRef ?? '—'} · importe debido '
                '${_bsCents(widget.item.amountDue)}. Confirma solo si el '
                'ingreso está en la cuenta.',
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: LuxSpacing.md),
              TextField(
                key: const Key('confirm-amount'),
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(prefixText: 'Bs ').copyWith(
                  labelText: 'Importe recibido',
                  errorText: amount == null || exact
                      ? null
                      : 'Debe ser exactamente '
                          '${_bsCents(widget.item.amountDue)}',
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              TextField(
                key: const Key('confirm-operation'),
                controller: _op,
                inputFormatters: [
                  _opFormat,
                  LengthLimitingTextInputFormatter(40),
                ],
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration().copyWith(
                  labelText: 'N.º de operación del banco',
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              TextField(
                key: const Key('confirm-reason'),
                controller: _why,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(
                  hint: 'Obligatorio, mínimo $kAdminReasonMinLength '
                      'caracteres (queda en la auditoría)',
                ).copyWith(labelText: 'Motivo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirm-payment'),
          onPressed: ok
              ? () => Navigator.pop<_ConfirmData>(context, (
                    amount: amount,
                    operation: _op.text.trim(),
                    reason: _why.text.trim(),
                  ))
              : null,
          child: const Text('Confirmar pago'),
        ),
      ],
    );
  }
}

/// Registrar una devolución: manual con la referencia del banco; con
/// tarjeta, la hace el proveedor (sin referencia).
class RecordRefundDialog extends StatefulWidget {
  const RecordRefundDialog({
    super.key,
    required this.item,
    required this.entry,
  });
  final PaymentInboxItem item;
  final PendingRefund entry;

  @override
  State<RecordRefundDialog> createState() => _RecordRefundDialogState();
}

class _RecordRefundDialogState extends State<RecordRefundDialog> {
  final _ref = TextEditingController();
  final _why = TextEditingController();

  @override
  void dispose() {
    _ref.dispose();
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.entry.byCard;
    final ok = (card || _ref.text.trim().isNotEmpty) &&
        _why.text.trim().length >= kAdminReasonMinLength;
    return AlertDialog(
      title: Text(
        card ? 'Devolver con el proveedor' : 'Registrar devolución',
        style: LuxTypography.titleLarge,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card
                    ? 'Se pedirá al proveedor la devolución de '
                        '${_bsCents(widget.entry.amount)} a la tarjeta con '
                        'la que se pagó.'
                    : 'Haz la transferencia de '
                        '${_bsCents(widget.entry.amount)} a la cuenta desde '
                        'la que pagó el pasajero y anota su referencia. '
                        'Solo entonces se le avisa.',
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: LuxSpacing.md),
              if (!card) ...[
                TextField(
                  key: const Key('refund-ref'),
                  controller: _ref,
                  inputFormatters: [
                    _opFormat,
                    LengthLimitingTextInputFormatter(60),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: adminInputDecoration().copyWith(
                    labelText: 'Referencia de la devolución (banco)',
                  ),
                ),
                const SizedBox(height: LuxSpacing.sm),
              ],
              TextField(
                key: const Key('refund-reason'),
                controller: _why,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(
                  hint: 'Obligatorio, mínimo $kAdminReasonMinLength '
                      'caracteres (queda en la auditoría)',
                ).copyWith(labelText: 'Motivo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('refund-confirm'),
          onPressed: ok
              ? () => Navigator.pop<_RefundData>(context, (
                    reason: _why.text.trim(),
                    externalRef: card ? null : _ref.text.trim(),
                  ))
              : null,
          child: Text(card ? 'Pedir devolución' : 'Registrar'),
        ),
      ],
    );
  }
}

/// Cobrar un saldo pendiente (G2): el pasajero pagó la diferencia fuera
/// del sistema. Importe igual al saldo o menor (cobro parcial), método,
/// número de operación (no se puede usar dos veces) y motivo.
class CollectBalanceDialog extends StatefulWidget {
  const CollectBalanceDialog({super.key, required this.item});
  final PaymentInboxItem item;

  @override
  State<CollectBalanceDialog> createState() => _CollectBalanceDialogState();
}

class _CollectBalanceDialogState extends State<CollectBalanceDialog> {
  late final _amount = TextEditingController(
    text: (widget.item.balanceDue / 100).toStringAsFixed(2),
  );
  final _op = TextEditingController();
  final _why = TextEditingController();
  String _method = 'manual_qr';

  @override
  void dispose() {
    _amount.dispose();
    _op.dispose();
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final cents = amount == null ? null : (amount * 100).round();
    final amountOk =
        cents != null && cents > 0 && cents <= widget.item.balanceDue;
    final ok = amountOk &&
        _op.text.trim().isNotEmpty &&
        _why.text.trim().length >= kAdminReasonMinLength;
    return AlertDialog(
      title: const Text('Cobrar saldo', style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reserva #${shortId(widget.item.bookingId)} · saldo pendiente '
                '${_bsCents(widget.item.balanceDue)}. Registra solo lo que '
                'ya está en la cuenta; si es menos, el resto sigue pendiente.',
                style: LuxTypography.bodyMedium,
              ),
              const SizedBox(height: LuxSpacing.md),
              TextField(
                key: const Key('collect-amount'),
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(prefixText: 'Bs ').copyWith(
                  labelText: 'Importe cobrado',
                  errorText: amount == null || amountOk
                      ? null
                      : 'Entre 0,01 y ${_bsCents(widget.item.balanceDue)}',
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              const Text('Método', style: LuxTypography.labelLarge),
              for (final m in const ['manual_qr', 'card'])
                RadioListTile<String>(
                  key: Key('collect-method-$m'),
                  value: m,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v ?? _method),
                  title: Text(_methodLabel(m), style: LuxTypography.bodyMedium),
                  contentPadding: EdgeInsets.zero,
                ),
              TextField(
                key: const Key('collect-operation'),
                controller: _op,
                inputFormatters: [
                  _opFormat,
                  LengthLimitingTextInputFormatter(40),
                ],
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration().copyWith(
                  labelText: 'N.º de operación o referencia',
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              TextField(
                key: const Key('collect-reason'),
                controller: _why,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: adminInputDecoration(
                  hint: 'Obligatorio, mínimo $kAdminReasonMinLength '
                      'caracteres (queda en la auditoría)',
                ).copyWith(labelText: 'Motivo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('collect-confirm'),
          onPressed: ok
              ? () => Navigator.pop<_CollectData>(context, (
                    amount: amount!,
                    operation: _op.text.trim(),
                    method: _method,
                    reason: _why.text.trim(),
                  ))
              : null,
          child: const Text('Registrar cobro'),
        ),
      ],
    );
  }
}
