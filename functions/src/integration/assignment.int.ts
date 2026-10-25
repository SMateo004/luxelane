/**
 * assignNearestDriver contra el emulador: un chófer bloqueado (users.isActive
 * false) no se asigna aunque su perfil diga disponible y esté más cerca (H10).
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { assignNearestDriver as assignFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const assign = (bookingId: string) =>
  (assignFn as unknown as Runnable).run({ auth: { uid: 'ana' }, app: {}, data: { bookingId } });

async function clear(): Promise<void> {
  for (const col of ['bookings', 'users', 'driverProfiles', 'vehicles', 'rateLimits', 'config']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

async function driver(uid: string, isActive: boolean, lat: number): Promise<void> {
  await db.doc(`users/${uid}`).set({ role: 'driver', isActive });
  await db.doc(`driverProfiles/${uid}`).set({
    userId: uid, documentsVerified: true, isAvailable: true,
    currentLocation: new admin.firestore.GeoPoint(lat, -63.18),
  });
  await db.doc(`vehicles/v_${uid}`).set({ driverId: uid, class: 'business', isActive: true });
}

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('bookings/b1').set({
    riderId: 'ana', status: 'pending', class: 'business', estimatedPrice: 100,
    origin: { coordinates: new admin.firestore.GeoPoint(-17.78, -63.18) },
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('assignNearestDriver y chóferes bloqueados (H10)', () => {
  it('salta al bloqueado aunque esté más cerca', async () => {
    await driver('bloq', false, -17.781);
    await driver('libre', true, -17.70);
    expect(await assign('b1')).toEqual({ assigned: true, driverId: 'libre' });
    expect((await db.doc('bookings/b1').get()).data()?.driverId).toBe('libre');
    expect((await db.doc('driverProfiles/bloq').get()).data()?.isAvailable).toBe(true);
  });

  it('si solo hay bloqueados, no asigna a nadie', async () => {
    await driver('bloq', false, -17.781);
    expect(await assign('b1')).toEqual({ assigned: false, reason: 'no_drivers_available' });
    expect((await db.doc('bookings/b1').get()).data()?.status).toBe('pending');
  });
});
