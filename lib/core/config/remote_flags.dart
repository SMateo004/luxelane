import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Product switches the admin controls from the panel (`config/global`).
///
/// Readable by everyone (guests included) so public pages can react; only an
/// admin can write them (see firestore.rules). Defaults are the safe state —
/// anything not explicitly enabled stays hidden.
class RemoteFlags {
  RemoteFlags._();
  static final instance = RemoteFlags._();

  /// First Class is not on the market yet: hidden until an admin enables it.
  final firstClassEnabled = ValueNotifier<bool>(false);

  /// Teléfono de central para el chófer (config/global.dispatchPhone). Sin
  /// él no se muestra «Llamar a central»: el número lo fija el responsable.
  final dispatchPhone = ValueNotifier<String?>(null);

  /// Números de emergencia (config/global.emergencyNumbers, nombre → número).
  /// Vacío si no están configurados: el código no trae ninguno.
  final emergencyNumbers = ValueNotifier<Map<String, String>>(const {});

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  void listen(FirebaseFirestore db) {
    _sub?.cancel();
    _sub = db.collection('config').doc('global').snapshots().listen(
      (doc) {
        final data = doc.data() ?? const {};
        firstClassEnabled.value = data['firstClassEnabled'] == true;
        dispatchPhone.value = dispatchPhoneFrom(data);
        emergencyNumbers.value = emergencyNumbersFrom(data);
      },
      // Offline / no permission: keep the safe defaults.
      onError: (_) {},
    );
  }
}

/// El teléfono de central si está configurado (texto no vacío).
String? dispatchPhoneFrom(Map<String, dynamic> global) {
  final v = global['dispatchPhone'];
  return v is String && v.trim().isNotEmpty ? v.trim() : null;
}

/// Solo las entradas con nombre y número no vacíos.
Map<String, String> emergencyNumbersFrom(Map<String, dynamic> global) {
  final v = global['emergencyNumbers'];
  if (v is! Map) return const {};
  return {
    for (final e in v.entries)
      if (e.key is String &&
          (e.key as String).trim().isNotEmpty &&
          e.value is String &&
          (e.value as String).trim().isNotEmpty)
        (e.key as String).trim(): (e.value as String).trim(),
  };
}
