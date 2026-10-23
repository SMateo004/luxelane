import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  ) => showDialog<void>(
    context: context,
    builder: (_) => AppUpdateDialog(failure: failure),
  );

  @override
  Widget build(BuildContext context) {
    final url = storeUrlFor(failure, defaultTargetPlatform, web: web);
    return AlertDialog(
      title: Text(
        failure.forDriver
            ? 'Actualiza la app para seguir'
            : 'Actualiza la app para reservar',
      ),
      content: Text(
        web
            ? 'Hay una versión nueva de la web. Recarga la página para '
                'seguir reservando.'
            : 'Hay una versión nueva de la app. Actualízala para seguir '
                'reservando.',
      ),
      actions: [
        if (url != null)
          FilledButton(
            onPressed: () {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              Navigator.of(context).pop();
            },
            child: const Text('Ir a la tienda'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
      ],
    );
  }
}
