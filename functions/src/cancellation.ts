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
import { alert, appendEvent, location, Status } from './trip_flow';
import { buildOpenRequest, BookingForRequest } from './open_requests';
import { opsConfig } from './ops_config';
import { readPolicy } from './cancellation_policy';
import { computeCancelSettle, readForSettle, writeCancelSettle } from './payment_settle';
import { cents, paymentStateRef } from './payment_model';

export { CancellationPolicy, policySchema, readPolicy, retentionFor } from './cancellation_policy';

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
  /**
   * Retención que el pasajero vio y aceptó, en bolivianos; si la del
   * servidor es mayor, se rechaza. El importe lo calcula siempre el servidor.
   */
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
  const { policy, state } = readPolicy(await opsConfig(db, nowMs(deps)));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw cancelError('not-found', 'booking_not_found');
    const b = snap.data()!;
    if (b.riderId !== uid) throw cancelError('permission-denied', 'not_owner');
    const status = b.status as Status;
    // Doble toque o reintento: ya está cancelada; misma respuesta.
    if (status === 'cancelled') {
      const prev = await tx.get(paymentStateRef(db, ref.id));
      return { status, alreadyCancelled: true, cancellationFee: Number(prev.data()?.amountRetained ?? 0) / 100 };
    }
    if (!RIDER_CANCELLABLE.includes(status)) throw cancelError('failed-precondition', 'not_cancellable', { status });

    // Retención según la etapa (A7), sobre lo PAGADO; sin pago, 0.
    const read = await readForSettle(tx, db, ref.id, status);
    const settle = { bookingId: ref.id, status, cause: 'rider' as const, policy, policyState: state, read, at };
    const r = computeCancelSettle(settle);
    const fee = r.retained / 100;
    const answer = { cancellationFee: fee, feeBasis: r.basis, retained: r.retained, refund: r.refund };
    if (input.dryRun) return { status, dryRun: true, ...answer };
    // El pasajero confirma viendo la retención: si ahora es mayor (pasó la
    // gracia mientras decidía), se le vuelve a mostrar.
    if (r.retained > cents(input.acceptedFee ?? 0)) {
      throw cancelError('failed-precondition', 'cancellation_fee_changed', { cancellationFee: fee });
    }

    const driverId = typeof b.driverId === 'string' && b.driverId ? b.driverId : null;
    const driverRef = driverId ? db.collection('driverProfiles').doc(driverId) : null;
    const driver = driverRef ? await tx.get(driverRef) : null;

    // Importes fuera de la reserva y de los eventos: el chófer los lee (A1).
    tx.update(ref, {
      status: 'cancelled', cancelledBy: 'rider', cancelledAt: at, cancellationReason: input.reason, updatedAt: at,
    });
    writeCancelSettle(tx, db, settle, r);
    // Libera al chófer: disponible si sigue conectado (como releaseDriver).
    if (driver?.exists) tx.update(driverRef!, { isAvailable: driver.data()?.online !== false });
    if (driverId) {
      notifyDriver(tx, db, driverId, ref.id, at, 'Reserva cancelada',
        'El pasajero canceló la reserva. Ya estás disponible.', 'booking_cancelled_by_rider');
    }
    appendEvent(tx, db, ref.id, {
      from: status, to: 'cancelled', actor: { uid, role: 'rider' }, source: 'rider_app',
      extra: { method: 'rider_cancel', cancellationReason: input.reason, retentionBasis: r.basis },
      adminDetail: { retained: r.retained, refund: r.refund, retentionPercent: r.percent },
    });
    return { status: 'cancelled' as Status, ...answer };
  });
}

/** Motivos del chófer para liberar una reserva (lista cerrada). */
export const DRIVER_RELEASE_REASONS = ['vehicle_issue', 'personal_emergency', 'unsafe_conditions', 'schedule_conflict', 'other'] as const;

/** Antes de llegar a la recogida; después, el camino es no_show o central. */
export const DRIVER_RELEASABLE: readonly Status[] = ['confirmed', 'driver_arriving'];

export const releaseSchema = z.strictObject({
  bookingId: docId,
  reason: z.enum(DRIVER_RELEASE_REASONS),
  location: location.optional(),
  appVersion: z.string().max(40).optional(),
});

/**
 * B5: el chófer asignado devuelve la reserva antes de llegar. Vuelve a
 * pending sin chófer, reaparece en openRequests, central recibe una alerta y
 * el contador del chófer (driverProfiles.releasedBookingsCount, solo lo
 * escribe el servidor) sube. No hay sanción automática.
 */
export async function releaseBooking(deps: CancelDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw cancelError('unauthenticated', 'unauthenticated');
  const input = parseInput(releaseSchema, data);
  const db = deps.db;
  const ref = db.collection('bookings').doc(input.bookingId);
  const driverRef = db.collection('driverProfiles').doc(uid);
  const at = admin.firestore.Timestamp.fromMillis(nowMs(deps));

  return db.runTransaction(async (tx) => {
    const [snap, driver] = await Promise.all([tx.get(ref), tx.get(driverRef)]);
    if (!snap.exists) throw cancelError('not-found', 'booking_not_found');
    const b = snap.data()!;
    const status = b.status as Status;
    // Reintento tras liberarla: ya no es suya, pero la última liberación sí.
    if (b.driverId !== uid) {
      if (b.lastRelease?.driverId === uid) return { status, alreadyReleased: true };
      throw cancelError('permission-denied', 'not_assigned');
    }
    if (!DRIVER_RELEASABLE.includes(status)) throw cancelError('failed-precondition', 'not_releasable', { status });

    tx.update(ref, {
      status: 'pending', driverId: admin.firestore.FieldValue.delete(),
      lastRelease: { driverId: uid, reason: input.reason, at, from: status },
      // Quien la liberó no vuelve a tomarla (assignNearestDriver,
      // acceptBooking y las reglas lo comprueban).
      releasedBy: admin.firestore.FieldValue.arrayUnion(uid),
      updatedAt: at,
    });
    // La ubicación del chófer que se va no debe verla el siguiente.
    tx.delete(ref.collection('tracking').doc('driver'));
    tx.set(db.collection('openRequests').doc(ref.id), buildOpenRequest({
      ...(b as BookingForRequest),
      releasedBy: [...(Array.isArray(b.releasedBy) ? b.releasedBy : []), uid],
    }));
    if (driver.exists) {
      tx.update(driverRef, {
        isAvailable: driver.data()?.online !== false,
        releasedBookingsCount: admin.firestore.FieldValue.increment(1),
        lastReleasedAt: at,
      });
    }
    appendEvent(tx, db, ref.id, {
      from: status, to: 'pending', actor: { uid, role: 'driver' }, source: 'driver_app',
      appVersion: input.appVersion, location: input.location,
      extra: { method: 'driver_release', releaseReason: input.reason },
    });
    // Cuánto falta para la recogida: central decide si hay que llamar ya al
    // pasajero (no hay otro aviso hasta que se asigne o se cancele).
    const pickupMs = (b.scheduledAt as admin.firestore.Timestamp | undefined)?.toMillis();
    const minutesToPickup = pickupMs === undefined ? null : Math.round((pickupMs - nowMs(deps)) / 60_000);
    alert(tx, db, {
      type: 'driver_released_booking', severity: 'high', bookingId: ref.id, driverId: uid,
      reason: input.reason, minutesToPickup,
      message: minutesToPickup === null
        ? 'El chófer liberó la reserva. Vuelve a estar buscando chófer; revisa si hay que asignarla.'
        : `El chófer liberó la reserva y faltan ${minutesToPickup} min para la recogida. ` +
          'Vuelve a estar buscando chófer; revisa si hay que asignarla o llamar al pasajero.',
    });
    return { status: 'pending' as Status, alreadyReleased: false };
  });
}
