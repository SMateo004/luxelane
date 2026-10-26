/**
 * Cierre del pago de una reserva cancelada (A7). Lo usan todas las formas de
 * cancelar: el pasajero (cancelBooking), el admin (adminUpdateBooking), el
 * sistema (sin chófer a tiempo) y el vencimiento (A6, sin pago).
 *
 * - Sin pagar: el pago queda en expired (nunca hubo dinero).
 * - Pagada: asientos fee_retained (si se retiene algo) y refund pendiente
 *   (si hay algo que devolver), y el pago en refund_pending, o refunded si
 *   no hay nada que devolver. El reembolso lo ejecuta A8 (manual o por el
 *   proveedor). Los importes no van en la reserva: el chófer la lee.
 */
import * as admin from 'firebase-admin';
import { CancelCause, RetentionBasis, retainedCents, retentionFor, CancellationPolicy, PolicyState } from './cancellation_policy';
import { addLedger, PaymentState, paymentStateRef } from './payment_model';

export interface SettleResult {
  /** null: reserva sin estado de pago (anterior a pagos). */
  paymentStatus: string | null;
  retained: number;
  refund: number;
  percent: number;
  basis: RetentionBasis | 'not_paid' | 'no_payment_state';
}

/** Lecturas que necesita el cierre (van antes de cualquier escritura). */
export async function readForSettle(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  bookingId: string, status: string): Promise<{ state: PaymentState | null; stageEnteredMs: number | null;
    stateRef: admin.firestore.DocumentReference }> {
  const stateRef = paymentStateRef(db, bookingId);
  const [snap, events] = await Promise.all([
    tx.get(stateRef),
    tx.get(db.collection('bookings').doc(bookingId).collection('events').where('to', '==', status)),
  ]);
  // Entrada en la etapa: el último evento que llevó a este estado. Las
  // aceptaciones antiguas no dejaban evento: entonces null (gracia a favor
  // del cliente).
  let entered: number | null = null;
  for (const e of events.docs) {
    const at = (e.data().at as admin.firestore.Timestamp | undefined)?.toMillis();
    if (at !== undefined && (entered === null || at > entered)) entered = at;
  }
  return { state: (snap.data() as PaymentState | undefined) ?? null, stageEnteredMs: entered, stateRef };
}

export interface SettleInput {
  bookingId: string;
  status: string;
  cause: CancelCause;
  policy: CancellationPolicy | null;
  policyState: PolicyState;
  read: Awaited<ReturnType<typeof readForSettle>>;
  at: admin.firestore.Timestamp;
}

/** Retención y devolución que corresponden ahora (sin escribir). */
export function computeCancelSettle(i: SettleInput): SettleResult {
  const s = i.read.state;
  if (!s) return { paymentStatus: null, retained: 0, refund: 0, percent: 0, basis: 'no_payment_state' };
  if (s.paymentStatus !== 'paid') {
    return { paymentStatus: s.paymentStatus, retained: 0, refund: 0, percent: 0, basis: 'not_paid' };
  }
  const { percent, basis } = retentionFor(i.policy, i.policyState, {
    status: i.status, cause: i.cause, stageEnteredMs: i.read.stageEnteredMs, now: i.at.toMillis(),
  });
  const retained = retainedCents(s.amountPaid, percent);
  const refund = s.amountPaid - retained;
  return { paymentStatus: refund > 0 ? 'refund_pending' : 'refunded', retained, refund, percent, basis };
}

/** Escribe el cierre calculado por computeCancelSettle. */
export function writeCancelSettle(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, i: SettleInput,
  r: SettleResult): void {
  const s = i.read.state;
  if (!s) return;
  if (s.paymentStatus === 'awaiting_payment' || s.paymentStatus === 'failed') {
    // Nunca hubo dinero: el pedido de pago deja de valer.
    tx.update(i.read.stateRef, { paymentStatus: 'expired', closedReason: 'cancelled_before_payment', updatedAt: i.at });
    return;
  }
  if (s.paymentStatus !== 'paid') return;
  const base = { bookingId: i.bookingId, riderId: s.riderId, method: s.paymentMethod, createdAt: i.at };
  if (r.retained > 0) {
    addLedger(tx, db, {
      ...base, type: 'fee_retained', amount: r.retained, actor: { role: 'system' }, externalRef: null,
      reason: `cancellation_${r.basis}_${r.percent}`, status: 'completed',
    }, `fee_${i.bookingId}`);
  }
  if (r.refund > 0) {
    addLedger(tx, db, {
      ...base, type: 'refund', amount: r.refund, actor: { role: 'system' }, externalRef: null,
      reason: `cancellation_${i.cause}`, status: 'pending',
    }, `refund_${i.bookingId}`);
    tx.set(db.collection('adminAlerts').doc(), {
      type: 'refund_pending', severity: 'high', bookingId: i.bookingId, amount: r.refund, method: s.paymentMethod,
      message: 'Reserva cancelada con pago: hay que devolver el importe al método de pago original.',
      createdAt: i.at, resolved: false,
    });
  }
  tx.update(i.read.stateRef, {
    paymentStatus: r.paymentStatus, amountRetained: r.retained, refundDue: r.refund, amountRefunded: 0,
    retentionPercent: r.percent, retentionBasis: r.basis, cancelCause: i.cause, updatedAt: i.at,
  });
}
