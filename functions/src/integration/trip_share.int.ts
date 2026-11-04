/**
 * Prompt 18, Parte B (A7): viaje compartido contra el emulador. Secreto, sal,
 * límites, márgenes y datos de PRUEBA, ficticios.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminRevokeTripShare as adminRevokeTripShareFn } from '../index';
import {
  adminRevokeTripShare, createTripShare, handleSharedTrip, hashToken, PUBLIC_FIELDS, readSharedTrip, revokeTripShare,
  TRIP_SHARE_MAX_HOURS,
} from '../trip_share';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const SECRET = 'secreto-ficticio-de-prueba';
const SALT = 'sal-ficticia-de-prueba';
const MIN = 60_000;
const T0 = Date.UTC(2026, 10, 20, 15);
let clock = T0;
const deps = () => ({ db, secret: SECRET, now: () => clock });
const JEFA = { adminId: 'jefa', adminEmail: 'jefa@prueba.test' };
const REASON = 'Pedido por el pasajero por teléfono (prueba)';
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'tripShares', 'rateLimits', 'admin_logs', 'adminAlerts']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

/** Reserva FICTICIA de ana con todo lo que NO debe salir en la página. */
async function booking(id: string, status: string, extra: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', driverId: 'luis', status, serviceType: 'oneWay', class: 'business', estimatedPrice: 345,
    finalPrice: 350, scheduledAt: ts(T0 + 30 * MIN), updatedAt: ts(clock),
    origin: { name: 'Casa de Ana (prueba)', address: 'Calle Exacta 123 (prueba)',
      coordinates: new admin.firestore.GeoPoint(-17.6448, -63.1353) },
    destination: { name: 'Oficina (prueba)', address: 'Avenida Exacta 456 (prueba)',
      coordinates: new admin.firestore.GeoPoint(-17.7834, -63.1821) },
    pickupArea: 'Aeropuerto', dropoffArea: 'Santa Cruz de la Sierra',
    notes: 'Toque el timbre (prueba)', guest: { firstName: 'Carla', lastName: 'Tercero', phone: '+59170000001',
      email: 'carla@prueba.test' }, flightNumber: 'ZZ123', flight: { flightNumber: 'ZZ123' },
    preferredDriverLanguages: ['es'],
    driverInfo: { name: 'Luis Pérez Prueba', phone: '+59170000002', photoUrl: null, rating: 4.9,
      vehicle: { make: 'Marca de prueba', model: 'Modelo de prueba', color: 'Negro', plate: 'PRB-123' } },
    ...extra,
  });
  await db.doc(`bookings/${id}/tracking/driver`).set({ lat: -17.7001, lng: -63.1502, updatedAt: ts(clock - MIN) });
}
const post = (token: string, lang = 'es', ip = '203.0.113.7') =>
  handleSharedTrip({ ...deps(), salt: SALT }, { method: 'POST', ip, acceptLanguage: lang, body: { token } });
const view = async (token: string, lang = 'es') => JSON.parse((await post(token, lang)).body);
const UNAVAILABLE = { state: 'unavailable' };

beforeEach(async () => {
  await clear();
  clock = T0;
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/beto').set({ role: 'rider', isActive: true });
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
});
afterAll(async () => { await db.doc('config/security').delete(); await clear(); await admin.app().delete(); });

describe('crear y revocar', () => {
  it('reserva ajena o inexistente: la misma negativa', async () => {
    await booking('b1', 'confirmed');
    expect(await reason(createTripShare(deps(), 'beto', { bookingId: 'b1' }))).toBe('booking_not_found');
    expect(await reason(createTripShare(deps(), 'ana', { bookingId: 'nada' }))).toBe('booking_not_found');
  });

  it.each(['pending', 'driver_arrived', 'completed', 'cancelled', 'no_show'])(
    'estado %s: solo se crea entre confirmed e in_progress', async (status) => {
      await booking('b1', status);
      const r = await reason(createTripShare(deps(), 'ana', { bookingId: 'b1' }));
      expect(r).toBe(status === 'driver_arrived' ? 'ok' : 'share_not_available');
    });

  it('se guarda solo el hash: ningún documento tiene el token', async () => {
    await booking('b1', 'confirmed');
    const { token, path } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    expect(token).toMatch(/^[A-Za-z0-9_-]{22}$/);
    expect(path).toBe(`/t#${token}`);
    const docs = (await db.collection('tripShares').get()).docs;
    expect(docs.map((d) => d.id)).toEqual([hashToken(SECRET, token)]);
    expect(JSON.stringify(docs[0].data())).not.toContain(token);
    expect(JSON.stringify((await db.doc('bookings/b1').get()).data())).not.toContain(token);
  });

  it('un segundo enlace revoca el primero', async () => {
    await booking('b1', 'confirmed');
    const a = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    const b = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    expect(await view(a.token)).toEqual(UNAVAILABLE);
    expect((await view(b.token)).state).toBe('active');
    expect((await db.collection('tripShares').where('active', '==', true).get()).size).toBe(1);
  });

  it('el pasajero lo revoca; un tercero no puede', async () => {
    await booking('b1', 'confirmed');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    expect(await reason(revokeTripShare(deps(), 'beto', { bookingId: 'b1' }))).toBe('booking_not_found');
    expect((await view(token)).state).toBe('active');
    expect(await revokeTripShare(deps(), 'ana', { bookingId: 'b1' })).toEqual({ revoked: 1 });
    expect(await view(token)).toEqual(UNAVAILABLE);
  });

  it('el admin lo revoca con motivo y queda en la auditoría', async () => {
    await booking('b1', 'confirmed');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    expect(await adminRevokeTripShare({ db, now: () => clock }, JEFA, { bookingId: 'b1', reason: REASON }))
      .toEqual({ revoked: 1 });
    expect(await view(token)).toEqual(UNAVAILABLE);
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({ action: 'revoke_trip_share', targetId: 'b1', reason: REASON })]);
    expect(JSON.stringify(logs)).not.toContain(token);
  });

  it('admin sin segundo factor (con mfaEnforced): rechazado', async () => {
    await db.doc('config/security').set({ mfaEnforced: true });
    const NOW_S = Math.floor(Date.now() / 1000);
    const token = { role: 'admin', auth_time: NOW_S, firebase: { sign_in_provider: 'password' } };
    expect(await reason((adminRevokeTripShareFn as unknown as Runnable).run({ auth: { uid: 'jefa', token }, app: {},
      data: { bookingId: 'b1', reason: REASON } }))).toBe('mfa_required');
    await db.doc('config/security').delete();
  });
});

describe('lectura pública', () => {
  it('token adivinado, mal formado o vacío: la misma respuesta que uno revocado', async () => {
    await booking('b1', 'confirmed');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    await revokeTripShare(deps(), 'ana', { bookingId: 'b1' });
    const revoked = await post(token);
    for (const guess of ['AAAAAAAAAAAAAAAAAAAAAA', 'corto', '', '../../etc']) {
      const r = await post(guess);
      expect(r.status).toBe(revoked.status);
      expect(r.body).toBe(revoked.body);
    }
    expect(JSON.parse(revoked.body)).toEqual(UNAVAILABLE);
  });

  it('caduca al llegar a un estado final; con margen de config/ops, al pasar el margen', async () => {
    await booking('b1', 'in_progress');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    await db.doc('bookings/b1').update({ status: 'completed', completedAt: ts(clock) });
    expect(await view(token)).toEqual(UNAVAILABLE);
    await db.doc('config/ops').set({ tripShareGraceMinutes: 10 });
    const v = await view(token);
    expect(v.state).toBe('finished');
    expect(v.position).toBeNull();
    clock += 10 * MIN;
    expect(await view(token)).toEqual(UNAVAILABLE);
  });

  it('tope técnico: pasado TRIP_SHARE_MAX_HOURS deja de servir aunque el viaje siga', async () => {
    await booking('b1', 'confirmed');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    clock += TRIP_SHARE_MAX_HOURS * 60 * MIN;
    expect(await view(token)).toEqual(UNAVAILABLE);
  });

  it('campos uno por uno: la lista cerrada y ningún dato prohibido', async () => {
    await booking('b1', 'driver_arriving');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    const v = await view(token);
    expect(Object.keys(v).sort()).toEqual([...PUBLIC_FIELDS].sort());
    expect(v.state).toBe('active');
    expect(v.status).toBe('El chófer va hacia la recogida');
    expect(v.statusKey).toBe('share.status.arriving');
    expect(v.pickupTime).toBe('11:30');
    expect(v.driverName).toBe('Luis');
    expect(v.vehicle).toEqual({ make: 'Marca de prueba', model: 'Modelo de prueba', color: 'Negro', plate: 'PRB-123' });
    expect(v.pickupArea).toBe('Aeropuerto');
    expect(v.destinationArea).toBe('Santa Cruz de la Sierra');
    expect(v.position).toEqual({ lat: -17.7001, lng: -63.1502, at: '10:59' });
    const text = JSON.stringify(v);
    for (const bad of ['Pérez', '+591', '345', '350', 'timbre', 'ZZ123', 'carla', 'Carla', 'Tercero', 'Exacta', 'Casa',
      'Oficina', 'ana', 'b1', 'luis', '-17.6448', '-17.7834', 'pickupCode', 'payment']) {
      expect(text).not.toContain(bad);
    }
  });

  it('posición solo entre driver_arriving e in_progress', async () => {
    await booking('b1', 'confirmed');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    expect((await view(token)).position).toBeNull();
    for (const status of ['driver_arriving', 'driver_arrived', 'verified', 'in_progress']) {
      await db.doc('bookings/b1').update({ status });
      expect((await view(token)).position).not.toBeNull();
    }
  });

  it('idioma según Accept-Language (es, en, pt; por defecto español)', async () => {
    await booking('b1', 'in_progress');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    expect((await view(token, 'en-US,en;q=0.9')).status).toBe('On the trip');
    expect((await view(token, 'pt-BR')).status).toBe('Em viagem');
    expect((await view(token, 'fr-FR')).status).toBe('En viaje');
    const page = await handleSharedTrip({ ...deps(), salt: SALT }, { method: 'GET', ip: '1.1.1.1', acceptLanguage: 'pt' });
    expect(page.body).toContain('<html lang="pt">');
    expect(page.body).toContain('Acompanhamento da viagem');
  });

  it.each([['es', 'activa JavaScript'], ['en', 'turn on JavaScript'], ['pt', 'ative o JavaScript']])(
    'sin JavaScript (%s): un aviso visible, no una página vacía ni «cargando» eterno', async (lang, text) => {
      const page = await handleSharedTrip({ ...deps(), salt: SALT }, { method: 'GET', ip: '1.1.1.1', acceptLanguage: lang });
      const noscript = /<noscript>([\s\S]*?)<\/noscript>/.exec(page.body)?.[1] ?? '';
      expect(noscript).toContain(text);
      // Lo único visible sin script: el título y ese aviso.
      for (const id of ['loading', 'gone', 'busy', 'trip']) {
        expect(page.body).toMatch(new RegExp(`id="${id}"[^>]*hidden`));
      }
    });

  it('cabeceras: no-store, noindex, no-referrer y CSP estricta con nonce', async () => {
    const page = await handleSharedTrip({ ...deps(), salt: SALT }, { method: 'GET', ip: '1.1.1.1' });
    expect(page.headers).toMatchObject({ 'Cache-Control': 'no-store', 'X-Robots-Tag': 'noindex, nofollow',
      'Referrer-Policy': 'no-referrer', 'X-Frame-Options': 'DENY' });
    const csp = page.headers['Content-Security-Policy'];
    expect(csp).toMatch(/default-src 'none'/);
    expect(csp).toMatch(/script-src 'nonce-[a-f0-9]{32}'/);
    expect(csp).not.toMatch(/unsafe-inline|unsafe-eval|https?:/);
    expect(page.body).not.toMatch(/<script(?![^>]*nonce=)/);
    const api = await post('x');
    expect(api.headers['Cache-Control']).toBe('no-store');
  });

  it('límite de tasa por IP: el siguiente recibe 429; otra IP sigue', async () => {
    const limited = (ip: string) => handleSharedTrip({ ...deps(), salt: SALT, limit: { limit: 2, windowSeconds: 600 } },
      { method: 'POST', ip, body: { token: 'x' } });
    expect((await limited('198.51.100.1')).status).toBe(200);
    expect((await limited('198.51.100.1')).status).toBe(200);
    expect((await limited('198.51.100.1')).status).toBe(429);
    expect((await limited('198.51.100.2')).status).toBe(200);
    // Solo el hash de la IP en el contador.
    expect(JSON.stringify((await db.collection('rateLimits').get()).docs.map((d) => d.data()))).not.toContain('198.51.100');
  });

  it('sin la sal: falla cerrado (503) sin leer nada', async () => {
    const r = await handleSharedTrip({ ...deps(), salt: '' }, { method: 'POST', ip: '1.1.1.1', body: { token: 'x' } });
    expect(r.status).toBe(503);
  });

  it('sin el secreto: ningún token sirve', async () => {
    await booking('b1', 'confirmed');
    const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
    expect(await readSharedTrip({ db, secret: '' }, token, 'es')).toBeNull();
  });
});

describe('registros sin el token', () => {
  it('crear, leer, revocar y la página no escriben el token en los logs', async () => {
    const captured: string[] = [];
    const spies = (['log', 'info', 'warn', 'error'] as const).map((m) =>
      jest.spyOn(console, m).mockImplementation((...args: unknown[]) => {
        captured.push(args.map((a) => (typeof a === 'string' ? a : JSON.stringify(a))).join(' '));
      }));
    try {
      await booking('b1', 'in_progress');
      const { token } = await createTripShare(deps(), 'ana', { bookingId: 'b1' });
      await post(token);
      await post(token.slice(0, 21) + 'Z');
      await revokeTripShare(deps(), 'ana', { bookingId: 'b1' });
      await post(token);
      expect(captured.length).toBeGreaterThan(0);
      expect(captured.join('\n')).not.toContain(token);
      expect(captured.join('\n')).not.toContain(hashToken(SECRET, token));
    } finally {
      spies.forEach((s) => s.mockRestore());
    }
  });
});
