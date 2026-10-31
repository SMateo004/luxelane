import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failures.dart';
import '../../../l10n/l10n.dart';

/// Por qué no se pudo abrir una reserva. Antes todo era «Revisa tu
/// conexión», también si la reserva no existía (E13).
String rideLoadErrorMessage(Object error) => switch (error) {
      BookingNotFoundException() ||
      FirebaseException(code: 'permission-denied' || 'not-found') =>
        L10n.current.rideLoadNotFound,
      FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
        L10n.current.rideLoadOffline,
      _ => L10n.current.rideLoadFailed,
    };
