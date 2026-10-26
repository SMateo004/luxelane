import 'package:cloud_firestore/cloud_firestore.dart';

/// ¿Llegan datos del servidor? Escucha config/global (lectura pública) con
/// los cambios de metadatos: si el último dato viene de la caché, no hay
/// conexión con Firestore. Sin dependencias nuevas y sin lecturas extra
/// mientras no cambie el documento (E12).
abstract final class ConnectionStatus {
  static Stream<bool> watch(FirebaseFirestore db) => db
      .collection('config')
      .doc('global')
      .snapshots(includeMetadataChanges: true)
      .map((s) => !s.metadata.isFromCache)
      // Un error (reglas, documento) no es «sin red»: no se avisa.
      .handleError((Object _) {})
      .distinct();
}
