/**
 * Empezar a pagar y cobro con tarjeta (A5).
 *
 * - startPayment: el pasajero dueño elige método. Manual: devuelve las
 *   instrucciones de config/ops, el importe exacto, la referencia y el
 *   plazo. Tarjeta: crea el cobro en el proveedor con el importe del
 *   servidor y una clave de idempotencia por intento (un reintento del mismo
 *   intento no cobra dos veces).
 * - handlePaymentWebhook: el proveedor avisa del resultado. La firma se
 *   verifica a través de la interfaz; un cobro que llega con otro importe no
 *   confirma nada y avisa a central. El cobro al pedir chófer es el cargo:
 *   no hay captura posterior.
 */
import { z } from 'zod';
import { loadPaymentSettings } from './payment_config';
import { markPaidInTx, nowOf, payError, PaymentDeps } from './payment_manual';
import { CURRENCY, PAYMENT_METHODS, PaymentState, paymentStateRef } from './payment_model';
import { providerFor, WebhookEvent } from './payment_provider';
import { logger } from './logger';
import { docId, parseInput } from './schemas';

export const startSchema = z.strictObject({ bookingId: docId, method: z.enum(PAYMENT_METHODS) });

/** Estados desde los que se puede (volver a) intentar pagar. */
const PAYABLE = ['awaiting_payment', 'failed'];

export async function startPayment(deps: PaymentDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw payError('unauthenticated', 'unauthenticated');
  const input = parseInput(startSchema, data);
  const db = deps.db;
  const provider = providerFor(input.method, await loadPaymentSettings(db), deps.providers);
  const at = nowOf(deps);
  const stateRef = paymentStateRef(db, input.bookingId);

  // 1) Reserva el intento en una transacción (y valida dueño y estado).
  const attempt = await db.runTransaction(async (tx) => {
    const [snap, booking] = await Promise.all([tx.get(stateRef), tx.get(db.collection('bookings').doc(input.bookingId))]);
    const s = snap.data() as (PaymentState & { cardAttempt?: number; providerChargeRef?: string | null }) | undefined;
    if (!s || !booking.exists) throw payError('not-found', 'booking_not_found');
    if (s.riderId !== uid) throw payError('permission-denied', 'not_owner');
    if (s.paymentStatus === 'paid') throw payError('failed-precondition', 'already_paid');
    if (!PAYABLE.includes(s.paymentStatus) || booking.data()?.status === 'cancelled') {
      throw payError('failed-precondition', 'not_awaiting_payment', { paymentStatus: s.paymentStatus });
    }
    // Tras un fallo, intento nuevo; si no, el mismo (misma clave, sin doble cargo).
    const n = (s.cardAttempt ?? 0) + (input.method === 'card' && s.paymentStatus === 'failed' ? 1 : 0);
    tx.update(stateRef, {
      paymentMethod: input.method, paymentStatus: 'awaiting_payment', updatedAt: at,
      ...(input.method === 'card' ? { cardAttempt: n } : {}),
    });
    return { state: s, n };
  });
  const s = attempt.state;

  // 2) Pide el cobro al proveedor fuera de la transacción (red).
  const start = await provider.createCharge({
    bookingId: input.bookingId, riderId: s.riderId, amount: s.amountDue, currency: CURRENCY,
    paymentRef: s.paymentRef, idempotencyKey: `charge:${input.bookingId}:${attempt.n}`,
  });
  if (start.kind === 'client_secret') {
    await stateRef.update({ providerChargeRef: start.externalRef, updatedAt: at });
  }
  const common = {
    method: input.method, amountDue: s.amountDue, currency: CURRENCY, paymentRef: s.paymentRef,
    paymentDeadline: s.paymentDeadline ? s.paymentDeadline.toMillis() : null,
  };
  return start.kind === 'manual'
    ? { ...common, instructions: start.instructions }
    : { ...common, clientSecret: start.clientSecret };
}

/**
 * Evento del proveedor de tarjeta ya verificado. Idempotente: el mismo
 * evento dos veces no cambia nada la segunda.
 */
export async function applyWebhookEvent(deps: PaymentDeps, e: WebhookEvent) {
  const db = deps.db;
  const at = nowOf(deps);
  const stateRef = paymentStateRef(db, e.bookingId);
  const bookingRef = db.collection('bookings').doc(e.bookingId);
  return db.runTransaction(async (tx) => {
    const [snap, booking] = await Promise.all([tx.get(stateRef), tx.get(bookingRef)]);
    const s = snap.data() as (PaymentState & { providerChargeRef?: string | null }) | undefined;
    if (!s || !booking.exists) return { applied: false, reason: 'unknown_booking' };
    // Solo el cobro que esta reserva pidió; nunca uno ajeno.
    if (s.paymentMethod !== 'card' || s.providerChargeRef !== e.externalRef) {
      return { applied: false, reason: 'unknown_charge' };
    }
    if (s.paymentStatus === 'paid' || s.amountPaid > 0) return { applied: false, reason: 'already_paid' };
    if (e.type === 'charge.failed') {
      tx.update(stateRef, { paymentStatus: 'failed', updatedAt: at });
      return { applied: true, paymentStatus: 'failed' };
    }
    if (e.amount !== s.amountDue) {
      tx.set(db.collection('adminAlerts').doc(), {
        type: 'payment_amount_mismatch', severity: 'high', bookingId: e.bookingId, amount: e.amount,
        amountDue: s.amountDue,
        message: 'El proveedor cobró un importe distinto del debido: no se confirmó el pago. Revisa y devuelve si hace falta.',
        createdAt: at, resolved: false,
      });
      return { applied: false, reason: 'amount_mismatch' };
    }
    const late = s.paymentStatus === 'expired' ||
      (s.paymentDeadline !== null && s.paymentDeadline.toMillis() < at.toMillis());
    const r = markPaidInTx(tx, db, {
      bookingId: e.bookingId, state: s, booking: booking.data()!, method: 'card', amount: e.amount,
      externalRef: e.externalRef, actorRole: 'provider', at, late,
    });
    return { applied: true, paymentStatus: r.paymentStatus };
  });
}

/** Entrada del webhook: verifica la firma con el proveedor de tarjeta activo. */
export async function handlePaymentWebhook(deps: PaymentDeps, rawBody: Buffer, signature: string | undefined):
  Promise<{ status: number; body: Record<string, unknown> }> {
  let provider;
  try {
    provider = providerFor('card', await loadPaymentSettings(deps.db), deps.providers);
  } catch {
    return { status: 404, body: { error: 'method_disabled' } };
  }
  let event: WebhookEvent;
  try {
    if (!provider.verifyWebhook) throw new Error('no_webhook');
    event = provider.verifyWebhook(rawBody, signature);
  } catch (e) {
    logger.warn('paymentWebhook', 'rejected', { error: String((e as Error).message ?? e) });
    return { status: 400, body: { error: 'invalid_signature' } };
  }
  const r = await applyWebhookEvent(deps, event);
  return { status: 200, body: r };
}
