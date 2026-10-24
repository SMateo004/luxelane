import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../incidents/presentation/help_contacts.dart';
import '../bloc/admin_bloc.dart';
import 'admin_shared_widgets.dart';
import 'incident_beep_io.dart'
    if (dart.library.js_interop) 'incident_beep_web.dart' as beep;

/// Tiempo sin reconocer, legible para el admin.
String incidentWaitLabel(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  if (s < 60) return '${s}s';
  final m = s ~/ 60;
  return m < 60 ? '${m}min ${s % 60}s' : '${m ~/ 60}h ${m % 60}min';
}

String incidentStatusLabel(Incident i) => switch (i.status) {
      IncidentStatus.open => 'SIN RECONOCER',
      IncidentStatus.acknowledged => 'Reconocido',
      IncidentStatus.cancelRequested =>
        'CANCELADO POR EL USUARIO: VERIFICAR POR LLAMADA',
      IncidentStatus.closed => 'Cerrado',
    };

const _logLabels = {
  'raised': 'SOS disparado',
  'repeated': 'Pulsado de nuevo',
  'escalated': 'Escalado (sin reconocer)',
  'acknowledged': 'Reconocido',
  'closed': 'Cerrado',
  'cancel_requested': 'Cancelado por el usuario: verificar por llamada',
  'reopened_by_reporter': 'Reactivado por el usuario',
};

/// Incidentes SOS sin cerrar, arriba de todo en cualquier sección del
/// panel. Suena mientras haya alguno sin reconocer (se puede silenciar en
/// este navegador o dispositivo).
class AdminIncidentsStrip extends StatefulWidget {
  const AdminIncidentsStrip({
    super.key,
    this.beepEvery = const Duration(seconds: 5),
    this.onBeep,
    this.launch,
  });

  final Duration beepEvery;

  /// Sonido (sustituible en tests).
  final VoidCallback? onBeep;
  final Future<void> Function(Uri uri)? launch;

  @override
  State<AdminIncidentsStrip> createState() => _AdminIncidentsStripState();
}

class _AdminIncidentsStripState extends State<AdminIncidentsStrip> {
  Timer? _clock;
  Timer? _alarm;
  bool _muted = false;

  @override
  void dispose() {
    _clock?.cancel();
    _alarm?.cancel();
    super.dispose();
  }

  void _sync(AdminState s) {
    final anyLive = s.incidents.isNotEmpty;
    // Reloj para el «tiempo sin reconocer».
    if (anyLive && _clock == null) {
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!anyLive) {
      _clock?.cancel();
      _clock = null;
    }
    final ring = s.unacknowledgedIncidents > 0 && !_muted;
    if (ring && _alarm == null) {
      _beep();
      _alarm = Timer.periodic(widget.beepEvery, (_) => _beep());
    } else if (!ring) {
      _alarm?.cancel();
      _alarm = null;
    }
  }

  void _beep() => (widget.onBeep ?? beep.playIncidentBeep)();

  Future<void> _open(Uri uri) =>
      widget.launch != null ? widget.launch!(uri) : launchUrl(uri);

  @override
  Widget build(BuildContext context) => BlocBuilder<AdminBloc, AdminState>(
        buildWhen: (a, b) =>
            a.incidents != b.incidents ||
            a.users != b.users ||
            a.bookings != b.bookings ||
            a.globalSettings != b.globalSettings,
        builder: (context, s) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _sync(s);
          });
          if (s.incidents.isEmpty) return const SizedBox.shrink();
          final list = [...s.incidents]..sort((a, b) {
              int rank(Incident i) => switch (i.status) {
                    IncidentStatus.open || IncidentStatus.cancelRequested => 0,
                    IncidentStatus.acknowledged => 1,
                    _ => 2,
                  };
              final r = rank(a).compareTo(rank(b));
              if (r != 0) return r;
              return (a.createdAt ?? DateTime(0)).compareTo(
                b.createdAt ?? DateTime(0),
              );
            });
          final unack = s.unacknowledgedIncidents;
          return Container(
            key: const ValueKey('incidents-strip'),
            width: double.infinity,
            color: unack > 0
                ? LuxColors.error.withValues(alpha: 0.08)
                : LuxColors.warning.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(
              LuxSpacing.md,
              LuxSpacing.sm,
              LuxSpacing.md,
              LuxSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sos_rounded, color: LuxColors.error),
                    const SizedBox(width: LuxSpacing.sm),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          unack > 0
                              ? '$unack ${unack == 1 ? 'incidente sin reconocer' : 'incidentes sin reconocer'}'
                              : 'Incidentes en curso',
                          style: LuxTypography.titleMedium.copyWith(
                            color: LuxColors.error,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _muted = !_muted;
                        _sync(s);
                      }),
                      icon: Icon(
                        _muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                      ),
                      label: Text(_muted ? 'Activar sonido' : 'Silenciar'),
                    ),
                  ],
                ),
                for (final i in list)
                  _IncidentCard(incident: i, state: s, open: _open),
              ],
            ),
          );
        },
      );
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.state,
    required this.open,
  });

  final Incident incident;
  final AdminState state;
  final Future<void> Function(Uri) open;

  Booking? get _booking {
    for (final b in state.bookings) {
      if (b.id == incident.bookingId) return b;
    }
    return null;
  }

  String? _phone(String? uid) {
    if (uid == null) return null;
    final p = state.userById(uid)?.phone ?? '';
    return p.trim().isEmpty ? null : p;
  }

  Future<void> _close(BuildContext context) async {
    final note = await confirmAdminAction(
      context,
      title: 'Cerrar incidente',
      message:
          'El incidente de la reserva #${bookingShortId(incident.bookingId)} '
          'quedará cerrado y deja de compartirse la ubicación. La nota queda '
          'en la auditoría.',
      confirmLabel: 'Cerrar incidente',
      reasonLabel: 'Nota de cierre (mínimo 10 caracteres)',
      minReasonLength: 10,
    );
    if (note == null || !context.mounted) return;
    context.read<AdminBloc>().add(
          AdminCloseIncidentRequested(incident.id, note),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdminBloc>();
    final b = _booking;
    final reporter = state.userName(incident.reporterId);
    final role = incident.reporterRole == 'driver' ? 'chófer' : 'pasajero';
    final since = incident.createdAt == null
        ? null
        : DateTime.now().difference(incident.createdAt!);
    final riderPhone = _phone(b?.riderId);
    final driverPhone = _phone(b?.driverId);
    final dispatch = state.globalSettings['dispatchPhone'];
    final open0 = incident.needsAck;
    return Container(
      margin: const EdgeInsets.only(top: LuxSpacing.sm),
      padding: const EdgeInsets.all(LuxSpacing.sm),
      decoration: BoxDecoration(
        color: LuxColors.surface,
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        border: Border.all(
          color: open0 ? LuxColors.error : LuxColors.border,
          width: open0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: LuxSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminTag(
                incidentStatusLabel(incident),
                color: open0 ? LuxColors.error : LuxColors.warning,
              ),
              Text(
                'Reserva #${bookingShortId(incident.bookingId)} · SOS del '
                '$role $reporter',
                style: LuxTypography.titleMedium,
              ),
              if (since != null && open0)
                Text(
                  'Sin reconocer: ${incidentWaitLabel(since)}',
                  style: LuxTypography.bodyMedium.copyWith(
                    color: LuxColors.error,
                  ),
                ),
              if (incident.count > 1)
                Text(
                  'Pulsado ${incident.count} veces',
                  style: LuxTypography.caption,
                ),
              if (incident.escalationCount > 0)
                Text(
                  'Escalado ${incident.escalationCount}×',
                  style: LuxTypography.caption,
                ),
            ],
          ),
          const SizedBox(height: LuxSpacing.xs),
          Wrap(
            spacing: LuxSpacing.sm,
            runSpacing: LuxSpacing.xs,
            children: [
              StreamBuilder<({double lat, double lng})?>(
                stream: bloc.incidentLocation(incident.id),
                builder: (_, snap) => snap.data == null
                    ? const AdminTag(
                        'Sin ubicación del aviso',
                        color: LuxColors.inkTertiary,
                      )
                    : AdminActionButton(
                        icon: Icons.location_on_outlined,
                        label: 'Ubicación del aviso',
                        onTap: () => open(
                          Uri.parse(
                            mapLink(snap.data!.lat, snap.data!.lng),
                          ),
                        ),
                      ),
              ),
              if (b != null)
                StreamBuilder<({double lat, double lng})?>(
                  stream: bloc.driverTracking(b.id),
                  builder: (_, snap) => snap.data == null
                      ? const SizedBox.shrink()
                      : AdminActionButton(
                          icon: Icons.directions_car_outlined,
                          label: 'Ubicación del chófer',
                          onTap: () => open(
                            Uri.parse(
                              mapLink(snap.data!.lat, snap.data!.lng),
                            ),
                          ),
                        ),
                ),
              if (riderPhone != null)
                AdminActionButton(
                  icon: Icons.call_outlined,
                  label: 'Llamar al pasajero',
                  onTap: () => open(telUri(riderPhone)),
                ),
              if (driverPhone != null)
                AdminActionButton(
                  icon: Icons.call_outlined,
                  label: 'Llamar al chófer',
                  onTap: () => open(telUri(driverPhone)),
                ),
              if (dispatch is String && dispatch.trim().isNotEmpty)
                AdminActionButton(
                  icon: Icons.support_agent_outlined,
                  label: 'Llamar a central',
                  onTap: () => open(telUri(dispatch)),
                ),
              if (open0)
                AdminActionButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Reconocer',
                  color: LuxColors.error,
                  onTap: () => bloc.add(
                    AdminAcknowledgeIncidentRequested(incident.id),
                  ),
                ),
              AdminActionButton(
                icon: Icons.task_alt_rounded,
                label: 'Cerrar con nota',
                onTap: () => _close(context),
              ),
            ],
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Registro', style: LuxTypography.caption),
              children: [
                StreamBuilder<List<IncidentLogEntry>>(
                  stream: bloc.incidentLog(incident.id),
                  builder: (_, snap) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in snap.data ?? const <IncidentLogEntry>[])
                        Text(
                          '${e.at == null ? '—' : adminDate(e.at!)} · '
                          '${_logLabels[e.type] ?? e.type}'
                          '${e.note != null ? ': ${e.note}' : ''}',
                          style: LuxTypography.caption,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
