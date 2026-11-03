/**
 * Vuelos, Parte B: el planificador (B1) y los avisos (B2) contra el
 * emulador de Firestore, con reloj simulado y la fuente de pruebas.
 * Minutos, umbrales, aeropuerto y vuelos: FICTICIOS de prueba.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { adminSetFlightInfo } from '../flight';
import { FakeFlightProvider } from '../flight_provider';
import { localToUtcMs } from '../flight_time';
import { pollDue, runFlightPoll } from '../flight_updates';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const MIN = 60_000;
const SCHEDULED = localToUtcMs('2026-11-20', '14:00')!;
const READY = SCHEDULED + 25 * MIN;
let clock = SCHEDULED - 6 * 60 * MIN;
const JEFA = { adminId: 'jefa', adminEmail: 'jefa@prueba.test' };
const REASON = 'Confirmado con la aerolínea (prueba)';
const Q = { airportCode: 'VVI', flightNumber: 'ZZ123', flightDate: '2026-11-20' };

// Valores FICTICIOS de prueba.
const EXIT = { domestic: { noCheckedBag: 10, checkedBag: 25 }, international: { noCheckedBag: 30, checkedBag: 50 } };
const POLL = { flightCheckpointsMinutes: [120, 60], flightPollMinutes: 15 };

let pushes: { title: string; body: string; tokens: string[] }[] = [];
const push = async (tokens: string[], title: string, body: string) => { pushes.push({ tokens, title, body }); };
let provider: FakeFlightProvider;
const run = () => runFlightPoll({ db, provider, now: () => clock, push });
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const doc = async (p: string) => (await db.doc(p).get()).data();
const alerts = async () => (await db.collection('adminAlerts').get()).docs.map((d) => d.data());
const inbox = async (uid: string) => (await db.collection(`users/${uid}/notifications`).get()).docs.map((d) => d.data());

async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'adminAlerts', 'admin_logs', 'flightBoard', 'openRequests']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

async function booking(over: Record<string, unknown> = {}, flight: Record<string, unknown> = {}) {
  await db.doc('bookings/b1').set({
    riderId: 'ana', driverId: 'chofer', status: 'confirmed', estimatedPrice: 100, flightActive: true,
    readyAt: ts(READY), scheduledAt: ts(READY),
    flight: { airportCode: 'VVI', flightType: 'domestic', airline: null, flightNumber: 'ZZ123', flightDate: '2026-11-20',
      scheduledArrival: ts(SCHEDULED), hasCheckedBag: true, estimatedArrival: null, actualArrival: null, status: 'scheduled',
      source: 'passenger', lastObservedAt: null, lastChangeAt: ts(clock), dataQuality: 'none', manualLock: false, ...flight },
    ...over,
  });
}
const found = (over: Record<string, unknown> = {}) => ({ kind: 'found' as const, status: 'delayed' as const,
  scheduled: SCHEDULED, estimated: SCHEDULED + 40 * MIN, actual: null, observedAt: clock, sourceLabel: 'fake', ...over });

beforeEach(async () => {
  await clear();
  clock = SCHEDULED - 6 * 60 * MIN;
  pushes = [];
  provider = new FakeFlightProvider();
  await db.doc('users/ana').set({ role: 'rider', isActive: true, locale: 'es', fcmTokens: ['t-ana'] });
  await db.doc('users/chofer').set({ role: 'driver', isActive: true, locale: 'en', fcmTokens: ['t-chofer'] });
  await db.doc('config/ops').set({ flightExitMinutes: EXIT, flightNotifyThresholdMinutes: 15, ...POLL });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('pollDue (puntos de revisión)', () => {
  it('cada punto una vez; después, cada flightPollMinutes hasta aterrizar', () => {
    const a = SCHEDULED;
    expect(pollDue(a, a - 121 * MIN, [120, 60], 15, {}).due).toBe(false);
    expect(pollDue(a, a - 120 * MIN, [120, 60], 15, {})).toEqual({ due: true, checkpoint: 120 });
    expect(pollDue(a, a - 90 * MIN, [120, 60], 15, { checkpointsDone: [120] }).due).toBe(false);
    expect(pollDue(a, a - 60 * MIN, [120, 60], 15, { checkpointsDone: [120] })).toEqual({ due: true, checkpoint: 60 });
    const after = { checkpointsDone: [120, 60], lastPollAt: ts(a - 60 * MIN) };
    expect(pollDue(a, a - 50 * MIN, [120, 60], 15, after).due).toBe(false);
    expect(pollDue(a, a - 45 * MIN, [120, 60], 15, after)).toEqual({ due: true, checkpoint: null });
  });
});

describe('planificador (B1)', () => {
  it('sin flightCheckpointsMinutes o flightPollMinutes no hace nada', async () => {
    await booking();
    await db.doc('config/ops').update({ flightPollMinutes: admin.firestore.FieldValue.delete() });
    clock = SCHEDULED - 30 * MIN;
    expect(await run()).toMatchObject({ skipped: 'config_missing' });
    expect(provider.calls).toEqual([]);
  });

  it('consulta solo en los puntos y aplica lo nuevo: readyAt, recogida, solicitud abierta, copia del chófer y caché', async () => {
    await booking({ status: 'pending', driverId: null });
    await db.doc('openRequests/b1').set({ scheduledAt: ts(READY), pickupAirport: 'VVI' });
    provider.set(Q, found());
    expect(await run()).toMatchObject({ queried: 0 });
    clock = SCHEDULED - 120 * MIN;
    expect(await run()).toMatchObject({ queried: 1, updated: 1 });
    const b = (await doc('bookings/b1'))!;
    expect(b.flight).toMatchObject({ status: 'delayed', source: 'auto', dataQuality: 'ok' });
    expect(b.readyAt.toMillis()).toBe(SCHEDULED + 65 * MIN);
    expect(b.scheduledAt.toMillis()).toBe(SCHEDULED + 65 * MIN);
    expect(b.estimatedPrice).toBe(100);
    expect((await doc('openRequests/b1'))!.scheduledAt.toMillis()).toBe(SCHEDULED + 65 * MIN);
    expect((await doc('bookings/b1/driverView/flight'))!.readyAt.toMillis()).toBe(SCHEDULED + 65 * MIN);
    expect((await doc('flightBoard/VVI_2026-11-20'))!.flights.ZZ123.status).toBe('delayed');
    // Mismo punto otra vez: no vuelve a consultar.
    expect(await run()).toMatchObject({ queried: 0 });
  });

  it('idempotente: la misma observación no cambia nada ni avisa dos veces', async () => {
    await booking();
    provider.set(Q, found());
    clock = SCHEDULED - 120 * MIN;
    await run();
    const n = pushes.length;
    // Los puntos cuentan desde la hora efectiva (ahora la estimada, +40).
    clock = SCHEDULED + 40 * MIN - 60 * MIN;
    provider.set(Q, found({ observedAt: clock }));
    await run();
    expect(pushes.length).toBe(n);
    expect((await doc('bookings/b1'))!.flight.lastObservedAt.toMillis()).toBe(clock);
    expect((await alerts()).filter((a) => a.type === 'flight_time_changed')).toHaveLength(0);
  });

  it('con bloqueo manual no pisa nada; si la fuente difiere, una sola alerta', async () => {
    await booking({}, { manualLock: true, source: 'manual', status: 'delayed', estimatedArrival: ts(SCHEDULED + 20 * MIN),
      dataQuality: 'ok', lastObservedAt: ts(clock) });
    provider.set(Q, found());
    clock = SCHEDULED - 120 * MIN;
    await run();
    clock = SCHEDULED - 60 * MIN;
    await run();
    const b = (await doc('bookings/b1'))!;
    expect(b.flight).toMatchObject({ source: 'manual', manualLock: true });
    expect(b.flight.estimatedArrival.toMillis()).toBe(SCHEDULED + 20 * MIN);
    expect((await alerts()).filter((a) => a.type === 'flight_source_differs')).toHaveLength(1);
  });

  it('dato viejo (flightStaleMinutes): marca stale y una sola alerta por episodio; sin el valor, no marca', async () => {
    await booking({}, { dataQuality: 'ok', source: 'auto', lastObservedAt: ts(clock - 50 * MIN) });
    await run();
    expect((await doc('bookings/b1'))!.flight.dataQuality).toBe('ok');
    await db.doc('config/ops').update({ flightStaleMinutes: 30 });
    await run();
    await run();
    expect((await doc('bookings/b1'))!.flight.dataQuality).toBe('stale');
    expect((await doc('bookings/b1/driverView/flight'))!.dataQuality).toBe('stale');
    expect((await alerts()).filter((a) => a.type === 'flight_data_stale')).toHaveLength(1);
  });

  it('deja de vigilar reservas terminadas y vuelos aterrizados', async () => {
    await booking({ status: 'completed' });
    clock = SCHEDULED - 120 * MIN;
    await run();
    expect((await doc('bookings/b1'))!.flightActive).toBe(false);
    expect(provider.calls).toEqual([]);
    await booking();
    provider.set(Q, found({ status: 'landed', actual: SCHEDULED - 5 * MIN }));
    clock = SCHEDULED;
    await run();
    expect((await doc('bookings/b1'))!.flightActive).toBe(false);
  });
});

describe('avisos (B2, decisión 4)', () => {
  const set = (estimated: number) => adminSetFlightInfo({ db, now: () => clock, push }, JEFA,
    { bookingId: 'b1', status: 'delayed', estimatedArrival: estimated, reason: REASON });

  it('por debajo del umbral, nada; en el umbral, pasajero y chófer en su idioma, sin número de vuelo', async () => {
    await booking();
    await set(SCHEDULED + 14 * MIN);
    expect(pushes).toEqual([]);
    expect(await inbox('ana')).toEqual([]);
    await set(SCHEDULED + 15 * MIN);
    expect(pushes.map((p) => p.tokens[0]).sort()).toEqual(['t-ana', 't-chofer']);
    const [ana] = await inbox('ana');
    const [chofer] = await inbox('chofer');
    expect(ana).toMatchObject({ type: 'flight_time_changed_rider', locale: 'es', bookingId: 'b1' });
    expect(ana.body).toContain('14:40');
    expect(chofer).toMatchObject({ type: 'flight_time_changed_driver', locale: 'en' });
    expect(chofer.body).toMatch(/2:40\sPM/);
    for (const p of pushes) expect(`${p.title} ${p.body}`).not.toContain('ZZ123');
  });

  it('por encima del umbral avisa; el siguiente se mide desde el último avisado (sin dobles avisos)', async () => {
    await booking();
    await set(SCHEDULED + 40 * MIN);
    expect(pushes).toHaveLength(2);
    await set(SCHEDULED + 50 * MIN);
    expect(pushes).toHaveLength(2);
    await set(SCHEDULED + 56 * MIN);
    expect(pushes).toHaveLength(4);
  });

  it('sin flightNotifyThresholdMinutes no avisa a nadie: solo alerta a central', async () => {
    await db.doc('config/ops').update({ flightNotifyThresholdMinutes: admin.firestore.FieldValue.delete() });
    await booking();
    await set(SCHEDULED + 90 * MIN);
    expect(pushes).toEqual([]);
    expect(await inbox('ana')).toEqual([]);
    expect(await alerts()).toEqual([expect.objectContaining({ type: 'flight_time_changed', severity: 'low' })]);
  });

  it.each(['cancelled', 'diverted'])('%s: alerta alta, aviso sobrio y la reserva NO se cancela sola', async (status) => {
    await booking();
    await adminSetFlightInfo({ db, now: () => clock, push }, JEFA, { bookingId: 'b1', status, reason: REASON });
    expect((await doc('bookings/b1'))!.status).toBe('confirmed');
    expect(await alerts()).toEqual([expect.objectContaining({ type: 'flight_disrupted', severity: 'high' })]);
    expect((await inbox('ana'))[0]).toMatchObject({ type: 'flight_disrupted_rider' });
    expect((await inbox('chofer'))[0]).toMatchObject({ type: 'flight_disrupted_driver' });
    // Otra vez el mismo estado: ni otra alerta ni otro aviso.
    await adminSetFlightInfo({ db, now: () => clock, push }, JEFA, { bookingId: 'b1', status, reason: REASON });
    expect(await alerts()).toHaveLength(1);
    expect(pushes).toHaveLength(2);
  });

  it('sin chófer asignado todavía: solo el pasajero', async () => {
    await booking({ status: 'pending', driverId: null });
    await set(SCHEDULED + 30 * MIN);
    expect(pushes.map((p) => p.tokens[0])).toEqual(['t-ana']);
    expect(await inbox('chofer')).toEqual([]);
  });
});
