import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../widgets/components.dart';

/// Antes de la petición del sistema, una explicación propia y sobria
/// (Prompt 18, C4). Solo si el permiso aún no se ha pedido: si ya se
/// concedió o se negó, no se insiste.
class PushPermissionGate {
  const PushPermissionGate({
    required this.status,
    required this.request,
    this.explain,
  });

  /// Estado actual del permiso.
  final Future<AuthorizationStatus> Function() status;

  /// Petición del sistema.
  final Future<void> Function() request;

  /// Explicación previa; true = la persona quiere seguir.
  final Future<bool> Function()? explain;

  /// true si se pidió el permiso al sistema.
  Future<bool> run() async {
    final s = await status();
    if (s != AuthorizationStatus.notDetermined) return false;
    final go = explain == null || await explain!();
    if (!go) return false;
    await request();
    return true;
  }
}

/// Diálogo de la explicación previa. «Ahora no» no pide nada; se vuelve a
/// ofrecer en el próximo inicio de sesión.
Future<bool> showPushPermissionExplainer(BuildContext context) async {
  final t = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const ExcludeSemantics(
        child: Icon(Icons.notifications_outlined, color: LuxColors.ink),
      ),
      title: Semantics(header: true, child: Text(t.pushPermissionTitle)),
      content: Text(t.pushPermissionBody),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
              minimumSize: const Size(
                  kMinInteractiveDimension, kMinInteractiveDimension)),
          onPressed: () => Navigator.of(c).pop(false),
          child: Text(t.pushPermissionNotNow),
        ),
        LuxButton(
          label: t.pushPermissionContinue,
          width: 160,
          onPressed: () => Navigator.of(c).pop(true),
        ),
      ],
    ),
  );
  return ok ?? false;
}
