/**
 * Pagos A8: devoluciones manuales y con tarjeta (proveedor SIMULADO), contra
 * el emulador. Importes de prueba, ficticios.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminRecordRefund as refundFn } from '../index';
import { adminRecordRefund, onRefundPending } from '../payment_refund';
import type { PaymentProvider, RefundRequest } from '../payment_provider';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const NOW = Date.UTC(2026, 9, 26, 12);
const jefa = { adminId: 'jefa', adminEmail: 'jefa@example.com' };
const REASON = 'Devuelto por transferencia hoy';

const refund = jest.fn(async (_r: RefundRequest) => ({ status: 'succeeded' as const, externalRef: 're_sim_1' }));
const simulated = { method: 'card', refund, createCharge: jest.fn(), confirm: jest.fn() } as unknown as PaymentProvider;
const deps = { db, now: () => NOW, providers: { card: simulated } };
const OPS = {
  paymentMethods: { manual_qr: true, card: true },
  paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' }, card: { provider: 'stripe' } },
};

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'adminAlerts', 'payments', 'admin_logs', 'rateLimits']) await db.recursiveDelete(db.collection(col));
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const all = async (col: string) => (await db.collection(col).get()).docs.map((d) => ({ id: d.id, ...d.data() }));

/** Reserva cancelada con 25 % retenido (de prueba): 10000 pagado, 2500 retenido, 7500 por devolver. */
async function cancelled(method: 'manual_qr' | 'card', retained = 2500) {
  const paid = 10000;
  await db.doc('bookings/b1').set({ riderId: 'ana', status: 'cancelled' });
  await db.doc('bookings/b1/payment/state').set({
    bookingId: 'b1', riderId: 'ana', paymentStatus: 'refund_pending', paymentMethod: method, amountDue: paid, amountPaid: paid,
    amountRetained: retained, refundDue: paid - retained, amountRefunded: 0, providerChargeRef: method === 'card' ? 'ch_1' : null,
  });
  if (retained > 0) await db.doc('payments/fee_b1').set({ type: 'fee_retained', bookingId: 'b1', riderId: 'ana', amount: retained, method, status: 'completed' });
  await db.doc('payments/refund_b1').set({ type: 'refund', bookingId: 'b1', riderId: 'ana', amount: paid - retained, method, status: 'pending' });
  await db.collection('adminAlerts').add({ type: 'refund_pending', bookingId: 'b1', resolved: false });
}

beforeEach(async () => {
  await clear();
  refund.mockClear();
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('config/ops').set(OPS);
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('adminRecordRefund (manual)', () => {
  it('cierra la devolución: asiento completado, partially_refunded, alerta cerrada, aviso y auditoría', async () => {
    await cancelled('manual_qr');
    await expect(adminRecordRefund(deps, jefa, { bookingId: 'b1', externalRef: 'DEV 1', reason: REASON }))
      .resolves.toEqual({ paymentStatus: 'partially_refunded', amount: 7500 });
    expect(await doc('payments/refund_b1')).toMatchObject({ status: 'completed', externalRef: 'DEV 1' });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'partially_refunded', amountRefunded: 7500, refundDue: 0 });
    expect((await all('adminAlerts'))[0]).toMatchObject({ resolved: true, resolvedBy: 'jefa' });
    expect(await all('users/ana/notifications')).toEqual([expect.objectContaining({
      type: 'refund_recorded', body: 'Te devolvemos el dinero al método con el que pagaste.',
    })]);
    expect(await all('admin_logs')).toEqual([expect.objectContaining({ operation: 'record_refund', reason: REASON })]);
  });

  it('sin nada retenido queda refunded', async () => {
    await cancelled('manual_qr', 0);
    await expect(adminRecordRefund(deps, jefa, { bookingId: 'b1', externalRef: 'DEV 1', reason: REASON }))
      .resolves.toEqual({ paymentStatus: 'refunded', amount: 10000 });
  });

  it('manual sin referencia externa: invalid_request', async () => {
    await cancelled('manual_qr');
    expect(await reason(adminRecordRefund(deps, jefa, { bookingId: 'b1', reason: REASON }))).toBe('invalid_request');
  });

  it('dos intentos no duplican (también a la vez)', async () => {
    await cancelled('manual_qr');
    const r = await Promise.allSettled([
      adminRecordRefund(deps, jefa, { bookingId: 'b1', externalRef: 'DEV 1', reason: REASON }),
      adminRecordRefund(deps, jefa, { bookingId: 'b1', externalRef: 'DEV 2', reason: REASON }),
    ]);
    expect(r.filter((x) => x.status === 'fulfilled')).toHaveLength(1);
    expect(await reason(adminRecordRefund(deps, jefa, { bookingId: 'b1', externalRef: 'DEV 3', reason: REASON }))).toBe('already_refunded');
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ amountRefunded: 7500 });
    expect(await all('users/ana/notifications')).toHaveLength(1);
  });

  it('nunca más de lo cobrado menos lo retenido', async () => {
    await cancelled('manual_qr');
    await db.doc('payments/refund_b1').update({ amount: 9000 });
    expect(await reason(adminRecordRefund(deps, jefa, { bookingId: 'b1', externalRef: 'DEV 1', reason: REASON }))).toBe('refund_exceeds_paid');
    expect((await doc('payments/refund_b1'))!.status).toBe('pending');
  });

  it('por la callable: un pasajero no puede (admin_required)', async () => {
    await cancelled('manual_qr');
    const r = (refundFn as unknown as Runnable).run({
      auth: { uid: 'ana', token: { auth_time: Math.floor(Date.now() / 1000) } }, app: {},
      data: { bookingId: 'b1', externalRef: 'DEV 1', reason: REASON },
    });
    expect(await reason(r)).toBe('admin_required');
  });
});

describe('devolución con tarjeta por el proveedor (simulado)', () => {
  const trigger = async () => {
    const after = await db.doc('bookings/b1/payment/state').get();
    return onRefundPending(deps, 'b1', { paymentStatus: 'paid' }, after.data());
  };

  it('al pasar a refund_pending se pide al proveedor con clave fija y se cierra', async () => {
    await cancelled('card');
    await expect(trigger()).resolves.toEqual({ paymentStatus: 'partially_refunded', amount: 7500 });
    expect(refund).toHaveBeenCalledTimes(1);
    expect(refund.mock.calls[0][0]).toMatchObject({ amount: 7500, chargeRef: 'ch_1', idempotencyKey: 'refund:refund_b1' });
    expect(await doc('payments/refund_b1')).toMatchObject({ status: 'completed', externalRef: 're_sim_1' });
    // Repetir el aviso no vuelve a devolver.
    await trigger();
    expect(refund).toHaveBeenCalledTimes(1);
  });

  it('si el proveedor falla: alerta y queda pendiente; el reintento del admin usa la misma clave', async () => {
    await cancelled('card');
    refund.mockRejectedValueOnce(new Error('caído'));
    await expect(trigger()).resolves.toBeNull();
    expect((await doc('payments/refund_b1'))!.status).toBe('pending');
    expect((await all('adminAlerts')).some((a) => (a as { type?: string }).type === 'refund_failed')).toBe(true);
    await adminRecordRefund(deps, jefa, { bookingId: 'b1', reason: REASON });
    expect(refund.mock.calls.map((c) => c[0].idempotencyKey)).toEqual(['refund:refund_b1', 'refund:refund_b1']);
    expect((await doc('payments/refund_b1'))!.status).toBe('completed');
  });

  it('pagos manuales no se devuelven por el proveedor', async () => {
    await cancelled('manual_qr');
    await expect(trigger()).resolves.toBeNull();
    expect(refund).not.toHaveBeenCalled();
  });
});
