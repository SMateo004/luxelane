/** Pagos A11: bandejas de pagos del panel, contra el emulador. */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminPaymentInbox as inboxFn } from '../index';
import { adminPaymentInbox } from '../payment_inbox';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const T = Date.UTC(2026, 9, 26, 12);
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'rateLimits']) await db.recursiveDelete(db.collection(col));
  await db.recursiveDelete(db.collection('bookings'));
}
async function booking(id: string, state: Record<string, unknown>, status = 'pending') {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', status, class: 'business', pickupArea: 'Santa Cruz de la Sierra', scheduledAt: ts(T + 3600_000),
    notes: 'Toque el timbre', guest: { phone: '+59170000001' },
  });
  await db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentRef: `REF${id}`, amountDue: 10000, amountPaid: 0, paymentDeadline: null, ...state,
  });
}
const ids = (r: { items: { bookingId: string }[] }) => r.items.map((i) => i.bookingId);

beforeEach(async () => {
  await clear();
  await booking('pend1', { paymentStatus: 'awaiting_payment', paymentDeadline: ts(T + 30 * 60_000) });
  await booking('pend2', { paymentStatus: 'awaiting_payment', paymentDeadline: ts(T + 10 * 60_000) });
  await booking('aviso', { paymentStatus: 'awaiting_payment', riderReportedAt: ts(T), riderOperationNumber: 'OP 1' });
  await booking('devol', { paymentStatus: 'refund_pending', amountPaid: 10000, refundDue: 7500, amountRetained: 2500 }, 'cancelled');
  await booking('saldo', { paymentStatus: 'paid', amountPaid: 10000, balanceDue: 1250 }, 'completed');
  await booking('pagada', { paymentStatus: 'paid', amountPaid: 10000 }, 'confirmed');
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('adminPaymentInbox', () => {
  it('pendientes de pago (sin «ya pagué»), el plazo más cercano primero', async () => {
    expect(ids(await adminPaymentInbox(db, { kind: 'awaiting' }))).toEqual(['pend2', 'pend1']);
  });

  it('«ya pagué» por confirmar, con el número de operación', async () => {
    const r = await adminPaymentInbox(db, { kind: 'reported' });
    expect(r.items).toEqual([expect.objectContaining({ bookingId: 'aviso', riderOperationNumber: 'OP 1', amountDue: 10000 })]);
  });

  it('devoluciones y saldos pendientes', async () => {
    expect((await adminPaymentInbox(db, { kind: 'refunds' })).items)
      .toEqual([expect.objectContaining({ bookingId: 'devol', refundDue: 7500, amountRetained: 2500 })]);
    expect((await adminPaymentInbox(db, { kind: 'balances' })).items)
      .toEqual([expect.objectContaining({ bookingId: 'saldo', balanceDue: 1250 })]);
  });

  it('sin datos de contacto del pasajero', async () => {
    const r = JSON.stringify(await adminPaymentInbox(db, { kind: 'awaiting' }));
    for (const secret of ['timbre', '+5917', 'ana']) expect(r).not.toContain(secret);
  });

  it('por la callable: solo admin', async () => {
    await db.doc('users/ana').set({ role: 'rider', isActive: true });
    let reason: string | undefined;
    try {
      await (inboxFn as unknown as Runnable).run({
        auth: { uid: 'ana', token: { auth_time: Math.floor(Date.now() / 1000) } }, app: {}, data: { kind: 'awaiting' },
      });
    } catch (e) { reason = ((e as HttpsError).details as { reason?: string })?.reason; }
    expect(reason).toBe('admin_required');
  });
});
