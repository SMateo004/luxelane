/**
 * Pagos A4: pago manual (QR o transferencia) contra el emulador. Importes,
 * plazos y datos de cobro son de prueba, ficticios.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminConfirmPayment, adminRejectPayment, markPaymentSent } from '../payment_manual';
import { adminConfirmPayment as confirmFn, markPaymentSent as sentFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const NOW = Date.UTC(2026, 9, 26, 12);
const deps = { db, now: () => NOW };
const jefa = { adminId: 'jefa', adminEmail: 'jefa@example.com' };
const REASON = 'Ingreso visto en el extracto del banco';
const OPS = {
  paymentMethods: { manual_qr: true },
  paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } },
};

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'openRequests', 'adminAlerts', 'payments', 'paymentOperations', 'admin_logs', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const all = async (col: string) => (await db.collection(col).get()).docs.map((d) => ({ id: d.id, ...d.data() }));
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

async function booking(id: string, extra: Record<string, unknown> = {}, state: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', status: 'pending', driverId: null, class: 'business', serviceType: 'oneWay', estimatedPrice: 100,
    scheduledAt: ts(NOW + 3 * 3600_000), ...extra,
  });
  await db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentStatus: 'awaiting_payment', paymentMethod: null, amountDue: 10000,
    amountPaid: 0, paymentRef: `REF${id.toUpperCase()}`.slice(0, 8), paidAt: null, paymentDeadline: null,
    createdAt: ts(NOW - 60_000), updatedAt: ts(NOW - 60_000), ...state,
  });
}
const confirm = (over: Record<string, unknown> = {}) =>
  adminConfirmPayment(deps, jefa, { bookingId: 'b1', operationNumber: 'OP 123', amountReceived: 100, reason: REASON, ...over });

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/beto').set({ role: 'rider', isActive: true });
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('config/ops').set(OPS);
  await booking('b1');
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('markPaymentSent («ya pagué»)', () => {
  it('crea una alerta de prioridad alta y no confirma nada', async () => {
    await expect(markPaymentSent(deps, 'ana', { bookingId: 'b1', operationNumber: 'OP 123' }))
      .resolves.toEqual({ paymentStatus: 'awaiting_payment', alreadyReported: false });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({
      paymentStatus: 'awaiting_payment', amountPaid: 0, paymentMethod: 'manual_qr', riderOperationNumber: 'OP 123',
    });
    expect(await all('adminAlerts')).toEqual([expect.objectContaining({
      type: 'payment_reported', severity: 'high', bookingId: 'b1', operationNumber: 'OP 123', resolved: false,
    })]);
    expect(await all('openRequests')).toEqual([]);
    expect(await all('payments')).toEqual([]);
  });

  it('doble toque: una sola alerta', async () => {
    await markPaymentSent(deps, 'ana', { bookingId: 'b1' });
    await expect(markPaymentSent(deps, 'ana', { bookingId: 'b1' })).resolves.toMatchObject({ alreadyReported: true });
    expect(await all('adminAlerts')).toHaveLength(1);
  });

  it('usuario ajeno: not_owner, sin escribir nada', async () => {
    expect(await reason(markPaymentSent(deps, 'beto', { bookingId: 'b1' }))).toBe('not_owner');
    expect(await all('adminAlerts')).toEqual([]);
  });

  it('número de operación demasiado largo o con símbolos: invalid_request', async () => {
    for (const operationNumber of ['x'.repeat(41), 'OP<script>']) {
      expect(await reason(markPaymentSent(deps, 'ana', { bookingId: 'b1', operationNumber }))).toBe('invalid_request');
    }
  });

  it('método manual desactivado o sin datos de cobro: method_disabled', async () => {
    await db.doc('config/ops').set({ paymentMethods: { manual_qr: true } });
    expect(await reason(markPaymentSent(deps, 'ana', { bookingId: 'b1' }))).toBe('method_disabled');
  });

  it('por la callable: solo con sesión', async () => {
    expect(await reason((sentFn as unknown as Runnable).run({ app: {}, data: { bookingId: 'b1' } }))).toBe('unauthenticated');
  });
});

describe('adminConfirmPayment', () => {
  it('importe distinto del debido: amount_mismatch y no escribe nada', async () => {
    expect(await reason(confirm({ amountReceived: 99.99 }))).toBe('amount_mismatch');
    expect((await doc('bookings/b1/payment/state'))!.paymentStatus).toBe('awaiting_payment');
    expect(await all('payments')).toEqual([]);
    expect(await all('paymentOperations')).toEqual([]);
  });

  it('confirma: paid, asiento del cobro, solicitud abierta, alerta cerrada, aviso y auditoría', async () => {
    await markPaymentSent(deps, 'ana', { bookingId: 'b1', operationNumber: 'OP 123' });
    await expect(confirm()).resolves.toEqual({ paymentStatus: 'paid', dispatched: true, late: false });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({
      paymentStatus: 'paid', paymentMethod: 'manual_qr', amountPaid: 10000, riderReportedAt: null,
    });
    expect(((await doc('bookings/b1/payment/state'))!.paidAt as admin.firestore.Timestamp).toMillis()).toBe(NOW);
    expect(await all('payments')).toEqual([expect.objectContaining({
      id: 'charge_b1', type: 'charge', amount: 10000, currency: 'bob', method: 'manual_qr', actor: { role: 'admin' },
      externalRef: 'OP 123', status: 'completed', riderId: 'ana',
    })]);
    // El asiento lo lee el pasajero: no lleva el uid del admin.
    expect(JSON.stringify(await all('payments'))).not.toContain('jefa');
    expect(await doc('openRequests/b1')).toMatchObject({ estimatedPrice: 100 });
    expect((await all('adminAlerts'))[0]).toMatchObject({ resolved: true, resolvedBy: 'jefa' });
    expect((await all('users/ana/notifications'))[0]).toMatchObject({ type: 'payment_confirmed', bookingId: 'b1' });
    expect(await all('admin_logs')).toEqual([expect.objectContaining({
      operation: 'confirm_payment', docPath: 'bookings/b1', reason: REASON,
      changes: { paymentStatus: { before: 'awaiting_payment', after: 'paid' }, amountPaid: { before: 0, after: 10000 } },
    })]);
  });

  it('una referencia ya pagada no se confirma dos veces', async () => {
    await confirm();
    expect(await reason(confirm({ operationNumber: 'OP 999' }))).toBe('already_paid');
    expect(await all('payments')).toHaveLength(1);
  });

  it('un número de operación ya usado no confirma otra reserva (sin espacios ni mayúsculas)', async () => {
    await booking('b2');
    await confirm();
    expect(await reason(confirm({ bookingId: 'b2', operationNumber: 'op123' }))).toBe('operation_already_used');
    expect((await doc('bookings/b2/payment/state'))!.paymentStatus).toBe('awaiting_payment');
  });

  it('dos confirmaciones a la vez: una sola gana', async () => {
    const r = await Promise.allSettled([confirm(), confirm({ operationNumber: 'OP 124' })]);
    expect(r.filter((x) => x.status === 'fulfilled')).toHaveLength(1);
    expect(await all('payments')).toHaveLength(1);
  });

  it('fuera de plazo: se confirma y se anota', async () => {
    await db.doc('bookings/b1/payment/state').update({ paymentDeadline: ts(NOW - 60_000) });
    await expect(confirm()).resolves.toMatchObject({ paymentStatus: 'paid', late: true });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ confirmedLate: true });
    expect((await all('admin_logs'))[0]).toMatchObject({ context: expect.objectContaining({ late: true }) });
  });

  it('reserva ya cancelada: se registra el cobro y queda la devolución entera pendiente', async () => {
    await db.doc('bookings/b1').update({ status: 'cancelled' });
    await expect(confirm()).resolves.toMatchObject({ paymentStatus: 'refund_pending', dispatched: false });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'refund_pending', refundDue: 10000, amountRetained: 0 });
    expect(await doc('payments/refund_b1')).toMatchObject({ type: 'refund', amount: 10000, status: 'pending' });
    expect(await all('openRequests')).toEqual([]);
  });

  it('por la callable: un pasajero no confirma (admin_required)', async () => {
    const r = (confirmFn as unknown as Runnable).run({
      auth: { uid: 'ana', token: { auth_time: Math.floor(Date.now() / 1000) } }, app: {},
      data: { bookingId: 'b1', operationNumber: 'OP 1', amountReceived: 100, reason: REASON },
    });
    expect(await reason(r)).toBe('admin_required');
    expect((await doc('bookings/b1/payment/state'))!.paymentStatus).toBe('awaiting_payment');
  });

  it('sin motivo suficiente: invalid_request', async () => {
    expect(await reason(confirm({ reason: 'ok' }))).toBe('invalid_request');
  });
});

describe('adminRejectPayment', () => {
  it('rechaza el aviso: failed, alerta cerrada, auditoría; el pasajero puede volver a avisar', async () => {
    await markPaymentSent(deps, 'ana', { bookingId: 'b1' });
    await expect(adminRejectPayment(deps, jefa, { bookingId: 'b1', reason: REASON })).resolves.toEqual({ paymentStatus: 'failed' });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'failed', riderReportedAt: null });
    expect((await all('admin_logs'))[0]).toMatchObject({ operation: 'reject_payment', reason: REASON });
    await expect(markPaymentSent(deps, 'ana', { bookingId: 'b1' })).resolves.toMatchObject({ alreadyReported: false });
    expect((await all('adminAlerts')).filter((a) => (a as { resolved?: boolean }).resolved === false)).toHaveLength(1);
  });

  it('no rechaza un pago ya confirmado', async () => {
    await confirm();
    expect(await reason(adminRejectPayment(deps, jefa, { bookingId: 'b1', reason: REASON }))).toBe('not_awaiting_payment');
  });
});
