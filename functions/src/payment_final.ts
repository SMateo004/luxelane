/**
 * Diferencia entre el importe final y lo pagado (A9, A10). Al completarse el
 * viaje (o si cambia su importe final después), si no coincide con lo
 * pagado:
 *
 * - debe más: saldo pendiente (balanceDue y asiento charge pendiente
 *   balance_{id}) y alerta para central;
 * - pagó de más: devolución pendiente (refundDue y asiento refund pendiente
 *   refund_final_{id}) y alerta.
 *
 * Nada se cobra ni se devuelve solo: lo gestiona central (adminRecordRefund
 * para la devolución). La liquidación al chófer usa el importe final
 * (settleBooking no cambia). El servicio por horas paga por adelantado la
 * estimación y su diferencia va por aquí (A10).
 */
import * as admin from 'firebase-admin';
import { addLedger, cents, LedgerEntry, PaymentState, paymentStateRef } from './payment_model';

export async function reconcileFinalAmount(db: admin.firestore.Firestore, bookingId: string,
  now: () => number = Date.now): Promise<{ diff: number; action: 'none' | 'balance_due' | 'refund_due' | 'locked' | 'skipped' }> {
  const bookingRef = db.collection('bookings').doc(bookingId);
  const stateRef = paymentStateRef(db, bookingId);
  const balanceRef = db.collection('payments').doc(`balance_${bookingId}`);
  const refundRef = db.collection('payments').doc(`refund_final_${bookingId}`);
  return db.runTransaction(async (tx) => {
    const [booking, stateSnap, balance, refund] = await Promise.all([
      tx.get(bookingRef), tx.get(stateRef), tx.get(balanceRef), tx.get(refundRef),
    ]);
    const b = booking.data();
    const s = stateSnap.data() as PaymentState | undefined;
    // Sin estado de pago (reservas antiguas) o sin cobro: nada que comparar.
    if (!b || b.status !== 'completed' || !s || s.amountPaid <= 0) return { diff: 0, action: 'skipped' as const };
    const at = admin.firestore.Timestamp.fromMillis(now());
    const finalCents = cents(Number(b.finalPrice ?? b.estimatedPrice ?? 0));
    const diff = finalCents - s.amountPaid;
    const prevBalance = balance.data() as LedgerEntry | undefined;
    const prevRefund = refund.data() as LedgerEntry | undefined;
    // Lo ya ejecutado no se rehace: central decide.
    if (prevBalance?.status === 'completed' || prevRefund?.status === 'completed') {
      if ((diff > 0 ? diff : 0) !== (prevBalance?.amount ?? 0) || (diff < 0 ? -diff : 0) !== (prevRefund?.amount ?? 0)) {
        tx.set(db.collection('adminAlerts').doc(), {
          type: 'final_amount_changed_after_settlement', severity: 'high', bookingId, diff,
          message: 'El importe final cambió después de cobrar o devolver la diferencia: revísalo.',
          createdAt: at, resolved: false,
        });
      }
      return { diff, action: 'locked' as const };
    }
    const base = { bookingId, riderId: s.riderId, method: s.paymentMethod, actor: { role: 'system' as const },
      externalRef: null, status: 'pending' as const, createdAt: at };
    const prevRefundDue = Number(s.refundDue ?? 0) - (prevRefund?.amount ?? 0);
    if (prevBalance && diff <= 0) tx.delete(balanceRef);
    if (prevRefund && diff >= 0) tx.delete(refundRef);
    if (diff > 0) {
      if (prevBalance?.amount !== diff) addLedger(tx, db, { ...base, type: 'charge', amount: diff, reason: 'final_amount_above_paid' }, balanceRef.id);
      tx.update(stateRef, { balanceDue: diff, refundDue: Math.max(0, prevRefundDue), updatedAt: at });
    } else if (diff < 0) {
      if (prevRefund?.amount !== -diff) addLedger(tx, db, { ...base, type: 'refund', amount: -diff, reason: 'final_amount_below_paid' }, refundRef.id);
      tx.update(stateRef, {
        balanceDue: 0, refundDue: Math.max(0, prevRefundDue) - diff, paymentStatus: 'refund_pending', updatedAt: at,
      });
    } else {
      tx.update(stateRef, { balanceDue: 0, refundDue: Math.max(0, prevRefundDue), updatedAt: at });
      return { diff, action: 'none' as const };
    }
    const changed = diff > 0 ? prevBalance?.amount !== diff : prevRefund?.amount !== -diff;
    if (changed) {
      tx.set(db.collection('adminAlerts').doc(), {
        type: diff > 0 ? 'balance_due' : 'refund_pending', severity: 'medium', bookingId, amount: Math.abs(diff),
        message: diff > 0
          ? 'El importe final supera lo pagado: queda un saldo pendiente del pasajero (no se cobra solo).'
          : 'El importe final es menor que lo pagado: hay que devolver la diferencia (no se devuelve sola).',
        createdAt: at, resolved: false,
      });
    }
    return { diff, action: diff > 0 ? 'balance_due' as const : 'refund_due' as const };
  });
}
