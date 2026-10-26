/**
 * assignNearestDriver contra el emulador: un chófer bloqueado (users.isActive
 * false) no se asigna aunque su perfil diga disponible y esté más cerca (H10).
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { assignNearestDriver as assignFn, acceptBooking as acceptFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const assign = (bookingId: string) =>
  (assignFn as unknown as Runnable).run({ auth: { uid: 'ana' }, app: {}, data: { bookingId } });
const accept = (uid: string, bookingId: string) =>
  (acceptFn as unknown as Runnable).run({ auth: { uid, token: {} }, app: {}, data: { bookingId } });

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
  // Pagada: sin pago confirmado no se ofrece a chóferes (pagos, A3).
  await db.doc('bookings/b1/payment/state').set({ riderId: 'ana', paymentStatus: 'paid' });
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

describe('quien liberó la reserva no vuelve a tomarla (0.3)', () => {
  beforeEach(async () => { await db.doc('bookings/b1').update({ releasedBy: ['cerca'] }); });

  it('assignNearestDriver salta al que la liberó aunque esté más cerca', async () => {
    await driver('cerca', true, -17.781);
    await driver('lejos', true, -17.70);
    expect(await assign('b1')).toEqual({ assigned: true, driverId: 'lejos' });
  });

  it('si solo queda el que la liberó, no asigna a nadie', async () => {
    await driver('cerca', true, -17.781);
    expect(await assign('b1')).toEqual({ assigned: false, reason: 'no_drivers_available' });
    expect((await db.doc('bookings/b1').get()).data()?.status).toBe('pending');
  });

  it('acceptBooking lo rechaza y otro chófer sí la acepta', async () => {
    await driver('cerca', true, -17.781);
    await driver('lejos', true, -17.70);
    expect(await accept('cerca', 'b1')).toEqual({ accepted: false, reason: 'released_by_you' });
    expect((await db.doc('bookings/b1').get()).data()?.status).toBe('pending');
    expect(await accept('lejos', 'b1')).toEqual({ accepted: true });
  });
});
