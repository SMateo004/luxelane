import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.dart';
import 'core/config/env.dart';
import 'core/config/firebase_env.dart';
import 'core/di/injection.dart';
import 'core/widgets/startup_error_app.dart';
import 'core/services/app_check_service.dart';
import 'core/services/crash_service.dart';
import 'core/services/performance_service.dart';
import 'core/utils/maps_web_loader.dart'
    if (dart.library.io) 'core/utils/maps_web_loader_stub.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Date symbols for every supported language; the active one follows the
  // device language (see IntlLocaleSync in the app widget).
  await initializeDateFormatting();

  // Pre-load brand fonts so every TextStyle(fontFamily: 'Montserrat'/
  // 'Cormorant Garamond') resolves correctly across the entire app —
  // web and native.
  GoogleFonts.config.allowRuntimeFetching = true;
  await Future.wait([
    GoogleFonts.pendingFonts([
      GoogleFonts.montserrat(),
      GoogleFonts.montserrat(fontWeight: FontWeight.w300),
      GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      GoogleFonts.montserrat(fontWeight: FontWeight.w600),
      GoogleFonts.montserrat(fontWeight: FontWeight.w700),
      GoogleFonts.cormorantGaramond(),
      GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w300),
      GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w500),
      GoogleFonts.cormorantGaramond(fontStyle: FontStyle.italic),
      GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
    ]),
  ]);

  try {
    await Firebase.initializeApp(
      // Production, unless a project is given with dart-defines (staging).
      options: FirebaseEnv.options(() => DefaultFirebaseOptions.currentPlatform),
    );
  } catch (e) {
    // Without Firebase nothing works (sign-in, bookings, push): say so
    // instead of running an app that silently does nothing.
    debugPrint('[Luxelane] Firebase init failed: $e');
    runApp(const StartupErrorApp());
    return;
  }

  // Google Maps JS API — load dynamically so the dart-define key is used
  // instead of the placeholder in index.html.
  if (kIsWeb) {
    await initMapsForWeb(AppConfig.googleMapsKey);
  }

  // Stripe (card payments) only with a real key; not supported on web.
  // A failure here must not stop the app: rides are paid in Bs anyway.
  if (!kIsWeb && AppConfig.stripeEnabled) {
    try {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      Stripe.merchantIdentifier = 'luxelane';
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('[Luxelane] Stripe init failed: $e');
    }
  }

  await AppCheckService.init();
  await CrashService.init();
  await PerformanceService.init();
  await configureDependencies();

  // FCM background handler — not supported on web
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      (msg) async {/* handled by NotificationService */},
    );
  }

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
    debugPrint('[Luxelane] env=${AppConfig.env.name} web=$kIsWeb');
    if (kIsWeb && AppConfig.googleMapsKey.isEmpty) {
      debugPrint('[Luxelane] WARNING: GOOGLE_MAPS_KEY is empty. Autocomplete will NOT work. Run with --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY');
    }
  }

  runApp(const LuxelaneApp());
}
