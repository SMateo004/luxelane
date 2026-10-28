import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/booking_payment.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../domain/card_payment_presenter.dart';
import '../bloc/booking_payment_cubit.dart';

/// Pago de una reserva (pagos, B1): importe exacto, referencia, método y
/// el estado que manda el servidor. Hasta que el pago se confirma no se
/// busca chófer. Textos sin plazos ni promesas que no estén en config/ops.
class BookingPaymentScreen extends StatelessWidget {
  const BookingPaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => BookingPaymentCubit(
          repository: sl<BookingPaymentRepository>(),
          bookingId: bookingId,
          isWeb: kIsWeb,
          cardPresenter: sl.isRegistered<CardPaymentPresenter>()
              ? sl<CardPaymentPresenter>()
              : null,
        ),
        child: BookingPaymentView(bookingId: bookingId),
      );
}

/// La vista, separada para probarla con un cubit de prueba.
class BookingPaymentView extends StatelessWidget {
  const BookingPaymentView({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: LuxColors.bg,
        appBar: AppBar(
          title: const Text('Pago de tu reserva'),
          leading: IconButton(
            tooltip: 'Ver mi viaje',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.go('/ride/$bookingId'),
          ),
        ),
        body: BlocBuilder<BookingPaymentCubit, BookingPaymentState>(
          builder: (context, s) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _body(context, s),
            ),
          ),
        ),
      );

  Widget _body(BuildContext context, BookingPaymentState s) {
    if (!s.loaded) return const LuxSkeletonList(count: 3, itemHeight: 120);
    final p = s.payment;
    toTrip() => context.go('/ride/$bookingId');
    if (p == null) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: s.error ?? 'Esta reserva no tiene un pago pendiente.',
        actionLabel: 'Ver mi viaje',
        onAction: toTrip,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LuxSpacing.md,
        LuxSpacing.md,
        LuxSpacing.md,
        LuxSpacing.xl,
      ),
      children: [
        ..._content(context, s, p, toTrip),
      ],
    );
  }

  List<Widget> _content(
    BuildContext context,
    BookingPaymentState s,
    BookingPayment p,
    VoidCallback toTrip,
  ) {
    switch (p.status) {
      case BookingPaymentStatus.paid:
        return [
          const _Outcome(
            success: true,
            title: 'Pago confirmado',
            message: 'Ya buscamos a tu chófer. Te avisaremos cuando esté '
                'asignado.',
          ),
          const SizedBox(height: LuxSpacing.lg),
          LuxButton(label: 'Ver mi viaje', onPressed: toTrip),
        ];
      case BookingPaymentStatus.expired:
        return [
          _Outcome(
            title: 'El plazo para pagar terminó',
            message: 'La reserva se canceló porque no recibimos el pago a '
                'tiempo. Si ya habías pagado, contacta con central e indica '
                'la referencia ${p.paymentRef ?? ''}.',
          ),
          const SizedBox(height: LuxSpacing.lg),
          LuxButton(
            label: 'Hacer una nueva reserva',
            onPressed: () => context.go('/'),
          ),
        ];
      case BookingPaymentStatus.refundPending:
      case BookingPaymentStatus.refunded:
      case BookingPaymentStatus.partiallyRefunded:
      case BookingPaymentStatus.unknown:
        return [
          const _Outcome(
            title: 'Esta reserva ya no admite pagos',
            message: 'Consulta el detalle y el comprobante en tu viaje.',
          ),
          const SizedBox(height: LuxSpacing.lg),
          LuxButton(label: 'Ver mi viaje', onPressed: toTrip),
        ];
      case BookingPaymentStatus.awaitingPayment:
      case BookingPaymentStatus.failed:
        break;
    }

    final cubit = context.read<BookingPaymentCubit>();
    final usable = cubit.usableMethods(p);
    return [
      _AmountCard(payment: p),
      const SizedBox(height: LuxSpacing.md),
      if (p.reported)
        _Waiting(payment: p)
      else ...[
        if (p.rejected) ...[
          const _Notice(
            error: true,
            text: 'No pudimos confirmar tu pago. Revisa los datos y vuelve '
                'a avisarnos, o contacta con central.',
          ),
          const SizedBox(height: LuxSpacing.md),
        ],
        if (usable.isEmpty)
          const _Notice(
            error: true,
            text: 'Ahora mismo no podemos recibir el pago desde aquí. '
                'Contacta con central para completar tu reserva.',
          )
        else if (s.start == null)
          _MethodChoice(methods: usable, busy: s.busy)
        else if (s.start!.method == PayMethod.manualQr)
          _ManualPay(start: s.start!, busy: s.busy)
        else
          _CardPay(state: s),
        if (s.start != null && usable.length > 1 && !s.busy) ...[
          const SizedBox(height: LuxSpacing.sm),
          LuxButton.ghost(
            label: 'Cambiar método de pago',
            onPressed: cubit.changeMethod,
          ),
        ],
      ],
      if (s.error != null) ...[
        const SizedBox(height: LuxSpacing.md),
        _Notice(error: true, text: s.error!),
      ],
      const SizedBox(height: LuxSpacing.lg),
      Text(
        'Buscamos chófer cuando el pago está confirmado.',
        style: LuxTypography.caption.copyWith(color: LuxColors.inkTertiary),
        textAlign: TextAlign.center,
      ),
    ];
  }
}

// ── Importe, referencia y plazo ─────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.payment});
  final BookingPayment payment;

  @override
  Widget build(BuildContext context) {
    final ref = payment.paymentRef;
    return LuxCard(
      padding: const EdgeInsets.all(LuxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Text('IMPORTE A PAGAR', style: LuxTypography.eyebrow),
          ),
          const SizedBox(height: LuxSpacing.xs),
          Text(
            LuxFormat.money(BookingPayment.bs(payment.amountDue)),
            style: LuxTypography.displayMedium.copyWith(color: LuxColors.ink),
          ),
          if (ref != null) ...[
            const SizedBox(height: LuxSpacing.md),
            _CopyRow(label: 'Referencia', value: ref),
          ],
          if (payment.paymentDeadline != null) ...[
            const SizedBox(height: LuxSpacing.sm),
            _Deadline(deadline: payment.paymentDeadline!),
          ],
        ],
      ),
    );
  }
}

/// Tiempo que queda para pagar, refrescado cada 30 s.
class _Deadline extends StatefulWidget {
  const _Deadline({required this.deadline});
  final DateTime deadline;

  @override
  State<_Deadline> createState() => _DeadlineState();
}

class _DeadlineState extends State<_Deadline> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = paymentTimeLeft(widget.deadline, DateTime.now());
    return Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 18,
          color: LuxColors.inkTertiary,
        ),
        const SizedBox(width: LuxSpacing.xs),
        Expanded(
          child: Text(
            text,
            style:
                LuxTypography.bodyMedium.copyWith(color: LuxColors.inkTertiary),
          ),
        ),
      ],
    );
  }
}

/// «Quedan 24 min para pagar (hasta las 14:30)». Solo con el plazo que da
/// el servidor (config/ops.paymentWindowMinutes); sin él no se muestra nada.
String paymentTimeLeft(DateTime deadline, DateTime now) {
  final left = deadline.difference(now);
  final until = LuxFormat.time(deadline);
  if (left.inSeconds <= 0) return 'El plazo para pagar terminó a las $until.';
  final mins = (left.inSeconds / 60).ceil();
  final span = mins < 60
      ? '$mins min'
      : '${mins ~/ 60} h${mins % 60 == 0 ? '' : ' ${mins % 60} min'}';
  return 'Quedan $span para pagar (hasta las $until).';
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: LuxTypography.caption),
                Text(
                  value,
                  style: LuxTypography.titleMedium.copyWith(
                    color: LuxColors.ink,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar ${label.toLowerCase()}',
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: LuxColors.sapphire,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                showLuxSnackbar(context, '$label copiada.');
              }
            },
          ),
        ],
      );
}

// ── Método ──────────────────────────────────────────────────────────────────

String payMethodLabel(String m) => switch (m) {
      PayMethod.manualQr => 'QR o transferencia bancaria',
      PayMethod.card => 'Tarjeta',
      _ => m,
    };

class _MethodChoice extends StatelessWidget {
  const _MethodChoice({required this.methods, required this.busy});
  final List<String> methods;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: const Text('¿CÓMO QUIERES PAGAR?',
                style: LuxTypography.eyebrow),
          ),
          const SizedBox(height: LuxSpacing.sm),
          for (final m in methods)
            Padding(
              padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
              child: Semantics(
                button: true,
                label: payMethodLabel(m),
                excludeSemantics: true,
                onTap: busy
                    ? null
                    : () => context.read<BookingPaymentCubit>().choose(m),
                child: LuxCard(
                  onTap: busy
                      ? null
                      : () => context.read<BookingPaymentCubit>().choose(m),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        Icon(
                          m == PayMethod.card
                              ? Icons.credit_card_rounded
                              : Icons.qr_code_2_rounded,
                          color: LuxColors.sapphire,
                        ),
                        const SizedBox(width: LuxSpacing.md),
                        Expanded(
                          child: Text(
                            payMethodLabel(m),
                            style: LuxTypography.titleMedium,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: LuxColors.inkTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (busy) const LinearProgressIndicator(),
        ],
      );
}

// ── Pago manual ─────────────────────────────────────────────────────────────

class _ManualPay extends StatefulWidget {
  const _ManualPay({required this.start, required this.busy});
  final PaymentStart start;
  final bool busy;

  @override
  State<_ManualPay> createState() => _ManualPayState();
}

class _ManualPayState extends State<_ManualPay> {
  final _op = TextEditingController();

  @override
  void dispose() {
    _op.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.start.instructions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxCard(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'PAGA POR QR O TRANSFERENCIA',
                  style: LuxTypography.eyebrow,
                ),
              ),
              const SizedBox(height: LuxSpacing.md),
              if (i?.qrImageUrl != null) ...[
                Center(
                  child: Semantics(
                    image: true,
                    label: 'Código QR para pagar',
                    child: Image.network(
                      i!.qrImageUrl!,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 220,
                        child: Text(
                          'No pudimos mostrar el QR. Usa los datos de la '
                          'cuenta.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: LuxSpacing.md),
              ],
              if (i != null) ...[
                _Line('Titular', i.holderName),
                if (i.bankName != null) _Line('Banco', i.bankName!),
                if (i.accountType != null)
                  _Line('Tipo de cuenta', i.accountType!),
                if (i.accountNumber != null)
                  _CopyRow(label: 'Cuenta', value: i.accountNumber!),
                if (i.note != null) ...[
                  const SizedBox(height: LuxSpacing.sm),
                  Text(i.note!, style: LuxTypography.bodyMedium),
                ],
              ],
              const SizedBox(height: LuxSpacing.md),
              Text(
                'Paga exactamente '
                '${LuxFormat.money(BookingPayment.bs(widget.start.amountDue))}'
                ' y escribe la referencia ${widget.start.paymentRef} en el '
                'concepto o glosa.',
                style: LuxTypography.bodyMedium.copyWith(color: LuxColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: LuxSpacing.md),
        LuxTextField(
          label: 'Número de operación (opcional)',
          hint: 'El que aparece en tu comprobante',
          controller: _op,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
        ),
        const SizedBox(height: LuxSpacing.md),
        LuxButton(
          label: 'Ya pagué',
          icon: Icons.check_rounded,
          loading: widget.busy,
          onPressed: widget.busy
              ? null
              : () => context
                  .read<BookingPaymentCubit>()
                  .reportPaid(operationNumber: _op.text),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: LuxTypography.caption),
            Text(
              value,
              style: LuxTypography.bodyLarge.copyWith(color: LuxColors.ink),
            ),
          ],
        ),
      );
}

class _Waiting extends StatelessWidget {
  const _Waiting({required this.payment});
  final BookingPayment payment;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: LuxCard(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  color: LuxColors.sapphire),
              const SizedBox(width: LuxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Esperando confirmación',
                        style: LuxTypography.titleMedium),
                    const SizedBox(height: LuxSpacing.xs),
                    const Text(
                      'Central está revisando tu pago. Te avisaremos aquí y '
                      'en tus notificaciones cuando lo confirme.',
                      style: LuxTypography.bodyMedium,
                    ),
                    if (payment.riderOperationNumber != null) ...[
                      const SizedBox(height: LuxSpacing.sm),
                      Text(
                        'Número de operación: ${payment.riderOperationNumber}',
                        style: LuxTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Tarjeta (solo app nativa, con un proveedor registrado) ──────────────────

class _CardPay extends StatelessWidget {
  const _CardPay({required this.state});
  final BookingPaymentState state;

  @override
  Widget build(BuildContext context) {
    if (state.cardSubmitted) {
      return Semantics(
        liveRegion: true,
        child: const LuxCard(
          padding: EdgeInsets.all(LuxSpacing.lg),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: LuxSpacing.md),
              Expanded(child: Text('Confirmando tu pago…')),
            ],
          ),
        ),
      );
    }
    return LuxButton(
      label: state.error == null ? 'Pagar con tarjeta' : 'Reintentar',
      icon: Icons.credit_card_rounded,
      loading: state.busy,
      onPressed: state.busy
          ? null
          : () => context.read<BookingPaymentCubit>().choose(PayMethod.card),
    );
  }
}

// ── Avisos ──────────────────────────────────────────────────────────────────

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.error = false});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? LuxColors.error : LuxColors.sapphire;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(LuxRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: LuxTypography.bodyMedium.copyWith(color: LuxColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.title,
    required this.message,
    this.success = false,
  });
  final String title;
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(top: LuxSpacing.xl),
          child: Column(
            children: [
              if (success)
                const LuxSuccessMark()
              else
                const Icon(
                  Icons.info_outline_rounded,
                  size: 48,
                  color: LuxColors.sapphire,
                ),
              const SizedBox(height: LuxSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: LuxTypography.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: LuxSpacing.sm),
              Text(
                message,
                style: LuxTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
