import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';
import '../../data/support_repository.dart';
import '../../domain/support_ticket.dart';
import '../pages/new_ticket_page.dart';

/// Bolivian police emergency line (the one the help center tells people to call).
const policeNumber = '110';

/// "Seguridad" on an active trip, for the rider and the chauffeur: call the
/// police, report a safety problem about this trip (an urgent ticket that
/// pushes the team) or get help with the trip.
class TripSafetyButton extends StatelessWidget {
  const TripSafetyButton({super.key, required this.bookingId, this.repository, this.launcher});
  final String bookingId;
  final SupportRepository? repository;

  /// Opens tel: links; injectable for tests.
  final Future<bool> Function(Uri uri)? launcher;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: TextButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: LuxColors.blackElevated,
          builder: (_) => TripSafetySheet(bookingId: bookingId, repository: repository, launcher: launcher),
        ),
        style: TextButton.styleFrom(foregroundColor: LuxColors.warning, minimumSize: const Size(0, 48)),
        icon: const Icon(Icons.shield_outlined, size: 18),
        label: Text(l.tripSafetyButton),
      ),
    );
  }
}

class TripSafetySheet extends StatelessWidget {
  const TripSafetySheet({super.key, required this.bookingId, this.repository, this.launcher});
  final String bookingId;
  final SupportRepository? repository;
  final Future<bool> Function(Uri uri)? launcher;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: policeNumber);
    final open = launcher ?? (u) => launchUrl(u, mode: LaunchMode.externalApplication);
    if (!await open(uri) && context.mounted) {
      showLuxSnackbar(context, context.l10n.tripSafetyCallFailed(policeNumber), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget option(IconData icon, String title, String body, VoidCallback onTap, {Color? color}) => ListTile(
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 12,
          leading: Icon(icon, color: color ?? LuxColors.accent),
          title: Text(title, style: LuxTypography.bodyLarge.copyWith(color: color)),
          subtitle: Text(body, style: LuxTypography.caption),
          onTap: onTap,
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(LuxSpacing.lg, LuxSpacing.lg, LuxSpacing.lg, LuxSpacing.md),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.tripSafetyTitle, style: LuxTypography.titleLarge),
          const SizedBox(height: LuxSpacing.sm),
          option(Icons.local_police_outlined, l.tripSafetyCallPolice(policeNumber), l.tripSafetyCallPoliceBody,
              () => _call(context),
              color: LuxColors.error),
          option(Icons.report_outlined, l.tripSafetyReport, l.tripSafetyReportBody, () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.push(MaterialPageRoute<void>(
              builder: (_) => NewTicketPage(
                repository: repository ?? sl<SupportRepository>(),
                bookingId: bookingId,
                initialCategory: TicketCategory.safety,
                initialSubject: l.tripSafetyReportSubject,
              ),
            ));
          }),
          option(Icons.support_agent_outlined, l.tripSafetyHelp, l.tripSafetyHelpBody, () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push('/ayuda?booking=$bookingId');
          }),
        ]),
      ),
    );
  }
}
