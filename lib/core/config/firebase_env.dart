/// Proyecto de Firebase contra el que corre la app. Se elige al compilar con
/// `--dart-define=FIREBASE_ENV=staging|production`.
enum FirebaseEnv {
  staging,
  production;

  static const String _raw = String.fromEnvironment('FIREBASE_ENV');

  /// El de esta compilación. Sin FIREBASE_ENV es staging: producción nunca
  /// se usa por omisión.
  static FirebaseEnv get current => parse(_raw);

  static FirebaseEnv parse(String raw) => switch (raw) {
        '' || 'staging' => FirebaseEnv.staging,
        'production' => FirebaseEnv.production,
        _ => throw ArgumentError.value(
            raw,
            'FIREBASE_ENV',
            'Debe ser "staging" o "production"', // i18n-ignore: solo desarrollo
          ),
      };
}

/// El proyecto de staging aún tiene los valores de marcador de
/// `lib/firebase_options.dart`.
class StagingNotConfiguredError implements Exception {
  const StagingNotConfiguredError();

  String get message =>
      'Falta configurar el proyecto de staging: reemplaza los valores ' // i18n-ignore: solo desarrollo
      'REEMPLAZAR_* de lib/firebase_options.dart y .firebaserc (DEPLOY.md), ' // i18n-ignore: solo desarrollo
      'o compila con --dart-define=FIREBASE_ENV=production.'; // i18n-ignore: solo desarrollo

  @override
  String toString() => message;
}
