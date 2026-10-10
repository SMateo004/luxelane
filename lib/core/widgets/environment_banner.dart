import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../config/firebase_env.dart';

/// "STAGING" ribbon on every screen of a non-production build, so nobody
/// mistakes test bookings for real ones (or the other way round).
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({super.key, required this.child, this.show});
  final Widget child;

  /// Defaults to "not the production project".
  final bool? show;

  @override
  Widget build(BuildContext context) {
    if (!(show ?? !FirebaseEnv.isProduction)) return child;
    return Banner(
      message: context.l10n.envStagingRibbon,
      location: BannerLocation.topStart,
      color: const Color(0xFFB3261E),
      child: child,
    );
  }
}
