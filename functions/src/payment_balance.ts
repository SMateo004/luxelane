/**
 * Cobro de un saldo pendiente (G2): el importe final del viaje superó lo
 * pagado (A9) y el pasajero paga la diferencia fuera del sistema (QR,
 * transferencia o tarjeta del proveedor). Central lo registra:
 *
 * - solo admin con segundo factor, con motivo y número de operación;
 * - el importe es el saldo o menos (cobro parcial), nunca más;
 * - un número de operación vale una sola vez (compartido con
 *   adminConfirmPayment). El mismo envío repetido (misma reserva e importe)
 *   devuelve lo mismo sin cobrar dos veces;
 * - en la misma transacción: asiento charge completado, estado del pago
 *   (amountPaid sube, balanceDue baja), asiento pendiente balance_{id}
 *   reducido o borrado, alertas balance_due resueltas al saldarlo y
 *   auditoría.
 *
 * Así, si el importe final cambia después, A9 vuelve a calcular la
 * diferencia contra lo ya cobrado sin contar nada dos veces.
 */
import { z } from 'zod';
import { AdminActor, changedFields, reasonSchema, writeAudit } from './admin_audit';
import { nowOf, operationKey, payError, PaymentDeps } from './payment_manual';
import { addLedger, cents, CURRENCY, LedgerEntry, PAYMENT_METHODS, PaymentState, paymentStateRef } from './payment_model';
import { docId, parseInput } from './schemas';

export const collectBalanceSchema = z.strictObject({
  bookingId: docId,
  /** En bolivianos con dos decimales: el saldo pendiente o menos. */
  amount: z.number().finite().positive().max(1_000_000),
  /** Número de operación del banco o referencia del proveedor. */
  operationNumber: z.string().trim().min(1).max(40).regex(/^[A-Za-z0-9 ._/-]+$/),
  method: z.enum(PAYMENT_METHODS),
  reason: reasonSchema,
});

export async function adminCollectBalance(deps: PaymentDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(collectBalanceSchema, data);
  const db = deps.db;
  const at = nowOf(deps);
  const amount = cents(input.amount);
  const key = operationKey(input.method, input.operationNumber);
  const stateRef = paymentStateRef(db, input.bookingId);
  const opRef = db.collection('paymentOperations').doc(key);
  const balanceRef = db.collection('payments').doc(`balance_${input.bookingId}`);
  const entryId = `collect_${key}`;
  return db.runTransaction(async (tx) => {
    const [stateSnap, op, balance, alerts] = await Promise.all([
      tx.get(stateRef), tx.get(opRef), tx.get(balanceRef),
      tx.get(db.collection('adminAlerts').where('bookingId', '==', input.bookingId)
        .where('type', '==', 'balance_due').where('resolved', '==', false)),
    ]);
    const s = stateSnap.data() as PaymentState | undefined;
    if (!s) throw payError('not-found', 'booking_not_found');
    if (op.exists) {
      const o = op.data()!;
      // Doble envío: la misma operación ya registró este cobro.
      if (o.kind === 'balance' && o.bookingId === input.bookingId && o.amount === amount) {
        return { alreadyRecorded: true, collected: amount, balanceDue: Number(s.balanceDue ?? 0) };
      }
      throw payError('failed-precondition', 'operation_already_used');
    }
    const due = Number(s.balanceDue ?? 0);
    if (due <= 0) throw payError('failed-precondition', 'no_balance_due');
    if (amount > due) throw payError('failed-precondition', 'amount_exceeds_balance', { balanceDue: due });

    const left = due - amount;
    tx.create(opRef, { bookingId: input.bookingId, method: input.method, kind: 'balance', amount, createdAt: at });
    addLedger(tx, db, {
      type: 'charge', bookingId: input.bookingId, riderId: s.riderId, amount, method: input.method,
      actor: { role: 'admin' }, externalRef: input.operationNumber, reason: 'balance_collected', status: 'completed',
      createdAt: at,
    }, entryId);
    const pending = balance.data() as LedgerEntry | undefined;
    if (pending?.status === 'pending') {
      if (left > 0) tx.update(balanceRef, { amount: left });
      else tx.delete(balanceRef);
    }
    tx.update(stateRef, { amountPaid: s.amountPaid + amount, balanceDue: left, updatedAt: at });
    if (left === 0) {
      alerts.docs.forEach((a) => tx.update(a.ref, { resolved: true, resolvedAt: at, resolvedBy: actor.adminId }));
    }
    writeAudit(tx, db, {
      actor, operation: 'collect_balance', collection: 'payments', docId: entryId, targetType: 'payment',
      changes: changedFields({ balanceDue: due, amountPaid: s.amountPaid },
        { balanceDue: left, amountPaid: s.amountPaid + amount }),
      reason: input.reason,
      details: `Saldo cobrado: ${(amount / 100).toFixed(2)} ${CURRENCY} · op. ${input.operationNumber}`,
      context: { bookingId: input.bookingId, method: input.method, amount, balanceLeft: left },
    });
    return { alreadyRecorded: false, collected: amount, balanceDue: left };
  });
}
