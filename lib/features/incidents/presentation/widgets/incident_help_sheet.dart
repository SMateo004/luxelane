import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/lux_motion.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
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
    final t = L10n.current;
    if (s.sending) {
      return (t.incidentSendingTitle, t.incidentSendingBody);
    }
    if (s.offline) {
      return (t.incidentFailedTitle, t.incidentOfflineBody);
    }
    final f = s.failure;
    if (f != null) return (t.incidentFailedTitle, f.message);
    final i = s.incident;
    // Cancelado por el usuario (aunque central ya lo haya reconocido).
    if (i != null &&
        i.cancelledByReporter &&
        i.status != IncidentStatus.closed) {
      return (t.incidentCancelledTitle, t.incidentCancelledBody);
    }
    return switch (i?.status) {
      IncidentStatus.open => (t.incidentOpenTitle, t.incidentOpenBody),
      IncidentStatus.acknowledged => (t.incidentAckTitle, t.incidentAckBody),
      IncidentStatus.closed => (t.incidentClosedTitle, t.incidentClosedBody),
      IncidentStatus.cancelRequested => (
          t.incidentCancelledTitle,
          t.incidentCancelRequestedBody,
        ),
      null => (t.incidentHelp, t.incidentIdleBody),
    };
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<IncidentBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.incidentFalseAlarmQuestion),
        content: Text(ctx.l10n.incidentFalseAlarmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.incidentBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.incidentCancelAlert),
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
          final t = context.l10n;
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
                            t.incidentSentTimes(count),
                            style: LuxTypography.caption,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: LuxSpacing.lg),
                if (s.offline && phone != null) ...[
                  LuxButton(
                    label: t.incidentCallDispatch,
                    icon: Icons.call_rounded,
                    onPressed: () => _open(telUri(phone)),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                  LuxOutlinedButton(
                    label: t.incidentSmsDispatch,
                    icon: Icons.sms_outlined,
                    onPressed: () => _open(
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
                    label: t.incidentCallDispatch,
                    icon: Icons.call_outlined,
                    onPressed: () => _open(telUri(phone)),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                ],
                if (s.failure != null)
                  LuxButton.ghost(
                    label: t.incidentRetry,
                    onPressed: s.sending
                        ? null
                        : () => context.read<IncidentBloc>().add(
                              const IncidentRaised(),
                            ),
                  ),
                const SizedBox(height: LuxSpacing.md),
                const LuxDivider(),
                const SizedBox(height: LuxSpacing.sm),
                if (emergencyNumbers.isEmpty)
                  Text(t.incidentNoNumbersHelp, style: LuxTypography.bodyMedium)
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
                          label: t.incidentAlertAgain,
                          onActivated: () => context.read<IncidentBloc>().add(
                                const IncidentRaised(),
                              ),
                        ),
                        const SizedBox(height: LuxSpacing.xs),
                        Text(
                          t.incidentHoldToAlertAgain,
                          style: LuxTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                  LuxButton.ghost(
                    label: t.incidentFalseAlarm,
                    onPressed: () => _confirmCancel(context),
                  ),
                ],
              ],
            ),
          );
        },
      );
}
