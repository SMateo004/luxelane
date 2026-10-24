import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/config/driver_documents.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widgets/components.dart';

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
        ? const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: LuxColors.inkTertiary,
            semanticLabel: 'Bloqueado',
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
              title: 'Licencia',
              subtitle:
                  '${profile.licenseNumber.isEmpty ? '—' : profile.licenseNumber}'
                  ' · vence ${DateFormat('MM/yyyy').format(profile.licenseExpiry)}',
              trailing: lock,
            ),
            if (v != null) ...[
              LuxListRow(
                icon: Icons.directions_car_outlined,
                title: '${v.make} ${v.model} ${v.year}',
                subtitle: '${v.vehicleClass.label} · placa ${v.plate}',
                trailing: lock,
              ),
              LuxListRow(
                icon: Icons.palette_outlined,
                title: 'Color',
                subtitle: v.color.isEmpty ? '—' : v.color,
                onTap: onEditColor,
              ),
            ],
          ],
        ),
        if (locked)
          const Padding(
            padding: EdgeInsets.only(top: LuxSpacing.xs, left: LuxSpacing.xs),
            child: Text(kLockedDocumentsMessage, style: LuxTypography.caption),
          ),
      ],
    );
  }
}
