import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../error/failures.dart';

/// Enlace a la tienda de la plataforma actual, si el admin lo configuró.
String? storeUrlFor(
  AppUpdateRequiredFailure f,
  TargetPlatform platform, {
  bool web = kIsWeb,
}) =>
    web
        ? null
        : switch (platform) {
            TargetPlatform.android => f.androidStoreUrl,
            TargetPlatform.iOS => f.iosStoreUrl,
            _ => null,
          };

/// Aviso sobrio cuando la versión instalada ya no puede reservar.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.failure, this.web = kIsWeb});

  final AppUpdateRequiredFailure failure;
  final bool web;

  static Future<void> show(
    BuildContext context,
    AppUpdateRequiredFailure failure,
  ) =>
      showDialog<void>(
        context: context,
        builder: (_) => AppUpdateDialog(failure: failure),
      );

  @override
  Widget build(BuildContext context) {
    final url = storeUrlFor(failure, defaultTargetPlatform, web: web);
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        failure.forDriver
            ? l10n.commonUpdateTitleDriver
            : l10n.commonUpdateTitleRider,
      ),
      content: Text(
        web ? l10n.commonUpdateBodyWeb : l10n.commonUpdateBodyApp,
      ),
      actions: [
        if (url != null)
          FilledButton(
            onPressed: () {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              Navigator.of(context).pop();
            },
            child: Text(l10n.commonUpdateGoToStore),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonGotIt),
          ),
      ],
    );
  }
}
