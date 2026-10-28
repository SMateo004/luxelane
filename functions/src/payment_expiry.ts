/**
 * Vencimiento del plazo para pagar (A6). Una función programada pasa las
 * reservas en awaiting_payment con el plazo vencido a expired y cancela la
 * reserva sin retención (no se cobró nada).
 *
 * - Sin config/ops.paymentWindowMinutes no hace nada: no hay vencimiento
 *   automático y central ve las reservas en la bandeja de impagos (A11).
 * - Si el pasajero ya avisó «ya pagué», no vence: el dinero puede haber
 *   llegado y decide central (confirmar o rechazar).
 * - Un pago confirmado después (adminConfirmPayment o el proveedor) se trata
 *   en markPaidInTx: si la recogida aún no pasó, la reserva vuelve a buscar
 *   chófer; si pasó, se devuelve todo. En ambos casos queda anotado.
 */
import { loadPaymentSettings } from './payment_config';
import { notifyRider, nowOf, PaymentDeps } from './payment_manual';
import { PaymentState, paymentStateRef } from './payment_model';
import { appendEvent } from './trip_flow';

export async function expirePayments(deps: PaymentDeps): Promise<{ expired: string[]; skipped?: 'no_window' }> {
  const db = deps.db;
  if ((await loadPaymentSettings(db)).windowMinutes === null) return { expired: [], skipped: 'no_window' };
  const at = nowOf(deps);
  const due = await db.collectionGroup('payment')
    .where('paymentStatus', '==', 'awaiting_payment')
    .where('paymentDeadline', '<=', at)
    .limit(200)
    .get();

  const expired: string[] = [];
  for (const d of due.docs) {
    const bookingId = d.ref.parent.parent?.id;
    if (!bookingId || d.id !== 'state') continue;
    const done = await db.runTransaction(async (tx) => {
      const bookingRef = db.collection('bookings').doc(bookingId);
      const [snap, booking] = await Promise.all([tx.get(paymentStateRef(db, bookingId)), tx.get(bookingRef)]);
      const s = snap.data() as PaymentState | undefined;
      // Revalidado dentro de la transacción: pudo pagarse o avisarse mientras.
      if (!s || s.paymentStatus !== 'awaiting_payment' || !s.paymentDeadline ||
        s.paymentDeadline.toMillis() > at.toMillis() || s.riderReportedAt) return false;
      tx.update(snap.ref, { paymentStatus: 'expired', expiredAt: at, updatedAt: at });
      const b = booking.data();
      if (b && b.status === 'pending' && !b.driverId) {
        tx.update(bookingRef, {
          status: 'cancelled', cancelledBy: 'system', cancelledAt: at, cancellationReason: 'payment_expired',
          updatedAt: at,
        });
        tx.delete(db.collection('openRequests').doc(bookingId));
        appendEvent(tx, db, bookingId, {
          from: 'pending', to: 'cancelled', actor: { uid: 'system', role: 'system' }, source: 'system',
          extra: { method: 'payment_expired' },
        });
      }
      notifyRider(tx, db, s.riderId, bookingId, at, 'Reserva cancelada',
        'El plazo para pagar terminó y la reserva se canceló. No se te cobró nada.', 'payment_expired');
      return true;
    });
    if (done) expired.push(bookingId);
  }
  return { expired };
}

