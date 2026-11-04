import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Cierre del viaje en la app del chófer (ventana del chófer, A4): la
/// reserva salió de su ventana (terminada, cancelada o «no se presentó») y
/// ya no la puede leer. No es un error: dice cómo terminó y vuelve a las
/// solicitudes. [status] null = aún no se sabe o el viaje ya no es suyo.
class DriverTripClosedView extends StatelessWidget {
  const DriverTripClosedView({super.key, required this.status});
  final BookingStatus? status;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final (icon, title, body) = switch (status) {
      BookingStatus.completed => (
          Icons.check_circle_outline_rounded,
          t.driverTripClosedCompletedTitle,
          t.driverTripClosedCompletedBody,
        ),
      BookingStatus.noShow => (
          Icons.person_off_outlined,
          t.driverTripClosedNoShowTitle,
          t.driverTripClosedNoShowBody,
        ),
      BookingStatus.cancelled => (
          Icons.event_busy_outlined,
          t.driverTripClosedCancelledTitle,
          t.driverTripClosedCancelledBody,
        ),
      _ => (
          Icons.info_outline_rounded,
          t.driverTripClosedOtherTitle,
          t.driverTripClosedOtherBody,
        ),
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, size: 56, color: LuxColors.inkSecondary),
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: LuxTypography.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: LuxSpacing.sm),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: LuxTypography.bodyMedium,
                  ),
                  const SizedBox(height: LuxSpacing.lg),
                  LuxButton(
                    label: t.driverTripClosedBack,
                    onPressed: () => context.go('/driver/queue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
