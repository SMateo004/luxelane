import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../data/business_repository.dart';
import '../../domain/business_models.dart';

String bs(num v) => LuxFormat.bs(v, decimals: true);

String shortDate(DateTime d) {
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

/// Contenido centrado con ancho máximo legible en escritorio.
class BusinessBody extends StatelessWidget {
  const BusinessBody({super.key, required this.children, this.maxWidth = 1040});
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            LuxSpacing.md, LuxSpacing.lg, LuxSpacing.md, LuxSpacing.xxl),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = LuxColors.sapphire});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(text,
            style: LuxTypography.caption
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}

Color companyStatusColor(CompanyStatus s) => switch (s) {
      CompanyStatus.active => LuxColors.success,
      CompanyStatus.pending => LuxColors.warning,
      CompanyStatus.suspended || CompanyStatus.rejected => LuxColors.error,
    };

Color statementStatusColor(CompanyStatement s) => s.isOverdue
    ? LuxColors.error
    : switch (s.status) {
        StatementStatus.draft => LuxColors.inkTertiary,
        StatementStatus.issued => LuxColors.warning,
        StatementStatus.paid => LuxColors.success,
      };

String statementStatusLabel(CompanyStatement s) =>
    s.isOverdue ? 'Vencido' : s.status.label;

/// Cifra destacada con su etiqueta.
class StatTile extends StatelessWidget {
  const StatTile(
      {super.key, required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) => LuxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: LuxTypography.caption.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(value,
                style: LuxTypography.headlineMedium
                    .copyWith(color: LuxColors.sapphire)),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint!, style: LuxTypography.caption),
            ],
          ],
        ),
      );
}

/// Fila de cifras que se apila en móvil.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        if (box.maxWidth < 600) {
          return Column(children: [
            for (final t in tiles) ...[t, const SizedBox(height: 8)],
          ]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      });
}

/// Detalle de un extracto mensual. Con [adminActions] muestra los controles
/// de Luxelane (recalcular, ajustes, emitir, marcar pagado).
class StatementView extends StatefulWidget {
  const StatementView(
      {super.key, required this.statement, this.adminActions = false});
  final CompanyStatement statement;
  final bool adminActions;

  @override
  State<StatementView> createState() => _StatementViewState();
}

class _StatementViewState extends State<StatementView> {
  final _repo = sl<BusinessRepository>();
  bool _busy = false;

  Future<void> _run(Future<dynamic> Function() action, String ok) async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold((f) => showLuxSnackbar(context, f.message, isError: true),
        (_) => showLuxSnackbar(context, ok));
  }

  Future<void> _addAdjustment() async {
    final concept = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajuste del mes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LuxTextField(label: 'Concepto', controller: concept),
            const SizedBox(height: 12),
            LuxTextField(
              label: 'Importe Bs (negativo = abono)',
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-\d.,]')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Añadir ajuste')),
        ],
      ),
    );
    if (ok != true) return;
    final value = double.tryParse(amount.text.replaceAll(',', '.'));
    if (value == null || value == 0) {
      if (mounted) showLuxSnackbar(context, 'Importe no válido', isError: true);
      return;
    }
    await _run(
        () => _repo.addAdjustment(widget.statement.id, concept.text, value),
        'Ajuste añadido');
  }

  Future<void> _markPaid() async {
    final ref = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar pago'),
        content: LuxTextField(
            label: 'Referencia (transferencia, factura…)', controller: ref),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Marcar pagado')),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _repo.markPaid(widget.statement.id, ref.text),
          'Pago registrado');
    }
  }

  Future<void> _issue() async {
    final s = widget.statement;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Emitir extracto?'),
        content: Text('Se enviará a ${s.companyName} por ${bs(s.totalBs)} '
            'y ya no podrá modificarse.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Emitir')),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => _repo.issueStatement(s.id), 'Extracto emitido');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.statement;
    final draft = s.status == StatementStatus.draft;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Extracto de ${s.periodLabel}',
                  style: LuxTypography.titleLarge),
              Pill(statementStatusLabel(s), color: statementStatusColor(s)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.companyName} · NIT ${s.taxId}'
            '${s.issuedAt != null ? ' · emitido ${shortDate(s.issuedAt!)}' : ''}'
            '${s.dueAt != null && s.status != StatementStatus.paid ? ' · vence ${shortDate(s.dueAt!)}' : ''}'
            '${s.paidAt != null ? ' · pagado ${shortDate(s.paidAt!)}' : ''}',
            style: LuxTypography.caption,
          ),
          const SizedBox(height: LuxSpacing.md),
          if (s.lines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Sin viajes completados en este periodo.',
                  style: LuxTypography.bodyMedium),
            )
          else
            for (final l in s.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 84,
                        child: Text(shortDate(l.date),
                            style: LuxTypography.caption)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.riderName.isEmpty ? 'Pasajero' : l.riderName,
                              style: LuxTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('${l.origin} → ${l.destination}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: LuxTypography.caption),
                          if (l.costCenter.isNotEmpty)
                            Text('Centro de coste: ${l.costCenter}',
                                style: LuxTypography.caption),
                        ],
                      ),
                    ),
                    Text(bs(l.amountBs), style: LuxTypography.bodyMedium),
                  ],
                ),
              ),
          const LuxDivider(),
          _TotalRow('Subtotal (${s.tripCount} viajes)', s.subtotalBs),
          if (s.discountBs > 0)
            _TotalRow('Descuento ${s.discountPct.toStringAsFixed(0)} %',
                -s.discountBs),
          for (final a in s.adjustments)
            _TotalRow(
              a.concept,
              a.amountBs,
              onRemove: widget.adminActions && draft && !_busy
                  ? () => _run(() => _repo.removeAdjustment(s.id, a.id),
                      'Ajuste quitado')
                  : null,
            ),
          _TotalRow('Total', s.totalBs, bold: true),
          if (s.paymentReference != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Referencia de pago: ${s.paymentReference}',
                  style: LuxTypography.caption),
            ),
          const SizedBox(height: LuxSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: s.toCsv()));
                  if (context.mounted) {
                    showLuxSnackbar(context,
                        'Extracto copiado en CSV: pégalo en Excel u hojas de cálculo.');
                  }
                },
                icon: const Icon(Icons.table_view_outlined, size: 18),
                label: const Text('Copiar CSV'),
              ),
              if (widget.adminActions && draft) ...[
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => _repo.generateStatement(s.companyId, s.period),
                          'Extracto recalculado'),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Recalcular'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _addAdjustment,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Añadir ajuste'),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _issue,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Emitir extracto'),
                ),
              ],
              if (widget.adminActions && s.status == StatementStatus.issued)
                FilledButton.icon(
                  onPressed: _busy ? null : _markPaid,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Marcar pagado'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, {this.bold = false, this.onRemove});
  final String label;
  final double amount;
  final bool bold;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? LuxTypography.titleMedium.copyWith(color: LuxColors.sapphire)
        : LuxTypography.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          if (onRemove != null)
            IconButton(
              tooltip: 'Quitar ajuste',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
          Text(bs(amount), style: style),
        ],
      ),
    );
  }
}

/// Invitaciones pendientes para el usuario, con aceptar o rechazar.
class CompanyInvitesCard extends StatelessWidget {
  const CompanyInvitesCard(
      {super.key, required this.email, required this.emailVerified});
  final String email;
  final bool emailVerified;

  @override
  Widget build(BuildContext context) {
    final repo = sl<BusinessRepository>();
    return StreamBuilder<List<CompanyInvite>>(
      stream: repo.watchMyInvites(email),
      builder: (context, snap) {
        final invites = snap.data ?? const [];
        if (invites.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final inv in invites)
              Padding(
                padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                child: LuxCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.apartment_rounded,
                            color: LuxColors.sapphire),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              '${inv.companyName} te invitó a su cuenta de empresa',
                              style: LuxTypography.titleMedium),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        'Podrás cargar tus viajes de trabajo a la empresa'
                        '${inv.monthlyLimitBs != null ? ' hasta ${bs(inv.monthlyLimitBs!)} al mes' : ''}. '
                        'Tus viajes personales siguen siendo privados.',
                        style: LuxTypography.caption,
                      ),
                      if (!emailVerified) ...[
                        const SizedBox(height: 6),
                        Text(
                            'Para unirte, primero verifica tu correo con el enlace que te enviamos.',
                            style: LuxTypography.caption
                                .copyWith(color: LuxColors.warning)),
                      ],
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, children: [
                        FilledButton(
                          onPressed: () async {
                            final r = await repo.respondInvite(inv.companyId,
                                accept: true);
                            if (!context.mounted) return;
                            r.fold(
                                (f) => showLuxSnackbar(context, f.message,
                                    isError: true),
                                (_) => showLuxSnackbar(context,
                                    'Ya formas parte de ${inv.companyName}'));
                          },
                          child: const Text('Unirme'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final r = await repo.respondInvite(inv.companyId,
                                accept: false);
                            if (!context.mounted) return;
                            r.fold(
                                (f) => showLuxSnackbar(context, f.message,
                                    isError: true),
                                (_) => showLuxSnackbar(
                                    context, 'Invitación rechazada'));
                          },
                          child: const Text('Rechazar'),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
