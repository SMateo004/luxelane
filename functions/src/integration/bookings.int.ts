/**
 * createBooking, quoteBooking y los triggers de reservas, con los handlers
 * reales contra el emulador de Firestore (el emulador de Functions no puede
 * registrar triggers detrás del proxy de este entorno; ver README).
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';

// Stripe falso: se comprueba qué importe pediría cobrar createPaymentIntent.
const createIntent = jest.fn(async (_p: { amount: number }) => ({ id: 'pi_test', clientSecret: 'secret' }));
jest.mock('../stripe_service', () => ({
  STRIPE_SECRET_KEY: { value: () => 'sk_test_falsa' },
  createIntent: (p: { amount: number }) => createIntent(p),
}));

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { closeOpenRequest, createBooking as createBookingFn, createPaymentIntent, onBookingCreated } from '../index';
import { BookingDeps, createBooking, quoteBooking } from '../booking_service';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (event: any) => Promise<any> };

// Distancia por calles simulada: 12 km.
const routesOk = (async () => ({ ok: true, json: async () => ({ routes: [{ distanceMeters: 12000 }] }) })) as unknown as typeof fetch;
const routesDown = (async () => { throw new Error('sin red'); }) as unknown as typeof fetch;
const deps = (over: Partial<BookingDeps> = {}): BookingDeps => ({ db, mapsKey: 'clave-de-prueba', fetchFn: routesOk, ...over });

// Tarifas de prueba (no son las de negocio).
const RULES = {
  business_oneWay: { vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true },
  business_byTheHour: { vehicleClass: 'business', serviceType: 'byTheHour', basePriceUsd: 0, pricePerKmUsd: 0, pricePerHourUsd: 80, minimumPriceUsd: 160, isActive: true },
};

const SCZ = { name: '', address: 'Calle Exacta 123', lat: -17.7834, lng: -63.1821 };
const EQUIPETROL = { name: 'Equipetrol', address: 'Av. Exacta 456', lat: -17.765, lng: -63.196 };
const LA_PAZ = { name: '', address: 'Plaza Murillo', lat: -16.4958, lng: -68.1336 };

const trip = (over: Record<string, unknown> = {}) => ({
  origin: SCZ,
  destination: EQUIPETROL,
  scheduledAt: Date.now() + 2 * 60 * 60 * 1000,
  vehicleClass: 'business',
  serviceType: 'oneWay',
  passengerCount: 2,
  luggageCount: 1,
  notes: 'Toque el timbre',
  guest: { title: 'Sra.', firstName: 'Carla', phone: '+59170000001', language: 'Español' },
  ...over,
});

async function reason(p: Promise<unknown>): Promise<{ code: string; reason: string; price?: number }> {
  try {
    await p;
  } catch (e) {
    const err = e as HttpsError;
    const details = err.details as { reason: string; price?: number };
    return { code: err.code, reason: details?.reason, price: details?.price };
  }
  throw new Error('se esperaba un error');
}

const count = async (col: string) => (await db.collection(col).get()).size;

async function clear(): Promise<void> {
  for (const col of ['bookings', 'openRequests', 'adminAlerts', 'users', 'pricingRules', 'config']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

beforeEach(async () => {
  await clear();
  createIntent.mockClear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true, stripeCustomerId: 'cus_ana', ridePreferences: { music: 'jazz' } });
  await db.doc('users/ina').set({ role: 'rider', isActive: false });
  await db.doc('users/carlos').set({ role: 'driver', isActive: true });
  for (const [id, r] of Object.entries(RULES)) await db.doc(`pricingRules/${id}`).set(r);
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('createBooking', () => {
  it('reserva válida: reserva y openRequests juntas, con el precio del servidor', async () => {
    const { bookingId, price } = await createBooking(deps(), 'ana', trip());
    expect(price).toBe(86); // 50 + 12 km × 3
    const booking = (await db.doc(`bookings/${bookingId}`).get()).data()!;
    expect(booking).toMatchObject({
      riderId: 'ana', status: 'pending', estimatedPrice: 86, class: 'business',
      pickupArea: 'Santa Cruz de la Sierra', dropoffArea: 'Santa Cruz de la Sierra',
      guest: { firstName: 'Carla' }, notes: 'Toque el timbre', riderPreferences: { music: 'jazz' },
      pricing: { source: 'server', distanceSource: 'routes' },
    });
    expect(typeof booking.pricing.rulesVersion).toBe('string');
    const request = (await db.doc(`openRequests/${bookingId}`).get()).data()!;
    expect(request).toMatchObject({ estimatedPrice: 86, vehicleClass: 'business' });
    for (const secret of ['ana', 'Exacta', 'timbre', 'Carla', 'jazz', '+5917']) {
      expect(JSON.stringify(request)).not.toContain(secret);
    }
  });

  it('quotedPrice menor que el del servidor (precio manipulado): price_changed y no crea nada', async () => {
    expect(await reason(createBooking(deps(), 'ana', trip({ quotedPrice: 40 }))))
      .toEqual({ code: 'failed-precondition', reason: 'price_changed', price: 86 });
    expect(await count('bookings')).toBe(0);
    expect(await count('openRequests')).toBe(0);
  });

  it('quotedPrice mayor se acepta y se guarda el precio del servidor, que es el que se cobra', async () => {
    const { bookingId } = await createBooking(deps(), 'ana', trip({ quotedPrice: 500 }));
    expect((await db.doc(`bookings/${bookingId}`).get()).data()!.estimatedPrice).toBe(86);
    // createPaymentIntent ignora cualquier importe que mande el cliente.
    await (createPaymentIntent as unknown as Runnable).run({ auth: { uid: 'ana' }, data: { bookingId, amount: 1, estimatedPrice: 1 } });
    expect(createIntent).toHaveBeenCalledTimes(1);
    expect(createIntent.mock.calls[0][0]).toMatchObject({ amount: 8600, currency: 'bob' });
  });

  it('por horas: horas enteras con el mínimo de la tarifa', async () => {
    const { price } = await createBooking(deps(), 'ana',
      trip({ serviceType: 'byTheHour', hours: 3, destination: undefined }));
    expect(price).toBe(240);
  });

  it('fuera de zona: destino en otra ciudad', async () => {
    expect(await reason(createBooking(deps(), 'ana', trip({ destination: LA_PAZ }))))
      .toMatchObject({ code: 'invalid-argument', reason: 'out_of_area' });
  });

  it('clase inexistente', async () => {
    expect(await reason(createBooking(deps(), 'ana', trip({ vehicleClass: 'limousine' }))))
      .toMatchObject({ code: 'invalid-argument', reason: 'invalid_request' });
  });

  it('horas no enteras', async () => {
    expect(await reason(createBooking(deps(), 'ana',
      trip({ serviceType: 'byTheHour', hours: 2.5, destination: undefined }))))
      .toMatchObject({ code: 'invalid-argument', reason: 'invalid_hours' });
  });

  it('sin ruta y sin routeFactor: falla cerrada', async () => {
    expect(await reason(createBooking(deps({ fetchFn: routesDown }), 'ana', trip())))
      .toMatchObject({ code: 'failed-precondition', reason: 'pricing_unavailable' });
    expect(await reason(createBooking(deps({ mapsKey: '' }), 'ana', trip())))
      .toMatchObject({ reason: 'pricing_unavailable' });
    expect(await count('bookings')).toBe(0);
  });

  it('sin ruta pero con routeFactor: línea recta × factor y alerta para el admin', async () => {
    await db.doc('config/pricing').set({ routeFactor: 1.4 });
    const { bookingId } = await createBooking(deps({ fetchFn: routesDown }), 'ana', trip());
    const booking = (await db.doc(`bookings/${bookingId}`).get()).data()!;
    expect(booking.pricing.distanceSource).toBe('fallback');
    const alerts = await db.collection('adminAlerts').get();
    expect(alerts.docs.map((d) => d.data())).toEqual([
      expect.objectContaining({ type: 'distance_fallback', bookingId }),
    ]);
  });

  it('sin tarifa en pricingRules: falla cerrada (no usa tarifas de fábrica)', async () => {
    await db.doc('pricingRules/business_oneWay').delete();
    expect(await reason(createBooking(deps(), 'ana', trip())))
      .toMatchObject({ reason: 'pricing_unavailable' });
  });

  it('sin autenticar', async () => {
    expect(await reason(createBooking(deps(), undefined, trip())))
      .toMatchObject({ code: 'unauthenticated' });
    // También a través de la callable real.
    expect(await reason((createBookingFn as unknown as Runnable).run({ data: trip() })))
      .toMatchObject({ code: 'unauthenticated' });
  });

  it('usuario inactivo o que no es pasajero', async () => {
    expect(await reason(createBooking(deps(), 'ina', trip()))).toMatchObject({ code: 'permission-denied', reason: 'inactive_user' });
    expect(await reason(createBooking(deps(), 'carlos', trip()))).toMatchObject({ reason: 'inactive_user' });
  });

  it('guest inválido (con correo, o sin nombre)', async () => {
    expect(await reason(createBooking(deps(), 'ana', trip({ guest: { firstName: 'Carla', email: 'c@example.com' } }))))
      .toMatchObject({ reason: 'invalid_request' });
    expect(await reason(createBooking(deps(), 'ana', trip({ guest: { firstName: '' } }))))
      .toMatchObject({ reason: 'invalid_request' });
  });

  it('sin origen, destino, hora o clase: se rechaza (antes se publicaba vacía)', async () => {
    for (const missing of ['origin', 'destination', 'scheduledAt', 'vehicleClass']) {
      const t = trip();
      delete (t as Record<string, unknown>)[missing];
      expect(await reason(createBooking(deps(), 'ana', t))).toMatchObject({ reason: 'invalid_request' });
    }
    expect(await count('bookings')).toBe(0);
  });

  it('campos que no son del viaje (precio, estado, chófer) se rechazan', async () => {
    for (const extra of [{ estimatedPrice: 1 }, { status: 'confirmed' }, { driverId: 'carlos' }, { pricing: {} }]) {
      expect(await reason(createBooking(deps(), 'ana', trip(extra)))).toMatchObject({ reason: 'invalid_request' });
    }
  });

  it('doble envío rápido de la misma solicitud: hoy crea dos reservas', async () => {
    const same = trip();
    await Promise.all([createBooking(deps(), 'ana', same), createBooking(deps(), 'ana', same)]);
    // Riesgo documentado: sin clave de idempotencia hay dos reservas y dos solicitudes.
    expect(await count('bookings')).toBe(2);
    expect(await count('openRequests')).toBe(2);
  });
});

describe('quoteBooking', () => {
  it('devuelve precio y desglose sin crear nada', async () => {
    const { guest: _g, notes: _n, passengerCount: _p, luggageCount: _l, ...q } = trip();
    const quote = await quoteBooking(deps(), 'ana', q);
    expect(quote).toMatchObject({ price: 86, distanceSource: 'routes', breakdown: { km: 12, perKm: 3, minimumApplied: false } });
    expect(await count('bookings')).toBe(0);
  });
});

describe('triggers', () => {
  it('onBookingCreated ya no crea openRequests, solo avisa', async () => {
    const ref = db.collection('bookings').doc('manual');
    await ref.set({ riderId: 'ana', status: 'pending', estimatedPrice: 100, class: 'business', serviceType: 'oneWay' });
    await (onBookingCreated as unknown as Runnable).run({ data: await ref.get(), params: { bookingId: 'manual' } });
    expect((await db.doc('openRequests/manual').get()).exists).toBe(false);
  });

  for (const status of ['confirmed', 'cancelled']) {
    it(`closeOpenRequest borra la solicitud al pasar a ${status}`, async () => {
      const { bookingId } = await createBooking(deps(), 'ana', trip());
      const ref = db.doc(`bookings/${bookingId}`);
      const before = await ref.get();
      await ref.update({ status });
      await (closeOpenRequest as unknown as Runnable).run({ data: { before, after: await ref.get() }, params: { bookingId } });
      expect((await db.doc(`openRequests/${bookingId}`).get()).exists).toBe(false);
    });
  }
});
