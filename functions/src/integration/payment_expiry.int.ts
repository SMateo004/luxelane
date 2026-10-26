/**
 * Pagos A6: vencimiento del plazo con reloj simulado, contra el emulador.
 * El plazo (30 min) es un valor de prueba, ficticio.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import '../index'; // initializeApp
import { expirePayments } from '../payment_expiry';
import { adminConfirmPayment } from '../payment_manual';

const db = admin.firestore();
const T0 = Date.UTC(2026, 9, 26, 12);
const MIN = 60_000;
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const at = (ms: number) => ({ db, now: () => ms });
const OPS = {
  paymentWindowMinutes: 30,
  paymentMethods: { manual_qr: true },
  paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } },
};

async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'openRequests', 'adminAlerts', 'payments', 'paymentOperations', 'admin_logs']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const all = async (col: string) => (await db.collection(col).get()).docs.map((d) => d.data());

async function booking(id: string, state: Record<string, unknown> = {}, pickupMs = T0 + 3 * 60 * MIN) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', status: 'pending', driverId: null, class: 'business', estimatedPrice: 100, scheduledAt: ts(pickupMs),
  });
  await db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentStatus: 'awaiting_payment', paymentMethod: null, amountDue: 10000,
    amountPaid: 0, paymentRef: 'ABCD2345', paidAt: null, paymentDeadline: ts(T0 + 30 * MIN), ...state,
  });
}

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('config/ops').set(OPS);
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('expirePayments', () => {
  it('sin paymentWindowMinutes no hace nada', async () => {
    await db.doc('config/ops').set({ paymentMethods: OPS.paymentMethods });
    await booking('b1');
    await expect(expirePayments(at(T0 + 120 * MIN))).resolves.toEqual({ expired: [], skipped: 'no_window' });
    expect((await doc('bookings/b1'))!.status).toBe('pending');
  });

  it('antes del plazo no vence; después, expired y la reserva se cancela sin retención', async () => {
    await booking('b1');
    await expect(expirePayments(at(T0 + 29 * MIN))).resolves.toEqual({ expired: [] });
    await expect(expirePayments(at(T0 + 31 * MIN))).resolves.toEqual({ expired: ['b1'] });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'expired', amountPaid: 0 });
    expect(await doc('bookings/b1')).toMatchObject({
      status: 'cancelled', cancelledBy: 'system', cancellationReason: 'payment_expired',
    });
    expect(await all('payments')).toEqual([]);
    expect(await all('users/ana/notifications')).toEqual([expect.objectContaining({ type: 'payment_expired' })]);
    // Una segunda pasada no cambia nada.
    await expect(expirePayments(at(T0 + 40 * MIN))).resolves.toEqual({ expired: [] });
  });

  it('si el pasajero avisó «ya pagué», no vence (decide central)', async () => {
    await booking('b1', { riderReportedAt: ts(T0 + 10 * MIN) });
    await expect(expirePayments(at(T0 + 31 * MIN))).resolves.toEqual({ expired: [] });
    expect((await doc('bookings/b1/payment/state'))!.paymentStatus).toBe('awaiting_payment');
  });

  it('una reserva pagada no vence', async () => {
    await booking('b1', { paymentStatus: 'paid', amountPaid: 10000 });
    await expect(expirePayments(at(T0 + 31 * MIN))).resolves.toEqual({ expired: [] });
  });
});

describe('pago confirmado fuera de plazo (A6 + A4)', () => {
  const confirm = (ms: number) => adminConfirmPayment(at(ms), { adminId: 'jefa', adminEmail: null },
    { bookingId: 'b1', operationNumber: 'OP 1', amountReceived: 100, reason: 'Ingreso visto tarde en el banco' });

  it('vencida y con la recogida por delante: vuelve a buscar chófer y se anota', async () => {
    await booking('b1');
    await expirePayments(at(T0 + 31 * MIN));
    await expect(confirm(T0 + 45 * MIN)).resolves.toEqual({ paymentStatus: 'paid', dispatched: true, late: true });
    expect(await doc('bookings/b1')).toMatchObject({ status: 'pending' });
    expect((await doc('bookings/b1'))!.cancellationReason).toBeUndefined();
    expect((await db.doc('openRequests/b1').get()).exists).toBe(true);
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'paid', confirmedLate: true });
    const events = await all('bookings/b1/events');
    expect(events.map((e) => e.method)).toEqual(expect.arrayContaining(['payment_expired', 'paid_after_deadline']));
  });

  it('vencida y con la recogida ya pasada: se registra el cobro y se devuelve todo', async () => {
    await booking('b1', {}, T0 + 40 * MIN);
    await expirePayments(at(T0 + 31 * MIN));
    await expect(confirm(T0 + 60 * MIN)).resolves.toMatchObject({ paymentStatus: 'refund_pending', late: true });
    expect(await doc('payments/refund_b1')).toMatchObject({ type: 'refund', amount: 10000, status: 'pending' });
    expect((await doc('bookings/b1'))!.status).toBe('cancelled');
  });
});
