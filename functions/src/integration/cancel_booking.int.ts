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
      .resolves.toEqual({ status: 'cancelled', cancellationFee: 0 });
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
      .resolves.toEqual({ status: 'confirmed', dryRun: true, cancellationFee: 0 });
    expect((await doc('bookings/b1'))?.status).toBe('confirmed');
  });

  it('por la callable exportada', async () => {
    await booking('b1', 'pending');
    const r = await (cancelBookingFn as unknown as Runnable).run({ auth: { uid: 'ana', token: {} }, app: {}, data: { bookingId: 'b1' } });
    expect(r).toMatchObject({ status: 'cancelled' });
  });
});
