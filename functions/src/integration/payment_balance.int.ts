/**
 * G2: cobrar un saldo pendiente (adminCollectBalance), contra el emulador.
 * El saldo nace como en producción: viaje completado con un importe final
 * mayor que lo pagado (A9). Importes y números de operación de PRUEBA,
 * ficticios.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminCollectBalance as collectFn } from '../index';
import { adminCollectBalance } from '../payment_balance';
import { adminConfirmPayment } from '../payment_manual';
import { reconcileFinalAmount } from '../payment_final';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const ACTOR = { adminId: 'jefa', adminEmail: null };
const WHY = 'Saldo visto en el extracto del banco';

async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'adminAlerts', 'payments', 'paymentOperations', 'paymentRefs', 'admin_logs', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const ledger = async () => (await db.collection('payments').get()).docs.map((d) => ({ id: d.id, ...d.data() }));
async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
const collect = (over: Record<string, unknown> = {}) => adminCollectBalance({ db }, ACTOR, {
  bookingId: 'b1', amount: 12.5, operationNumber: 'OP 500', method: 'manual_qr', reason: WHY, ...over,
});

/** Pagó 100 Bs y el importe final fue 112,50: saldo de 12,50 (1250 céntimos). */
async function withBalance(id = 'b1') {
  await db.doc(`bookings/${id}`).set({ riderId: 'ana', status: 'completed', estimatedPrice: 100, finalPrice: 112.5 });
  await db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentStatus: 'paid', paymentMethod: 'manual_qr', amountDue: 10000, amountPaid: 10000,
  });
  await reconcileFinalAmount(db, id);
}

beforeEach(async () => { await clear(); await withBalance(); });
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('adminCollectBalance', () => {
  it('parte de un saldo real de A9', async () => {
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 1250 });
    expect(await doc('payments/balance_b1')).toMatchObject({ type: 'charge', amount: 1250, status: 'pending' });
  });

  it('exacto: cierra el saldo con un asiento charge, resuelve la alerta y audita', async () => {
    await expect(collect()).resolves.toEqual({ alreadyRecorded: false, collected: 1250, balanceDue: 0 });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 0, amountPaid: 11250 });
    const entries = await ledger();
    expect(entries).toEqual(expect.arrayContaining([
      expect.objectContaining({
        type: 'charge', amount: 1250, status: 'completed', externalRef: 'OP 500', method: 'manual_qr', actor: { role: 'admin' },
      }),
      // H4: el pendiente no se borra: queda cerrado por el cobro.
      expect.objectContaining({ id: 'balance_b1', amount: 1250, status: 'superseded' }),
    ]));
    expect(entries).toHaveLength(2);
    const alerts = (await db.collection('adminAlerts').where('type', '==', 'balance_due').get()).docs.map((d) => d.data());
    expect(alerts).toEqual([expect.objectContaining({ resolved: true, resolvedBy: 'jefa' })]);
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({ operation: 'collect_balance', reason: WHY })]);
    // A9 vuelve a calcular contra lo cobrado: nada nuevo pendiente.
    await reconcileFinalAmount(db, 'b1');
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 0 });
    expect((await ledger()).filter((e) => (e as { status?: string }).status === 'pending')).toEqual([]);
  });

  it('parcial: queda el resto pendiente y la alerta abierta', async () => {
    await expect(collect({ amount: 5 })).resolves.toMatchObject({ collected: 500, balanceDue: 750 });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 750, amountPaid: 10500 });
    // H4: el pendiente original no cambia de importe; el resto es un asiento nuevo.
    expect(await doc('payments/balance_b1')).toMatchObject({ amount: 1250, status: 'superseded' });
    expect(await doc('payments/balance_b1_2')).toMatchObject({ amount: 750, status: 'pending' });
    const alert = (await db.collection('adminAlerts').where('type', '==', 'balance_due').get()).docs[0].data();
    expect(alert.resolved).toBe(false);
    // El resto, con otra operación, lo cierra.
    await expect(collect({ amount: 7.5, operationNumber: 'OP 501' })).resolves.toMatchObject({ balanceDue: 0 });
    expect(await doc('payments/balance_b1_2')).toMatchObject({ amount: 750, status: 'superseded' });
    expect((await ledger()).filter((e) => (e as { status?: string }).status === 'pending')).toEqual([]);
    // A9 recalcula igual: sin saldo nuevo.
    await reconcileFinalAmount(db, 'b1');
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 0, amountPaid: 11250 });
  });

  it('más que el saldo: rechazado y sin cambios', async () => {
    expect(await reason(collect({ amount: 12.51 }))).toBe('amount_exceeds_balance');
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 1250, amountPaid: 10000 });
    expect((await db.collection('paymentOperations').get()).size).toBe(0);
  });

  it('número de operación repetido: rechazado (en otra reserva, con otro importe o ya usado al confirmar)', async () => {
    await withBalance('b2');
    await collect({ amount: 5 });
    expect(await reason(collect({ bookingId: 'b2', amount: 5 }))).toBe('operation_already_used');
    expect(await reason(collect({ amount: 6 }))).toBe('operation_already_used');
    // Ya usado por adminConfirmPayment en otra reserva.
    await db.doc('config/ops').set({ paymentMethods: { manual_qr: true },
      paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } } });
    await db.doc('bookings/b3').set({ riderId: 'ana', status: 'pending', estimatedPrice: 50 });
    await db.doc('bookings/b3/payment/state').set({ bookingId: 'b3', riderId: 'ana', paymentStatus: 'awaiting_payment',
      paymentMethod: null, amountDue: 5000, amountPaid: 0, paymentRef: 'REFB3XXX', paymentDeadline: null });
    await adminConfirmPayment({ db }, ACTOR, { bookingId: 'b3', operationNumber: 'OP 900', amountReceived: 50, reason: WHY });
    expect(await reason(collect({ bookingId: 'b2', operationNumber: 'op 900' }))).toBe('operation_already_used');
    expect(await doc('bookings/b2/payment/state')).toMatchObject({ balanceDue: 1250, amountPaid: 10000 });
  });

  it('doble envío: el mismo cobro dos veces a la vez se registra una sola', async () => {
    const [a, b] = await Promise.all([collect(), collect()]);
    expect([a.alreadyRecorded, b.alreadyRecorded].sort()).toEqual([false, true]);
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ balanceDue: 0, amountPaid: 11250 });
    // El cobro y el pendiente cerrado: nada duplicado.
    expect((await ledger()).filter((e) => (e as { status?: string }).status === 'completed')).toHaveLength(1);
    expect((await ledger()).length).toBe(2);
    expect((await db.collection('admin_logs').get()).size).toBe(1);
    // Y después, otra vez: igual.
    await expect(collect()).resolves.toMatchObject({ alreadyRecorded: true });
  });

  it('sin saldo pendiente: rechazado', async () => {
    await db.doc('bookings/b4/payment/state').set({ bookingId: 'b4', riderId: 'ana', paymentStatus: 'paid', amountDue: 100, amountPaid: 100 });
    expect(await reason(collect({ bookingId: 'b4', operationNumber: 'OP 4' }))).toBe('no_balance_due');
  });

  it('por la callable: solo admin', async () => {
    await db.doc('users/ana').set({ role: 'rider', isActive: true });
    let r: string | undefined;
    try {
      await (collectFn as unknown as Runnable).run({
        auth: { uid: 'ana', token: { auth_time: Math.floor(Date.now() / 1000) } }, app: {},
        data: { bookingId: 'b1', amount: 12.5, operationNumber: 'OP 1', method: 'manual_qr', reason: WHY },
      });
    } catch (e) { r = ((e as HttpsError).details as { reason?: string })?.reason; }
    expect(r).toBe('admin_required');
  });
});
