import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/support_ticket.dart';

extension TicketCategoryL10n on TicketCategory {
  String localizedLabel(AppLocalizations l) => switch (this) {
        TicketCategory.trip => l.supportCatTrip,
        TicketCategory.lostItem => l.supportCatLostItem,
        TicketCategory.billing => l.supportCatBilling,
        TicketCategory.chauffeur => l.supportCatChauffeur,
        TicketCategory.safety => l.supportCatSafety,
        TicketCategory.app => l.supportCatApp,
        TicketCategory.other => l.supportCatOther,
      };

  IconData get icon => switch (this) {
        TicketCategory.trip => Icons.directions_car_outlined,
        TicketCategory.lostItem => Icons.work_outline_rounded,
        TicketCategory.billing => Icons.receipt_long_outlined,
        TicketCategory.chauffeur => Icons.person_outline_rounded,
        TicketCategory.safety => Icons.health_and_safety_outlined,
        TicketCategory.app => Icons.phone_iphone_rounded,
        TicketCategory.other => Icons.chat_bubble_outline_rounded,
      };
}

/// Status with icon and label (never color alone).
class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.status, this.forTeam = false});
  final TicketStatus status;

  /// Team view words the states from the agent's side.
  final bool forTeam;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (IconData icon, Color color, String label) = switch (status) {
      TicketStatus.open => (
          Icons.schedule_rounded,
          LuxColors.info,
          forTeam ? l.supportStatusOpenTeam : l.supportStatusOpen
        ),
      TicketStatus.answered => (
          Icons.mark_chat_read_outlined,
          LuxColors.accent,
          forTeam ? l.supportStatusAnsweredTeam : l.supportStatusAnswered
        ),
      TicketStatus.resolved => (Icons.check_circle_outline_rounded, LuxColors.success, l.supportStatusResolved),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LuxSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: LuxTypography.caption.copyWith(color: LuxColors.white)),
      ]),
    );
  }
}
