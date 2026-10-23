/**
 * Privacidad de los logs (T6): durante un viaje completo con código de
 * recogida y un SOS con ubicación en vivo, ni el código ni ninguna
 * coordenada aparecen en lo que escriben las funciones.
 */
import { describe, it, expect, beforeAll, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { onBookingStatusChanged } from '../index';
import { advanceBooking, getPickupCode, verifyPickup } from '../trip_flow';
import { cancelIncident, escalateIncidents, raiseIncident } from '../incidents';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const LAT = -17.6448123;
const LNG = -63.1353456;
const captured: string[] = [];

async function clear(): Promise<void> {
  for (const col of ['bookings', 'incidents', 'incidentRateLimits', 'adminAlerts', 'users', 'config']) {
    const snap = await db.collection(col).get();
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
  }
}

beforeAll(async () => {
  await clear();
  for (const m of ['log', 'info', 'warn', 'error'] as const) {
    jest.spyOn(console, m).mockImplementation((...args: unknown[]) => {
      captured.push(args.map((a) => (typeof a === 'string' ? a : JSON.stringify(a))).join(' '));
    });
  }
});
afterAll(async () => { jest.restoreAllMocks(); await clear(); await admin.app().delete(); });

describe('logs sin código de recogida ni ubicaciones', () => {
  it('viaje completo con código y SOS con ubicación: nada sensible en los logs', async () => {
    await db.doc('users/ana').set({ role: 'rider', fcmTokens: ['t1'] });
    await db.doc('users/chofer').set({ role: 'driver', isActive: true });
    await db.doc('users/jefa').set({ role: 'admin', fcmTokens: ['t2'] });
    await db.doc('config/global').set({ arrivalRadiusMeters: 50 });
    const ref = db.doc('bookings/viaje');
    await ref.set({
      riderId: 'ana', driverId: 'chofer', status: 'confirmed', estimatedPrice: 100,
      origin: { address: 'Recogida', coordinates: new admin.firestore.GeoPoint(-17.70, -63.20) },
    });
    const deps = { db, pickupSecret: 'secreto-de-prueba' };
    const loc = { lat: LAT, lng: LNG };
    const step = async (fn: () => Promise<unknown>) => {
      const before = await ref.get();
      await fn();
      await (onBookingStatusChanged as unknown as Runnable).run({ data: { before, after: await ref.get() }, params: { bookingId: 'viaje' } });
    };

    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'driver_arriving' }));
    // Lejos del punto: genera alerta y log de la llegada.
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'driver_arrived', location: loc }));
    const { code } = await getPickupCode(deps, 'ana', { bookingId: 'viaje' });
    const wrong = String((Number(code) + 1) % 10000).padStart(4, '0');
    await verifyPickup(deps, 'chofer', { bookingId: 'viaje', code: wrong, location: loc }).catch(() => undefined);
    await step(() => verifyPickup(deps, 'chofer', { bookingId: 'viaje', code, location: loc }));
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'in_progress' }));

    const incDeps = { db, now: () => Date.now(), push: async () => undefined };
    const { incidentId } = await raiseIncident(incDeps, 'ana', { bookingId: 'viaje', location: loc });
    await escalateIncidents({ ...incDeps, now: () => Date.now() + 10 * 60 * 1000 });
    await cancelIncident(incDeps, 'ana', { incidentId });
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'completed', location: loc }));

    const all = captured.join('\n');
    expect(captured.length).toBeGreaterThan(0);
    expect(all).not.toMatch(new RegExp(`\\b${code}\\b`));
    expect(all).not.toContain(wrong);
    for (const v of [LAT, LNG]) {
      expect(all).not.toContain(String(v));
      expect(all).not.toContain(v.toFixed(4));
    }
  });
});
