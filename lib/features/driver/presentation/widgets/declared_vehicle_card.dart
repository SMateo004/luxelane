import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/vehicles/vehicle_catalog.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/widgets/components.dart';
import '../../../../l10n/l10n.dart';

/// Admin document review: the vehicle the chauffeur declared, with its
/// class, so it can be checked against the registration document (dispatch
/// offers rides by class) and corrected if it doesn't match.
class DeclaredVehicleCard extends StatefulWidget {
  const DeclaredVehicleCard({super.key, required this.driverId, this.repository});
  final String driverId;
  final VehicleRepository? repository;

  @override
  State<DeclaredVehicleCard> createState() => _DeclaredVehicleCardState();
}

class _DeclaredVehicleCardState extends State<DeclaredVehicleCard> {
  VehicleRepository? _repo;
  Vehicle? _vehicle;
  VehicleClass? _class;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? (sl.isRegistered<VehicleRepository>() ? sl<VehicleRepository>() : null);
    _repo?.getVehicleByDriver(widget.driverId).then((r) {
      final v = r.fold((_) => null, (v) => v);
      if (mounted && v != null) {
        setState(() {
          _vehicle = v;
          _class = v.vehicleClass;
        });
      }
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    final v = _vehicle!;
    final updated = Vehicle(
      id: v.id,
      driverId: v.driverId,
      make: v.make,
      model: v.model,
      year: v.year,
      plate: v.plate,
      vehicleClass: _class!,
      color: v.color,
      photoUrl: v.photoUrl,
      capacity: v.capacity,
      isActive: v.isActive,
    );
    setState(() => _busy = true);
    final r = await _repo!.updateVehicle(updated);
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold(
      (_) => showLuxSnackbar(context, l.adminActionFailed, isError: true),
      (_) {
        setState(() => _vehicle = updated);
        showLuxSnackbar(context, l.vehicleClassSaved);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _vehicle;
    if (v == null) return const SizedBox.shrink();
    final l = context.l10n;
    final changed = _class != v.vehicleClass;
    return Padding(
      padding: const EdgeInsets.only(bottom: LuxSpacing.md),
      child: LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.directions_car_outlined, color: LuxColors.accent),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(child: Text(l.vehicleDeclaredTitle, style: LuxTypography.titleMedium)),
          ]),
          const SizedBox(height: LuxSpacing.sm),
          Text(l.vehicleDeclaredLine('${v.make} ${v.model} ${v.year}'.trim(), v.plate),
              style: LuxTypography.bodyMedium.copyWith(color: LuxColors.white)),
          const SizedBox(height: LuxSpacing.xs),
          Text(l.vehicleClassCheck, style: LuxTypography.caption),
          const SizedBox(height: LuxSpacing.sm),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final c in {...VehicleCatalog.instance.active.map((v) => v.vehicleClass), if (_class != null) _class!})
              ChoiceChip(
                label: Text(c.localizedLabel(l)),
                selected: _class == c,
                selectedColor: LuxColors.accent.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => _class = c),
              ),
          ]),
          if (changed) ...[
            const SizedBox(height: LuxSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: LuxButton(
                label: l.vehicleClassSave,
                width: 220,
                height: 44,
                loading: _busy,
                onPressed: _busy ? null : _save,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
