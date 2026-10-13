import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../di/injection.dart';
import '../widgets/components.dart';
import 'global_config.dart';

/// Wraps the whole app (MaterialApp.builder) with the switches in
/// config/global: an update screen when this build is older than the
/// minimum an admin set, and, in the rider app, a notice while new bookings
/// are paused for maintenance.
class AppGate extends StatefulWidget {
  const AppGate({
    super.key,
    required this.app,
    required this.child,
    this.showMaintenance = true,
    this.repository,
    this.build,
    this.ios,
  });

  final LuxApp app;
  final Widget child;

  /// False for admins (the dashboard has its own maintenance banner).
  final bool showMaintenance;
  final GlobalConfigRepository? repository;

  /// This binary's build number (tests); defaults to [kAppBuild].
  final int? build;

  /// Platform (tests); defaults to the running one.
  final bool? ios;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  // Keeps the navigator (and every open page) when the notice comes and goes.
  final _childKey = GlobalKey();
  StreamSubscription<GlobalConfig>? _sub;
  GlobalConfig _config = const GlobalConfig();

  @override
  void initState() {
    super.initState();
    final repo = widget.repository ??
        (sl.isRegistered<GlobalConfigRepository>() ? sl<GlobalConfigRepository>() : null);
    // Unreadable config (offline, rules) never locks anyone out.
    _sub = repo?.watch().listen((c) => setState(() => _config = c), onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    final ios = widget.ios ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);
    if (_config.updateRequired(widget.app, widget.build ?? kAppBuild)) {
      return UpdateRequiredPage(url: _config.storeUrl(widget.app, ios: ios));
    }
    final notice = widget.app == LuxApp.rider && widget.showMaintenance && _config.maintenance;
    final media = MediaQuery.of(context);
    return Column(children: [
      if (notice) MaintenanceBar(topInset: media.padding.top),
      Expanded(
        child: notice ? MediaQuery.removePadding(context: context, removeTop: true, child: child) : child,
      ),
    ]);
  }
}

/// Thin notice across the top of the rider app while bookings are paused.
class MaintenanceBar extends StatelessWidget {
  const MaintenanceBar({super.key, this.topInset = 0});
  final double topInset;

  @override
  Widget build(BuildContext context) => Material(
        color: LuxColors.accent,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(LuxSpacing.md, topInset + LuxSpacing.sm, LuxSpacing.md, LuxSpacing.sm),
            child: Row(children: [
              const Icon(Icons.construction_rounded, size: 18, color: LuxColors.black),
              const SizedBox(width: LuxSpacing.sm),
              Expanded(
                child: Text(context.l10n.maintenanceBar,
                    style: LuxTypography.caption.copyWith(color: LuxColors.black, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      );
}

/// Full screen shown instead of the app when this build is too old.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key, this.url});

  /// Store page; null when the App Store link isn't known yet.
  final String? url;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: LuxColors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.system_update_rounded, size: 56, color: LuxColors.accent),
                  const SizedBox(height: LuxSpacing.lg),
                  Semantics(
                    header: true,
                    child: Text(l.updateRequiredTitle, textAlign: TextAlign.center, style: LuxTypography.headlineMedium),
                  ),
                  const SizedBox(height: LuxSpacing.md),
                  Text(l.updateRequiredBody, textAlign: TextAlign.center, style: LuxTypography.bodyMedium),
                  const SizedBox(height: LuxSpacing.xl),
                  if (url != null)
                    LuxButton(
                      label: l.updateRequiredButton,
                      icon: Icons.open_in_new_rounded,
                      onPressed: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
                    )
                  else
                    Text(l.updateRequiredNoLink, textAlign: TextAlign.center, style: LuxTypography.caption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
