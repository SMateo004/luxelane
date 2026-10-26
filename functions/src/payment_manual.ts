/**
 * Pago manual por QR o transferencia (A4).
 *
 * - markPaymentSent: el pasajero dueño avisa «ya pagué» (con número de
 *   operación opcional). Crea una alerta de prioridad alta para central y NO
 *   confirma nada.
 * - adminConfirmPayment: solo admin, con motivo y número de operación.
 *   Comprueba que el importe sea el debido, pone paid, abre la solicitud
 *   para los chóferes (el aviso sale por notifyDriversOnPaid) y audita en
 *   la misma transacción. Una referencia ya pagada o un número de operación
 *   ya usado no se confirman dos veces.
 * - adminRejectPayment: el pago avisado no llegó; queda en failed y el
 *   pasajero puede volver a avisar.
 *
 * markPaidInTx es el paso común a cualquier confirmación (también la de
 * tarjeta, A5).
 */
import { createHash } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { AdminActor, changedFields, reasonSchema, writeAudit } from './admin_audit';
import { loadPaymentSettings } from './payment_config';
import { openForDrivers } from './payment_booking';
import { addLedger, cents, PaymentMethod, PaymentState, paymentStateRef } from './payment_model';
import { ProviderOverrides, providerFor } from './payment_provider';
import { docId, parseInput } from './schemas';

export interface PaymentDeps {
  db: admin.firestore.Firestore;
  now?: () => number;
  /** Proveedores simulados en los tests. */
  providers?: ProviderOverrides;
}

export const payError = (code: 'failed-precondition' | 'not-found' | 'permission-denied' | 'invalid-argument' | 'unauthenticated',
  reason: string, extra: Record<string, unknown> = {}) => new HttpsError(code, reason, { reason, ...extra });

export const nowOf = (d: PaymentDeps) => admin.firestore.Timestamp.fromMillis(d.now?.() ?? Date.now());

/** Número de operación del banco: texto corto sin símbolos raros. */
const operationNumber = z.string().trim().min(1).max(40).regex(/^[A-Za-z0-9 ._/-]+$/);

/** Clave de unicidad del número de operación por método (sin espacios ni mayúsculas). */
export const operationKey = (method: PaymentMethod, op: string): string =>
  createHash('sha256').update(`${method}:${op.replace(/\s+/g, '').toUpperCase()}`).digest('hex').slice(0, 40);

/** Notificación al pasajero en su bandeja (texto sobrio, sin plazos ni promesas). */
export function notifyRider(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, riderId: string,
  bookingId: string, at: admin.firestore.Timestamp, title: string, body: string, type: string): void {
  const ref = db.collection('users').doc(riderId).collection('notifications').doc();
  tx.set(ref, { id: ref.id, userId: riderId, title, body, type, isRead: false, bookingId, createdAt: at });
}

/** Marca como revisadas las alertas «ya pagué» de la reserva (lecturas: antes de escribir). */
async function reportedAlerts(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, bookingId: string) {
  return (await tx.get(db.collection('adminAlerts')
    .where('bookingId', '==', bookingId).where('type', '==', 'payment_reported').where('resolved', '==', false))).docs;
}

// ---------------------------------------------------------------------------
// markPaymentSent (pasajero)
// ---------------------------------------------------------------------------

export const sentSchema = z.strictObject({ bookingId: docId, operationNumber: operationNumber.optional() });

/** Estados en los que el pasajero puede avisar «ya pagué». */
const REPORTABLE = ['awaiting_payment', 'failed'];

export async function markPaymentSent(deps: PaymentDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw payError('unauthenticated', 'unauthenticated');
  const input = parseInput(sentSchema, data);
  const db = deps.db;
  if (!(await loadPaymentSettings(db)).enabled.includes('manual_qr')) throw payError('failed-precondition', 'method_disabled');
  const at = nowOf(deps);
  const stateRef = paymentStateRef(db, input.bookingId);
  return db.runTransaction(async (tx) => {
    const [stateSnap, booking] = await Promise.all([tx.get(stateRef), tx.get(db.collection('bookings').doc(input.bookingId))]);
    const s = stateSnap.data() as PaymentState | undefined;
    if (!s || !booking.exists) throw payError('not-found', 'booking_not_found');
    if (s.riderId !== uid) throw payError('permission-denied', 'not_owner');
    if (s.paymentStatus === 'paid') return { paymentStatus: s.paymentStatus, alreadyPaid: true };
    if (!REPORTABLE.includes(s.paymentStatus) || booking.data()?.status === 'cancelled') {
      throw payError('failed-precondition', 'not_awaiting_payment', { paymentStatus: s.paymentStatus });
    }
    // Doble toque: ya avisó y central aún no respondió.
    if (s.paymentStatus === 'awaiting_payment' && s.riderReportedAt) {
      return { paymentStatus: s.paymentStatus, alreadyReported: true };
    }
    tx.update(stateRef, {
      paymentStatus: 'awaiting_payment', paymentMethod: 'manual_qr',
      riderReportedAt: at, riderOperationNumber: input.operationNumber ?? null, updatedAt: at,
    });
    tx.set(db.collection('adminAlerts').doc(), {
      type: 'payment_reported', severity: 'high', bookingId: input.bookingId, paymentRef: s.paymentRef,
      amountDue: s.amountDue, operationNumber: input.operationNumber ?? null,
      message: `El pasajero avisa que pagó la reserva (referencia ${s.paymentRef}). Revisa el ingreso y confírmalo o recházalo.`,
      createdAt: at, resolved: false,
    });
    return { paymentStatus: 'awaiting_payment' as const, alreadyReported: false };
  });
}

// ---------------------------------------------------------------------------
// markPaidInTx (común a manual y tarjeta)
// ---------------------------------------------------------------------------

export interface MarkPaid {
  bookingId: string;
  state: PaymentState;
  booking: admin.firestore.DocumentData;
  method: PaymentMethod;
  amount: number;
  externalRef: string;
  actorRole: 'admin' | 'provider';
  at: admin.firestore.Timestamp;
  /** Confirmado después de vencer el plazo (A6): se anota. */
  late: boolean;
}

/**
 * Deja el pago en paid, el asiento del cobro y, si la reserva sigue
 * esperando chófer, su solicitud abierta. Si la reserva ya estaba
 * cancelada, el dinero se devuelve entero (decisión 2): refund_pending.
 * Solo escribe: las lecturas van antes.
 */
export function markPaidInTx(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, p: MarkPaid):
  { paymentStatus: 'paid' | 'refund_pending'; dispatched: boolean } {
  const stateRef = paymentStateRef(db, p.bookingId);
  // Id fijo: el mismo cobro no se asienta dos veces.
  addLedger(tx, db, {
    type: 'charge', bookingId: p.bookingId, riderId: p.state.riderId, amount: p.amount, method: p.method,
    actor: { role: p.actorRole }, externalRef: p.externalRef,
    reason: p.late ? 'payment_confirmed_late' : 'payment_confirmed', status: 'completed', createdAt: p.at,
  }, `charge_${p.bookingId}`);
  const base = {
    paymentMethod: p.method, amountPaid: p.amount, paidAt: p.at, updatedAt: p.at,
    riderReportedAt: null, ...(p.late ? { confirmedLate: true } : {}),
  };
  if (p.booking.status === 'cancelled') {
    // Pagó una reserva que ya no existe: se devuelve todo y central lo ejecuta.
    addLedger(tx, db, {
      type: 'refund', bookingId: p.bookingId, riderId: p.state.riderId, amount: p.amount, method: p.method,
      actor: { role: 'system' }, externalRef: null, reason: 'paid_after_cancellation', status: 'pending', createdAt: p.at,
    }, `refund_${p.bookingId}`);
    tx.update(stateRef, { ...base, paymentStatus: 'refund_pending', amountRetained: 0, refundDue: p.amount });
    tx.set(db.collection('adminAlerts').doc(), {
      type: 'refund_pending', severity: 'high', bookingId: p.bookingId, amount: p.amount,
      message: 'Llegó el pago de una reserva ya cancelada: hay que devolverlo entero al método de pago original.',
      createdAt: p.at, resolved: false,
    });
    return { paymentStatus: 'refund_pending', dispatched: false };
  }
  tx.update(stateRef, { ...base, paymentStatus: 'paid' });
  return { paymentStatus: 'paid', dispatched: openForDrivers(tx, db, p.bookingId, p.booking) };
}

// ---------------------------------------------------------------------------
// adminConfirmPayment / adminRejectPayment
// ---------------------------------------------------------------------------

export const confirmSchema = z.strictObject({
  bookingId: docId,
  operationNumber,
  /** Lo que llegó, en bolivianos con dos decimales; debe ser lo debido. */
  amountReceived: z.number().finite().positive().max(1_000_000),
  reason: reasonSchema,
});

/** Estados desde los que un admin confirma un pago manual. */
const CONFIRMABLE = ['awaiting_payment', 'failed', 'expired'];

export async function adminConfirmPayment(deps: PaymentDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(confirmSchema, data);
  const db = deps.db;
  const provider = providerFor('manual_qr', await loadPaymentSettings(db), deps.providers);
  const at = nowOf(deps);
  const stateRef = paymentStateRef(db, input.bookingId);
  const bookingRef = db.collection('bookings').doc(input.bookingId);
  const opRef = db.collection('paymentOperations').doc(operationKey('manual_qr', input.operationNumber));
  return db.runTransaction(async (tx) => {
    const [stateSnap, booking, op] = await Promise.all([tx.get(stateRef), tx.get(bookingRef), tx.get(opRef)]);
    const alerts = await reportedAlerts(tx, db, input.bookingId);
    const s = stateSnap.data() as PaymentState | undefined;
    if (!s || !booking.exists) throw payError('not-found', 'booking_not_found');
    if (s.paymentStatus === 'paid' || s.amountPaid > 0) throw payError('failed-precondition', 'already_paid');
    if (!CONFIRMABLE.includes(s.paymentStatus)) {
      throw payError('failed-precondition', 'not_awaiting_payment', { paymentStatus: s.paymentStatus });
    }
    if (op.exists) throw payError('failed-precondition', 'operation_already_used');
    const { amount, externalRef } = provider.confirm({
      amountReceived: cents(input.amountReceived), amountDue: s.amountDue, externalRef: input.operationNumber,
    });
    const late = s.paymentStatus === 'expired' ||
      (s.paymentDeadline !== null && s.paymentDeadline.toMillis() < at.toMillis());
    tx.create(opRef, { bookingId: input.bookingId, method: 'manual_qr', createdAt: at });
    const result = markPaidInTx(tx, db, {
      bookingId: input.bookingId, state: s, booking: booking.data()!, method: 'manual_qr', amount,
      externalRef, actorRole: 'admin', at, late,
    });
    alerts.forEach((a) => tx.update(a.ref, { resolved: true, resolvedAt: at, resolvedBy: actor.adminId }));
    notifyRider(tx, db, s.riderId, input.bookingId, at, 'Pago confirmado',
      result.paymentStatus === 'paid'
        ? 'Confirmamos tu pago. Estamos buscando a tu chófer.'
        : 'Confirmamos tu pago, pero la reserva ya estaba cancelada. Central gestionará la devolución.',
      'payment_confirmed');
    writeAudit(tx, db, {
      actor, operation: 'confirm_payment', collection: 'bookings', docId: input.bookingId, targetType: 'payment',
      changes: changedFields({ paymentStatus: s.paymentStatus, amountPaid: s.amountPaid },
        { paymentStatus: result.paymentStatus, amountPaid: amount }),
      reason: input.reason,
      details: `Pago ${s.paymentRef} · operación ${input.operationNumber}${late ? ' · fuera de plazo' : ''}`,
      context: { paymentRef: s.paymentRef, operationNumber: input.operationNumber, amount, late },
    });
    return { paymentStatus: result.paymentStatus, dispatched: result.dispatched, late };
  });
}

export const rejectSchema = z.strictObject({ bookingId: docId, reason: reasonSchema });

export async function adminRejectPayment(deps: PaymentDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(rejectSchema, data);
  const db = deps.db;
  const at = nowOf(deps);
  const stateRef = paymentStateRef(db, input.bookingId);
  return db.runTransaction(async (tx) => {
    const stateSnap = await tx.get(stateRef);
    const alerts = await reportedAlerts(tx, db, input.bookingId);
    const s = stateSnap.data() as PaymentState | undefined;
    if (!s) throw payError('not-found', 'booking_not_found');
    if (s.paymentStatus !== 'awaiting_payment') {
      throw payError('failed-precondition', 'not_awaiting_payment', { paymentStatus: s.paymentStatus });
    }
    tx.update(stateRef, { paymentStatus: 'failed', riderReportedAt: null, rejectedAt: at, updatedAt: at });
    alerts.forEach((a) => tx.update(a.ref, { resolved: true, resolvedAt: at, resolvedBy: actor.adminId }));
    notifyRider(tx, db, s.riderId, input.bookingId, at, 'Pago no confirmado',
      'No pudimos confirmar tu pago. Revisa los datos del pago en la app o contacta con central.', 'payment_rejected');
    writeAudit(tx, db, {
      actor, operation: 'reject_payment', collection: 'bookings', docId: input.bookingId, targetType: 'payment',
      changes: changedFields({ paymentStatus: s.paymentStatus }, { paymentStatus: 'failed' }),
      reason: input.reason, details: `Pago ${s.paymentRef} rechazado`,
      context: { paymentRef: s.paymentRef, riderOperationNumber: s.riderOperationNumber ?? null },
    });
    return { paymentStatus: 'failed' as const };
  });
}
