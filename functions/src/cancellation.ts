/**
 * Cancelaciones (Parte B de la auditoría). Solo el servidor cancela: el
 * pasajero con cancelBooking (antes escribía la reserva desde la app), el
 * chófer libera con releaseBooking y el admin con adminUpdateBooking. Cada
 * una deja evento en bookings/{id}/events con quién y cuándo (hora del
 * servidor).
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { docId, parseInput } from './schemas';
import { appendEvent, Status } from './trip_flow';

export interface CancelDeps { db: admin.firestore.Firestore; now?: () => number }

const cancelError = (code: 'unauthenticated' | 'permission-denied' | 'not-found' | 'failed-precondition',
  reason: string, extra: Record<string, unknown> = {}) => new HttpsError(code, reason, { reason, ...extra });

const nowMs = (d: CancelDeps) => d.now?.() ?? Date.now();

/** Motivos que elige el pasajero (lista cerrada). */
export const RIDER_CANCEL_REASONS = ['changed_plans', 'other_transport', 'driver_late', 'payment_failed', 'other'] as const;

/** Hasta la llegada del chófer; nunca desde verified, in_progress ni completed. */
export const RIDER_CANCELLABLE: readonly Status[] = ['pending', 'confirmed', 'driver_arriving', 'driver_arrived'];

export const cancelSchema = z.strictObject({
  bookingId: docId,
  reason: z.enum(RIDER_CANCEL_REASONS).default('other'),
  /** Solo calcula lo que pasaría (el aviso de la app antes de confirmar). */
  dryRun: z.boolean().default(false),
  /** Recargo que el pasajero vio y aceptó; si el del servidor es mayor, se rechaza. */
  acceptedFee: z.number().finite().min(0).max(1_000_000).optional(),
});

/** Aviso en la bandeja del chófer, escrito por el servidor. */
function notifyDriver(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, driverId: string,
  bookingId: string, at: admin.firestore.Timestamp, title: string, body: string, type: string): void {
  const ref = db.collection('users').doc(driverId).collection('notifications').doc();
  tx.set(ref, { id: ref.id, userId: driverId, title, body, type, isRead: false, bookingId, createdAt: at });
}

export async function cancelBooking(deps: CancelDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw cancelError('unauthenticated', 'unauthenticated');
  const input = parseInput(cancelSchema, data);
  const db = deps.db;
  const ref = db.collection('bookings').doc(input.bookingId);
  const at = admin.firestore.Timestamp.fromMillis(nowMs(deps));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw cancelError('not-found', 'booking_not_found');
    const b = snap.data()!;
    if (b.riderId !== uid) throw cancelError('permission-denied', 'not_owner');
    const status = b.status as Status;
    // Doble toque o reintento: ya está cancelada; misma respuesta.
    if (status === 'cancelled') {
      return { status, alreadyCancelled: true, cancellationFee: Number(b.cancellationFee ?? 0) };
    }
    if (!RIDER_CANCELLABLE.includes(status)) throw cancelError('failed-precondition', 'not_cancellable', { status });

    const fee = 0;
    if (input.dryRun) return { status, dryRun: true, cancellationFee: fee };

    const driverId = typeof b.driverId === 'string' && b.driverId ? b.driverId : null;
    const driverRef = driverId ? db.collection('driverProfiles').doc(driverId) : null;
    const driver = driverRef ? await tx.get(driverRef) : null;

    tx.update(ref, {
      status: 'cancelled', cancelledBy: 'rider', cancelledAt: at,
      cancellationReason: input.reason, cancellationFee: fee, updatedAt: at,
    });
    // Libera al chófer: disponible si sigue conectado (como releaseDriver).
    if (driver?.exists) tx.update(driverRef!, { isAvailable: driver.data()?.online !== false });
    if (driverId) {
      notifyDriver(tx, db, driverId, ref.id, at, 'Reserva cancelada',
        'El pasajero canceló la reserva. Ya estás disponible.', 'booking_cancelled_by_rider');
    }
    appendEvent(tx, db, ref.id, {
      from: status, to: 'cancelled', actor: { uid, role: 'rider' }, source: 'rider_app',
      extra: { method: 'rider_cancel', cancellationReason: input.reason, cancellationFee: fee },
    });
    return { status: 'cancelled' as Status, cancellationFee: fee };
  });
}
