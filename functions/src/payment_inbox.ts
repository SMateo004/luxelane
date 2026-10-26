/**
 * Bandejas de pagos del panel (A11; las pantallas son de la Parte B):
 *
 * - awaiting: pendientes de pago (sin «ya pagué»), con su plazo.
 * - reported: «ya pagué» por confirmar o rechazar.
 * - refunds: devoluciones pendientes, con los asientos por cerrar (el de la
 *   cancelación, refund_{id}, o el de un importe final menor, refund_final_{id}).
 * - balances: saldos pendientes del pasajero (A9).
 *
 * Solo lo que central necesita para actuar: referencia, importes, estado y
 * la reserva (estado, hora, clase, zona); nada de contacto del pasajero.
 */
import * as admin from 'firebase-admin';
import { z } from 'zod';
import { parseInput } from './schemas';
import type { PaymentState } from './payment_model';

export const INBOXES = ['awaiting', 'reported', 'refunds', 'balances'] as const;
export const inboxSchema = z.strictObject({ kind: z.enum(INBOXES), limit: z.number().int().min(1).max(100).default(50) });

const ms = (t: unknown) => (t instanceof admin.firestore.Timestamp ? t.toMillis() : null);

export async function adminPaymentInbox(db: admin.firestore.Firestore, data: unknown) {
  const { kind, limit } = parseInput(inboxSchema, data);
  const group = db.collectionGroup('payment');
  // Consultas de una sola condición; lo demás se filtra aquí (el volumen
  // de un piloto es pequeño). 4× el límite como margen para el filtro.
  const snap = kind === 'balances'
    ? await group.where('balanceDue', '>', 0).limit(limit * 4).get()
    : await group.where('paymentStatus', '==', kind === 'refunds' ? 'refund_pending' : 'awaiting_payment')
      .limit(limit * 4).get();
  const states = snap.docs
    .filter((d) => d.id === 'state' && d.ref.parent.parent)
    .map((d) => ({ bookingId: d.ref.parent.parent!.id, s: d.data() as PaymentState & Record<string, unknown> }))
    .filter(({ s }) => kind !== 'awaiting' || !s.riderReportedAt)
    .filter(({ s }) => kind !== 'reported' || !!s.riderReportedAt)
    .slice(0, limit);
  const bookings = states.length
    ? await db.getAll(...states.map((x) => db.collection('bookings').doc(x.bookingId)))
    : [];
  // Asientos de devolución pendientes de cada reserva: el panel cierra uno
  // concreto (adminRecordRefund con entryId).
  const pendingRefunds = kind === 'refunds'
    ? await Promise.all(states.map(async ({ bookingId }) => (await db.collection('payments')
      .where('bookingId', '==', bookingId).where('type', '==', 'refund').where('status', '==', 'pending').get())
      .docs.map((d) => ({ entryId: d.id, amount: Number(d.data().amount ?? 0), method: d.data().method ?? null }))))
    : [];
  const items = states.map(({ bookingId, s }, i) => {
    const b = bookings[i]?.data() ?? {};
    return {
      bookingId,
      paymentRef: s.paymentRef ?? null,
      paymentStatus: s.paymentStatus,
      paymentMethod: s.paymentMethod ?? null,
      amountDue: s.amountDue ?? 0,
      amountPaid: s.amountPaid ?? 0,
      amountRetained: Number(s.amountRetained ?? 0),
      refundDue: Number(s.refundDue ?? 0),
      balanceDue: Number(s.balanceDue ?? 0),
      paymentDeadline: ms(s.paymentDeadline),
      riderReportedAt: ms(s.riderReportedAt),
      riderOperationNumber: (s.riderOperationNumber as string | null | undefined) ?? null,
      pendingRefunds: pendingRefunds[i] ?? [],
      booking: {
        status: b.status ?? null,
        scheduledAt: ms(b.scheduledAt),
        vehicleClass: b.class ?? b.vehicleClass ?? null,
        pickupArea: b.pickupArea ?? null,
      },
    };
  });
  // Lo más urgente primero: plazo o recogida más cercanos.
  const key = (x: (typeof items)[number]) => x.paymentDeadline ?? x.booking.scheduledAt ?? Number.MAX_SAFE_INTEGER;
  items.sort((a, b) => key(a) - key(b));
  return { kind, items };
}
