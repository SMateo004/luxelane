import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import 'app_check_debug_stub.dart'
    if (dart.library.js_interop) 'app_check_debug_web.dart' as web_debug;

/// Clave del sitio de reCAPTCHA v3 para la web (App Check). Solo por
/// `--dart-define=RECAPTCHA_SITE_KEY=...`; no hay valor por defecto.
const kRecaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

/// Token de depuración de App Check para la web en debug
/// (`--dart-define=APP_CHECK_DEBUG_TOKEN=...`). Nunca se usa en release.
const kAppCheckDebugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

enum AppCheckStatus { active, debug, unavailable, failed }

/// Qué proveedores usar. Puro, para poder probarlo.
class AppCheckPlan {
  const AppCheckPlan({
    required this.debug,
    required this.android,
    required this.apple,
    this.webSiteKey,
    this.webDebugToken,
    this.problem,
  });

  final bool debug;
  final AndroidProvider android;
  final AppleProvider apple;

  /// null = en web no se activa (falta la clave).
  final String? webSiteKey;
  final String? webDebugToken;

  /// Por qué no se puede activar (solo nombres, nunca valores).
  final String? problem;
}

AppCheckPlan appCheckPlan({
  required bool debugBuild,
  required bool web,
  String siteKey = kRecaptchaSiteKey,
  String debugToken = kAppCheckDebugToken,
}) {
  // Proveedor de depuración solo en debug; en release, nunca, aunque se
  // haya pasado un token.
  if (debugBuild) {
    return AppCheckPlan(
      debug: true,
      android: AndroidProvider.debug,
      apple: AppleProvider.debug,
      webSiteKey: siteKey.isEmpty ? null : siteKey,
      webDebugToken: debugToken.isEmpty ? null : debugToken,
      problem: web && siteKey.isEmpty
          ? 'Falta --dart-define=RECAPTCHA_SITE_KEY para App Check en la web.' // i18n-ignore: solo desarrollo
          : null,
    );
  }
  return AppCheckPlan(
    debug: false,
    android: AndroidProvider.playIntegrity,
    apple: AppleProvider.appAttestWithDeviceCheckFallback,
    webSiteKey: siteKey.isEmpty ? null : siteKey,
    problem: web && siteKey.isEmpty
        ? 'Release web sin --dart-define=RECAPTCHA_SITE_KEY: App Check no se ' // i18n-ignore: solo desarrollo
            'activa.'
        : null,
  );
}

typedef AppCheckActivator = Future<void> Function({
  ReCaptchaV3Provider? webProvider,
  required AndroidProvider androidProvider,
  required AppleProvider appleProvider,
});

/// Estado de App Check de esta ejecución: los mensajes de error lo usan.
class AppCheckState {
  AppCheckState._();
  static AppCheckStatus status = AppCheckStatus.unavailable;
}

/// Activa App Check antes de cualquier llamada a Functions. Si falla, la
/// app arranca igual: las llamadas que lo exijan fallarán con «No se pudo
/// verificar la app».
Future<AppCheckStatus> activateAppCheck({
  AppCheckPlan? plan,
  bool web = kIsWeb,
  AppCheckActivator? activate,
  void Function(String token)? setWebDebugToken,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final p = plan ?? appCheckPlan(debugBuild: kDebugMode, web: web);
  if (web && p.webSiteKey == null) {
    debugPrint('[AppCheck] ${p.problem}');
    return AppCheckState.status =
        p.debug ? AppCheckStatus.unavailable : AppCheckStatus.failed;
  }
  try {
    if (web && p.debug && p.webDebugToken != null) {
      (setWebDebugToken ?? web_debug.setAppCheckDebugToken)(p.webDebugToken!);
    }
    final run = activate ??
        ({webProvider, required androidProvider, required appleProvider}) =>
            FirebaseAppCheck.instance.activate(
              webProvider: webProvider,
              androidProvider: androidProvider,
              appleProvider: appleProvider,
            );
    await run(
      webProvider:
          p.webSiteKey == null ? null : ReCaptchaV3Provider(p.webSiteKey!),
      androidProvider: p.android,
      appleProvider: p.apple,
    ).timeout(timeout);
    return AppCheckState.status =
        p.debug ? AppCheckStatus.debug : AppCheckStatus.active;
  } catch (_) {
    // Sin detalles en el registro: pueden incluir identificadores.
    debugPrint('[AppCheck] no se pudo activar');
    return AppCheckState.status = AppCheckStatus.failed;
  }
}

/// Mensaje cuando el servidor exige App Check y esta app no lo superó.
String get kAppCheckFailedMessage => L10n.current.errorAppCheckFailed;
