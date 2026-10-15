import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../business/data/business_repository.dart';
import '../../../business/domain/business_models.dart';
import '../../../business/presentation/widgets/business_widgets.dart';

/// Panel admin · Empresas: aprobar solicitudes, condiciones (descuento,
/// plazo, presupuesto) y el ajuste mensual de cada empresa.
class CompaniesTab extends StatefulWidget {
  const CompaniesTab({super.key});

  @override
  State<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends State<CompaniesTab> {
  final _repo = sl<BusinessRepository>();
  String? _selectedId;
  CompanyStatus? _filter;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Company>>(
        stream: _repo.watchAllCompanies(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('No pudimos cargar las empresas.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final selected = all.where((c) => c.id == _selectedId).firstOrNull;
          if (selected != null) {
            return _CompanyDetail(
              company: selected,
              onBack: () => setState(() => _selectedId = null),
            );
          }
          final list =
              _filter == null ? all : all.where((c) => c.status == _filter);
          final pending =
              all.where((c) => c.status == CompanyStatus.pending).length;
          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.md),
            children: [
              Text('Empresas', style: LuxTypography.headlineMedium),
              const SizedBox(height: 4),
              Text(
                  '${all.length} registradas'
                  '${pending > 0 ? ' · $pending pendientes de aprobar' : ''}',
                  style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.md),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final s in CompanyStatus.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
              ]),
              const SizedBox(height: LuxSpacing.md),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay empresas en este estado.'),
                ),
              for (final c in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LuxCard(
                    onTap: () => setState(() => _selectedId = c.id),
                    child: Row(children: [
                      const Icon(Icons.apartment_outlined,
                          color: LuxColors.sapphire),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: LuxTypography.titleMedium),
                            Text(
                                'NIT ${c.taxId} · ${c.contactName} · ${c.phone}',
                                style: LuxTypography.caption),
                          ],
                        ),
                      ),
                      Pill(c.status.label, color: companyStatusColor(c.status)),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ),
            ],
          );
        },
      );
}

class _CompanyDetail extends StatefulWidget {
  const _CompanyDetail({required this.company, required this.onBack});
  final Company company;
  final VoidCallback onBack;

  @override
  State<_CompanyDetail> createState() => _CompanyDetailState();
}

class _CompanyDetailState extends State<_CompanyDetail> {
  final _repo = sl<BusinessRepository>();
  bool _busy = false;
  late String _period = previousPeriodOf(currentPeriod());

  Future<void> _act(Future<dynamic> Function() f, String ok) async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await f();
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold((x) => showLuxSnackbar(context, x.message, isError: true),
        (_) => showLuxSnackbar(context, ok));
  }

  Future<String?> _askReason(String title) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: LuxTextField(
            label: 'Motivo (se lo mostramos a la empresa)', controller: c),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    return ok == true ? c.text.trim() : null;
  }

  Future<void> _editTerms() async {
    final c = widget.company;
    final discount =
        TextEditingController(text: c.discountPct.toStringAsFixed(0));
    final terms = TextEditingController(text: c.paymentTermsDays.toString());
    final budget = TextEditingController(
        text: c.monthlyBudgetBs?.toStringAsFixed(0) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Condiciones comerciales'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          LuxTextField(
              label: 'Descuento % (0 a 50)',
              controller: discount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 12),
          LuxTextField(
              label: 'Plazo de pago (días)',
              controller: terms,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 12),
          LuxTextField(
              label: 'Presupuesto mensual Bs (vacío = sin límite)',
              controller: budget,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;
    final b = double.tryParse(budget.text.trim());
    await _act(
      () => _repo.adminUpdateCompany(
        c.id,
        'update',
        discountPct: double.tryParse(discount.text.trim()) ?? 0,
        paymentTermsDays: int.tryParse(terms.text.trim()) ?? 15,
        monthlyBudgetBs: b,
        clearBudget: b == null,
      ),
      'Condiciones guardadas',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    return ListView(
      padding: const EdgeInsets.all(LuxSpacing.md),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Todas las empresas'),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(c.name, style: LuxTypography.headlineMedium),
            Pill(c.status.label, color: companyStatusColor(c.status)),
          ],
        ),
        const SizedBox(height: 8),
        LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NIT ${c.taxId}', style: LuxTypography.bodyMedium),
              Text('Facturación: ${c.billingEmail}',
                  style: LuxTypography.bodyMedium),
              Text('Contacto: ${c.contactName} · ${c.phone}',
                  style: LuxTypography.bodyMedium),
              Text('Dirección: ${c.address}', style: LuxTypography.bodyMedium),
              const SizedBox(height: 8),
              Text(
                  'Descuento ${c.discountPct.toStringAsFixed(0)} % · pago a '
                  '${c.paymentTermsDays} días · presupuesto '
                  '${c.monthlyBudgetBs == null ? 'sin límite' : bs(c.monthlyBudgetBs!)}',
                  style: LuxTypography.caption),
              if (c.statusReason?.isNotEmpty == true)
                Text('Motivo del estado: ${c.statusReason}',
                    style: LuxTypography.caption),
            ],
          ),
        ),
        const SizedBox(height: LuxSpacing.md),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (c.status == CompanyStatus.pending ||
              c.status == CompanyStatus.rejected)
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _act(() => _repo.adminUpdateCompany(c.id, 'approve'),
                      'Empresa aprobada'),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Aprobar'),
            ),
          if (c.status == CompanyStatus.pending)
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final r = await _askReason('Rechazar solicitud');
                      if (r != null) {
                        await _act(
                            () => _repo.adminUpdateCompany(c.id, 'reject',
                                reason: r),
                            'Solicitud rechazada');
                      }
                    },
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Rechazar'),
            ),
          if (c.status == CompanyStatus.active)
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final r = await _askReason('Suspender empresa');
                      if (r != null) {
                        await _act(
                            () => _repo.adminUpdateCompany(c.id, 'suspend',
                                reason: r),
                            'Empresa suspendida');
                      }
                    },
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: const Text('Suspender'),
            ),
          if (c.status == CompanyStatus.suspended)
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _act(
                      () => _repo.adminUpdateCompany(c.id, 'reactivate'),
                      'Empresa reactivada'),
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Reactivar'),
            ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _editTerms,
            icon: const Icon(Icons.handshake_outlined, size: 18),
            label: const Text('Condiciones'),
          ),
        ]),
        const SizedBox(height: LuxSpacing.xl),
        Text('Ajuste mensual', style: LuxTypography.titleLarge),
        const SizedBox(height: 4),
        const Text(
            'El día 1 se genera automáticamente el borrador del mes anterior. '
            'Revísalo, añade ajustes y emítelo para enviárselo a la empresa.',
            style: LuxTypography.caption),
        const SizedBox(height: LuxSpacing.sm),
        Row(children: [
          IconButton(
            tooltip: 'Mes anterior',
            onPressed: () =>
                setState(() => _period = previousPeriodOf(_period)),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(periodName(_period), style: LuxTypography.titleMedium),
          IconButton(
            tooltip: 'Mes siguiente',
            onPressed: _period == currentPeriod()
                ? null
                : () => setState(() {
                      final y = int.parse(_period.substring(0, 4));
                      final m = int.parse(_period.substring(5));
                      _period = m == 12
                          ? '${y + 1}-01'
                          : '$y-${(m + 1).toString().padLeft(2, '0')}';
                    }),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _busy
                ? null
                : () => _act(() => _repo.generateStatement(c.id, _period),
                    'Borrador de ${periodName(_period)} generado'),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Generar borrador'),
          ),
        ]),
        const SizedBox(height: LuxSpacing.sm),
        StreamBuilder<List<CompanyStatement>>(
          stream: _repo.watchStatements(c.id, includeDrafts: true),
          builder: (context, snap) {
            final list = snap.data ?? const <CompanyStatement>[];
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Sin extractos todavía.'),
              );
            }
            return Column(children: [
              for (final s in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                  child: StatementView(statement: s, adminActions: true),
                ),
            ]);
          },
        ),
      ],
    );
  }
}
