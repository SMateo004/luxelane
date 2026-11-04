import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/business_repository.dart';
import '../../domain/business_models.dart';
import '../widgets/business_widgets.dart';

/// /empresa — panel de la cuenta de empresa. El administrador gestiona
/// equipo, presupuesto, viajes y extractos; un empleado ve su cupo del mes.
class CompanyDashboardPage extends StatelessWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    final repo = sl<BusinessRepository>();

    Widget body;
    if (user == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (user.companyId == null) {
      body = BusinessBody(children: [
        CompanyInvitesCard(
            email: user.email, emailVerified: repo.emailVerified),
        LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Aún no perteneces a ninguna empresa',
                  style: LuxTypography.titleLarge),
              const SizedBox(height: 8),
              const Text(
                  'Registra tu empresa o pide a su administrador que te invite '
                  'con este correo.',
                  style: LuxTypography.bodyMedium),
              const SizedBox(height: LuxSpacing.md),
              LuxButton(
                  label: 'Registrar mi empresa',
                  onPressed: () => context.go('/empresas/registro')),
            ],
          ),
        ),
      ]);
    } else {
      body = StreamBuilder<Company?>(
        stream: repo.watchCompany(user.companyId!),
        builder: (context, snap) {
          final company = snap.data;
          if (company == null) {
            return Center(
                child: snap.hasError
                    ? const Text('No pudimos cargar la empresa.')
                    : const CircularProgressIndicator());
          }
          return user.isCompanyAdmin
              ? _AdminView(company: company, me: user)
              : _EmployeeView(company: company, me: user);
        },
      );
    }

    return Scaffold(
      backgroundColor: LuxColors.bg,
      appBar: AppBar(
        title: const Text('Mi empresa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: body,
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(company.name, style: LuxTypography.headlineLarge),
              Pill(company.status.label,
                  color: companyStatusColor(company.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text('NIT ${company.taxId} · ${company.billingEmail}',
              style: LuxTypography.caption),
          if (company.status == CompanyStatus.pending) ...[
            const SizedBox(height: LuxSpacing.md),
            const _Notice(
              icon: Icons.hourglass_top_rounded,
              text:
                  'Estamos revisando tu solicitud. Podrás invitar a tu equipo '
                  'y reservar con la cuenta de empresa en cuanto la aprobemos.',
            ),
          ],
          if (company.status == CompanyStatus.suspended ||
              company.status == CompanyStatus.rejected) ...[
            const SizedBox(height: LuxSpacing.md),
            _Notice(
              icon: Icons.block_rounded,
              color: LuxColors.error,
              text: company.status == CompanyStatus.suspended
                  ? 'Cuenta suspendida: no se pueden cargar viajes a la empresa.'
                      '${company.statusReason?.isNotEmpty == true ? ' Motivo: ${company.statusReason}' : ''}'
                  : 'Solicitud rechazada.'
                      '${company.statusReason?.isNotEmpty == true ? ' Motivo: ${company.statusReason}' : ''}',
            ),
          ],
          const SizedBox(height: LuxSpacing.lg),
        ],
      );
}

class _Notice extends StatelessWidget {
  const _Notice(
      {required this.icon, required this.text, this.color = LuxColors.warning});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: LuxTypography.bodyMedium)),
        ]),
      );
}

// ───────────────────────────────────────────────────────────────────────────
// Empleado
// ───────────────────────────────────────────────────────────────────────────

class _EmployeeView extends StatelessWidget {
  const _EmployeeView({required this.company, required this.me});
  final Company company;
  final User me;

  @override
  Widget build(BuildContext context) {
    final repo = sl<BusinessRepository>();
    final period = currentPeriod();
    final (start, end) = periodRange(period);
    return StreamBuilder<CompanyMember?>(
      stream: repo.watchMember(company.id, me.id),
      builder: (context, mSnap) => StreamBuilder<List<Booking>>(
        stream: sl<BookingRepository>().watchBookingsByRider(me.id),
        builder: (context, bSnap) {
          final member = mSnap.data;
          final mine = (bSnap.data ?? const <Booking>[])
              .where((b) =>
                  b.isCorporate &&
                  b.companyId == company.id &&
                  b.status != BookingStatus.cancelled &&
                  !b.scheduledAt.isBefore(start) &&
                  b.scheduledAt.isBefore(end))
              .toList();
          final spent = mine.fold(0.0, (s, b) => s + b.chargedAmount);
          final limit = member?.monthlyLimitBs;
          return BusinessBody(children: [
            _CompanyHeader(company: company),
            if (member != null && !member.active)
              const Padding(
                padding: EdgeInsets.only(bottom: LuxSpacing.md),
                child: _Notice(
                    icon: Icons.block_rounded,
                    color: LuxColors.error,
                    text:
                        'Tu empresa desactivó tu acceso a la cuenta corporativa.'),
              ),
            StatRow(tiles: [
              StatTile(
                  label: 'Gastado en ${periodName(period)}', value: bs(spent)),
              StatTile(
                label: 'Tu límite mensual',
                value: limit == null ? 'Sin límite' : bs(limit),
                hint: limit == null
                    ? null
                    : 'Disponible: ${bs((limit - spent).clamp(0, limit))}',
              ),
              StatTile(label: 'Viajes este mes', value: '${mine.length}'),
            ]),
            const SizedBox(height: LuxSpacing.lg),
            const Text(
                'Para cargar un viaje a la empresa, elige "Cuenta de empresa" '
                'como método de pago al reservar.',
                style: LuxTypography.bodyMedium),
          ]);
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Administrador de la empresa
// ───────────────────────────────────────────────────────────────────────────

class _AdminView extends StatefulWidget {
  const _AdminView({required this.company, required this.me});
  final Company company;
  final User me;

  @override
  State<_AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<_AdminView> {
  int _tab = 0;
  static const _tabs = ['Resumen', 'Equipo', 'Viajes', 'Extractos'];

  @override
  Widget build(BuildContext context) => BusinessBody(children: [
        _CompanyHeader(company: widget.company),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < _tabs.length; i++)
            ChoiceChip(
              label: Text(_tabs[i]),
              selected: _tab == i,
              onSelected: (_) => setState(() => _tab = i),
            ),
        ]),
        const SizedBox(height: LuxSpacing.lg),
        switch (_tab) {
          0 => _SummaryTab(company: widget.company),
          1 => _TeamTab(company: widget.company, me: widget.me),
          2 => _TripsTab(company: widget.company),
          _ => _StatementsTab(company: widget.company),
        },
      ]);
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.company});
  final Company company;

  Future<void> _editBudget(BuildContext context) async {
    final c = TextEditingController(
        text: company.monthlyBudgetBs?.toStringAsFixed(0) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presupuesto mensual'),
        content: LuxTextField(
          label: 'Bs al mes (vacío = sin límite)',
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
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
    final v = double.tryParse(c.text.trim());
    final r = await sl<BusinessRepository>().setBudget(v);
    if (!context.mounted) return;
    r.fold((f) => showLuxSnackbar(context, f.message, isError: true),
        (_) => showLuxSnackbar(context, 'Presupuesto actualizado'));
  }

  @override
  Widget build(BuildContext context) {
    final period = currentPeriod();
    return StreamBuilder<List<Booking>>(
      stream: sl<BusinessRepository>().watchCompanyBookings(company.id, period),
      builder: (context, snap) {
        final list = (snap.data ?? const <Booking>[])
            .where((b) => b.isCorporate && b.status != BookingStatus.cancelled)
            .toList();
        final committed = list.fold(0.0, (s, b) => s + b.chargedAmount);
        final done = list.where((b) => b.status == BookingStatus.completed);
        final billed = done.fold(0.0, (s, b) => s + b.chargedAmount);
        final budget = company.monthlyBudgetBs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatRow(tiles: [
              StatTile(
                label: 'Facturable ${periodName(period)}',
                value: bs(billed),
                hint: '${done.length} viajes completados',
              ),
              StatTile(
                label: 'Comprometido',
                value: bs(committed),
                hint: 'Incluye viajes reservados',
              ),
              StatTile(
                label: 'Presupuesto',
                value: budget == null ? 'Sin límite' : bs(budget),
                hint: budget == null
                    ? null
                    : 'Disponible: ${bs((budget - committed).clamp(0, budget))}',
              ),
            ]),
            const SizedBox(height: LuxSpacing.md),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => _editBudget(context),
                icon: const Icon(Icons.savings_outlined, size: 18),
                label: const Text('Cambiar presupuesto'),
              ),
            ]),
            const SizedBox(height: LuxSpacing.lg),
            LuxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Condiciones', style: LuxTypography.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                      'Descuento pactado: ${company.discountPct.toStringAsFixed(0)} %',
                      style: LuxTypography.bodyMedium),
                  Text(
                      'Plazo de pago: ${company.paymentTermsDays} días desde la emisión',
                      style: LuxTypography.bodyMedium),
                  const Text(
                      'El día 1 de cada mes preparamos el extracto del mes anterior.',
                      style: LuxTypography.caption),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({required this.company, required this.me});
  final Company company;
  final User me;

  Future<void> _invite(BuildContext context) async {
    final email = TextEditingController();
    final limit = TextEditingController();
    var asAdmin = false;
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Invitar a tu equipo'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LuxTextField(
                  label: 'Correo del empleado',
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  validator: LuxValidators.email,
                ),
                const SizedBox(height: 12),
                LuxTextField(
                  label: 'Límite mensual Bs (vacío = sin límite)',
                  controller: limit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: asAdmin,
                  onChanged: (v) => set(() => asAdmin = v ?? false),
                  title: const Text('También administra la cuenta'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Enviar invitación'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final r = await sl<BusinessRepository>().invite(
      email: email.text.trim(),
      admin: asAdmin,
      limitBs: double.tryParse(limit.text.trim()),
    );
    if (!context.mounted) return;
    r.fold(
      (f) => showLuxSnackbar(context, f.message, isError: true),
      (registered) => showLuxSnackbar(
          context,
          registered
              ? 'Invitación enviada: la verá al abrir Luxelane.'
              : 'Invitación enviada: al crear su cuenta con ese correo podrá unirse.'),
    );
  }

  Future<void> _editLimit(BuildContext context, CompanyMember m) async {
    final c =
        TextEditingController(text: m.monthlyLimitBs?.toStringAsFixed(0) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Límite de ${m.displayName}'),
        content: LuxTextField(
          label: 'Bs al mes (vacío = sin límite)',
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
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
    final v = double.tryParse(c.text.trim());
    final r = await sl<BusinessRepository>()
        .updateMember(m.uid, limitBs: v, clearLimit: v == null);
    if (context.mounted) {
      r.fold((f) => showLuxSnackbar(context, f.message, isError: true),
          (_) => showLuxSnackbar(context, 'Límite actualizado'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = sl<BusinessRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Expanded(
              child: Text('Equipo', style: LuxTypography.titleLarge)),
          FilledButton.icon(
            onPressed: company.isActive ? () => _invite(context) : null,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Invitar'),
          ),
        ]),
        if (!company.isActive)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Podrás invitar cuando la empresa esté activa.',
                style: LuxTypography.caption),
          ),
        const SizedBox(height: LuxSpacing.md),
        StreamBuilder<List<CompanyMember>>(
          stream: repo.watchMembers(company.id),
          builder: (context, snap) => Column(children: [
            for (final m in snap.data ?? const <CompanyMember>[])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LuxCard(
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: LuxColors.sapphireTint,
                      child: Text(
                          m.displayName.isEmpty
                              ? '?'
                              : m.displayName[0].toUpperCase(),
                          style: const TextStyle(color: LuxColors.sapphire)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${m.displayName}${m.uid == me.id ? ' (tú)' : ''}',
                              style: LuxTypography.titleMedium),
                          Text(m.email, style: LuxTypography.caption),
                          Text(
                            '${m.isAdmin ? 'Administrador' : 'Empleado'} · '
                            '${m.monthlyLimitBs == null ? 'sin límite' : 'límite ${bs(m.monthlyLimitBs!)}/mes'}'
                            '${m.active ? '' : ' · desactivado'}',
                            style: LuxTypography.caption.copyWith(
                                color: m.active
                                    ? LuxColors.inkTertiary
                                    : LuxColors.error),
                          ),
                        ],
                      ),
                    ),
                    if (m.uid != me.id)
                      PopupMenuButton<String>(
                        tooltip: 'Opciones de ${m.displayName}',
                        onSelected: (v) async {
                          final r = switch (v) {
                            'limit' => null,
                            'toggle' =>
                              await repo.updateMember(m.uid, active: !m.active),
                            'admin' =>
                              await repo.updateMember(m.uid, admin: !m.isAdmin),
                            _ => await repo.removeMember(m.uid),
                          };
                          if (v == 'limit') {
                            if (context.mounted) await _editLimit(context, m);
                            return;
                          }
                          if (!context.mounted || r == null) return;
                          r.fold(
                              (f) => showLuxSnackbar(context, f.message,
                                  isError: true),
                              (_) => showLuxSnackbar(context, 'Hecho'));
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'limit', child: Text('Cambiar límite')),
                          PopupMenuItem(
                              value: 'toggle',
                              child: Text(m.active ? 'Desactivar' : 'Activar')),
                          PopupMenuItem(
                              value: 'admin',
                              child: Text(m.isAdmin
                                  ? 'Quitar administrador'
                                  : 'Hacer administrador')),
                          const PopupMenuItem(
                              value: 'remove',
                              child: Text('Quitar del equipo')),
                        ],
                      ),
                  ]),
                ),
              ),
          ]),
        ),
        StreamBuilder<List<CompanyInvite>>(
          stream: repo.watchCompanyInvites(company.id),
          builder: (context, snap) {
            final invites = snap.data ?? const <CompanyInvite>[];
            if (invites.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: LuxSpacing.md),
                const Text('Invitaciones pendientes',
                    style: LuxTypography.titleMedium),
                const SizedBox(height: 8),
                for (final i in invites)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: Text(i.email),
                    subtitle: Text(i.monthlyLimitBs == null
                        ? 'Sin límite'
                        : 'Límite ${bs(i.monthlyLimitBs!)}/mes'),
                    trailing: TextButton(
                      onPressed: () async {
                        final r = await repo.revokeInvite(i.email);
                        if (context.mounted) {
                          r.fold(
                              (f) => showLuxSnackbar(context, f.message,
                                  isError: true),
                              (_) => showLuxSnackbar(
                                  context, 'Invitación anulada'));
                        }
                      },
                      child: const Text('Anular'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TripsTab extends StatefulWidget {
  const _TripsTab({required this.company});
  final Company company;

  @override
  State<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<_TripsTab> {
  late String _period = currentPeriod();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  : () => setState(() => _period = _nextPeriod(_period)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          StreamBuilder<List<Booking>>(
            stream: sl<BusinessRepository>()
                .watchCompanyBookings(widget.company.id, _period),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()));
              }
              final list = snap.data!.where((b) => b.isCorporate).toList();
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Sin viajes con la cuenta de empresa este mes.',
                      style: LuxTypography.bodyMedium),
                );
              }
              return Column(children: [
                for (final b in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        '${LuxFormat.dateTime(b.scheduledAt)} · ${b.origin.displayName}'),
                    subtitle: Text(
                        '${b.riderName?.isNotEmpty == true ? '${b.riderName} · ' : ''}'
                        '${b.status.displayLabel}'
                        '${b.costCenter?.isNotEmpty == true ? ' · ${b.costCenter}' : ''}'),
                    trailing: Text(bs(b.chargedAmount)),
                  ),
              ]);
            },
          ),
        ],
      );
}

String _nextPeriod(String p) {
  final y = int.parse(p.substring(0, 4));
  final m = int.parse(p.substring(5));
  return m == 12 ? '${y + 1}-01' : '$y-${(m + 1).toString().padLeft(2, '0')}';
}

class _StatementsTab extends StatelessWidget {
  const _StatementsTab({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<CompanyStatement>>(
        stream: sl<BusinessRepository>().watchStatements(company.id),
        builder: (context, snap) {
          // La empresa ve los extractos ya emitidos; el borrador es interno.
          final list = (snap.data ?? const <CompanyStatement>[])
              .where((s) => s.status != StatementStatus.draft)
              .toList();
          if (list.isEmpty) {
            return const Text(
                'Aún no hay extractos. El primero llegará el día 1 del próximo mes.',
                style: LuxTypography.bodyMedium);
          }
          return Column(children: [
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: LuxSpacing.md),
                child: StatementView(statement: s),
              ),
          ]);
        },
      );
}
