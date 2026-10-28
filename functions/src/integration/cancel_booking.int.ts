/**
 * B2: cancelBooking del pasajero contra el emulador de Firestore. Sustituye
 * a la escritura directa: evento, aviso al chófer, chófer libre, quién y
 * cuándo, e idempotente.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { cancelBooking } from '../cancellation';
import { cancelBooking as cancelBookingFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const NOW = Date.UTC(2026, 9, 25, 12);
const deps = () => ({ db, now: () => NOW });
const cancel = (uid: string, data: Record<string, unknown>) => cancelBooking(deps(), uid, data);

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'config', 'rateLimits', 'adminAlerts']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
async function booking(id: string, status: string, extra: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', status, estimatedPrice: 100, createdAt: admin.firestore.Timestamp.fromMillis(NOW - 3600_000),
    scheduledAt: admin.firestore.Timestamp.fromMillis(NOW + 3600_000), ...extra,
  });
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const events = async (id: string) => (await db.collection(`bookings/${id}/events`).get()).docs.map((d) => d.data());

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/luis').set({ role: 'driver', isActive: true });
  await db.doc('driverProfiles/luis').set({ userId: 'luis', isAvailable: false, online: true, documentsVerified: true });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('cancelBooking (pasajero)', () => {
  it('cancela, deja evento, libera y avisa al chófer, con quién y cuándo', async () => {
    await booking('b1', 'driver_arriving', { driverId: 'luis' });
    await expect(cancel('ana', { bookingId: 'b1', reason: 'changed_plans' }))
      .resolves.toEqual({ status: 'cancelled', cancellationFee: 0, feeBasis: 'no_payment_state', retained: 0, refund: 0 });
    const b = (await doc('bookings/b1'))!;
    expect(b).toMatchObject({ status: 'cancelled', cancelledBy: 'rider', cancellationReason: 'changed_plans' });
    expect((b.cancelledAt as admin.firestore.Timestamp).toMillis()).toBe(NOW);
    expect(await events('b1')).toEqual([expect.objectContaining({
      from: 'driver_arriving', to: 'cancelled', method: 'rider_cancel', actor: { uid: 'ana', role: 'rider' }, source: 'rider_app',
    })]);
    expect((await doc('driverProfiles/luis'))?.isAvailable).toBe(true);
    const n = (await db.collection('users/luis/notifications').get()).docs.map((d) => d.data());
    expect(n).toEqual([expect.objectContaining({ type: 'booking_cancelled_by_rider', bookingId: 'b1', isRead: false })]);
  });

  it.each([['pending'], ['confirmed'], ['driver_arriving'], ['driver_arrived']])('desde %s sí', async (status) => {
    await booking('b1', status);
    expect(await reason(cancel('ana', { bookingId: 'b1' }))).toBe('ok');
  });

  it.each([['verified'], ['in_progress'], ['completed']])('desde %s no, y no escribe nada', async (status) => {
    await booking('b1', status);
    expect(await reason(cancel('ana', { bookingId: 'b1' }))).toBe('not_cancellable');
    expect((await doc('bookings/b1'))?.status).toBe(status);
    expect(await events('b1')).toHaveLength(0);
  });

  it('doble toque: la segunda responde igual y no duplica evento ni aviso', async () => {
    await booking('b1', 'confirmed', { driverId: 'luis' });
    await Promise.all([cancel('ana', { bookingId: 'b1' }), cancel('ana', { bookingId: 'b1' })]);
    await expect(cancel('ana', { bookingId: 'b1' })).resolves.toMatchObject({ status: 'cancelled', alreadyCancelled: true });
    expect(await events('b1')).toHaveLength(1);
    expect((await db.collection('users/luis/notifications').get()).size).toBe(1);
  });

  it('solo el pasajero dueño', async () => {
    await booking('b1', 'confirmed');
    expect(await reason(cancel('luis', { bookingId: 'b1' }))).toBe('not_owner');
  });

  it('dryRun: informa sin escribir', async () => {
    await booking('b1', 'confirmed');
    await expect(cancel('ana', { bookingId: 'b1', dryRun: true }))
      .resolves.toEqual({ status: 'confirmed', dryRun: true, cancellationFee: 0, feeBasis: 'no_payment_state', retained: 0, refund: 0 });
    expect((await doc('bookings/b1'))?.status).toBe('confirmed');
  });

  it('por la callable exportada', async () => {
    await booking('b1', 'pending');
    const r = await (cancelBookingFn as unknown as Runnable).run({ auth: { uid: 'ana', token: {} }, app: {}, data: { bookingId: 'b1' } });
    expect(r).toMatchObject({ status: 'cancelled' });
  });
});

describe('retención con config/ops.cancellationPolicy (pagos, A7)', () => {
  // Porcentajes de PRUEBA, ficticios; los de negocio los pone el responsable.
  const policy = {
    stages: [
      { fromStatus: 'confirmed', percent: 11, graceMinutes: 5 },
      { fromStatus: 'driver_arriving', percent: 37 },
      { fromStatus: 'driver_arrived', percent: 73 },
    ],
    noShowWaitMinutes: 15,
  };
  const paid = (id: string, amountPaid = 9999) => db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentStatus: 'paid', paymentMethod: 'manual_qr', amountDue: amountPaid, amountPaid,
  });
  const state = async (id: string) => (await doc(`bookings/${id}/payment/state`))!;
  const ledger = async () => (await db.collection('payments').get()).docs.map((d) => ({ id: d.id, ...d.data() }));

  beforeEach(async () => { await db.recursiveDelete(db.collection('payments')); });

  it('sin política: 0 %, devolución entera pendiente y el evento lo anota (no_policy)', async () => {
    await booking('b1', 'driver_arrived', { driverId: 'luis' });
    await paid('b1');
    await expect(cancel('ana', { bookingId: 'b1' })).resolves.toMatchObject({ cancellationFee: 0, feeBasis: 'no_policy', refund: 9999 });
    expect(await state('b1')).toMatchObject({ paymentStatus: 'refund_pending', amountRetained: 0, refundDue: 9999, retentionBasis: 'no_policy' });
    expect((await events('b1'))[0]).toMatchObject({ retentionBasis: 'no_policy' });
    expect(await ledger()).toEqual([expect.objectContaining({ id: 'refund_b1', type: 'refund', amount: 9999, status: 'pending' })]);
  });

  it('política inválida: igual que sin política (lo más restrictivo)', async () => {
    await db.doc('config/ops').set({ cancellationPolicy: { feeType: 'percent', feeValue: 10 } });
    await booking('b1', 'driver_arrived', { driverId: 'luis' });
    await paid('b1');
    await expect(cancel('ana', { bookingId: 'b1' })).resolves.toMatchObject({ cancellationFee: 0, feeBasis: 'policy_invalid' });
  });

  it.each([
    ['confirmed', 11, 1099], ['driver_arriving', 37, 3699], ['driver_arrived', 73, 7299],
  ])('desde %s: %i %% de lo pagado, hacia abajo; el resto se devuelve', async (status, _pct, retained) => {
    await db.doc('config/ops').set({ cancellationPolicy: policy });
    await booking('b1', status, { driverId: 'luis' });
    // Entró en la etapa hace 30 min: fuera de cualquier gracia.
    await db.doc('bookings/b1/events/e0').set({ to: status, at: admin.firestore.Timestamp.fromMillis(NOW - 30 * 60_000) });
    await paid('b1');
    const fee = retained / 100;
    await expect(cancel('ana', { bookingId: 'b1', dryRun: true }))
      .resolves.toMatchObject({ dryRun: true, cancellationFee: fee, feeBasis: 'stage', retained, refund: 9999 - retained });
    // Hay que aceptar la retención que se mostró.
    expect(await reason(cancel('ana', { bookingId: 'b1' }))).toBe('cancellation_fee_changed');
    expect((await doc('bookings/b1'))?.status).toBe(status);
    await cancel('ana', { bookingId: 'b1', acceptedFee: fee });
    expect(await state('b1')).toMatchObject({ paymentStatus: 'refund_pending', amountRetained: retained, refundDue: 9999 - retained });
    expect(await ledger()).toEqual(expect.arrayContaining([
      expect.objectContaining({ id: 'fee_b1', type: 'fee_retained', amount: retained, status: 'completed' }),
      expect.objectContaining({ id: 'refund_b1', type: 'refund', amount: 9999 - retained, status: 'pending' }),
    ]));
    // Ni la reserva ni el evento (los lee el chófer) llevan importes.
    const b = (await doc('bookings/b1'))!;
    for (const k of ['cancellationFee', 'amountRetained', 'refundDue']) expect(b).not.toHaveProperty(k);
    const cancelEvent = (await events('b1')).find((e) => e.to === 'cancelled');
    expect(JSON.stringify(cancelEvent)).not.toContain(String(retained));
  });

  it('el porcentaje nunca supera lo pagado (100 %): nada que devolver, refunded', async () => {
    await db.doc('config/ops').set({ cancellationPolicy: { stages: [{ fromStatus: 'driver_arrived', percent: 100 }] } });
    await booking('b1', 'driver_arrived', { driverId: 'luis' });
    await paid('b1', 5000);
    await cancel('ana', { bookingId: 'b1', acceptedFee: 50 });
    expect(await state('b1')).toMatchObject({ paymentStatus: 'refunded', amountRetained: 5000, refundDue: 0 });
    expect((await ledger()).map((e) => e.id)).toEqual(['fee_b1']);
  });

  it('dentro de la gracia de la etapa: 0 %', async () => {
    await db.doc('config/ops').set({ cancellationPolicy: policy });
    await booking('b1', 'confirmed', { driverId: 'luis' });
    await db.doc('bookings/b1/events/e1').set({ to: 'confirmed', at: admin.firestore.Timestamp.fromMillis(NOW - 2 * 60_000) });
    await paid('b1');
    await expect(cancel('ana', { bookingId: 'b1' })).resolves.toMatchObject({ cancellationFee: 0, feeBasis: 'grace', refund: 9999 });
  });

  it('sin chófer asignado: 0 % aunque haya política', async () => {
    await db.doc('config/ops').set({ cancellationPolicy: policy });
    await booking('b1', 'pending');
    await paid('b1');
    await expect(cancel('ana', { bookingId: 'b1' })).resolves.toMatchObject({ feeBasis: 'no_driver', refund: 9999 });
  });

  it('sin pagar: no se retiene ni se devuelve nada; el pedido de pago deja de valer', async () => {
    await db.doc('config/ops').set({ cancellationPolicy: policy });
    await booking('b1', 'pending');
    await db.doc('bookings/b1/payment/state').set({ riderId: 'ana', paymentStatus: 'awaiting_payment', amountDue: 9999, amountPaid: 0 });
    await expect(cancel('ana', { bookingId: 'b1' })).resolves.toMatchObject({ feeBasis: 'not_paid', retained: 0, refund: 0 });
    expect(await state('b1')).toMatchObject({ paymentStatus: 'expired', closedReason: 'cancelled_before_payment' });
    expect(await ledger()).toEqual([]);
  });

  it('el cliente no puede bajar la retención: el importe lo calcula el servidor', async () => {
    await db.doc('config/ops').set({ cancellationPolicy: policy });
    await booking('b1', 'driver_arrived', { driverId: 'luis' });
    await paid('b1');
    expect(await reason(cancel('ana', { bookingId: 'b1', acceptedFee: 1 }))).toBe('cancellation_fee_changed');
    expect(await reason(cancel('ana', { bookingId: 'b1', retained: 0 }))).toBe('invalid_request');
  });
});
