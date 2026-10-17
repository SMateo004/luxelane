import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../l10n/l10n.dart';
import '../bloc/driver_bloc.dart';

/// Shown while the chauffeur is available but their location can't be
/// shared: says why and takes them to fix it. Retries by itself when they
/// come back from the phone's settings.
class DriverLocationBanner extends StatefulWidget {
  const DriverLocationBanner({super.key, required this.problem, required this.userId, this.maps});
  final LocationProblem problem;
  final String userId;
  final MapsService? maps;

  @override
  State<DriverLocationBanner> createState() => _DriverLocationBannerState();
}

class _DriverLocationBannerState extends State<DriverLocationBanner> with WidgetsBindingObserver {
  MapsService get _maps => widget.maps ?? sl<MapsService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _retry();
  }

  void _retry() => context.read<DriverBloc>().add(DriverLocationTrackingStarted(userId: widget.userId));

  Future<void> _fix() async {
    await _maps.fixLocation(widget.problem);
    // The permission prompt answers in place; settings come back via resume.
    if (mounted && widget.problem == LocationProblem.denied) _retry();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final body = switch (widget.problem) {
      LocationProblem.serviceOff => l.driverLocationServiceOff,
      LocationProblem.denied => l.driverLocationDenied,
      LocationProblem.deniedForever => l.driverLocationDeniedForever,
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: LuxSpacing.md),
        padding: const EdgeInsets.all(LuxSpacing.md),
        decoration: BoxDecoration(
          color: LuxColors.error.withValues(alpha: 0.12),
          border: Border.all(color: LuxColors.error.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(LuxRadius.md),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.location_off_rounded, color: LuxColors.error, size: 20),
            const SizedBox(width: LuxSpacing.sm),
            Expanded(child: Text(l.driverLocationOffTitle, style: LuxTypography.titleMedium)),
          ]),
          const SizedBox(height: LuxSpacing.xs),
          Text(body, style: LuxTypography.bodyMedium),
          const SizedBox(height: LuxSpacing.sm),
          Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.xs, children: [
            FilledButton.icon(
              onPressed: _fix,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(widget.problem == LocationProblem.denied ? l.driverLocationAllow : l.driverLocationOpenSettings),
            ),
            TextButton(onPressed: _retry, child: Text(l.driverLocationRetry)),
          ]),
        ]),
      ),
    );
  }
}
