enum Env { dev, prod }

abstract class AppConfig {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// Google Maps key for the web and the Places/Directions calls. It only
  /// comes from `--dart-define=GOOGLE_MAPS_KEY=...` (or
  /// `--dart-define-from-file=env.local.json`); there is no built-in key.
  /// Without it maps show `MapsKeyMissing` instead of a map.
  static const String googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_KEY');

  static bool get hasMapsKey => googleMapsKey.isNotEmpty;

  static Env get env => _env == 'prod' ? Env.prod : Env.dev;

  static bool get isDev => env == Env.dev;
  static bool get isProd => env == Env.prod;

  static String get stripePublishableKey => isProd
      ? 'pk_live_XXXXXXXXXXXXXXXXXXXXXXXX'
      : 'pk_test_51...'; // Add real keys here or via --dart-define

  static bool get enableLogs => isDev;

  static const String fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  /// OAuth *Web* client ID of the Firebase project (Google Cloud Console →
  /// Credentials → "Web client (auto created by Google Service)").
  /// Android needs it to obtain the ID token Firebase verifies.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// OAuth iOS client ID (from GoogleService-Info.plist → CLIENT_ID).
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
}
