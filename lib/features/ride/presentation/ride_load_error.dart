import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failures.dart';

/// Por qué no se pudo abrir una reserva. Antes todo era «Revisa tu
/// conexión», también si la reserva no existía (E13).
String rideLoadErrorMessage(Object error) => switch (error) {
      BookingNotFoundException() ||
      FirebaseException(code: 'permission-denied' || 'not-found') =>
        'No encontramos esta reserva en tu cuenta.',
      FirebaseException(code: 'unavailable' || 'deadline-exceeded') =>
        'No pudimos cargar tu reserva. Revisa tu conexión.',
      _ => 'No pudimos cargar tu reserva. Inténtalo de nuevo.',
    };
