import 'package:firebase_core/firebase_core.dart';

/// Which Firebase project the build talks to.
///
/// Production builds use the generated firebase_options*.dart. A staging (or
/// any other) project is chosen at build time with dart-defines, so no
/// generated file has to be committed per project:
///
///   --dart-define=FIREBASE_PROJECT_ID=luxelane-staging
///   --dart-define=FIREBASE_API_KEY=… --dart-define=FIREBASE_APP_ID=…
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=…
///
/// scripts/setup_staging.sh writes these to .env.staging and
/// scripts/deploy_web.sh passes them when ENV=staging.
abstract final class FirebaseEnv {
  /// The production project (firebase_options.dart).
  static const productionProjectId = 'luxelane-4e7ae';

  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  /// Options from dart-defines, or [fallback] (the generated production
  /// options) when no project was given.
  static FirebaseOptions options(FirebaseOptions fallback) => fromDefines(
        projectId: _projectId,
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _senderId,
        authDomain: _authDomain,
        storageBucket: _storageBucket,
        fallback: fallback,
      );

  /// Testable core of [options].
  static FirebaseOptions fromDefines({
    required String projectId,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    String authDomain = '',
    String storageBucket = '',
    required FirebaseOptions fallback,
  }) {
    if (projectId.isEmpty) return fallback;
    if (apiKey.isEmpty || appId.isEmpty || messagingSenderId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID=$projectId needs FIREBASE_API_KEY, '
          'FIREBASE_APP_ID and FIREBASE_MESSAGING_SENDER_ID too (see .env.staging).');
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isNotEmpty ? authDomain : '$projectId.firebaseapp.com',
      storageBucket: storageBucket.isNotEmpty ? storageBucket : '$projectId.firebasestorage.app',
    );
  }

  /// Project this build uses.
  static String get projectId => _projectId.isNotEmpty ? _projectId : productionProjectId;

  /// Anything but production shows a "STAGING" ribbon.
  static bool get isProduction => projectId == productionProjectId;
}
