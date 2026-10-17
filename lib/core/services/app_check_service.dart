import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Firebase App Check: lets the server tell the real apps from scripts
/// (functions/src/app_check.ts). Android uses Play Integrity, iOS App Attest
/// (DeviceCheck before iOS 14), web reCAPTCHA Enterprise. Debug builds use
/// the debug provider: register the token they print in Firebase Console.
class AppCheckService {
  /// reCAPTCHA Enterprise site key for the web apps (rider site and admin);
  /// without it the web doesn't send App Check tokens.
  static const webSiteKey = String.fromEnvironment('APP_CHECK_WEB_KEY');

  static Future<void> init() async {
    if (kIsWeb && webSiteKey.isEmpty) return;
    try {
      await FirebaseAppCheck.instance.activate(
        webProvider: kIsWeb ? ReCaptchaEnterpriseProvider(webSiteKey) : null,
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
      );
    } catch (e) {
      // Never block startup: while the server only logs missing tokens the
      // app keeps working, and the logs show the problem.
      debugPrint('[Luxelane] App Check not active: $e');
    }
  }
}
