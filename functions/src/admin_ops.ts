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
import { SERVICE_TYPES, VEHICLE_CLASSES } from './fare';

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

// ---------------------------------------------------------------------------
// A2. adminRecordPayment: registrar y corregir un cobro manual (efectivo, QR,
// transferencia). El pago lo lee el pasajero: no lleva el uid del admin.
// ---------------------------------------------------------------------------

/** Los métodos que ofrece el panel (admin_finance_tab.dart). */
export const MANUAL_METHODS = ['cash', 'qr', 'transfer'] as const;

export const paymentSchema = z.discriminatedUnion('action', [
  z.strictObject({
    action: z.literal('record'), bookingId: docId, method: z.enum(MANUAL_METHODS),
    reference: z.string().trim().max(120).default(''), reason: reasonSchema,
  }),
  z.strictObject({
    action: z.literal('correct'), paymentId: docId,
    amountBs: z.number().finite().min(0).max(1_000_000).optional(),
    method: z.enum(MANUAL_METHODS).optional(),
    reference: z.string().trim().max(120).optional(),
    reason: reasonSchema,
  }),
]);

const toCents = (bs: number) => Math.round(bs * 100);

export async function adminRecordPayment(deps: AdminDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(paymentSchema, data);
  const db = deps.db;
  return db.runTransaction(async (tx) => {
    const now = admin.firestore.Timestamp.fromMillis(nowMs(deps));
    if (input.action === 'record') {
      const bookingRef = db.collection('bookings').doc(input.bookingId);
      const snap = await tx.get(bookingRef);
      if (!snap.exists) throw opError('not-found', 'booking_not_found');
      const b = snap.data()!;
      if (b.status !== 'completed') throw opError('failed-precondition', 'not_completed');
      const card = b.stripePaymentIntentId != null || b.stripePaymentMethodId != null;
      if (card && b.cardPaymentFailed !== true) throw opError('failed-precondition', 'card_payment');
      if (typeof b.paymentId === 'string' && b.paymentId) {
        const existing = await tx.get(db.collection('payments').doc(b.paymentId));
        if (['captured', 'refunded'].includes(existing.data()?.status)) throw opError('failed-precondition', 'already_paid');
      }
      const amountBs = Number(b.finalPrice ?? b.estimatedPrice ?? 0);
      const ref = db.collection('payments').doc();
      const payment = {
        bookingId: input.bookingId, riderId: b.riderId ?? null, stripePaymentIntentId: '',
        amount: toCents(amountBs), currency: 'bob', status: 'captured', method: input.method,
        reference: input.reference, manual: true, recordedByRole: 'admin', createdAt: now,
      };
      tx.set(ref, payment);
      tx.update(bookingRef, { paymentId: ref.id, finalPrice: amountBs });
      writeAudit(tx, db, {
        actor, operation: 'record_payment', collection: 'payments', docId: ref.id, targetType: 'payment',
        changes: changedFields({}, { amount: payment.amount, method: payment.method, reference: payment.reference }),
        reason: input.reason,
        details: `Reserva #${input.bookingId.slice(0, 6)} · ${money(amountBs)} · ${input.method}`,
        context: { bookingId: input.bookingId },
      });
      return { paymentId: ref.id, amount: payment.amount };
    }

    // correct: solo cobros manuales y cobrados; el valor anterior queda en
    // la auditoría.
    const ref = db.collection('payments').doc(input.paymentId);
    const snap = await tx.get(ref);
    if (!snap.exists) throw opError('not-found', 'payment_not_found');
    const p = snap.data()!;
    if (p.manual !== true && p.stripePaymentIntentId !== '') throw opError('failed-precondition', 'not_manual');
    if (p.status !== 'captured') throw opError('failed-precondition', 'not_captured');
    const after: Record<string, unknown> = {
      ...(input.amountBs !== undefined ? { amount: toCents(input.amountBs) } : {}),
      ...(input.method !== undefined ? { method: input.method } : {}),
      ...(input.reference !== undefined ? { reference: input.reference } : {}),
    };
    const changes = changedFields(p, after);
    if (Object.keys(changes).length === 0) throw opError('failed-precondition', 'no_change');
    const bookingRef = typeof p.bookingId === 'string' && p.bookingId ? db.collection('bookings').doc(p.bookingId) : null;
    const booking = bookingRef ? await tx.get(bookingRef) : null;
    tx.update(ref, { ...after, correctedAt: now, corrections: admin.firestore.FieldValue.increment(1) });
    if (changes.amount && booking?.exists) tx.update(bookingRef!, { finalPrice: input.amountBs });
    writeAudit(tx, db, {
      actor, operation: 'correct_payment', collection: 'payments', docId: ref.id, targetType: 'payment',
      changes, reason: input.reason, details: `Corrección: ${Object.keys(changes).join(', ')}`,
      context: { bookingId: p.bookingId ?? null },
    });
    return { paymentId: ref.id };
  });
}

// ---------------------------------------------------------------------------
// A3. adminUpdateConfig: config/global (lista blanca), config/finance y
// config/ops. config/security nunca: solo la consola.
// ---------------------------------------------------------------------------

const atLeastOne = (o: Record<string, unknown>) => Object.keys(o).length > 0;
const positiveInt = z.number().int().positive().max(1_000_000_000);

export const configSchema = z.discriminatedUnion('doc', [
  z.strictObject({
    doc: z.literal('global'),
    // Lo que el panel edita de config/global (público). Versiones mínimas,
    // teléfonos, legalVersion y el resto se editan en la consola.
    changes: z.strictObject({
      isMaintenanceMode: z.boolean().optional(),
      pushNotificationsEnabled: z.boolean().optional(),
      firstClassEnabled: z.boolean().optional(),
    }).refine(atLeastOne),
    reason: reasonSchema,
  }),
  z.strictObject({
    doc: z.literal('finance'),
    changes: z.strictObject({ platformCommissionPct: z.number().finite().min(0).max(100) }),
    reason: reasonSchema,
  }),
  z.strictObject({
    doc: z.literal('ops'),
    // Solo tipos y signo: los valores los decide el responsable.
    changes: z.strictObject({
      incidentAckSeconds: positiveInt.optional(),
      incidentEscalateEverySeconds: positiveInt.optional(),
      incidentLocationRetentionDays: positiveInt.optional(),
      arrivalRadiusMeters: z.number().finite().positive().max(1_000_000).optional(),
      maxPriceAdjustmentPercent: z.number().finite().min(0).max(100).optional(),
    }).refine(atLeastOne),
    reason: reasonSchema,
  }),
]);

export async function adminUpdateConfig(deps: AdminDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(configSchema, data);
  const db = deps.db;
  const ref = db.collection('config').doc(input.doc);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const changes = changedFields(snap.data(), input.changes);
    if (Object.keys(changes).length === 0) throw opError('failed-precondition', 'no_change');
    tx.set(ref, { ...input.changes, updatedAt: admin.firestore.Timestamp.fromMillis(nowMs(deps)) }, { merge: true });
    writeAudit(tx, db, {
      actor, operation: `update_config_${input.doc}`, collection: 'config', docId: input.doc, targetType: 'global_config',
      changes, reason: input.reason,
      details: Object.entries(changes).map(([k, c]) => `${k}: ${String(c.before)} → ${String(c.after)}`).join(', '),
    });
    return { doc: input.doc, changed: Object.keys(changes) };
  });
}

// ---------------------------------------------------------------------------
// A4. adminUpdatePricingRule: crear, cambiar y desactivar tarifas. Los
// importes los pone el responsable; aquí solo se comprueba que sean
// válidos. Borrar una tarifa pasa a desactivarla.
// ---------------------------------------------------------------------------

const amount = z.number().finite().min(0).max(1_000_000);
const fareKey = { vehicleClass: z.enum(VEHICLE_CLASSES), serviceType: z.enum(SERVICE_TYPES) };

export const pricingSchema = z.discriminatedUnion('action', [
  z.strictObject({
    action: z.literal('upsert'), ...fareKey,
    basePriceUsd: amount, pricePerKmUsd: amount, pricePerHourUsd: amount, minimumPriceUsd: amount,
    isActive: z.boolean(), reason: reasonSchema,
  }),
  z.strictObject({ action: z.literal('deactivate'), ...fareKey, reason: reasonSchema }),
]);

/** Igual que PricingRule.validate() en el panel. */
export function fareProblems(f: { serviceType: string; basePriceUsd: number; pricePerKmUsd: number;
  pricePerHourUsd: number; minimumPriceUsd: number }): string[] {
  const out: string[] = [];
  if (f.serviceType === 'oneWay' && f.basePriceUsd === 0 && f.pricePerKmUsd === 0 && f.minimumPriceUsd === 0) {
    out.push('zero_one_way');
  }
  if (f.serviceType === 'byTheHour' && f.pricePerHourUsd <= 0) out.push('hourly_without_rate');
  return out;
}

export async function adminUpdatePricingRule(deps: AdminDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(pricingSchema, data);
  const db = deps.db;
  const id = `${input.vehicleClass}_${input.serviceType}`;
  const ref = db.collection('pricingRules').doc(id);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = admin.firestore.Timestamp.fromMillis(nowMs(deps));
    if (input.action === 'deactivate') {
      if (!snap.exists) throw opError('not-found', 'fare_not_found');
      if (snap.data()?.isActive === false) throw opError('failed-precondition', 'no_change');
      tx.update(ref, { isActive: false, updatedAt: now });
      writeAudit(tx, db, {
        actor, operation: 'deactivate_pricing', collection: 'pricingRules', docId: id, targetType: 'pricing',
        changes: changedFields(snap.data(), { isActive: false }), reason: input.reason, details: `${id} desactivada`,
      });
      return { id, isActive: false };
    }
    const problems = fareProblems(input);
    if (problems.length) throw opError('invalid-argument', 'invalid_fare', { problems });
    // Los mismos campos que admite validFare en firestore.rules; sin updatedBy (C3).
    const fare = {
      id, vehicleClass: input.vehicleClass, serviceType: input.serviceType,
      basePriceUsd: input.basePriceUsd, pricePerKmUsd: input.pricePerKmUsd,
      pricePerHourUsd: input.pricePerHourUsd, minimumPriceUsd: input.minimumPriceUsd, isActive: input.isActive,
    };
    const changes = changedFields(snap.data(), fare);
    if (Object.keys(changes).length === 0) throw opError('failed-precondition', 'no_change');
    tx.set(ref, { ...fare, updatedAt: now });
    writeAudit(tx, db, {
      actor, operation: snap.exists ? 'update_pricing' : 'create_pricing', collection: 'pricingRules', docId: id,
      targetType: 'pricing', changes, reason: input.reason,
      details: `${id}: base ${money(fare.basePriceUsd)}, ${money(fare.pricePerKmUsd)}/km, ` +
        `${money(fare.pricePerHourUsd)}/h, mín. ${money(fare.minimumPriceUsd)}${fare.isActive ? '' : ' · DESACTIVADA'}`,
    });
    return { id, isActive: fare.isActive };
  });
}
