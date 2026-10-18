import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/driver_app.dart';
import 'core/config/brand_fonts.dart';
import 'core/config/env.dart';
import 'core/config/firebase_env.dart';
import 'core/di/injection.dart';
import 'core/widgets/startup_error_app.dart';
import 'core/services/app_check_service.dart';
import 'core/services/crash_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/performance_service.dart';
import 'firebase_options_driver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Date symbols for every supported language; the active one follows the
  // device language (see IntlLocaleSync in the app widget).
  await initializeDateFormatting();
  BrandFonts.registerLicenses();
  await BrandFonts.preload();

  try {
    await Firebase.initializeApp(
      // Production, unless a project is given with dart-defines (staging).
      options: FirebaseEnv.options(() => DefaultFirebaseOptions.currentPlatform),
    );
  } catch (e) {
    // Without Firebase nothing works (sign-in, bookings, push): say so
    // instead of running an app that silently does nothing.
    debugPrint('[LuxelaneDriver] Firebase init failed: $e');
    runApp(const StartupErrorApp());
    return;
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  await AppCheckService.init();
  await CrashService.init();
  await PerformanceService.init();
  await configureDependencies();

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Light app: dark status-bar icons on paper.
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

  runApp(const DriverApp());
}
