import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/app.dart';
import 'core/config/env.dart';
import 'core/config/remote_flags.dart';
import 'core/di/injection.dart';
import 'core/services/crash_service.dart';
import 'core/services/performance_service.dart';
import 'core/services/pricing_catalog.dart';
import 'core/utils/maps_web_loader.dart'
    if (dart.library.io) 'core/utils/maps_web_loader_stub.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      GoogleFonts.cormorantGaramond(
          fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
    ]),
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Admin-controlled switches (e.g. First Class availability).
    RemoteFlags.instance.listen(FirebaseFirestore.instance);
  } catch (e) {
    if (AppConfig.enableLogs) {
      debugPrint('[Luxelane] Firebase init skipped: $e');
    }
  }

  // Google Maps JS API — load dynamically so the dart-define key is used
  // instead of the placeholder in index.html.
  if (kIsWeb) {
    await initMapsForWeb(AppConfig.googleMapsKey);
  }

  // Stripe — not supported on web (uses dart:io internally)
  if (!kIsWeb) {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    Stripe.merchantIdentifier = 'luxelane';
    await Stripe.instance.applySettings();
  }

  await CrashService.init();
  await PerformanceService.init();
  await configureDependencies();

  // Tarifas y estado operativo en vivo (los configura el panel admin).
  if (Firebase.apps.isNotEmpty) {
    PricingCatalog.instance.start(FirebaseFirestore.instance);
  }

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
        systemNavigationBarColor: Color(0xFF070E18),
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
      debugPrint(
          '[Luxelane] WARNING: GOOGLE_MAPS_KEY is empty. Autocomplete will NOT work. Run with --dart-define=GOOGLE_MAPS_KEY=YOUR_KEY');
    }
  }

  runApp(const LuxelaneApp());
}
