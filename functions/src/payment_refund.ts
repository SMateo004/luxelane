/**
 * Reembolsos (A8). Siempre al método de pago original; no hay saldo a favor
 * ni billetera (decisión 4).
 *
 * - Manual (QR o transferencia): central devuelve el dinero fuera del
 *   sistema y lo anota con adminRecordRefund (admin con 2FA, motivo y
 *   referencia externa). Cierra el asiento refund pendiente.
 * - Tarjeta: el reembolso lo pide el servidor al proveedor por la interfaz,
 *   con una clave de idempotencia fija por asiento; lo dispara el paso del
 *   pago a refund_pending (refundOnRefundPending) y el admin puede
 *   reintentarlo con adminRecordRefund.
 *
 * Un reembolso nunca supera lo cobrado menos lo retenido menos lo ya
 * devuelto; un asiento ya cerrado no se cierra dos veces.
 */
import * as admin from 'firebase-admin';
import { z } from 'zod';
import { AdminActor, changedFields, reasonSchema, writeAudit } from './admin_audit';
import { loadPaymentSettings } from './payment_config';
import { notifyRider, nowOf, payError, PaymentDeps } from './payment_manual';
import { CURRENCY, LedgerEntry, PaymentState, paymentStateRef } from './payment_model';
import { providerFor } from './payment_provider';
import { docId, parseInput } from './schemas';
import { logger } from './logger';

export const refundSchema = z.strictObject({
  bookingId: docId,
  /** Asiento a cerrar; por defecto el de la cancelación (refund_{bookingId}). */
  entryId: docId.optional(),
  /** Referencia de la devolución (número de operación del banco). Obligatoria en el manual. */
  externalRef: z.string().trim().min(1).max(60).regex(/^[A-Za-z0-9 ._/-]+$/).optional(),
  reason: reasonSchema,
});

interface CloseInput {
  bookingId: string;
  entryId: string;
  externalRef: string;
  actor: AdminActor | null;
  reason: string | null;
}

/** Cierra un asiento refund pendiente y actualiza el estado del pago. */
async function closeRefund(deps: PaymentDeps, c: CloseInput) {
  const db = deps.db;
  const at = nowOf(deps);
  const entryRef = db.collection('payments').doc(c.entryId);
  const stateRef = paymentStateRef(db, c.bookingId);
  return db.runTransaction(async (tx) => {
    const [entrySnap, stateSnap, alerts] = await Promise.all([
      tx.get(entryRef), tx.get(stateRef),
      tx.get(db.collection('adminAlerts').where('bookingId', '==', c.bookingId)
        .where('type', '==', 'refund_pending').where('resolved', '==', false)),
    ]);
    const e = entrySnap.data() as LedgerEntry | undefined;
    const s = stateSnap.data() as PaymentState | undefined;
    if (!e || !s || e.type !== 'refund' || e.bookingId !== c.bookingId) throw payError('not-found', 'refund_not_found');
    if (e.status === 'completed') throw payError('failed-precondition', 'already_refunded');
    const refunded = Number(s.amountRefunded ?? 0);
    const available = s.amountPaid - Number(s.amountRetained ?? 0) - refunded;
    if (e.amount > available) throw payError('failed-precondition', 'refund_exceeds_paid', { available });
    const nowRefunded = refunded + e.amount;
    const pendingLeft = Math.max(0, Number(s.refundDue ?? 0) - e.amount);
    const status = pendingLeft > 0
      ? 'refund_pending'
      : nowRefunded >= s.amountPaid ? 'refunded' : 'partially_refunded';
    tx.update(entryRef, { status: 'completed', externalRef: c.externalRef, completedAt: at });
    tx.update(stateRef, { paymentStatus: status, amountRefunded: nowRefunded, refundDue: pendingLeft, updatedAt: at });
    if (pendingLeft === 0) alerts.docs.forEach((a) => tx.update(a.ref, { resolved: true, resolvedAt: at, resolvedBy: c.actor?.adminId ?? 'system' }));
    // Solo ahora, con la devolución registrada, se le dice al pasajero.
    notifyRider(tx, db, s.riderId, c.bookingId, at, 'Devolución registrada',
      'Te devolvemos el dinero al método con el que pagaste.', 'refund_recorded');
    if (c.actor) {
      writeAudit(tx, db, {
        actor: c.actor, operation: 'record_refund', collection: 'payments', docId: c.entryId, targetType: 'payment',
        changes: changedFields({ status: e.status, externalRef: e.externalRef }, { status: 'completed', externalRef: c.externalRef }),
        reason: c.reason, details: `Devolución de ${(e.amount / 100).toFixed(2)} ${CURRENCY} · ref. ${c.externalRef}`,
        context: { bookingId: c.bookingId, amount: e.amount, method: e.method },
      });
    }
    return { paymentStatus: status, amount: e.amount };
  });
}

/**
 * Reembolso con tarjeta por el proveedor. La clave de idempotencia es fija
 * por asiento: dos intentos no devuelven dos veces.
 */
export async function refundByProvider(deps: PaymentDeps, bookingId: string, entryId: string,
  actor: AdminActor | null = null, reason: string | null = null) {
  const db = deps.db;
  const [entrySnap, stateSnap] = await Promise.all([
    db.collection('payments').doc(entryId).get(), paymentStateRef(db, bookingId).get(),
  ]);
  const e = entrySnap.data() as LedgerEntry | undefined;
  const s = stateSnap.data() as (PaymentState & { providerChargeRef?: string | null }) | undefined;
  if (!e || !s || e.type !== 'refund') throw payError('not-found', 'refund_not_found');
  if (e.status === 'completed') throw payError('failed-precondition', 'already_refunded');
  if (e.method !== 'card') throw payError('failed-precondition', 'manual_refund');
  const provider = providerFor('card', await loadPaymentSettings(db), deps.providers);
  let result;
  try {
    result = await provider.refund({
      bookingId, amount: e.amount, currency: CURRENCY, chargeRef: s.providerChargeRef ?? null,
      idempotencyKey: `refund:${entryId}`,
    });
  } catch (err) {
    logger.error('refundByProvider', 'failed', { bookingId, error: String(err) });
    await db.collection('adminAlerts').add({
      type: 'refund_failed', severity: 'high', bookingId, amount: e.amount,
      message: 'El proveedor no pudo hacer la devolución con tarjeta. Revisa y reinténtala desde el panel.',
      createdAt: nowOf(deps), resolved: false,
    });
    throw payError('failed-precondition', 'provider_refund_failed');
  }
  if (result.status !== 'succeeded') throw payError('failed-precondition', 'provider_refund_failed');
  return closeRefund(deps, { bookingId, entryId, externalRef: result.externalRef, actor, reason });
}

/** adminRecordRefund: manual con referencia; tarjeta, por el proveedor. */
export async function adminRecordRefund(deps: PaymentDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(refundSchema, data);
  const entryId = input.entryId ?? `refund_${input.bookingId}`;
  const entry = (await deps.db.collection('payments').doc(entryId).get()).data() as LedgerEntry | undefined;
  if (entry?.method === 'card') return refundByProvider(deps, input.bookingId, entryId, actor, input.reason);
  if (!input.externalRef) throw payError('invalid-argument', 'invalid_request', { fields: ['externalRef'] });
  return closeRefund(deps, { bookingId: input.bookingId, entryId, externalRef: input.externalRef, actor, reason: input.reason });
}

/** Con tarjeta, la devolución se pide sola al pasar a refund_pending. */
export async function onRefundPending(deps: PaymentDeps, bookingId: string,
  before: admin.firestore.DocumentData | undefined, after: admin.firestore.DocumentData | undefined) {
  if (after?.paymentStatus !== 'refund_pending' || before?.paymentStatus === 'refund_pending') return null;
  if (after.paymentMethod !== 'card') return null;
  try {
    return await refundByProvider(deps, bookingId, `refund_${bookingId}`);
  } catch {
    // Ya avisado en adminAlerts (refund_failed) o ya cerrado.
    return null;
  }
}
