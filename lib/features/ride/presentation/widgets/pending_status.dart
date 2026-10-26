import '../../../../core/models/models.dart';

/// Qué ve el pasajero mientras su reserva busca chófer. Distingue la
/// búsqueda normal, la de después de que un chófer liberara el viaje y la
/// que sigue sin chófer pasada la hora de recogida (0.5).
enum PendingSituation { searching, driverReleased, pickupPassed }

PendingSituation pendingSituation(Booking b, DateTime now) {
  if (!now.isBefore(b.scheduledAt)) return PendingSituation.pickupPassed;
  if (b.lastReleaseReason != null) return PendingSituation.driverReleased;
  return PendingSituation.searching;
}

///
/// [canCallDispatch]: hay número de central configurado y, con él, botón
/// para llamar. Sin número no se pide «llama a central» (E19).
String pendingMessage(PendingSituation s, {bool canCallDispatch = false}) =>
    switch (s) {
      PendingSituation.searching =>
        'Estamos asignando a tu chófer. Te avisaremos en cuanto esté '
            'confirmado.',
      PendingSituation.driverReleased => canCallDispatch
          ? 'Tu chófer anterior no pudo hacer el viaje. Estamos buscando '
              'otro y central ya está avisada. Si lo necesitas, llama a '
              'central.'
          : 'Tu chófer anterior no pudo hacer el viaje. Estamos buscando '
              'otro y central ya está avisada.',
      PendingSituation.pickupPassed => canCallDispatch
          ? 'Ya pasó la hora de recogida y aún no hay chófer asignado. Llama '
              'a central o cancela la reserva.'
          : 'Ya pasó la hora de recogida y aún no hay chófer asignado. '
              'Puedes esperar o cancelar la reserva.',
    };

/// En estos casos se ofrece llamar a central (si hay número configurado).
bool pendingNeedsDispatch(PendingSituation s) =>
    s != PendingSituation.searching;
