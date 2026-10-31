import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Modo emuladores (solo para revisar la app en local, Parte A de
/// experiencia): se activa al compilar con `--dart-define=USE_EMULATORS=true`.
/// Sin esa variable la app usa el proyecto de siempre. En este modo solo se
/// acepta el proyecto de demostración: nunca uno real.
const kUseEmulators = bool.fromEnvironment('USE_EMULATORS');
const kEmulatorProjectId = 'demo-luxelane';
const kEmulatorHost =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

/// Opciones ficticias: el SDK no habla con Google, solo con los emuladores.
const kEmulatorOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:web:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: kEmulatorProjectId,
  authDomain: '$kEmulatorProjectId.firebaseapp.com',
);

/// Las opciones con las que arranca la app. [real] solo se evalúa fuera del
/// modo emuladores (staging sin configurar lanza error al leerlo).
FirebaseOptions startupOptions(
  FirebaseOptions Function() real, {
  bool useEmulators = kUseEmulators,
  FirebaseOptions emulator = kEmulatorOptions,
}) {
  if (!useEmulators) return real();
  if (emulator.projectId != kEmulatorProjectId) {
    throw StateError(
      'El modo emuladores solo admite el proyecto $kEmulatorProjectId ' // i18n-ignore: solo desarrollo
      '(recibido: ${emulator.projectId}).', // i18n-ignore: solo desarrollo
    );
  }
  return emulator;
}

/// Conecta Auth, Firestore y Functions a los emuladores locales.
Future<void> connectEmulators() async {
  await FirebaseAuth.instance.useAuthEmulator(kEmulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(kEmulatorHost, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(kEmulatorHost, 5001);
}
