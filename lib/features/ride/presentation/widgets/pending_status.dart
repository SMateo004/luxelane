import '../../../../core/models/models.dart';
import '../../../../l10n/l10n.dart';

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
String pendingMessage(PendingSituation s, {bool canCallDispatch = false}) {
  final t = L10n.current;
  return switch (s) {
    PendingSituation.searching => t.ridePendingSearching,
    PendingSituation.driverReleased =>
      canCallDispatch ? t.ridePendingReleasedCall : t.ridePendingReleased,
    PendingSituation.pickupPassed => canCallDispatch
        ? t.ridePendingPickupPassedCall
        : t.ridePendingPickupPassed,
  };
}

/// En estos casos se ofrece llamar a central (si hay número configurado).
bool pendingNeedsDispatch(PendingSituation s) =>
    s != PendingSituation.searching;
