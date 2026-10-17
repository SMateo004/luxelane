enum Env { dev, prod }

abstract class AppConfig {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_KEY',
    defaultValue: 'AIzaSyBbDde6GtLHy9_6qys4BMmq2P2G2INRUkM',
  );

  static Env get env => _env == 'prod' ? Env.prod : Env.dev;

  static bool get isDev => env == Env.dev;
  static bool get isProd => env == Env.prod;

  static String get firebaseProjectId =>
      isProd ? 'luxelane-prod' : 'luxelane-dev';

  /// Stripe publishable key (`pk_live_…`/`pk_test_…`), only if card
  /// payments are ever turned on. Empty by default: rides are paid in Bs to
  /// the chauffeur and Stripe isn't initialised.
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  static bool get stripeEnabled => RegExp(r'^pk_(live|test)_\w+$').hasMatch(stripePublishableKey);

  static bool get enableLogs => isDev;

  /// ISO 4217 code used for quotes and card authorisations.
  static const String currency =
      String.fromEnvironment('CURRENCY', defaultValue: 'bob');

  /// Public rider web app, for links shared outside the app (hotel QR codes).
  static const String riderWebUrl =
      String.fromEnvironment('RIDER_URL', defaultValue: 'https://luxelane-4e7ae.web.app');

  static const String fcmVapidKey =
      String.fromEnvironment('FCM_VAPID_KEY');
}
