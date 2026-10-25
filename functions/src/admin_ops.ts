/**
 * Escrituras de admin (Parte A): todo lo que el panel escribía desde el
 * cliente pasa por aquí. Cada operación valida contra el estado actual, hace
 * el cambio y escribe su auditoría (admin_logs) en la misma transacción.
 * Las reglas dejan al admin solo lectura en estas colecciones.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { AdminActor, changedFields, reasonSchema, writeAudit } from './admin_audit';
import { opsConfig } from './ops_config';
import { docId, parseInput } from './schemas';
import { appendEvent, Status } from './trip_flow';

export interface AdminDeps { db: admin.firestore.Firestore; now?: () => number }

const opError = (code: 'failed-precondition' | 'not-found' | 'invalid-argument', reason: string,
  extra: Record<string, unknown> = {}) => new HttpsError(code, reason, { reason, ...extra });

const nowMs = (d: AdminDeps) => d.now?.() ?? Date.now();
const money = (v: number) => `Bs${v.toFixed(2)}`;

// ---------------------------------------------------------------------------
// A1. adminUpdateBooking: asignar o reasignar, cancelar, mover el estado y
// ajustar el importe final.
// ---------------------------------------------------------------------------

/** Igual que AdminOperations en el panel (admin_operations.dart). */
export const ADMIN_TRANSITIONS: Readonly<Partial<Record<Status, readonly Status[]>>> = {
  pending: ['cancelled'],
  confirmed: ['driver_arriving', 'cancelled'],
  driver_arriving: ['driver_arrived', 'cancelled'],
  driver_arrived: ['cancelled'],
  verified: ['cancelled'],
  in_progress: ['completed'],
};

/** Se asigna o reasigna chófer antes de que llegue a la recogida. */
export const ASSIGNABLE: readonly Status[] = ['pending', 'confirmed', 'driver_arriving'];

/** Reservas con hora de recogida antes de esto ocupan ya al chófer (kBusyLead). */
export const BUSY_LEAD_MS = 60 * 60 * 1000;

export const bookingSchema = z.discriminatedUnion('action', [
  z.strictObject({ action: z.literal('assign'), bookingId: docId, driverId: docId, reason: reasonSchema }),
  z.strictObject({ action: z.literal('cancel'), bookingId: docId, reason: reasonSchema }),
  z.strictObject({
    action: z.literal('status'), bookingId: docId,
    to: z.enum(['driver_arriving', 'driver_arrived', 'completed']), reason: reasonSchema,
  }),
  z.strictObject({
    action: z.literal('adjust_price'), bookingId: docId,
    finalPrice: z.number().finite().min(0).max(1_000_000), reason: reasonSchema,
  }),
]);

/**
 * Límite del ajuste de importe: config/ops.maxPriceAdjustmentPercent. Sin
 * él (o con un valor que no es un porcentaje) no se ajusta nada.
 */
export function maxAdjustmentPercent(ops: Record<string, unknown>): number | null {
  const v = ops.maxPriceAdjustmentPercent;
  return typeof v === 'number' && Number.isFinite(v) && v >= 0 && v <= 100 ? v : null;
}

export async function adminUpdateBooking(deps: AdminDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(bookingSchema, data);
  const db = deps.db;
  const ref = db.collection('bookings').doc(input.bookingId);
  // Fuera de la transacción: no cambia durante ella y no la alarga.
  const maxPct = input.action === 'adjust_price' ? maxAdjustmentPercent(await opsConfig(db)) : null;
  if (input.action === 'adjust_price' && maxPct === null) {
    throw opError('failed-precondition', 'price_adjustment_disabled');
  }

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw opError('not-found', 'booking_not_found');
    const b = snap.data()!;
    const status = b.status as Status;
    const now = admin.firestore.Timestamp.fromMillis(nowMs(deps));
    const event = (to: Status, method: string, detail: Record<string, unknown> = {}) =>
      appendEvent(tx, db, ref.id, {
        from: status, to, actor: { uid: actor.adminId, role: 'admin' }, source: 'admin',
        extra: { method }, adminDetail: { reason: input.reason, ...detail },
      });

    if (input.action === 'assign') {
      if (!ASSIGNABLE.includes(status)) throw opError('failed-precondition', 'not_assignable', { status });
      const previous = (b.driverId as string | undefined) ?? null;
      if (previous === input.driverId) throw opError('failed-precondition', 'no_change');
      const [user, profile] = await Promise.all([
        tx.get(db.collection('users').doc(input.driverId)),
        tx.get(db.collection('driverProfiles').doc(input.driverId)),
      ]);
      if (user.data()?.role !== 'driver' || !profile.exists) throw opError('not-found', 'driver_not_found');
      if (user.data()?.isActive === false) throw opError('failed-precondition', 'driver_inactive');
      if (profile.data()?.documentsVerified !== true) throw opError('failed-precondition', 'driver_not_verified');
      if (profile.data()?.isAvailable !== true) throw opError('failed-precondition', 'driver_busy');

      const to: Status = status === 'pending' ? 'confirmed' : status;
      const after = { driverId: input.driverId, status: to };
      tx.update(ref, { ...after, updatedAt: now });
      const scheduledMs = (b.scheduledAt as admin.firestore.Timestamp | undefined)?.toMillis() ?? nowMs(deps);
      const busyNow = !['pending', 'confirmed'].includes(status) || scheduledMs < nowMs(deps) + BUSY_LEAD_MS;
      if (busyNow) tx.update(db.collection('driverProfiles').doc(input.driverId), { isAvailable: false });
      if (previous) tx.update(db.collection('driverProfiles').doc(previous), { isAvailable: true });
      event(to, previous ? 'admin_reassign' : 'admin_assign', { driverId: input.driverId, previousDriverId: previous });
      writeAudit(tx, db, {
        actor, operation: previous ? 'reassign_driver' : 'assign_driver', collection: 'bookings', docId: ref.id,
        targetType: 'booking', changes: changedFields(b, after), reason: input.reason,
        details: previous ? `Chófer ${previous} → ${input.driverId}` : `Chófer ${input.driverId}`,
      });
      return { status: to, driverId: input.driverId };
    }

    if (input.action === 'cancel') {
      if (!ADMIN_TRANSITIONS[status]?.includes('cancelled')) throw opError('failed-precondition', 'not_cancellable', { status });
      // El motivo del admin no va en la reserva (la leen pasajero y chófer):
      // va en eventDetails y en admin_logs.
      const after = { status: 'cancelled', cancelledBy: 'admin' };
      tx.update(ref, { ...after, cancelledAt: now, updatedAt: now });
      event('cancelled', 'admin_cancel');
      writeAudit(tx, db, {
        actor, operation: 'cancel_booking', collection: 'bookings', docId: ref.id, targetType: 'booking',
        changes: changedFields(b, after), reason: input.reason, details: `${status} → cancelled`,
      });
      return { status: 'cancelled' as Status };
    }

    if (input.action === 'status') {
      if (!ADMIN_TRANSITIONS[status]?.includes(input.to)) {
        throw opError('failed-precondition', 'invalid_transition', { status, to: input.to });
      }
      const after: Record<string, unknown> = { status: input.to };
      // Completar fija el importe si nadie lo ajustó (como hacía el panel).
      if (input.to === 'completed' && b.finalPrice == null) after.finalPrice = b.estimatedPrice ?? null;
      tx.update(ref, { ...after, updatedAt: now });
      event(input.to, 'admin_status');
      writeAudit(tx, db, {
        actor, operation: 'update_status', collection: 'bookings', docId: ref.id, targetType: 'booking',
        changes: changedFields(b, after), reason: input.reason, details: `${status} → ${input.to}`,
      });
      return { status: input.to };
    }

    // adjust_price: solo antes de completar, y dentro del límite de config/ops.
    if (status === 'completed' || status === 'cancelled') throw opError('failed-precondition', 'price_locked', { status });
    const original = Number(b.estimatedPrice ?? 0);
    const changePct = original > 0 ? (Math.abs(input.finalPrice - original) / original) * 100
      : (input.finalPrice === 0 ? 0 : Number.POSITIVE_INFINITY);
    if (changePct > maxPct! + 1e-9) {
      throw opError('failed-precondition', 'price_adjustment_too_large', { maxPercent: maxPct });
    }
    const after = { finalPrice: input.finalPrice };
    // Sin tocar updatedAt: las finanzas fechan el viaje por él.
    tx.update(ref, { ...after, priceAdjustedAt: now });
    writeAudit(tx, db, {
      actor, operation: 'adjust_price', collection: 'bookings', docId: ref.id, targetType: 'booking',
      changes: changedFields(b, after), reason: input.reason,
      details: `${money(Number(b.finalPrice ?? original))} → ${money(input.finalPrice)}`,
      context: { originalPrice: original, previousFinalPrice: b.finalPrice ?? null, maxPercent: maxPct },
    });
    return { finalPrice: input.finalPrice };
  });
}
