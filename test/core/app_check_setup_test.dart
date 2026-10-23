import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/app_check_setup.dart';

void main() {
  group('appCheckPlan', () {
    test('release: Play Integrity y App Attest con DeviceCheck de respaldo',
        () {
      final p = appCheckPlan(debugBuild: false, web: false);
      expect(p.debug, isFalse);
      expect(p.android, AndroidProvider.playIntegrity);
      expect(p.apple, AppleProvider.appAttestWithDeviceCheckFallback);
      expect(p.problem, isNull);
    });

    test('release nunca usa el proveedor de depuración, aunque haya token', () {
      final p = appCheckPlan(
          debugBuild: false,
          web: true,
          siteKey: 'clave-de-prueba',
          debugToken: 'token-de-prueba');
      expect(p.debug, isFalse);
      expect(p.android, isNot(AndroidProvider.debug));
      expect(p.apple, isNot(AppleProvider.debug));
      expect(p.webDebugToken, isNull);
      expect(p.webSiteKey, 'clave-de-prueba');
    });

    test(
        'release web sin RECAPTCHA_SITE_KEY: problema claro, sin valor por defecto',
        () {
      final p = appCheckPlan(debugBuild: false, web: true);
      expect(p.webSiteKey, isNull);
      expect(p.problem, contains('RECAPTCHA_SITE_KEY'));
    });

    test('debug: proveedores de depuración y token solo si se pasó', () {
      final p = appCheckPlan(
          debugBuild: true, web: true, siteKey: 'k', debugToken: 't');
      expect(p.android, AndroidProvider.debug);
      expect(p.apple, AppleProvider.debug);
      expect(p.webDebugToken, 't');
      expect(appCheckPlan(debugBuild: true, web: false).webDebugToken, isNull);
    });
  });

  group('activateAppCheck', () {
    const release = AppCheckPlan(
      debug: false,
      android: AndroidProvider.playIntegrity,
      apple: AppleProvider.appAttestWithDeviceCheckFallback,
      webSiteKey: 'clave-de-prueba',
    );

    test('activa con los proveedores del plan', () async {
      AndroidProvider? android;
      ReCaptchaV3Provider? web;
      final s = await activateAppCheck(
        plan: release,
        web: true,
        activate: (
            {webProvider,
            required androidProvider,
            required appleProvider}) async {
          android = androidProvider;
          web = webProvider;
        },
      );
      expect(s, AppCheckStatus.active);
      expect(android, AndroidProvider.playIntegrity);
      expect(web, isNotNull);
      expect(AppCheckState.status, AppCheckStatus.active);
    });

    test('si falla, no lanza: la app arranca y queda «failed»', () async {
      final s = await activateAppCheck(
        plan: release,
        web: false,
        activate: (
                {webProvider,
                required androidProvider,
                required appleProvider}) async =>
            throw Exception('sin Play Services'),
      );
      expect(s, AppCheckStatus.failed);
    });

    test('si no responde a tiempo, sigue sin bloquear el arranque', () async {
      final s = await activateAppCheck(
        plan: release,
        web: false,
        timeout: const Duration(milliseconds: 20),
        activate: (
                {webProvider,
                required androidProvider,
                required appleProvider}) =>
            Completer<void>().future,
      );
      expect(s, AppCheckStatus.failed);
    });

    test('release web sin clave: no activa nada y queda «failed»', () async {
      var called = false;
      final s = await activateAppCheck(
        plan: appCheckPlan(debugBuild: false, web: true),
        web: true,
        activate: (
                {webProvider,
                required androidProvider,
                required appleProvider}) async =>
            called = true,
      );
      expect(s, AppCheckStatus.failed);
      expect(called, isFalse);
    });

    test('debug web: fija el token de depuración antes de activar', () async {
      final order = <String>[];
      await activateAppCheck(
        plan: appCheckPlan(
            debugBuild: true, web: true, siteKey: 'k', debugToken: 'tok'),
        web: true,
        setWebDebugToken: (t) => order.add('token:$t'),
        activate: (
                {webProvider,
                required androidProvider,
                required appleProvider}) async =>
            order.add('activate'),
      );
      expect(order, ['token:tok', 'activate']);
    });
  });

  test('mensaje sobrio cuando falla la verificación', () {
    expect(kAppCheckFailedMessage, startsWith('No se pudo verificar la app'));
  });
}
