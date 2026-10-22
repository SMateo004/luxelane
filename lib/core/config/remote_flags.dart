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

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  void listen(FirebaseFirestore db) {
    _sub?.cancel();
    _sub = db.collection('config').doc('global').snapshots().listen(
      (doc) {
        final data = doc.data() ?? const {};
        firstClassEnabled.value = data['firstClassEnabled'] == true;
        dispatchPhone.value = dispatchPhoneFrom(data);
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
