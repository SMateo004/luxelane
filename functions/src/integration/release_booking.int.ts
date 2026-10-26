/**
 * B5: el chófer libera una reserva antes de llegar (releaseBooking) contra
 * el emulador: vuelve a pending sin chófer, reaparece en openRequests, alerta
 * a central y sube el contador del chófer, sin sanción automática.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { releaseBooking } from '../cancellation';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const T0 = Date.UTC(2026, 9, 25, 12);
const deps = { db, now: () => T0 };
const HERE = { lat: -17.6448, lng: -63.1353 };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['driverProfiles', 'adminAlerts', 'openRequests', 'bookings']) {
    await db.recursiveDelete(db.collection(col));
  }
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const release = (uid = 'chofer', extra: Record<string, unknown> = {}) =>
  releaseBooking(deps, uid, { bookingId: 'b1', reason: 'vehicle_issue', location: HERE, ...extra });

beforeEach(async () => {
  await clear();
  await db.doc('driverProfiles/chofer').set({ userId: 'chofer', isAvailable: false, online: true, releasedBookingsCount: 2 });
  await db.doc('bookings/b1').set({
    riderId: 'ana', driverId: 'chofer', status: 'driver_arriving', estimatedPrice: 100,
    class: 'business', serviceType: 'transfer', passengerCount: 2,
    origin: { address: 'Calle 1 #23', coordinates: new admin.firestore.GeoPoint(HERE.lat, HERE.lng) },
  });
  await db.doc('bookings/b1/tracking/driver').set({ lat: HERE.lat, lng: HERE.lng });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('releaseBooking', () => {
  it('vuelve a buscar chófer: pending, sin chófer, solicitud abierta, alerta y contador', async () => {
    await expect(release()).resolves.toEqual({ status: 'pending', alreadyReleased: false });
    const b = (await doc('bookings/b1'))!;
    expect(b.status).toBe('pending');
    expect(b).not.toHaveProperty('driverId');
    expect(b.lastRelease).toMatchObject({ driverId: 'chofer', reason: 'vehicle_issue', from: 'driver_arriving' });
    expect(b.releasedBy).toEqual(['chofer']);
    expect(await doc('bookings/b1/tracking/driver')).toBeUndefined();
    // La solicitud abierta no lleva la dirección exacta.
    const req = (await doc('openRequests/b1'))!;
    expect(req).toMatchObject({ vehicleClass: 'business', estimatedPrice: 100, passengerCount: 2 });
    expect(JSON.stringify(req)).not.toContain('Calle 1');
    // Quien la liberó viaja en la solicitud: su app ya no se la ofrece (E18).
    expect(req.releasedBy).toEqual(['chofer']);
    expect(await doc('driverProfiles/chofer')).toMatchObject({ isAvailable: true, releasedBookingsCount: 3 });
    const alerts = (await db.collection('adminAlerts').get()).docs.map((d) => d.data());
    expect(alerts).toEqual([expect.objectContaining({
      type: 'driver_released_booking', bookingId: 'b1', driverId: 'chofer', reason: 'vehicle_issue', resolved: false,
    })]);
    const ev = (await db.collection('bookings/b1/events').get()).docs.map((d) => d.data());
    expect(ev).toEqual([expect.objectContaining({
      from: 'driver_arriving', to: 'pending', method: 'driver_release', releaseReason: 'vehicle_issue', hasLocation: true,
    })]);
  });

  it('repetirlo no duplica alerta ni contador', async () => {
    await release();
    await expect(release()).resolves.toEqual({ status: 'pending', alreadyReleased: true });
    expect((await db.collection('adminAlerts').get()).size).toBe(1);
    expect((await doc('driverProfiles/chofer'))?.releasedBookingsCount).toBe(3);
  });

  it('solo el chófer asignado', async () => {
    expect(await reason(release('otro'))).toBe('not_assigned');
    expect((await doc('bookings/b1'))?.driverId).toBe('chofer');
  });

  it.each(['driver_arrived', 'verified', 'in_progress', 'completed', 'cancelled'])('no desde %s', async (status) => {
    await db.doc('bookings/b1').update({ status });
    expect(await reason(release())).toBe('not_releasable');
    expect((await doc('bookings/b1'))?.status).toBe(status);
    expect(await doc('openRequests/b1')).toBeUndefined();
  });

  it('motivo fuera de la lista: rechazado', async () => {
    expect(await reason(release('chofer', { reason: 'me_aburri' }))).not.toBe('ok');
    expect((await doc('bookings/b1'))?.status).toBe('driver_arriving');
  });
});
