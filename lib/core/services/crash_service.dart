import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashService {
  static Future<void> init() async {
    if (kIsWeb) return; // Crashlytics not supported on web

    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> setUser(String userId) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  static void log(String message) {
    if (!kIsWeb) FirebaseCrashlytics.instance.log(message);
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance
        .recordError(error, stack, fatal: fatal);
  }
}
