import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/driver_app.dart';
import 'core/config/env.dart';
import 'core/config/firebase_startup.dart';
import 'core/di/injection.dart';
import 'core/services/crash_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/performance_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebase = await startFirebase(
    () =>
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  );
  if (firebase is FirebaseFatal) {
    runApp(appForStartup(firebase, const DriverApp()));
    return;
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  await CrashService.init();
  await PerformanceService.init();
  await configureDependencies();

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  if (AppConfig.enableLogs) {
    debugPrint('[LuxelaneDriver] env=${AppConfig.env.name} web=$kIsWeb');
  }

  runApp(appForStartup(firebase, const DriverApp()));
}
