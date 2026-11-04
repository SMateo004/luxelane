import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';

/// Viaje compartido (Prompt 18, C2): una línea sobria en el viaje del chófer
/// para que no sea una sorpresa que el pasajero comparta el seguimiento.
class DriverTripShareNotice extends StatelessWidget {
  const DriverTripShareNotice({super.key});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.share_location_outlined,
                size: 16, color: LuxColors.inkSecondary),
          ),
          const SizedBox(width: LuxSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.driverTripShareNotice,
              style: LuxTypography.caption,
            ),
          ),
        ],
      );
}
