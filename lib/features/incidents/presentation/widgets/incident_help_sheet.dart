import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../bloc/incident_bloc.dart';
import '../help_contacts.dart';
import 'sos_button.dart';

/// Lo que ve quien pidió ayuda: el estado del aviso, cómo contactar si no
/// hay red, los números configurados y la opción de falsa alarma.
class IncidentHelpSheet extends StatelessWidget {
  const IncidentHelpSheet({
    super.key,
    required this.bookingId,
    this.dispatchPhone,
    this.emergencyNumbers = const {},
    this.launch,
  });

  final String bookingId;
  final String? dispatchPhone;
  final Map<String, String> emergencyNumbers;

  /// Abre tel: o sms: (sustituible en tests).
  final Future<void> Function(Uri uri)? launch;

  Future<void> _open(Uri uri) => launch != null ? launch!(uri) : launchUrl(uri);

  static (String, String) texts(IncidentState s) {
    if (s.sending) {
      return ('Avisando a central…', 'No cierres la app.');
    }
    if (s.offline) {
      return (
        'No pudimos avisar a central',
        'No hay conexión. Llama o envía el mensaje ya preparado.',
      );
    }
    final f = s.failure;
    if (f != null) return ('No pudimos avisar a central', f.message);
    final i = s.incident;
    return switch (i?.status) {
      IncidentStatus.open => (
        'Avisamos a central',
        'Te contactarán en breve. Compartimos tu ubicación mientras dure '
            'el aviso.',
      ),
      IncidentStatus.acknowledged => (
        'Central recibió tu aviso',
        'Una persona de central lo está atendiendo.',
      ),
      IncidentStatus.closed => (
        'Aviso cerrado',
        'Central cerró el aviso. Ya no compartimos tu ubicación.',
      ),
      IncidentStatus.cancelledByReporter => (
        'Aviso cancelado',
        'Central lo revisará igualmente. Ya no compartimos tu ubicación.',
      ),
      null => ('Ayuda', 'Mantén pulsado SOS para avisar a central.'),
    };
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<IncidentBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('¿Fue una falsa alarma?'),
            content: const Text(
              'Cancelaremos el aviso. Central lo verá igualmente y queda '
              'registrado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cancelar aviso'),
              ),
            ],
          ),
    );
    if (ok == true) bloc.add(const IncidentCancelled());
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<IncidentBloc, IncidentState>(
        builder: (context, s) {
          final (title, body) = texts(s);
          final phone = dispatchPhone;
          final loc = s.lastLocation;
          final count = s.incident?.count ?? 0;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              LuxSpacing.lg,
              LuxSpacing.lg,
              LuxSpacing.lg,
              LuxSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: LuxMotion.of(context, LuxMotion.base),
                  child: Column(
                    key: ValueKey(title),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(title, style: LuxTypography.titleLarge),
                      ),
                      const SizedBox(height: LuxSpacing.xs),
                      Text(body, style: LuxTypography.bodyMedium),
                      if (count > 1 && s.live)
                        Padding(
                          padding: const EdgeInsets.only(top: LuxSpacing.xs),
                          child: Text(
                            'Aviso enviado $count veces.',
                            style: LuxTypography.caption,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: LuxSpacing.lg),
                if (s.offline && phone != null) ...[
                  LuxButton(
                    label: 'Llamar a central',
                    icon: Icons.call_rounded,
                    onPressed: () => _open(telUri(phone)),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                  LuxOutlinedButton(
                    label: 'Enviar SMS a central',
                    icon: Icons.sms_outlined,
                    onPressed:
                        () => _open(
                          incidentSmsUri(
                            phone,
                            bookingShortId(bookingId),
                            lat: loc?.lat,
                            lng: loc?.lng,
                          ),
                        ),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                ] else if (phone != null) ...[
                  LuxOutlinedButton(
                    label: 'Llamar a central',
                    icon: Icons.call_outlined,
                    onPressed: () => _open(telUri(phone)),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                ],
                if (s.failure != null)
                  LuxButton.ghost(
                    label: 'Reintentar el aviso',
                    onPressed:
                        s.sending
                            ? null
                            : () => context.read<IncidentBloc>().add(
                              const IncidentRaised(),
                            ),
                  ),
                const SizedBox(height: LuxSpacing.md),
                const LuxDivider(),
                const SizedBox(height: LuxSpacing.sm),
                if (emergencyNumbers.isEmpty)
                  const Text(kNoNumbersHelp, style: LuxTypography.bodyMedium)
                else
                  for (final e in emergencyNumbers.entries)
                    LuxListRow(
                      icon: Icons.local_phone_outlined,
                      title: e.key,
                      subtitle: e.value,
                      onTap: () => _open(telUri(e.value)),
                    ),
                if (s.live) ...[
                  const SizedBox(height: LuxSpacing.lg),
                  Center(
                    child: Column(
                      children: [
                        SosButton(
                          label: 'Avisar de nuevo',
                          onActivated:
                              () => context.read<IncidentBloc>().add(
                                const IncidentRaised(),
                              ),
                        ),
                        const SizedBox(height: LuxSpacing.xs),
                        const Text(
                          'Mantén pulsado para avisar de nuevo',
                          style: LuxTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                  LuxButton.ghost(
                    label: 'Fue una falsa alarma',
                    onPressed: () => _confirmCancel(context),
                  ),
                ],
              ],
            ),
          );
        },
      );
}
