import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/lux_format.dart';
import '../../../../core/widgets/components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/special_repository.dart';
import '../../domain/special_models.dart';
import '../widgets/special_services_sheet.dart';

/// /especiales — solicitudes del cliente: estado, cotización y decisión.
class MySpecialRequestsPage extends StatelessWidget {
  const MySpecialRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final uid = auth is AuthAuthenticated ? auth.user.id : null;
    return Scaffold(
      backgroundColor: LuxColors.bg,
      appBar: AppBar(
        title: const Text('Servicios especiales'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<SpecialRequest>>(
              stream: sl<SpecialRepository>().watchMine(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('No pudimos cargar tus solicitudes.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                return ListView(
                  padding: const EdgeInsets.all(LuxSpacing.md),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (list.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: LuxSpacing.xl),
                                child: Column(children: [
                                  const Text('Aún no has pedido ninguno.',
                                      style: LuxTypography.bodyMedium),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () =>
                                        showSpecialServices(context),
                                    child:
                                        const Text('Ver servicios especiales'),
                                  ),
                                ]),
                              ),
                            for (final r in list)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: LuxSpacing.md),
                                child: _RequestCard(request: r),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.request});
  final SpecialRequest request;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _act(Future<dynamic> Function() f, String ok) async {
    setState(() => _busy = true);
    final r = await f();
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold((x) => showLuxSnackbar(context, x.message, isError: true),
        (_) => showLuxSnackbar(context, ok));
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar la solicitud?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok == true) {
      await _act(() => sl<SpecialRepository>().cancel(widget.request.id),
          'Solicitud cancelada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final muted = !r.status.isOpen && r.status != SpecialStatus.confirmed;
    return LuxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(r.kind.icon, color: LuxColors.inkSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(r.kind.label, style: LuxTypography.titleMedium)),
            Text(r.status.label,
                style: LuxTypography.caption.copyWith(
                    color: switch (r.status) {
                      SpecialStatus.quoted => LuxColors.sapphire,
                      SpecialStatus.confirmed ||
                      SpecialStatus.completed =>
                        LuxColors.success,
                      SpecialStatus.declined => LuxColors.error,
                      _ => LuxColors.inkTertiary,
                    },
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(r.summary,
              style: LuxTypography.bodyMedium.copyWith(
                  color: muted ? LuxColors.inkTertiary : LuxColors.ink)),
          Text(
              '${LuxFormat.dateTime(r.date)} · ${r.passengers} '
              '${r.passengers == 1 ? 'pasajero' : 'pasajeros'}',
              style: LuxTypography.caption),
          if (r.quoteBs != null &&
              (r.status == SpecialStatus.quoted ||
                  r.status == SpecialStatus.confirmed ||
                  r.status == SpecialStatus.completed)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuxColors.surfaceMuted,
                borderRadius: BorderRadius.circular(LuxRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(LuxFormat.bs(r.quoteBs!),
                      style: LuxTypography.headlineMedium),
                  if (r.adminNote?.isNotEmpty == true)
                    Text(r.adminNote!, style: LuxTypography.caption),
                ],
              ),
            ),
          ],
          if (r.status == SpecialStatus.declined &&
              r.adminNote?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(r.adminNote!, style: LuxTypography.caption),
          ],
          if (r.status.isOpen) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (r.status == SpecialStatus.quoted)
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _act(
                          () => sl<SpecialRepository>().acceptQuote(r.id),
                          'Confirmado. Te contactaremos para los detalles.'),
                  child: const Text('Aceptar cotización'),
                ),
              TextButton(
                onPressed: _busy ? null : _cancel,
                child: Text(r.status == SpecialStatus.quoted
                    ? 'Rechazar'
                    : 'Cancelar solicitud'),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
