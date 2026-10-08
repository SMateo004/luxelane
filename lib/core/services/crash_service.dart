import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'client_error_reporter.dart';

class CrashService {
  /// Web error reporting (Crashlytics doesn't support web).
  static final webReporter = ClientErrorReporter();

  static Future<void> init() async {
    if (kIsWeb) {
      if (kDebugMode) return;
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        previous?.call(details);
        webReporter.report(details.exception, details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        webReporter.report(error, stack);
        return true;
      };
      return;
    }

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
    if (kIsWeb) {
      if (!kDebugMode) await webReporter.report(error, stack);
      return;
    }
    await FirebaseCrashlytics.instance
        .recordError(error, stack, fatal: fatal);
  }
}
