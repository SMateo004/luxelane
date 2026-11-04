import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Apunta Auth, Firestore y Functions a los emuladores de Firebase
/// (puertos de firebase.json). Solo para desarrollo y pruebas en vivo.
/// Cada servicio por separado: si uno falla, los demás nunca quedan
/// apuntando a producción.
Future<void> useFirebaseEmulators(String host) async {
  try {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  } catch (e) {
    debugPrint('[Emuladores] Auth: $e');
  }
  try {
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  } catch (e) {
    debugPrint('[Emuladores] Firestore: $e');
  }
  try {
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  } catch (e) {
    debugPrint('[Emuladores] Functions: $e');
  }
}
