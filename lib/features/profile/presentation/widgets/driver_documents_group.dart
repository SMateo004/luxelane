import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Licencia y vehículo del chófer en su perfil. Tras la verificación, lo
/// que revisó el admin aparece bloqueado (lo cambia central); el color del
/// vehículo sigue editable.
class DriverDocumentsGroup extends StatelessWidget {
  const DriverDocumentsGroup({
    super.key,
    required this.profile,
    this.vehicle,
    this.onEditColor,
  });

  final DriverProfile profile;
  final Vehicle? vehicle;

  /// Cambiar el color del vehículo; null si no hay vehículo.
  final VoidCallback? onEditColor;

  @override
  Widget build(BuildContext context) {
    final locked = profile.documentsVerified;
    final lock = locked
        ? Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: LuxColors.inkTertiary,
            semanticLabel: context.l10n.profileLocked,
          )
        : null;
    final v = vehicle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuxGroup(
          children: [
            LuxListRow(
              icon: Icons.badge_outlined,
              title: context.l10n.profileLicence,
              subtitle: context.l10n.profileLicenceDetail(
                profile.licenseNumber.isEmpty ? '—' : profile.licenseNumber,
                // Mes y año en cifras: igual en los tres idiomas.
                DateFormat('MM/yyyy').format(profile.licenseExpiry),
              ),
              trailing: lock,
            ),
            if (v != null) ...[
              LuxListRow(
                icon: Icons.directions_car_outlined,
                title: '${v.make} ${v.model} ${v.year}',
                subtitle: context.l10n
                    .profileVehicleDetail(v.vehicleClass.label, v.plate),
                trailing: lock,
              ),
              LuxListRow(
                icon: Icons.palette_outlined,
                title: context.l10n.profileColor,
                subtitle: v.color.isEmpty ? '—' : v.color,
                onTap: onEditColor,
              ),
            ],
          ],
        ),
        if (locked)
          Padding(
            padding:
                const EdgeInsets.only(top: LuxSpacing.xs, left: LuxSpacing.xs),
            child: Text(
              context.l10n.commonLockedDocuments,
              style: LuxTypography.caption,
            ),
          ),
      ],
    );
  }
}
