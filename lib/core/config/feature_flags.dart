import 'env.dart';

abstract class FeatureFlags {
  static const bool _isProd = !bool.fromEnvironment('ENABLE_DEV_FLAGS', defaultValue: true);

  // Ride features
  static const bool realTimeTracking = true;
  static const bool scheduledBooking = true;

  // Payment features
  static const bool savedCards = true;
  static const bool refundsEnabled = true;

  // Driver features
  static const bool driverApp = true;
  static const bool stripeConnect = false;

  // Experimental
  static const bool nearestDriverMatching = true;
  static const bool adminPanel = true;
  static const bool ratingSystem = true;

  // Dev only
  static bool get devToolsOverlay => AppConfig.isDev;
  static bool get mockPayments => AppConfig.isDev;
  static bool get skipPhoneVerification => AppConfig.isDev;
}
