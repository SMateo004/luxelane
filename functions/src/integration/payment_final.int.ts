/**
 * Pagos A9/A10: diferencia entre el importe final y lo pagado, contra el
 * emulador. Importes y comisión de prueba, ficticios.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { reconcileFinalPayment, settleBooking } from '../index';
import { adminRecordRefund } from '../payment_refund';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

async function clear(): Promise<void> {
  for (const col of ['config', 'adminAlerts', 'payments', 'admin_logs']) await db.recursiveDelete(db.collection(col));
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const all = async (col: string) => (await db.collection(col).get()).docs.map((d) => ({ id: d.id, ...d.data() }));

async function setup(extra: Record<string, unknown> = {}) {
  await db.doc('bookings/b1').set({ riderId: 'ana', driverId: 'luis', status: 'in_progress', estimatedPrice: 100, finalPrice: null, ...extra });
  await db.doc('bookings/b1/payment/state').set({
    bookingId: 'b1', riderId: 'ana', paymentStatus: 'paid', paymentMethod: 'manual_qr', amountDue: 10000, amountPaid: 10000,
  });
}
/** Aplica el cambio y lanza el trigger con el antes y el después reales. */
async function update(change: Record<string, unknown>) {
  const ref = db.doc('bookings/b1');
  const before = await ref.get();
  await ref.update(change);
  const event = { data: { before, after: await ref.get() }, params: { bookingId: 'b1' } };
  await (reconcileFinalPayment as unknown as Runnable).run(event);
  return event;
}

beforeEach(clear);
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('importe final distinto de lo pagado (A9)', () => {
  it('igual: nada pendiente', async () => {
    await setup();
    await update({ status: 'completed', finalPrice: 100 });
    expect(await all('payments')).toEqual([]);
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'paid', balanceDue: 0 });
  });

  it('debe más: saldo pendiente con asiento y alerta, sin cobrarlo', async () => {
    await setup();
    await update({ status: 'completed', finalPrice: 112.5 });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'paid', balanceDue: 1250, amountPaid: 10000 });
    expect(await doc('payments/balance_b1')).toMatchObject({ type: 'charge', amount: 1250, status: 'pending' });
    expect(await all('adminAlerts')).toEqual([expect.objectContaining({ type: 'balance_due', amount: 1250 })]);
  });

  it('pagó de más: devolución pendiente con asiento y alerta, sin devolverla sola', async () => {
    await setup();
    await update({ status: 'completed', finalPrice: 80 });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'refund_pending', refundDue: 2000 });
    expect(await doc('payments/refund_final_b1')).toMatchObject({ type: 'refund', amount: 2000, status: 'pending' });
    // Central la registra después.
    await expect(adminRecordRefund({ db }, { adminId: 'jefa', adminEmail: null },
      { bookingId: 'b1', entryId: 'refund_final_b1', externalRef: 'DEV 9', reason: 'Diferencia devuelta por transferencia' }))
      .resolves.toEqual({ paymentStatus: 'partially_refunded', amount: 2000 });
  });

  it('si el importe final cambia otra vez antes de gestionarlo, se actualiza sin duplicar', async () => {
    await setup();
    await update({ status: 'completed', finalPrice: 112.5 });
    await update({ finalPrice: 110 });
    expect(await doc('payments/balance_b1')).toMatchObject({ amount: 1000, status: 'pending' });
    await update({ finalPrice: 100 });
    expect((await db.doc('payments/balance_b1').get()).exists).toBe(false);
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 0 });
  });

  it('el reparto al chófer usa el importe final (settleBooking igual que antes)', async () => {
    await db.doc('config/finance').set({ platformCommissionPct: 20 });
    await setup();
    const event = await update({ status: 'completed', finalPrice: 112.5 });
    await (settleBooking as unknown as Runnable).run(event);
    expect((await doc('bookings/b1'))!.settlement).toMatchObject({ amount: 112.5 });
  });

  it('reserva sin estado de pago (antigua): no hace nada', async () => {
    await db.doc('bookings/b1').set({ riderId: 'ana', status: 'in_progress', estimatedPrice: 100 });
    await update({ status: 'completed', finalPrice: 150 });
    expect(await all('payments')).toEqual([]);
  });
});
