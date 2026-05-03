import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/driver_app.dart';
import 'core/config/env.dart';
import 'core/di/injection.dart';
import 'core/services/crash_service.dart';
import 'core/services/performance_service.dart';
import 'firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (AppConfig.enableLogs) {
      debugPrint('[LuxelaneDriver] Firebase init skipped: $e');
    }
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      (msg) async {/* handled by NotificationService */},
    );
  }

  await CrashService.init();
  await PerformanceService.init();
  await configureDependencies();

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0A0A),
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

  runApp(const DriverApp());
}
