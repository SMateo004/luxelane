import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../special/data/special_repository.dart';
import '../../../special/domain/special_models.dart';

/// Panel admin · Especiales: solicitudes de aerotaxi y paseos para cotizar.
class SpecialRequestsTab extends StatefulWidget {
  const SpecialRequestsTab({super.key});

  @override
  State<SpecialRequestsTab> createState() => _SpecialRequestsTabState();
}

class _SpecialRequestsTabState extends State<SpecialRequestsTab> {
  // Por defecto lo que necesita acción: nuevas sin cotizar.
  SpecialStatus? _filter = SpecialStatus.newRequest;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SpecialRequest>>(
        stream: sl<SpecialRepository>().watchAll(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
                child: Text('No pudimos cargar las solicitudes.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final list = _filter == null
              ? all
              : all.where((r) => r.status == _filter).toList();
          // La cola por cotizar se atiende por orden de llegada.
          if (_filter == SpecialStatus.newRequest) {
            list.sort((a, b) =>
                (a.createdAt ?? a.date).compareTo(b.createdAt ?? b.date));
          }
          int count(SpecialStatus s) => all.where((r) => r.status == s).length;
          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              const Text('Servicios especiales',
                  style: LuxTypography.headlineMedium),
              const SizedBox(height: 4),
              const Text(
                  'Aerotaxi y paseos por la ciudad: se cotizan a mano y el '
                  'cliente acepta desde la app.',
                  style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.md),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in [
                  SpecialStatus.newRequest,
                  SpecialStatus.quoted,
                  SpecialStatus.confirmed,
                ])
                  ChoiceChip(
                    label: Text('${switch (s) {
                      SpecialStatus.newRequest => 'Por cotizar',
                      SpecialStatus.quoted => 'Cotizadas',
                      _ => 'Confirmadas',
                    }} (${count(s)})'),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                ChoiceChip(
                  label: Text('Todas (${all.length})'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ]),
              const SizedBox(height: LuxSpacing.md),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nada pendiente aquí.'),
                ),
              for (final r in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AdminRequestCard(request: r),
                ),
            ],
          );
        },
      );
}

class _AdminRequestCard extends StatefulWidget {
  const _AdminRequestCard({required this.request});
  final SpecialRequest request;

  @override
  State<_AdminRequestCard> createState() => _AdminRequestCardState();
}

class _AdminRequestCardState extends State<_AdminRequestCard> {
  final _repo = sl<SpecialRepository>();
  bool _busy = false;

  Future<void> _act(Future<dynamic> Function() f, String ok) async {
    setState(() => _busy = true);
    final r = await f();
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold((x) => showLuxSnackbar(context, x.message, isError: true),
        (_) => showLuxSnackbar(context, ok));
  }

  Future<void> _quote() async {
    final r = widget.request;
    final amount = TextEditingController(
        text: r.quoteBs != null ? r.quoteBs!.toStringAsFixed(0) : '');
    final note = TextEditingController(text: r.adminNote ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cotizar'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          LuxTextField(
            label: 'Importe total Bs',
            controller: amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          LuxTextField(
              label: 'Detalle para el cliente (aeronave, incluye…)',
              controller: note,
              maxLines: 2),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar cotización')),
        ],
      ),
    );
    if (ok != true) return;
    final v = double.tryParse(amount.text.trim());
    if (v == null || v <= 0) {
      if (mounted) {
        showLuxSnackbar(context, 'Importe no válido', isError: true);
      }
      return;
    }
    await _act(() => _repo.quote(r.id, v, note.text), 'Cotización enviada');
  }

  Future<void> _decline() async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No podemos atenderla'),
        content: LuxTextField(
            label: 'Motivo para el cliente', controller: note, maxLines: 2),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Rechazar')),
        ],
      ),
    );
    if (ok == true) {
      await _act(() => _repo.decline(widget.request.id, note.text),
          'Solicitud rechazada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(r.kind.icon, size: 20, color: LuxColors.inkSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${r.kind.label} · ${r.summary}',
                  style: LuxTypography.titleMedium),
            ),
            Text(r.status.label, style: LuxTypography.caption),
          ]),
          const SizedBox(height: 6),
          Text(
              '${LuxFormat.dateTime(r.date)} · ${r.passengers} pax'
              '${r.language != null ? ' · ${kTourLanguages[r.language] ?? r.language}' : ''}',
              style: LuxTypography.bodyMedium),
          Text('${r.riderName} · ${r.riderEmail} · ${r.riderPhone}',
              style: LuxTypography.caption),
          if (r.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('“${r.notes}”', style: LuxTypography.caption),
            ),
          if (r.quoteBs != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  'Cotizado: ${LuxFormat.bs(r.quoteBs!)}'
                  '${r.adminNote?.isNotEmpty == true ? ' · ${r.adminNote}' : ''}',
                  style: LuxTypography.caption
                      .copyWith(color: LuxColors.sapphire)),
            ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (r.status.isOpen)
              FilledButton(
                onPressed: _busy ? null : _quote,
                child: Text(r.status == SpecialStatus.quoted
                    ? 'Cambiar cotización'
                    : 'Cotizar'),
              ),
            if (r.status.isOpen)
              TextButton(
                  onPressed: _busy ? null : _decline,
                  child: const Text('Rechazar')),
            if (r.status == SpecialStatus.confirmed)
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _act(
                        () => _repo.complete(r.id), 'Marcado como realizado'),
                child: const Text('Marcar realizado'),
              ),
          ]),
        ],
      ),
    );
  }
}
