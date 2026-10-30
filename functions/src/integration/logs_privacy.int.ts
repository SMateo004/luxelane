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
import { updatePreferences as updatePreferencesFn } from '../index';
import { createBooking } from '../booking_service';
import { randomUUID } from 'crypto';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const LAT = -17.6448123;
const LNG = -63.1353456;
const captured: string[] = [];

async function clear(): Promise<void> {
  for (const col of ['bookings', 'incidents', 'incidentRateLimits', 'adminAlerts', 'users', 'config', 'pricingRules', 'paymentRefs', 'rateLimits']) {
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
    await db.doc('config/ops').set({ arrivalRadiusMeters: 50 });
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

  it('A5: preferencias con nota y lista de música, válidas y rechazadas: ni la nota ni la URL en los logs', async () => {
    captured.length = 0;
    const NOTE = 'Llevo un carrito de bebé gris';
    const URL = 'https://music.example.com/lista/privada-123';
    const BAD_URL = 'https://otro.example.com/lista/privada-456';
    await db.doc('users/ana').set({ role: 'rider', isActive: true });
    await db.doc('pricingRules/business_oneWay').set({
      vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: 50, pricePerKmUsd: 3,
      pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true,
    });
    await db.doc('config/ops').set({
      paymentMethods: { manual_qr: true },
      paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } },
      playlistHosts: ['music.example.com'],
    });
    const call = (data: unknown) => (updatePreferencesFn as unknown as Runnable)
      .run({ auth: { uid: 'ana', token: {} }, data }).catch(() => undefined);
    await call({ note: NOTE, playlistUrl: URL });
    await call({ note: NOTE, playlistUrl: BAD_URL });
    await call({ note: `${NOTE} www.algo.test`, playlistUrl: URL, extra: true });
    // Sin perfil: el update de Firestore falla y el error inesperado va al log.
    await (updatePreferencesFn as unknown as Runnable)
      .run({ auth: { uid: 'nadie', token: {} }, data: { note: NOTE, playlistUrl: URL } }).catch(() => undefined);
    const routesOk = (async () => ({ ok: true, json: async () => ({ routes: [{ distanceMeters: 12000 }] }) })) as unknown as typeof fetch;
    const trip = {
      origin: { name: '', address: 'Calle Exacta 123', lat: -17.7834, lng: -63.1821 },
      destination: { name: '', address: 'Av. Exacta 456', lat: -17.765, lng: -63.196 },
      scheduledAt: Date.now() + 2 * 60 * 60 * 1000, vehicleClass: 'business', serviceType: 'oneWay',
      passengerCount: 1, luggageCount: 0, channel: 'native',
    };
    await createBooking({ db, mapsKey: 'k', fetchFn: routesOk }, 'ana',
      { ...trip, requestId: randomUUID(), preferences: { note: NOTE, playlistUrl: URL } });
    await createBooking({ db, mapsKey: 'k', fetchFn: routesOk }, 'ana',
      { ...trip, requestId: randomUUID(), preferences: { note: NOTE, playlistUrl: BAD_URL } }).catch(() => undefined);

    const all = captured.join('\n');
    expect(captured.length).toBeGreaterThan(0);
    expect(all).not.toContain(NOTE);
    expect(all).not.toContain('carrito');
    expect(all).not.toContain('privada-123');
    expect(all).not.toContain('privada-456');
    expect(all).not.toContain('music.example.com');
  });
});
