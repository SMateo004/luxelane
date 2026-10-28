/**
 * Diferencia entre el importe final y lo pagado (A9, A10). Al completarse el
 * viaje (o si cambia su importe final después), si no coincide con lo
 * pagado neto (pagado menos devuelto):
 *
 * - debe más: saldo pendiente (balanceDue y asiento charge pendiente) y
 *   alerta para central;
 * - pagó de más: devolución pendiente (refundDue y asiento refund
 *   pendiente) y alerta.
 *
 * Nada se cobra ni se devuelve solo: lo gestiona central (adminCollectBalance
 * y adminRecordRefund). La liquidación al chófer usa el importe final
 * (settleBooking no cambia). El servicio por horas paga por adelantado la
 * estimación y su diferencia va por aquí (A10).
 *
 * El libro es de solo anexado (H4): si la diferencia cambia, el asiento
 * pendiente anterior se cierra como superseded y se crea otro (balance_{id},
 * balance_{id}_2…); el estado del pago apunta al vigente. Si central ya
 * cobró parte del saldo o devolvió la diferencia, no se rehace nada: solo
 * se avisa si el importe final cambia después.
 */
import * as admin from 'firebase-admin';
import { addLedger, cents, closePending, LedgerEntry, PaymentState, paymentStateRef, seriesId } from './payment_model';

export async function reconcileFinalAmount(db: admin.firestore.Firestore, bookingId: string,
  now: () => number = Date.now): Promise<{ diff: number; action: 'none' | 'balance_due' | 'refund_due' | 'locked' | 'skipped' }> {
  const bookingRef = db.collection('bookings').doc(bookingId);
  const stateRef = paymentStateRef(db, bookingId);
  return db.runTransaction(async (tx) => {
    const [booking, stateSnap] = await Promise.all([tx.get(bookingRef), tx.get(stateRef)]);
    const b = booking.data();
    const s = stateSnap.data() as PaymentState | undefined;
    // Sin estado de pago (reservas antiguas) o sin cobro: nada que comparar.
    if (!b || b.status !== 'completed' || !s || s.amountPaid <= 0) return { diff: 0, action: 'skipped' as const };
    const balanceRef = db.collection('payments').doc(s.balanceEntryId ?? seriesId('balance', bookingId, 1));
    const refundRef = db.collection('payments').doc(s.refundFinalEntryId ?? seriesId('refund_final', bookingId, 1));
    const [balance, refund] = await Promise.all([tx.get(balanceRef), tx.get(refundRef)]);
    const at = admin.firestore.Timestamp.fromMillis(now());
    const finalCents = cents(Number(b.finalPrice ?? b.estimatedPrice ?? 0));
    const diff = finalCents - (s.amountPaid - Number(s.amountRefunded ?? 0));
    const prevBalance = balance.data() as LedgerEntry | undefined;
    const prevRefund = refund.data() as LedgerEntry | undefined;
    const pendingBalance = prevBalance?.status === 'pending' ? prevBalance.amount : 0;
    const pendingRefund = prevRefund?.status === 'pending' ? prevRefund.amount : 0;

    // Lo ya ejecutado no se rehace: central decide.
    if (Number(s.balanceCollected ?? 0) > 0 || prevRefund?.status === 'completed') {
      if (diff !== pendingBalance - pendingRefund) {
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
    const update: Record<string, unknown> = { updatedAt: at };
    // Devolución por otros motivos (cancelación) que no es de esta serie.
    const otherRefundDue = Math.max(0, Number(s.refundDue ?? 0) - pendingRefund);
    const wantBalance = diff > 0 ? diff : 0;
    const wantRefund = diff < 0 ? -diff : 0;

    if (pendingBalance !== wantBalance) {
      let newId: string | null = null;
      if (wantBalance > 0) {
        const n = Number(s.balanceSeq ?? (prevBalance ? 1 : 0)) + 1;
        newId = seriesId('balance', bookingId, n);
        addLedger(tx, db, { ...base, type: 'charge', amount: wantBalance, reason: 'final_amount_above_paid' }, newId);
        update.balanceSeq = n;
      }
      if (pendingBalance > 0) closePending(tx, balanceRef, { status: 'superseded', closedBy: newId ? [newId] : [], at });
      update.balanceEntryId = newId;
    }
    if (pendingRefund !== wantRefund) {
      let newId: string | null = null;
      if (wantRefund > 0) {
        const n = Number(s.refundFinalSeq ?? (prevRefund ? 1 : 0)) + 1;
        newId = seriesId('refund_final', bookingId, n);
        addLedger(tx, db, { ...base, type: 'refund', amount: wantRefund, reason: 'final_amount_below_paid' }, newId);
        update.refundFinalSeq = n;
      }
      if (pendingRefund > 0) closePending(tx, refundRef, { status: 'superseded', closedBy: newId ? [newId] : [], at });
      update.refundFinalEntryId = newId;
    }
    update.balanceDue = wantBalance;
    update.refundDue = otherRefundDue + wantRefund;
    if (wantRefund > 0) update.paymentStatus = 'refund_pending';
    else if (pendingRefund > 0 && otherRefundDue === 0 && s.paymentStatus === 'refund_pending') update.paymentStatus = 'paid';
    tx.update(stateRef, update);

    if (diff === 0) return { diff, action: 'none' as const };
    const changed = diff > 0 ? pendingBalance !== wantBalance : pendingRefund !== wantRefund;
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
