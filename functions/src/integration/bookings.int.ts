/**
 * createBooking, quoteBooking y los triggers de reservas, con los handlers
 * reales contra el emulador de Firestore (el emulador de Functions no puede
 * registrar triggers detrás del proxy de este entorno; ver README).
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';

// Stripe falso: se comprueba qué importe pediría cobrar createPaymentIntent.
const createIntent = jest.fn(async (_p: { amount: number }) => ({ id: 'pi_test', clientSecret: 'secret' }));
const captureIntent = jest.fn(async (_id: string, _amount: number) => ({ status: 'succeeded', amount_received: 0 }));
jest.mock('../stripe_service', () => ({
  STRIPE_SECRET_KEY: { value: () => 'sk_test_falsa' },
  createIntent: (p: { amount: number }) => createIntent(p),
  captureIntent: (id: string, amount: number) => captureIntent(id, amount),
}));

import { randomUUID } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { capturePayment, closeOpenRequest, createBooking as createBookingFn, createPaymentIntent, onBookingCreated } from '../index';
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
  requestId: randomUUID(),
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
  captureIntent.mockClear();
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
    // createPaymentIntent no acepta importes del cliente (campo desconocido)
    // y cobra el precio del servidor.
    expect((await reason((createPaymentIntent as unknown as Runnable)
      .run({ auth: { uid: 'ana' }, data: { bookingId, amount: 1, estimatedPrice: 1 } }))).reason).toBe('invalid_request');
    expect(createIntent).not.toHaveBeenCalled();
    // Tarjeta activada en config/ops (A2); sin eso, method_disabled.
    await db.doc('config/ops').set({ paymentMethods: { card: true }, paymentInstructions: { card: { provider: 'stripe' } } });
    await (createPaymentIntent as unknown as Runnable).run({ auth: { uid: 'ana' }, data: { bookingId } });
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

});

describe('capturePayment', () => {
  it('rechaza un intent que no es el de la reserva y no llama a Stripe', async () => {
    await db.doc('bookings/b-captura').set({
      riderId: 'ana', status: 'completed', estimatedPrice: 86, stripePaymentIntentId: 'pi_propio',
    });
    const run = (data: unknown) => (capturePayment as unknown as Runnable).run({ auth: { uid: 'ana' }, data });
    expect((await reason(run({ bookingId: 'b-captura', stripePaymentIntentId: 'pi_ajeno' }))).code)
      .toBe('permission-denied');
    expect((await reason(run({ bookingId: 'b-captura', stripePaymentIntentId: 'pi_propio', amount: 1 }))).reason)
      .toBe('invalid_request');
    expect(captureIntent).not.toHaveBeenCalled();
  });

  it('si Stripe falla, ni la respuesta ni el log llevan la clave, el correo o las coordenadas', async () => {
    const leaky = 'Invalid API Key provided: sk_test_51FalsaClave000 (pasajera.prueba@example.com, -17.7834, -63.1821)';
    captureIntent.mockRejectedValueOnce(new Error(leaky));
    await db.doc('bookings/b-fallo').set({
      riderId: 'ana', status: 'completed', estimatedPrice: 86, stripePaymentIntentId: 'pi_propio',
    });
    const lines: string[] = [];
    for (const m of ['log', 'warn', 'error'] as const) {
      jest.spyOn(console, m).mockImplementation((...a: unknown[]) => { lines.push(a.map(String).join(' ')); });
    }
    let caught: HttpsError | undefined;
    try {
      await (capturePayment as unknown as Runnable)
        .run({ auth: { uid: 'ana' }, data: { bookingId: 'b-fallo', stripePaymentIntentId: 'pi_propio' } });
    } catch (e) {
      caught = e as HttpsError;
    } finally {
      jest.restoreAllMocks();
    }
    expect(captureIntent).toHaveBeenCalledTimes(1);
    expect(caught?.code).toBe('internal');
    expect(caught?.details).toEqual({ code: 'internal', reason: 'payment_failed' });
    const seen = JSON.stringify({ message: caught?.message, details: caught?.details }) + '\n' + lines.join('\n');
    for (const s of ['sk_test_51FalsaClave000', 'pasajera.prueba@example.com', '-17.7834', '-63.1821']) {
      expect(seen).not.toContain(s);
    }
    expect(lines.join('\n')).toContain('[stripe-key]');
  });
});

describe('createBooking: idempotencia por requestId', () => {
  it('doble envío simultáneo de la misma solicitud: una sola reserva, misma respuesta', async () => {
    const same = trip();
    const [a, b] = await Promise.all([createBooking(deps(), 'ana', same), createBooking(deps(), 'ana', same)]);
    expect(a).toEqual(b);
    expect(await count('bookings')).toBe(1);
    expect(await count('openRequests')).toBe(1);
  });

  it('reintento tras perder la respuesta: devuelve la reserva ya creada sin recalcular', async () => {
    const same = trip();
    const first = await createBooking(deps(), 'ana', same);
    // Aunque ahora la ruta falle, el reintento no vuelve a calcular nada.
    const retry = await createBooking(deps({ fetchFn: routesDown }), 'ana', same);
    expect(retry).toEqual(first);
    expect(await count('bookings')).toBe(1);
  });

  it('reintento tras un fallo: el primer intento no dejó nada y el segundo crea una reserva', async () => {
    const same = trip();
    expect(await reason(createBooking(deps({ fetchFn: routesDown }), 'ana', same)))
      .toMatchObject({ reason: 'pricing_unavailable' });
    await createBooking(deps(), 'ana', same);
    expect(await count('bookings')).toBe(1);
  });

  it('price_changed y reintento con el mismo requestId y el precio nuevo', async () => {
    const same = trip({ quotedPrice: 40 });
    expect(await reason(createBooking(deps(), 'ana', same))).toMatchObject({ reason: 'price_changed', price: 86 });
    const { price } = await createBooking(deps(), 'ana', { ...same, quotedPrice: 86 });
    expect(price).toBe(86);
    expect(await count('bookings')).toBe(1);
  });

  it('requestId de otro pasajero: se rechaza sin revelar la reserva', async () => {
    const same = trip();
    await createBooking(deps(), 'ana', same);
    await db.doc('users/beto').set({ role: 'rider', isActive: true });
    const err = await reason(createBooking(deps(), 'beto', same));
    expect(err).toEqual({ code: 'invalid-argument', reason: 'invalid_request', price: undefined });
    expect(await count('bookings')).toBe(1);
  });

  it('formato inválido o ausente: se rechaza', async () => {
    for (const requestId of ['no-es-un-uuid', '3f2b1c9e-8d7a-1b6c-9e5f-1a2b3c4d5e6f', '', undefined]) {
      expect(await reason(createBooking(deps(), 'ana', trip({ requestId }))))
        .toMatchObject({ code: 'invalid-argument', reason: 'invalid_request' });
    }
    expect(await count('bookings')).toBe(0);
  });
});

describe('versión mínima de la app (config/global.minAppVersion)', () => {
  beforeEach(async () => {
    await db.doc('config/global').set({ minAppVersion: '1.2.0', androidStoreUrl: 'https://play.example/luxelane' });
  });

  it('versión menor: app_update_required al cotizar y al reservar, sin crear nada', async () => {
    const { guest: _g, notes: _n, passengerCount: _p, luggageCount: _l, requestId: _r, ...q } = trip();
    const quote = await reason(quoteBooking(deps(), 'ana', { ...q, appVersion: '1.1.9' }));
    expect(quote).toMatchObject({ code: 'failed-precondition', reason: 'app_update_required' });
    expect(await reason(createBooking(deps(), 'ana', trip({ appVersion: '1.1.9' }))))
      .toMatchObject({ reason: 'app_update_required' });
    expect(await count('bookings')).toBe(0);
  });

  it('sin versión con el mínimo activo: app_update_required', async () => {
    expect(await reason(createBooking(deps(), 'ana', trip())))
      .toMatchObject({ reason: 'app_update_required' });
  });

  it('versión igual o mayor: reserva normal', async () => {
    await createBooking(deps(), 'ana', trip({ appVersion: '1.2.0' }));
    await createBooking(deps(), 'ana', trip({ appVersion: '1.3.0+12' }));
    expect(await count('bookings')).toBe(2);
  });
});

describe('quoteBooking', () => {
  it('devuelve precio y desglose sin crear nada', async () => {
    const { guest: _g, notes: _n, passengerCount: _p, luggageCount: _l, requestId: _r, ...q } = trip();
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
