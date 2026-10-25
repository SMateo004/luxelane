/**
 * Pasos del viaje desde la recogida contra el emulador de Firestore:
 * advanceBooking, getPickupCode, verifyPickup y adminOverrideVerify, con
 * los handlers reales (el emulador de Functions no corre en el contenedor).
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  advanceBooking,
  adminOverrideVerify,
  getPickupCode,
  TripDeps,
  verifyPickup,
} from '../trip_flow';
import { pickupCode, PICKUP_CODE_TTL_MS } from '../pickup_code';
import {
  advanceBooking as advanceBookingFn,
  adminOverrideVerify as adminOverrideVerifyFn,
  getPickupCode as getPickupCodeFn,
} from '../index';

const db = admin.firestore();
const SECRET = 'secreto-de-prueba';
let clock = Date.UTC(2026, 9, 20, 15, 0, 0);
const deps = (over: Partial<TripDeps> = {}): TripDeps => ({ db, pickupSecret: SECRET, now: () => clock, ...over });

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

async function failure(p: Promise<unknown>): Promise<{ code: string; reason?: string; details?: Record<string, unknown> }> {
  try {
    await p;
  } catch (e) {
    const err = e as HttpsError;
    const details = err.details as Record<string, unknown> | undefined;
    return { code: err.code, reason: details?.reason as string | undefined, details };
  }
  throw new Error('se esperaba un error');
}

const PICKUP = { lat: -17.6448, lng: -63.1353 };
const NEAR = { lat: -17.6450, lng: -63.1355 };
const FAR = { lat: -17.70, lng: -63.20 };

async function clear(): Promise<void> {
  const bookings = await db.collection('bookings').get();
  for (const b of bookings.docs) await db.recursiveDelete(b.ref);
  for (const col of ['adminAlerts', 'admin_logs', 'users', 'config']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

async function booking(id: string, status: string, extra: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana',
    driverId: 'chofer',
    status,
    estimatedPrice: 100,
    origin: { address: 'Aeropuerto', coordinates: new admin.firestore.GeoPoint(PICKUP.lat, PICKUP.lng) },
    ...extra,
  });
}

const status = async (id: string) => (await db.doc(`bookings/${id}`).get()).data()?.status;
const events = async (id: string) =>
  (await db.collection(`bookings/${id}/events`).orderBy('at').get()).docs
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    .map((d) => ({ id: d.id, ...d.data() }) as Record<string, any>);
/** Lo que solo ve el admin de un evento (eventDetails). */
const detail = async (bookingId: string, eventId: string) =>
  (await db.doc(`bookings/${bookingId}/eventDetails/${eventId}`).get()).data() ?? {};
/** Campos que pasajero y chófer no deben ver en los eventos (A8.7). */
const ADMIN_ONLY = ['reason', 'farFromPickup', 'arrivalCheck'];
const alerts = async () => (await db.collection('adminAlerts').get()).docs.map((d) => d.data());

/** Código que ve el pasajero (por la callable, como en la app). */
const codeFor = async (id: string) => (await getPickupCode(deps(), 'ana', { bookingId: id })).code;
const wrong = (code: string) => String((Number(code) + 1) % 10000).padStart(4, '0');

beforeEach(async () => {
  clock = Date.UTC(2026, 9, 20, 15, 0, 0);
  await clear();
  await db.doc('users/ana').set({ role: 'rider' });
  await db.doc('users/beto').set({ role: 'rider' });
  await db.doc('users/chofer').set({ role: 'driver', isActive: true });
  await db.doc('users/otro').set({ role: 'driver', isActive: true });
  await db.doc('users/jefa').set({ role: 'admin' });
  await db.doc('config/ops').set({ arrivalRadiusMeters: 300 });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('grafo completo', () => {
  it('confirmed → driver_arriving → driver_arrived → verified → in_progress → completed, con un evento por paso', async () => {
    await booking('b1', 'confirmed');
    const v = { appVersion: '2.0.0' };
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arriving', ...v });
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived', location: NEAR, ...v });
    const code = await codeFor('b1');
    expect(await verifyPickup(deps(), 'chofer', { bookingId: 'b1', code, location: NEAR, ...v }))
      .toEqual({ status: 'verified', alreadyVerified: false });
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'in_progress', ...v });
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'completed', location: NEAR, ...v });
    expect(await status('b1')).toBe('completed');

    const evs = await events('b1');
    expect(evs.map((e) => `${e.from}→${e.to}`)).toEqual([
      'confirmed→driver_arriving',
      'driver_arriving→driver_arrived',
      'driver_arrived→verified',
      'verified→in_progress',
      'in_progress→completed',
    ]);
    for (const e of evs) {
      expect(e).toMatchObject({ actor: { uid: 'chofer', role: 'driver' }, source: 'driver_app', appVersion: '2.0.0' });
      expect(e.at).toBeInstanceOf(admin.firestore.Timestamp);
    }
    // Ubicación solo en llegada, verificación y fin, y aparte (solo admin).
    expect(evs.map((e) => e.hasLocation)).toEqual([false, true, true, false, true]);
    const locs = await db.collection('bookings/b1/eventLocations').get();
    expect(locs.size).toBe(3);
    expect(evs.every((e) => !('lat' in e))).toBe(true);
    expect(await detail('b1', evs[1].id)).toMatchObject({ arrivalCheck: 'compared', farFromPickup: false });
    for (const e of evs) for (const k of ADMIN_ONLY) expect(e).not.toHaveProperty(k);
  });

  it('el código nunca se guarda: ni en la reserva, ni en los eventos, ni en la sal', async () => {
    await booking('b1', 'driver_arriving');
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived', location: NEAR });
    const code = await codeFor('b1');
    await verifyPickup(deps(), 'chofer', { bookingId: 'b1', code });
    const dump = JSON.stringify([
      (await db.doc('bookings/b1').get()).data(),
      await events('b1'),
      (await db.doc('bookings/b1/private/pickup').get()).data(),
    ]);
    expect(dump).not.toContain(`"${code}"`);
  });
});

describe('saltos y permisos', () => {
  it('driver_arrived → in_progress no se puede: falta verificar', async () => {
    await booking('b1', 'driver_arrived');
    expect(await failure(advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'in_progress' })))
      .toMatchObject({ code: 'failed-precondition', reason: 'invalid_transition' });
    expect(await status('b1')).toBe('driver_arrived');
  });

  it('otros saltos inválidos: confirmed → completed, verified → completed, retroceder', async () => {
    await booking('c', 'confirmed');
    await booking('v', 'verified');
    await booking('p', 'in_progress');
    for (const [id, to] of [['c', 'completed'], ['v', 'completed'], ['p', 'driver_arrived']]) {
      expect((await failure(advanceBooking(deps(), 'chofer', { bookingId: id, to }))).reason).toBe('invalid_transition');
    }
  });

  it('advanceBooking no lleva a verified: solo verifyPickup o el admin', async () => {
    await booking('b1', 'driver_arrived');
    expect((await failure(advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'verified' }))).reason)
      .toBe('invalid_request');
  });

  it('un chófer no asignado no avanza ni verifica', async () => {
    await booking('b1', 'confirmed');
    await booking('b2', 'driver_arrived');
    expect(await failure(advanceBooking(deps(), 'otro', { bookingId: 'b1', to: 'driver_arriving' })))
      .toMatchObject({ code: 'permission-denied', reason: 'not_assigned' });
    expect(await failure(verifyPickup(deps(), 'otro', { bookingId: 'b2', code: '0000' })))
      .toMatchObject({ code: 'permission-denied', reason: 'not_assigned' });
    expect(await status('b1')).toBe('confirmed');
  });

  it('un pasajero, un chófer bloqueado o alguien sin sesión no avanzan', async () => {
    await booking('b1', 'confirmed');
    await db.doc('users/chofer').update({ isActive: false });
    expect((await failure(advanceBooking(deps(), 'ana', { bookingId: 'b1', to: 'driver_arriving' }))).reason).toBe('inactive_driver');
    expect((await failure(advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arriving' }))).reason).toBe('inactive_driver');
    expect((await failure(advanceBooking(deps(), undefined, { bookingId: 'b1', to: 'driver_arriving' }))).code).toBe('unauthenticated');
  });

  it('doble envío de advanceBooking: un solo cambio y un solo evento', async () => {
    await booking('b1', 'confirmed');
    const req = { bookingId: 'b1', to: 'driver_arriving' };
    const [a, b] = await Promise.all([
      advanceBooking(deps(), 'chofer', req),
      advanceBooking(deps(), 'chofer', req),
    ]);
    expect([a.alreadyApplied, b.alreadyApplied].sort()).toEqual([false, true]);
    expect(await advanceBooking(deps(), 'chofer', req)).toEqual({ status: 'driver_arriving', alreadyApplied: true });
    expect(await events('b1')).toHaveLength(1);
  });

  it('entrada con campos desconocidos o mal formada', async () => {
    await booking('b1', 'confirmed');
    for (const data of [
      { bookingId: 'b1', to: 'driver_arriving', status: 'completed' },
      { bookingId: 'b1', to: 'driver_arriving', location: { lat: 200, lng: 0 } },
      { bookingId: '', to: 'driver_arriving' },
      { bookingId: 'b1' },
    ]) {
      expect((await failure(advanceBooking(deps(), 'chofer', data))).reason).toBe('invalid_request');
    }
  });

  it('app del chófer más vieja que minDriverAppVersion: app_update_required', async () => {
    await booking('b1', 'confirmed');
    await db.doc('config/global').set({ minDriverAppVersion: '2.0.0', androidStoreUrl: 'https://example.com/app' });
    expect(await failure(advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arriving', appVersion: '1.9.0' })))
      .toMatchObject({ code: 'failed-precondition', reason: 'app_update_required' });
    expect((await failure(verifyPickup(deps(), 'chofer', { bookingId: 'b1', code: '0000' }))).reason).toBe('app_update_required');
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arriving', appVersion: '2.0.0' });
    expect(await status('b1')).toBe('driver_arriving');
  });
});

describe('llegada: distancia al punto de recogida', () => {
  it('lejos: no bloquea, marca farFromPickup y crea una alerta', async () => {
    await booking('b1', 'driver_arriving');
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived', location: FAR });
    expect(await status('b1')).toBe('driver_arrived');
    const [e] = await events('b1');
    expect(await detail('b1', e.id)).toMatchObject({ farFromPickup: true, arrivalCheck: 'compared' });
    for (const k of ADMIN_ONLY) expect(e).not.toHaveProperty(k);
    const loc = (await db.doc(`bookings/b1/eventLocations/${e.id}`).get()).data()!;
    expect(loc.distanceMeters).toBeGreaterThan(300);
    expect(await alerts()).toEqual([expect.objectContaining({ type: 'far_from_pickup', bookingId: 'b1', resolved: false })]);
  });

  it('sin arrivalRadiusMeters no compara y lo anota', async () => {
    await db.doc('config/ops').set({});
    await booking('b1', 'driver_arriving');
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived', location: FAR });
    const [e] = await events('b1');
    expect(await detail('b1', e.id)).toMatchObject({ arrivalCheck: 'no_radius' });
    expect(await alerts()).toEqual([]);
  });

  it('sin ubicación del chófer lo anota y avisa (severidad baja)', async () => {
    await booking('b1', 'driver_arriving');
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived' });
    const [e] = await events('b1');
    expect(e).toMatchObject({ hasLocation: false });
    expect(await detail('b1', e.id)).toMatchObject({ arrivalCheck: 'no_location' });
    expect(await alerts()).toEqual([expect.objectContaining({
      type: 'arrival_without_location', severity: 'low', bookingId: 'b1', resolved: false,
    })]);
  });

  it('sin ubicación avisa aunque no haya radio configurado', async () => {
    await db.doc('config/ops').set({});
    await booking('b1', 'driver_arriving');
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived' });
    expect((await alerts()).map((a) => a.type)).toEqual(['arrival_without_location']);
  });
});

describe('código de recogida', () => {
  beforeEach(async () => {
    await booking('b1', 'driver_arriving');
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived', location: NEAR });
  });

  it('el pasajero lo obtiene; es el HMAC de su reserva y su sal', async () => {
    const res = await getPickupCode(deps(), 'ana', { bookingId: 'b1' });
    const salt = (await db.doc('bookings/b1/private/pickup').get()).data()!.salt;
    expect(res.code).toBe(pickupCode(SECRET, 'b1', salt));
    expect(res.expiresAt).toBe(clock + PICKUP_CODE_TTL_MS);
  });

  it('correcto: verifica', async () => {
    await verifyPickup(deps(), 'chofer', { bookingId: 'b1', code: await codeFor('b1') });
    expect(await status('b1')).toBe('verified');
  });

  it('incorrecto: sigue en driver_arrived y dice cuántos intentos quedan', async () => {
    const code = await codeFor('b1');
    expect(await failure(verifyPickup(deps(), 'chofer', { bookingId: 'b1', code: wrong(code) })))
      .toMatchObject({ code: 'failed-precondition', reason: 'wrong_code', details: expect.objectContaining({ attemptsLeft: 4 }) });
    expect(await status('b1')).toBe('driver_arrived');
  });

  it('5.º intento fallido: bloquea, crea alerta y ni el código correcto verifica', async () => {
    const code = await codeFor('b1');
    for (let i = 1; i <= 4; i++) {
      expect((await failure(verifyPickup(deps(), 'chofer', { bookingId: 'b1', code: wrong(code) }))).details?.attemptsLeft).toBe(5 - i);
    }
    expect((await failure(verifyPickup(deps(), 'chofer', { bookingId: 'b1', code: wrong(code) }))).reason).toBe('pickup_locked');
    const b = (await db.doc('bookings/b1').get()).data()!;
    expect(b).toMatchObject({ status: 'driver_arrived', pickupLocked: true });
    expect((await failure(verifyPickup(deps(), 'chofer', { bookingId: 'b1', code }))).reason).toBe('pickup_locked');
    expect((await failure(getPickupCode(deps(), 'ana', { bookingId: 'b1' }))).reason).toBe('pickup_locked');
    expect(await alerts()).toEqual([expect.objectContaining({ type: 'pickup_locked', bookingId: 'b1' })]);
    expect((await events('b1')).filter((e) => e.type === 'pickup_locked')).toHaveLength(1);
  });

  it('vencido a las 4 horas de la llegada', async () => {
    const code = await codeFor('b1');
    clock += PICKUP_CODE_TTL_MS + 1000;
    expect((await failure(verifyPickup(deps(), 'chofer', { bookingId: 'b1', code }))).reason).toBe('code_expired');
    expect((await failure(getPickupCode(deps(), 'ana', { bookingId: 'b1' }))).reason).toBe('code_expired');
    expect(await status('b1')).toBe('driver_arrived');
  });

  it('reintento tras éxito (se perdió la respuesta): misma respuesta, sin otro evento', async () => {
    const code = await codeFor('b1');
    await verifyPickup(deps(), 'chofer', { bookingId: 'b1', code });
    expect(await verifyPickup(deps(), 'chofer', { bookingId: 'b1', code })).toEqual({ status: 'verified', alreadyVerified: true });
    expect((await events('b1')).filter((e) => e.to === 'verified')).toHaveLength(1);
  });

  it('getPickupCode fuera de driver_arrived o para otro usuario', async () => {
    await booking('b2', 'driver_arriving');
    expect(await failure(getPickupCode(deps(), 'ana', { bookingId: 'b2' })))
      .toMatchObject({ code: 'failed-precondition', reason: 'not_at_pickup' });
    expect(await failure(getPickupCode(deps(), 'beto', { bookingId: 'b1' })))
      .toMatchObject({ code: 'permission-denied', reason: 'not_your_booking' });
    expect((await failure(getPickupCode(deps(), 'chofer', { bookingId: 'b1' }))).reason).toBe('not_your_booking');
    expect((await failure(getPickupCode(deps(), 'ana', { bookingId: 'no-existe' }))).reason).toBe('not_your_booking');
    expect((await failure(getPickupCode(deps(), undefined, { bookingId: 'b1' }))).code).toBe('unauthenticated');
  });

  it('una reserva que llegó sin advanceBooking (panel o antes del cambio) recibe su sal', async () => {
    await booking('vieja', 'driver_arrived');
    const code = await codeFor('vieja');
    await verifyPickup(deps(), 'chofer', { bookingId: 'vieja', code });
    expect(await status('vieja')).toBe('verified');
  });
});

describe('servicio por horas y reservas para un tercero: nadie queda varado', () => {
  async function fullTrip(id: string) {
    await advanceBooking(deps(), 'chofer', { bookingId: id, to: 'driver_arriving' });
    await advanceBooking(deps(), 'chofer', { bookingId: id, to: 'driver_arrived', location: NEAR });
    // El titular (ana) recibe el código y lo comparte; el chófer lo escribe.
    const code = await codeFor(id);
    await verifyPickup(deps(), 'chofer', { bookingId: id, code, location: NEAR });
    await advanceBooking(deps(), 'chofer', { bookingId: id, to: 'in_progress' });
    await advanceBooking(deps(), 'chofer', { bookingId: id, to: 'completed', location: NEAR });
    return status(id);
  }

  it('por horas (sin destino): mismo grafo hasta completed', async () => {
    await booking('horas', 'confirmed', { serviceType: 'byTheHour', hours: 3 });
    expect(await fullTrip('horas')).toBe('completed');
  });

  it('para un tercero: el código lo recibe el titular y el viaje se completa', async () => {
    await booking('tercero', 'confirmed', { guest: { firstName: 'Carla', lastName: 'Tercero', phone: '+000' } });
    expect(await fullTrip('tercero')).toBe('completed');
  });

  it('para un tercero sin el titular a mano: el admin fuerza la verificación y el viaje sigue', async () => {
    await booking('tercero2', 'driver_arrived', { guest: { firstName: 'Carla' } });
    await adminOverrideVerify(deps(), { adminId: 'jefa', adminEmail: null }, {
      bookingId: 'tercero2', reason: 'El titular no responde; invitada identificada por central',
    });
    await advanceBooking(deps(), 'chofer', { bookingId: 'tercero2', to: 'in_progress' });
    await advanceBooking(deps(), 'chofer', { bookingId: 'tercero2', to: 'completed' });
    expect(await status('tercero2')).toBe('completed');
  });
});

describe('falta del secreto PICKUP_CODE_SECRET (falla cerrado)', () => {
  it('sin secreto no hay código ni verificación', async () => {
    await booking('b1', 'driver_arrived');
    expect(await failure(getPickupCode(deps({ pickupSecret: '' }), 'ana', { bookingId: 'b1' })))
      .toMatchObject({ code: 'failed-precondition', reason: 'pickup_unavailable' });
    expect((await failure(verifyPickup(deps({ pickupSecret: undefined }), 'chofer', { bookingId: 'b1', code: '0000' }))).reason)
      .toBe('pickup_unavailable');
    expect(await status('b1')).toBe('driver_arrived');
  });

  it('la callable desplegada lee el secreto de Secret Manager; sin él, falla cerrado', async () => {
    delete process.env.PICKUP_CODE_SECRET;
    await booking('b1', 'driver_arrived');
    expect((await failure((getPickupCodeFn as unknown as Runnable).run({ auth: { uid: 'ana' }, data: { bookingId: 'b1' } }))).reason)
      .toBe('pickup_unavailable');
    process.env.PICKUP_CODE_SECRET = SECRET;
    const res = await (getPickupCodeFn as unknown as Runnable).run({ auth: { uid: 'ana' }, data: { bookingId: 'b1' } });
    expect(res.code).toMatch(/^\d{4}$/);
    delete process.env.PICKUP_CODE_SECRET;
  });

  it('advanceBooking desplegada no necesita el secreto', async () => {
    await booking('b1', 'confirmed');
    await (advanceBookingFn as unknown as Runnable).run({ auth: { uid: 'chofer' }, data: { bookingId: 'b1', to: 'driver_arriving' } });
    expect(await status('b1')).toBe('driver_arriving');
  });
});

describe('adminOverrideVerify', () => {
  const actor = { adminId: 'jefa', adminEmail: 'jefa@example.com' };

  it('con motivo: verifica, deja evento con motivo, alerta y auditoría', async () => {
    await booking('b1', 'driver_arrived', { pickupLocked: true });
    await adminOverrideVerify(deps(), actor, { bookingId: 'b1', reason: 'Pasajero sin batería, confirmado por teléfono' });
    expect(await status('b1')).toBe('verified');
    const [e] = await events('b1');
    expect(e).toMatchObject({
      from: 'driver_arrived', to: 'verified', source: 'admin', method: 'admin_override',
      actor: { uid: 'jefa', role: 'admin' },
    });
    // El motivo solo lo ve central: no está en el evento que leen pasajero y chófer.
    expect(e).not.toHaveProperty('reason');
    expect(await detail('b1', e.id)).toMatchObject({ reason: 'Pasajero sin batería, confirmado por teléfono' });
    expect(await alerts()).toEqual([expect.objectContaining({ type: 'pickup_override', bookingId: 'b1' })]);
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({ adminId: 'jefa', action: 'override_verify', targetId: 'b1' })]);
    // Después, el chófer inicia el viaje normalmente.
    await advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'in_progress' });
    expect(await status('b1')).toBe('in_progress');
  });

  it('la callable solo la usa un admin', async () => {
    await booking('b1', 'driver_arrived');
    const run = (uid: string) => (adminOverrideVerifyFn as unknown as Runnable)
      .run({ auth: { uid, token: { auth_time: Math.floor(Date.now() / 1000) } }, data: { bookingId: 'b1', reason: 'Motivo suficiente' } });
    expect((await failure(run('chofer'))).code).toBe('permission-denied');
    expect((await failure(run('ana'))).code).toBe('permission-denied');
    expect(await status('b1')).toBe('driver_arrived');
    await run('jefa');
    expect(await status('b1')).toBe('verified');
  });

  it('sin motivo (o vacío) no hace nada', async () => {
    await booking('b1', 'driver_arrived');
    for (const data of [{ bookingId: 'b1' }, { bookingId: 'b1', reason: '   ' }, { bookingId: 'b1', reason: 'ok' }]) {
      expect((await failure(adminOverrideVerify(deps(), actor, data))).reason).toBe('invalid_request');
    }
    expect(await status('b1')).toBe('driver_arrived');
    expect(await events('b1')).toEqual([]);
  });

  it('solo en driver_arrived; repetirlo no duplica', async () => {
    await booking('b1', 'driver_arriving');
    expect((await failure(adminOverrideVerify(deps(), actor, { bookingId: 'b1', reason: 'Motivo suficiente' }))).reason)
      .toBe('not_at_pickup');
    await booking('b2', 'driver_arrived');
    await adminOverrideVerify(deps(), actor, { bookingId: 'b2', reason: 'Motivo suficiente' });
    expect(await adminOverrideVerify(deps(), actor, { bookingId: 'b2', reason: 'Motivo suficiente' }))
      .toEqual({ status: 'verified', alreadyVerified: true });
    expect(await events('b2')).toHaveLength(1);
  });
});

