/**
 * Límites de tasa contra el emulador de Firestore: ventana, rechazo,
 * reinicio con reloj simulado, usuarios independientes, fallo del
 * contador (cerrado salvo el SOS) y el cableado en secureCallable.
 */
import { describe, it, expect, beforeEach, afterEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { HttpsError } from 'firebase-functions/v2/https';
import { enforceRateLimit, rateLimit, rateLimiter, RATE_LIMITS } from '../rate_limit';
import { raiseIncident as raiseIncidentFn, resolveAlert as resolveAlertFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const realCheck = rateLimiter.check;

async function failure(p: Promise<unknown>): Promise<{ code: string; reason?: string }> {
  try {
    await p;
  } catch (e) {
    const err = e as HttpsError;
    return { code: err.code, reason: (err.details as { reason?: string } | undefined)?.reason };
  }
  throw new Error('se esperaba un error');
}

async function clear(): Promise<void> {
  for (const col of ['rateLimits', 'bookings', 'incidents', 'incidentRateLimits', 'adminAlerts', 'users']) {
    const snap = await db.collection(col).get();
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
  }
}

beforeEach(async () => { await clear(); rateLimiter.check = realCheck; });
afterEach(() => { rateLimiter.check = realCheck; });
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('rateLimit (contador por transacción)', () => {
  const T0 = Date.UTC(2026, 9, 23, 12, 0, 0);

  it('dentro del límite pasa; el siguiente se rechaza', async () => {
    for (let i = 0; i < 3; i++) {
      expect((await rateLimit(db, 'ana', 'prueba', 3, 60000, T0 + i)).allowed).toBe(true);
    }
    const r = await rateLimit(db, 'ana', 'prueba', 3, 60000, T0 + 10);
    expect(r).toEqual({ allowed: false, remaining: 0, resetAt: T0 + 60000 });
    const doc = (await db.doc('rateLimits/prueba__ana').get()).data()!;
    expect(doc).toMatchObject({ uid: 'ana', key: 'prueba', count: 3 });
    expect((doc.expireAt as admin.firestore.Timestamp).toMillis()).toBe(T0 + 60000);
  });

  it('la ventana se reinicia con el reloj', async () => {
    for (let i = 0; i < 3; i++) await rateLimit(db, 'ana', 'prueba', 3, 60000, T0);
    expect((await rateLimit(db, 'ana', 'prueba', 3, 60000, T0 + 59999)).allowed).toBe(false);
    expect((await rateLimit(db, 'ana', 'prueba', 3, 60000, T0 + 60000)).allowed).toBe(true);
  });

  it('usuarios distintos y claves distintas no se afectan', async () => {
    for (let i = 0; i < 3; i++) await rateLimit(db, 'ana', 'prueba', 3, 60000, T0);
    expect((await rateLimit(db, 'beto', 'prueba', 3, 60000, T0)).allowed).toBe(true);
    expect((await rateLimit(db, 'ana', 'otra', 3, 60000, T0)).allowed).toBe(true);
  });

  it('llamadas simultáneas no superan el límite', async () => {
    const results = await Promise.all(Array.from({ length: 6 }, () => rateLimit(db, 'ana', 'prueba', 3, 60000, T0)));
    expect(results.filter((r) => r.allowed)).toHaveLength(3);
  });
});

describe('enforceRateLimit', () => {
  it('rechaza con resource-exhausted y retryAfterSeconds', async () => {
    const rule = { limit: 1, windowSeconds: 60 };
    await enforceRateLimit(db, 'prueba', 'ana', rule, 1000);
    try {
      await enforceRateLimit(db, 'prueba', 'ana', rule, 2000);
      throw new Error('no rechazó');
    } catch (e) {
      expect(e).toMatchObject({ code: 'resource-exhausted', details: { reason: 'rate_limited', retryAfterSeconds: 59 } });
    }
  });

  it('si el contador falla: cerrado (resource-exhausted) salvo failOpen', async () => {
    rateLimiter.check = async () => { throw new Error('Firestore no disponible'); };
    jest.spyOn(console, 'error').mockImplementation(() => undefined);
    expect(await failure(enforceRateLimit(db, 'prueba', 'ana', { limit: 5, windowSeconds: 60 })))
      .toEqual({ code: 'resource-exhausted', reason: 'rate_limited' });
    await expect(enforceRateLimit(db, 'prueba', 'ana', { limit: 5, windowSeconds: 60, failOpen: true }))
      .resolves.toBeUndefined();
  });
});

describe('cableado en secureCallable', () => {
  it('resolveAlert: con un límite de 2, la tercera llamada se rechaza antes del handler', async () => {
    await db.doc('users/jefa').set({ role: 'admin' });
    const saved = RATE_LIMITS.resolveAlert;
    RATE_LIMITS.resolveAlert = { limit: 2, windowSeconds: 600 };
    try {
      const run = () => (resolveAlertFn as unknown as Runnable).run({ auth: { uid: 'jefa', token: {} }, data: { alertId: 'nada' } });
      expect((await failure(run())).code).toBe('not-found');
      expect((await failure(run())).code).toBe('not-found');
      expect(await failure(run())).toEqual({ code: 'resource-exhausted', reason: 'rate_limited' });
    } finally {
      RATE_LIMITS.resolveAlert = saved;
    }
  });

  it('el fallo del contador no impide el SOS', async () => {
    await db.doc('users/ana').set({ role: 'rider' });
    await db.doc('bookings/b1').set({ riderId: 'ana', driverId: 'chofer', status: 'in_progress' });
    rateLimiter.check = async () => { throw new Error('Firestore no disponible'); };
    jest.spyOn(console, 'error').mockImplementation(() => undefined);
    const res = await (raiseIncidentFn as unknown as Runnable).run({ auth: { uid: 'ana', token: {} }, data: { bookingId: 'b1' } });
    expect(res.status).toBe('open');
    expect((await db.collection('incidents').get()).size).toBe(1);
  });
});
