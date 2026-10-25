import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/admin_bloc.dart';
import 'admin_shared_widgets.dart';

const _alertLabels = {
  'distance_fallback': 'Precio con distancia aproximada',
  'open_requests_reconciled': 'Solicitudes abiertas corregidas',
  'pickup_locked': 'Verificación bloqueada (5 códigos incorrectos)',
  'pickup_override': 'Verificación forzada por un admin',
  'far_from_pickup': '«Llegué» lejos del punto de recogida',
  'arrival_without_location': '«Llegué» sin ubicación del chófer',
  'new_driver_device': 'Chófer en un dispositivo nuevo',
  'ops_config_in_global': 'Configuración por mover a config/ops',
  'rider_no_show': 'El pasajero no se presentó (decidir)',
  'driver_released_booking': 'Un chófer liberó una reserva',
};

String alertLabel(String type) => _alertLabels[type] ?? type;

/// Avisos del servidor (adminAlerts), de solo lectura. Marcarlos como
/// revisados pasa por la callable resolveAlert, que lo audita.
class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading && state.alerts.isEmpty) {
            return const LuxSkeletonList();
          }
          final alerts = [...state.alerts]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (alerts.isEmpty) {
            return const AdminEmpty(
              icon: Icons.notification_important_outlined,
              title: 'Sin alertas',
              subtitle: 'Aquí aparecen los avisos del servidor que piden '
                  'revisión, como un precio calculado con distancia aproximada.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const LuxDivider(),
            itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
          );
        },
      );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final AdminAlert alert;

  Future<void> _resolve(BuildContext context) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _ResolveDialog(),
    );
    if (note != null && context.mounted) {
      context.read<AdminBloc>().add(
            AdminResolveAlertRequested(alert.id, note: note),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = alert.resolved ? LuxColors.inkTertiary : LuxColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LuxSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(LuxSpacing.xs),
            decoration: BoxDecoration(
              color: LuxColors.surfaceMuted,
              borderRadius: BorderRadius.circular(LuxRadius.sm),
            ),
            child: Icon(
              Icons.notification_important_outlined,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: LuxTypography.bodyMedium,
                    children: [
                      TextSpan(
                        text: alertLabel(alert.type),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (alert.bookingId != null)
                        TextSpan(
                          text: '  Reserva #${shortId(alert.bookingId!)}',
                          style: LuxTypography.caption,
                        ),
                      if (alert.driverId != null)
                        TextSpan(
                          text: '  Chófer #${shortId(alert.driverId!)}',
                          style: LuxTypography.caption,
                        ),
                    ],
                  ),
                ),
                if (alert.message.isNotEmpty)
                  Text(alert.message, style: LuxTypography.caption),
                const SizedBox(height: LuxSpacing.xs),
                AdminTag(
                  alert.resolved ? 'Revisada' : 'Pendiente',
                  color: alert.resolved ? LuxColors.success : LuxColors.warning,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd/MM HH:mm').format(alert.createdAt),
                style: LuxTypography.caption,
              ),
              if (!alert.resolved)
                TextButton(
                  onPressed: () => _resolve(context),
                  child: const Text('Marcar revisada'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pide una nota opcional; devuelve null si se cancela.
class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog();

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Marcar como revisada'),
        content: TextField(
          controller: _note,
          maxLength: 500,
          decoration: adminInputDecoration(hint: 'Nota (opcional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_note.text),
            child: const Text('Marcar revisada'),
          ),
        ],
      );
}
