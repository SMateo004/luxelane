/**
 * deleteAccount (preferencias, B0): borra las copias de preferencias de las
 * reservas del usuario (bookings/{id}/driverView/preferences) y deja
 * intactas las de los demás; las reservas se conservan.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const deleteUser = jest.fn(async (_uid: string) => undefined);
jest.spyOn(admin, 'auth').mockReturnValue({ deleteUser } as unknown as admin.auth.Auth);

import { deleteAccount } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

const VIEW = { conversation: 'quiet', note: 'Llevo un carrito', playlistUrl: null, needs: ['child_seat'] };

async function clear(): Promise<void> {
  await db.recursiveDelete(db.collection('bookings'));
  for (const col of ['users', 'admin_logs', 'vehicles', 'driverProfiles', 'rateLimits']) {
    const snap = await db.collection(col).get();
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
  }
}

beforeEach(async () => {
  deleteUser.mockClear();
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/beto').set({ role: 'rider', isActive: true });
  for (const [id, rider, status] of [['a1', 'ana', 'completed'], ['a2', 'ana', 'cancelled'], ['b1', 'beto', 'completed'],
    ['b2', 'beto', 'confirmed']] as const) {
    await db.doc(`bookings/${id}`).set({ riderId: rider, status, driverId: 'chofer' });
    await db.doc(`bookings/${id}/driverView/preferences`).set({ ...VIEW, riderId: rider, bookingId: id });
  }
});
afterAll(async () => { await clear(); await admin.app().delete(); });

const run = (uid: string) => (deleteAccount as unknown as Runnable).run({
  auth: { uid, token: { auth_time: Math.floor(Date.now() / 1000) } }, data: null,
});

describe('deleteAccount y las preferencias de cada reserva', () => {
  it('borra las copias driverView del usuario y deja las de los demás', async () => {
    expect(await run('ana')).toEqual({ success: true });
    for (const id of ['a1', 'a2']) {
      expect((await db.doc(`bookings/${id}/driverView/preferences`).get()).exists).toBe(false);
      // La reserva se conserva.
      expect((await db.doc(`bookings/${id}`).get()).exists).toBe(true);
    }
    for (const id of ['b1', 'b2']) {
      expect((await db.doc(`bookings/${id}/driverView/preferences`).get()).data()).toMatchObject(VIEW);
    }
    expect(deleteUser).toHaveBeenCalledWith('ana');
  });

  it('sin reservas: elimina la cuenta igual', async () => {
    await db.doc('users/carla').set({ role: 'rider', isActive: true });
    expect(await run('carla')).toEqual({ success: true });
    expect((await db.collection('bookings').get()).size).toBe(4);
  });
});
