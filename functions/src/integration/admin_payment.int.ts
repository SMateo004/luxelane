/** A2: adminRecordPayment contra el emulador de Firestore. */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminRecordPayment } from '../admin_ops';
import { computeSettlement } from '../settlement';
import { adminRecordPayment as adminRecordPaymentFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const jefa = { adminId: 'jefa', adminEmail: 'jefa@example.com' };
const REASON = 'Cobrado en efectivo al llegar';
const run = (data: unknown) => adminRecordPayment({ db }, jefa, data);

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'payments', 'admin_logs', 'rateLimits', 'config']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const logs = async () => (await db.collection('admin_logs').get()).docs.map((d) => d.data());

beforeEach(async () => {
  await clear();
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  // Reparto que fijó settleBooking al completarse (comisión 15 %).
  await db.doc('bookings/b1').set({
    riderId: 'ana', driverId: 'luis', status: 'completed', estimatedPrice: 120.5, finalPrice: null,
    settlement: { amount: 120.5, commissionPct: 15, platformCommission: 18.08, driverPayout: 102.42 },
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('registrar un cobro manual', () => {
  it('crea el pago en centavos, sin el uid del admin, y la auditoría', async () => {
    const { paymentId } = await run({ action: 'record', bookingId: 'b1', method: 'cash', reference: 'R-1', reason: REASON });
    const p = (await doc(`payments/${paymentId}`))!;
    expect(p).toMatchObject({ bookingId: 'b1', riderId: 'ana', amount: 12050, status: 'captured', method: 'cash',
      manual: true, recordedByRole: 'admin' });
    // El pasajero lee el pago: no debe ver qué admin lo registró.
    expect(JSON.stringify(p)).not.toContain('jefa');
    expect(await doc('bookings/b1')).toMatchObject({ paymentId, finalPrice: 120.5 });
    expect((await logs())[0]).toMatchObject({ operation: 'record_payment', collection: 'payments', reason: REASON,
      changes: { amount: { before: null, after: 12050 } }, context: { bookingId: 'b1' } });
  });

  it('solo viajes completados, sin doble cobro y sin pisar el cobro con tarjeta', async () => {
    await db.doc('bookings/b2').set({ riderId: 'ana', status: 'in_progress', estimatedPrice: 10 });
    await db.doc('bookings/b3').set({ riderId: 'ana', status: 'completed', estimatedPrice: 10, stripePaymentIntentId: 'pi_1' });
    expect(await reason(run({ action: 'record', bookingId: 'b2', method: 'cash', reason: REASON }))).toBe('not_completed');
    expect(await reason(run({ action: 'record', bookingId: 'b3', method: 'cash', reason: REASON }))).toBe('card_payment');
    await run({ action: 'record', bookingId: 'b1', method: 'qr', reason: REASON });
    expect(await reason(run({ action: 'record', bookingId: 'b1', method: 'qr', reason: REASON }))).toBe('already_paid');
    expect((await db.collection('payments').get()).size).toBe(1);
  });
});

describe('reservas con estado de pago (pagos, Q2)', () => {
  it('no admite un segundo cobro: solo se cobran con adminConfirmPayment', async () => {
    // Pagada antes de pedir chófer (charge_b1) y ya completada.
    await db.doc('bookings/b1/payment/state').set({
      bookingId: 'b1', riderId: 'ana', paymentStatus: 'paid', paymentMethod: 'manual_qr', amountDue: 12050, amountPaid: 12050,
    });
    await db.doc('payments/charge_b1').set({ type: 'charge', bookingId: 'b1', riderId: 'ana', amount: 12050, status: 'completed' });
    expect(await reason(run({ action: 'record', bookingId: 'b1', method: 'cash', reason: REASON }))).toBe('use_confirm_payment');
    const all = (await db.collection('payments').get()).docs.map((d) => d.id);
    expect(all).toEqual(['charge_b1']);
    expect(await logs()).toEqual([]);
  });

  it('tampoco una sin pagar aún (awaiting_payment)', async () => {
    await db.doc('bookings/b1/payment/state').set({ bookingId: 'b1', riderId: 'ana', paymentStatus: 'awaiting_payment', amountDue: 12050, amountPaid: 0 });
    expect(await reason(run({ action: 'record', bookingId: 'b1', method: 'qr', reason: REASON }))).toBe('use_confirm_payment');
  });
});

describe('métodos del panel', () => {
  it.each([['cash'], ['qr'], ['transfer'], ['card_terminal']])('acepta %s', async (method) => {
    await expect(run({ action: 'record', bookingId: 'b1', method, reason: REASON })).resolves.toHaveProperty('paymentId');
  });

  it('rechaza un método que el panel no ofrece', async () => {
    expect(await reason(run({ action: 'record', bookingId: 'b1', method: 'card', reason: REASON }))).toBe('invalid_request');
  });
});

describe('corregir el importe: reparto con la comisión guardada (D3)', () => {
  it('recalcula con la comisión de la reserva, no con la vigente', async () => {
    await db.doc('config/finance').set({ platformCommissionPct: 30 });
    const { paymentId } = await run({ action: 'record', bookingId: 'b1', method: 'cash', reason: REASON });
    await run({ action: 'correct', paymentId, amountBs: 110, reason: 'Importe mal anotado al cerrar' });
    const b = (await doc('bookings/b1'))!;
    expect(b.finalPrice).toBe(110);
    expect(b.settlement).toEqual({ amount: 110, commissionPct: 15, platformCommission: 16.5, driverPayout: 93.5 });
    expect((await doc(`payments/${paymentId}`))?.amount).toBe(11000);
    // settleBooking no lo vuelve a tocar: el reparto ya es el del importe.
    expect(computeSettlement(b, 30)).toBeNull();
    const c = (await logs()).find((l) => l.operation === 'correct_payment')!;
    expect(c.context.settlement.before).toMatchObject({ amount: 120.5, commissionPct: 15 });
    expect(c.context.settlement.after).toMatchObject({ amount: 110, commissionPct: 15 });
  });

  it('sin comisión guardada: rechaza con motivo claro, no cambia nada y deja auditoría', async () => {
    await db.doc('bookings/b2').set({ riderId: 'ana', status: 'completed', estimatedPrice: 50, finalPrice: null });
    const { paymentId } = await run({ action: 'record', bookingId: 'b2', method: 'cash', reason: REASON });
    expect(await reason(run({ action: 'correct', paymentId, amountBs: 40, reason: 'Importe mal anotado al cerrar' })))
      .toBe('settlement_commission_missing');
    expect((await doc(`payments/${paymentId}`))?.amount).toBe(5000);
    expect((await doc('bookings/b2'))?.finalPrice).toBe(50);
    const r = (await logs()).find((l) => l.operation === 'correct_payment_rejected')!;
    expect(r).toMatchObject({ reason: 'Importe mal anotado al cerrar', context: { rejected: 'settlement_commission_missing' } });
    // Sin tocar el importe (método o referencia) sí se corrige.
    await run({ action: 'correct', paymentId, method: 'qr', reason: 'Método mal anotado al cerrar' });
    expect((await doc(`payments/${paymentId}`))?.method).toBe('qr');
  });
});

describe('corregir un cobro manual', () => {
  it('cambia solo lo pedido y conserva el valor anterior en la auditoría', async () => {
    const { paymentId } = await run({ action: 'record', bookingId: 'b1', method: 'cash', reason: REASON });
    await run({ action: 'correct', paymentId, amountBs: 110, method: 'qr', reason: 'Importe mal anotado al cerrar' });
    expect(await doc(`payments/${paymentId}`)).toMatchObject({ amount: 11000, method: 'qr', corrections: 1 });
    expect((await doc('bookings/b1'))?.finalPrice).toBe(110);
    const c = (await logs()).find((l) => l.operation === 'correct_payment')!;
    expect(c.changes).toEqual({ amount: { before: 12050, after: 11000 }, method: { before: 'cash', after: 'qr' } });
  });

  it('no corrige un cobro con tarjeta ni un cambio vacío', async () => {
    await db.doc('payments/stripe').set({ bookingId: 'b1', status: 'captured', stripePaymentIntentId: 'pi_1', amount: 100 });
    expect(await reason(run({ action: 'correct', paymentId: 'stripe', amountBs: 1, reason: REASON }))).toBe('not_manual');
    const { paymentId } = await run({ action: 'record', bookingId: 'b1', method: 'cash', reason: REASON });
    expect(await reason(run({ action: 'correct', paymentId, method: 'cash', reason: REASON }))).toBe('no_change');
  });

  it('por la callable: solo admin', async () => {
    const call = (uid: string) => (adminRecordPaymentFn as unknown as Runnable).run({
      auth: { uid, token: { auth_time: Math.floor(Date.now() / 1000) } }, app: {},
      data: { action: 'record', bookingId: 'b1', method: 'cash', reason: REASON },
    });
    expect(await reason(call('ana'))).toBe('admin_required');
    expect(await reason(call('jefa'))).toBe('ok');
  });
});
