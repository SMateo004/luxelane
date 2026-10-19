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

  static String get stripePublishableKey => isProd
      ? 'pk_live_XXXXXXXXXXXXXXXXXXXXXXXX'
      : 'pk_test_51...'; // Add real keys here or via --dart-define

  static bool get enableLogs => isDev;

  /// Conecta la app a los emuladores locales de Firebase (pruebas en vivo).
  /// `--dart-define=USE_EMULATORS=true`. Nunca activo en producción.
  static const bool useEmulators =
      bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
  static const String emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

  static const String fcmVapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  /// OAuth *Web* client ID of the Firebase project (Google Cloud Console →
  /// Credentials → "Web client (auto created by Google Service)").
  /// Android needs it to obtain the ID token Firebase verifies.
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// OAuth iOS client ID (from GoogleService-Info.plist → CLIENT_ID).
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}
