/**
 * Vuelos (prompt de vuelos, Parte A) contra el emulador de Firestore:
 * reserva con vuelo (A1, A2, A4), datos fijados por un admin con bloqueo
 * (A5), regla del «no se presentó» (A7), cancelación por el admin con
 * reembolso entero (A8) y aeropuertos (A9).
 *
 * Minutos de salida, espera, tarifas, recargo nocturno, aeropuertos y
 * vuelos: FICTICIOS de prueba (los reales los carga el responsable).
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import { randomUUID } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminUpdateBooking } from '../admin_ops';
import { BookingDeps, createBooking, quoteBooking } from '../booking_service';
import { adminClearFlightLock, adminForceNoShow, adminSetFlightInfo, adminUpsertAirport } from '../flight';
import { writeBoard } from '../flight_provider';
import { localToUtcMs } from '../flight_time';
import { buildOpenRequest } from '../open_requests';
import { advanceBooking } from '../trip_flow';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const MIN = 60_000;
const T0 = Date.UTC(2026, 10, 19, 12); // un día antes del vuelo
let clock = T0;
const routesOk = (async () => ({ ok: true, json: async () => ({ routes: [{ distanceMeters: 20000 }] }) })) as unknown as typeof fetch;
const deps = (): BookingDeps => ({ db, mapsKey: 'clave-de-prueba', fetchFn: routesOk, now: () => clock });
const fdeps = () => ({ db, now: () => clock });
const JEFA = { adminId: 'jefa', adminEmail: 'jefa@prueba.test' };
const REASON = 'Confirmado por teléfono con la aerolínea (prueba)';

// Valores FICTICIOS de prueba.
const EXIT = { domestic: { noCheckedBag: 10, checkedBag: 25 }, international: { noCheckedBag: 30, checkedBag: 50 } };
const POLICY = { stages: [{ fromStatus: 'no_show', percent: 100 }], noShowWaitMinutes: 20 };
const RULE = { vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0,
  minimumPriceUsd: 60, isActive: true };
const VVI = { name: 'Aeropuerto Viru Viru', address: 'Aeropuerto (prueba)', lat: -17.6447, lng: -63.1353 };
const CENTRO = { name: '', address: 'Plaza (prueba)', lat: -17.7834, lng: -63.1821 };
const POINT = { name: 'Salida nacional (ficticia)', instructions: 'Frente a la puerta 1 (prueba)', lat: -17.6449, lng: -63.1351 };
const FLIGHT = { airportCode: 'VVI', flightType: 'domestic', airline: 'Aerolínea de prueba', flightNumber: 'zz 0123',
  flightDate: '2026-11-20', scheduledArrival: '14:00', hasCheckedBag: true };
const SCHEDULED = localToUtcMs('2026-11-20', '14:00')!;

const trip = (over: Record<string, unknown> = {}) => ({
  origin: VVI, destination: CENTRO, scheduledAt: T0 + 3 * 60 * MIN, vehicleClass: 'business', serviceType: 'oneWay',
  passengerCount: 1, luggageCount: 1, requestId: randomUUID(), channel: 'native', ...over,
});

/** Lo que acepta quoteBooking (sin los campos propios de la reserva). */
const quote = (over: Record<string, unknown> = {}) => {
  const { passengerCount: _p, luggageCount: _l, requestId: _r, channel: _c, ...q } = trip(over);
  return q;
};

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const alerts = async () => (await db.collection('adminAlerts').get()).docs.map((d) => d.data());
const logs = async () => (await db.collection('admin_logs').get()).docs.map((d) => d.data());

async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'pricingRules', 'config', 'adminAlerts', 'admin_logs', 'paymentRefs',
    'payments', 'airports', 'airportsPublic', 'flightBoard', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

async function airport(points: Record<string, unknown> = { domestic: POINT }) {
  await adminUpsertAirport(fdeps(), JEFA, { code: 'VVI', name: 'Aeropuerto Viru Viru (prueba)', city: 'Santa Cruz',
    pickupPoints: points, reason: 'Alta del aeropuerto (prueba)' });
  await db.recursiveDelete(db.collection('admin_logs'));
}

beforeEach(async () => {
  await clear();
  clock = T0;
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('pricingRules/business_oneWay').set(RULE);
  await db.doc('config/ops').set({ paymentMethods: { manual_qr: true }, flightExitMinutes: EXIT,
    paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } } });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('reserva con vuelo (A1, A2, A4)', () => {
  it('guarda el vuelo, readyAt = programada + minutos de salida, recogida derivada, copia del chófer y alerta «por verificar»', async () => {
    await airport();
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    const b = (await doc(`bookings/${r.bookingId}`))!;
    const ready = SCHEDULED + 25 * MIN;
    expect(b.flight).toMatchObject({ airportCode: 'VVI', flightType: 'domestic', airline: 'Aerolínea de prueba',
      flightNumber: 'ZZ123', flightDate: '2026-11-20', hasCheckedBag: true, status: 'scheduled', source: 'passenger',
      dataQuality: 'none', manualLock: false, estimatedArrival: null, actualArrival: null, lastObservedAt: null });
    expect(b.flight.scheduledArrival.toMillis()).toBe(SCHEDULED);
    expect(b.readyAt.toMillis()).toBe(ready);
    // La hora de recogida la deriva el servidor (no la del cliente).
    expect(b.scheduledAt.toMillis()).toBe(ready);
    // Las apps anteriores siguen viendo número y tipo sueltos.
    expect(b).toMatchObject({ flightNumber: 'ZZ123', flightType: 'domestic', pickupAirport: 'VVI' });
    const view = (await doc(`bookings/${r.bookingId}/driverView/flight`))!;
    expect(view).toMatchObject({ flightNumber: 'ZZ123', status: 'scheduled', dataQuality: 'none' });
    expect(view.readyAt.toMillis()).toBe(ready);
    expect(view).not.toHaveProperty('source');
    expect(view).not.toHaveProperty('manualLock');
    expect(await alerts()).toEqual([expect.objectContaining({ type: 'flight_unverified', severity: 'low', bookingId: r.bookingId })]);
  });

  it('internacional sin equipaje facturado usa su minuto de salida', async () => {
    await airport({ international: { ...POINT, name: 'Salida internacional (ficticia)' } });
    const r = await createBooking(deps(), 'ana', trip({ flight: { ...FLIGHT, flightType: 'international', hasCheckedBag: false } }));
    expect((await doc(`bookings/${r.bookingId}`))!.readyAt.toMillis()).toBe(SCHEDULED + 30 * MIN);
  });

  it('con la caché de la fuente: hora estimada, source=auto, sin alerta «por verificar»', async () => {
    await airport();
    await writeBoard(db, { airportCode: 'VVI', flightNumber: 'ZZ123', flightDate: '2026-11-20' }, {
      kind: 'found', status: 'delayed', scheduled: SCHEDULED, estimated: SCHEDULED + 40 * MIN, actual: null,
      observedAt: T0 - 10 * MIN, sourceLabel: 'fake' });
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    const b = (await doc(`bookings/${r.bookingId}`))!;
    expect(b.flight).toMatchObject({ status: 'delayed', source: 'auto', dataQuality: 'ok' });
    expect(b.readyAt.toMillis()).toBe(SCHEDULED + 65 * MIN);
    expect(await alerts()).toEqual([]);
  });

  it('sin punto de recogida para ese tipo: alerta a central (el chófer verá «por confirmar»)', async () => {
    await airport({ international: POINT });
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    expect((await alerts()).map((a) => a.type).sort()).toEqual(['flight_unverified', 'pickup_point_missing']);
    expect((await alerts()).find((a) => a.type === 'pickup_point_missing')).toMatchObject({ bookingId: r.bookingId });
  });

  it('rechazos: sin minutos de salida, aeropuerto desconocido, recogida fuera del aeropuerto o de otro aeropuerto', async () => {
    expect(await reason(createBooking(deps(), 'ana', trip({ flight: FLIGHT })))).toBe('airport_unknown');
    await airport();
    await db.doc('config/ops').update({ flightExitMinutes: admin.firestore.FieldValue.delete() });
    expect(await reason(createBooking(deps(), 'ana', trip({ flight: FLIGHT })))).toBe('flight_config_missing');
    expect(await reason(quoteBooking(deps(), 'ana', quote({ flight: FLIGHT })))).toBe('flight_config_missing');
    await db.doc('config/ops').update({ flightExitMinutes: EXIT });
    expect(await reason(createBooking(deps(), 'ana', trip({ origin: CENTRO, destination: VVI, flight: FLIGHT }))))
      .toBe('flight_not_airport_pickup');
    expect(await reason(createBooking(deps(), 'ana', trip({ flight: { ...FLIGHT, airportCode: 'LPB' } }))))
      .toBe('flight_not_airport_pickup');
    expect(await db.collection('bookings').count().get().then((c) => c.data().count)).toBe(0);
  });

  it('el cliente no manda readyAt ni estados', async () => {
    await airport();
    expect(await reason(createBooking(deps(), 'ana', trip({ flight: { ...FLIGHT, status: 'landed' } })))).toBe('invalid_request');
    expect(await reason(createBooking(deps(), 'ana', trip({ readyAt: SCHEDULED, flight: FLIGHT })))).toBe('invalid_request');
  });

  it('una app antigua (sin vuelo) reserva como hoy', async () => {
    const at = T0 + 3 * 60 * MIN;
    const r = await createBooking(deps(), 'ana', trip({ scheduledAt: at, flightNumber: 'OB760', flightType: 'domestic' }));
    const b = (await doc(`bookings/${r.bookingId}`))!;
    expect(b.scheduledAt.toMillis()).toBe(at);
    expect(b).not.toHaveProperty('flight');
    expect(b).not.toHaveProperty('readyAt');
    expect(b).toMatchObject({ flightNumber: 'OB760', flightType: 'domestic' });
    expect(await doc(`bookings/${r.bookingId}/driverView/flight`)).toBeUndefined();
  });

  it('idempotente: el mismo requestId no crea dos reservas', async () => {
    await airport();
    const t = trip({ flight: FLIGHT });
    const a = await createBooking(deps(), 'ana', t);
    const b = await createBooking(deps(), 'ana', t);
    expect(b.bookingId).toBe(a.bookingId);
    expect((await db.collection('bookings').get()).size).toBe(1);
    expect((await alerts()).filter((x) => x.type === 'flight_unverified')).toHaveLength(1);
  });

  it('decisión 6: el precio se fija con la hora de recogida al crear (recargo nocturno) y no cambia con un retraso', async () => {
    // Recargo nocturno FICTICIO de prueba.
    await db.doc('config/pricing').set({ nightSurchargePct: 20, nightStartHour: 22, nightEndHour: 6 });
    await airport();
    const night = { ...FLIGHT, scheduledArrival: '23:50' }; // readyAt 00:15 del día siguiente
    const day = await quoteBooking(deps(), 'ana', quote({ flight: FLIGHT }));
    const q = await quoteBooking(deps(), 'ana', quote({ flight: night }));
    expect(q.readyAt).toBe(localToUtcMs('2026-11-20', '23:50')! + 25 * MIN);
    expect(q.breakdown.nightSurchargePct).toBe(20);
    expect(day.breakdown.nightSurchargePct).toBeNull();
    const r = await createBooking(deps(), 'ana', trip({ flight: night }));
    expect(r.price).toBe(q.price);
    await adminSetFlightInfo(fdeps(), JEFA, { bookingId: r.bookingId, status: 'delayed',
      estimatedArrival: localToUtcMs('2026-11-21', '09:00')!, reason: REASON });
    const b = (await doc(`bookings/${r.bookingId}`))!;
    expect(b.estimatedPrice).toBe(q.price);
    expect(b.pricing.breakdown.nightSurchargePct).toBe(20);
  });

  it('solicitud abierta: solo el aeropuerto y el tipo de vuelo, sin número ni horas del vuelo', async () => {
    await airport();
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    const open = buildOpenRequest((await doc(`bookings/${r.bookingId}`)) as never);
    expect(open).toMatchObject({ pickupAirport: 'VVI', flightType: 'domestic' });
    const s = JSON.stringify(open);
    for (const k of ['ZZ123', 'flightNumber', 'airline', 'scheduledArrival', 'estimatedArrival', 'readyAt', '"flight"']) {
      expect(s).not.toContain(k);
    }
  });
});

describe('datos fijados por un admin (A5)', () => {
  it('fija estimada, real y estado con source=manual y bloqueo; recalcula readyAt; auditoría y copia del chófer', async () => {
    await airport();
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    await expect(adminSetFlightInfo(fdeps(), JEFA, { bookingId: r.bookingId, status: 'landed',
      actualArrival: SCHEDULED + 15 * MIN, reason: REASON })).resolves.toEqual({ status: 'landed',
      readyAt: SCHEDULED + 40 * MIN, manualLock: true });
    const b = (await doc(`bookings/${r.bookingId}`))!;
    expect(b.flight).toMatchObject({ status: 'landed', source: 'manual', manualLock: true, dataQuality: 'ok' });
    expect(b.flight.actualArrival.toMillis()).toBe(SCHEDULED + 15 * MIN);
    expect(b.readyAt.toMillis()).toBe(SCHEDULED + 40 * MIN);
    expect((await doc(`bookings/${r.bookingId}/driverView/flight`))!.readyAt.toMillis()).toBe(SCHEDULED + 40 * MIN);
    expect(await logs()).toEqual([expect.objectContaining({ operation: 'set_flight_info', targetId: r.bookingId, reason: REASON,
      actor: { uid: 'jefa', role: 'admin' } })]);
  });

  it('«aterrizado» sin hora real, rechazado; reserva sin vuelo, rechazada; sin minutos de salida, rechazado', async () => {
    await airport();
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    expect(await reason(adminSetFlightInfo(fdeps(), JEFA, { bookingId: r.bookingId, status: 'landed', reason: REASON })))
      .toBe('invalid_request');
    const old = await createBooking(deps(), 'ana', trip());
    expect(await reason(adminSetFlightInfo(fdeps(), JEFA, { bookingId: old.bookingId, status: 'delayed', reason: REASON })))
      .toBe('booking_without_flight');
    await db.doc('config/ops').update({ flightExitMinutes: admin.firestore.FieldValue.delete() });
    expect(await reason(adminSetFlightInfo(fdeps(), JEFA, { bookingId: r.bookingId, status: 'delayed', reason: REASON })))
      .toBe('flight_config_missing');
  });

  it('quitar el bloqueo: auditado; sin bloqueo, no cambia nada', async () => {
    await airport();
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    expect(await adminClearFlightLock(fdeps(), JEFA, { bookingId: r.bookingId, reason: REASON }))
      .toEqual({ manualLock: false, changed: false });
    await adminSetFlightInfo(fdeps(), JEFA, { bookingId: r.bookingId, status: 'delayed', estimatedArrival: SCHEDULED + 30 * MIN,
      reason: REASON });
    expect(await adminClearFlightLock(fdeps(), JEFA, { bookingId: r.bookingId, reason: REASON }))
      .toEqual({ manualLock: false, changed: true });
    expect((await doc(`bookings/${r.bookingId}`))!.flight.manualLock).toBe(false);
    expect((await logs()).map((l) => l.operation).sort()).toEqual(['clear_flight_lock', 'set_flight_info']);
  });
});

describe('«no se presentó» con vuelo (A7)', () => {
  const HERE = { lat: VVI.lat, lng: VVI.lng };
  const READY = SCHEDULED + 25 * MIN;
  const tdeps = () => ({ db, pickupSecret: 'secreto-de-prueba', now: () => clock });

  /** Reserva con vuelo, chófer en el punto (driver_arrived), con política. */
  async function arrived(flight: Record<string, unknown>) {
    await db.doc('config/ops').update({ cancellationPolicy: POLICY });
    await db.doc('users/chofer').set({ role: 'driver', isActive: true });
    await db.doc('driverProfiles/chofer').set({ userId: 'chofer', isAvailable: false, online: true });
    await db.doc('bookings/b1').set({
      riderId: 'ana', driverId: 'chofer', status: 'driver_arriving', estimatedPrice: 100,
      origin: { address: 'Aeropuerto', coordinates: new admin.firestore.GeoPoint(HERE.lat, HERE.lng) },
      readyAt: admin.firestore.Timestamp.fromMillis(READY), scheduledAt: admin.firestore.Timestamp.fromMillis(READY),
      flight: { airportCode: 'VVI', flightType: 'domestic', flightNumber: 'ZZ123', status: 'scheduled', dataQuality: 'none',
        estimatedArrival: null, actualArrival: null, ...flight },
    });
    clock = READY - 5 * MIN;
    await advanceBooking(tdeps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived', location: HERE });
  }
  const noShow = () => advanceBooking(tdeps(), 'chofer', { bookingId: 'b1', to: 'no_show', location: HERE });
  const landed = { status: 'landed', dataQuality: 'ok', actualArrival: admin.firestore.Timestamp.fromMillis(SCHEDULED) };

  it('aterrizado y espera cumplida (readyAt + espera): permitido', async () => {
    await arrived(landed);
    expect(((await doc('bookings/b1'))!.noShowAvailableAt as admin.firestore.Timestamp).toMillis()).toBe(READY + 20 * MIN);
    clock = READY + 20 * MIN;
    await expect(noShow()).resolves.toEqual({ status: 'no_show', alreadyApplied: false });
  });

  it('aterrizado y espera no cumplida: no_show_too_early (la espera cuenta desde readyAt, no desde la llegada)', async () => {
    await arrived(landed);
    clock = READY + 19 * MIN;
    expect(await reason(noShow())).toBe('no_show_too_early');
    expect((await doc('bookings/b1'))!.status).toBe('driver_arrived');
  });

  it.each([
    ['retrasado', { status: 'delayed', dataQuality: 'ok', estimatedArrival: admin.firestore.Timestamp.fromMillis(SCHEDULED + 60 * MIN) },
      'flight_not_landed'],
    ['«aterrizado» sin hora real', { status: 'landed', dataQuality: 'ok' }, 'flight_not_landed'],
    ['sin datos (declarado por el pasajero)', {}, 'flight_no_data'],
    ['sin datos (desconocido)', { status: 'unknown', dataQuality: 'stale' }, 'flight_no_data'],
    ['desviado', { status: 'diverted', dataQuality: 'ok' }, 'flight_disrupted'],
    ['cancelado', { status: 'cancelled', dataQuality: 'ok' }, 'flight_disrupted'],
  ])('%s: rechazado (%s) aunque pase mucho tiempo', async (_n, flight, want) => {
    await arrived(flight);
    clock = READY + 6 * 60 * MIN;
    expect(await reason(noShow())).toBe(want);
    expect((await doc('bookings/b1'))!.status).toBe('driver_arrived');
  });

  it('un admin puede forzarlo con motivo: evento, alerta y auditoría', async () => {
    await arrived({ status: 'delayed', dataQuality: 'ok' });
    clock = READY + 60 * MIN;
    expect(await reason(adminForceNoShow(fdeps(), JEFA, { bookingId: 'b1', reason: 'corto' }))).toBe('invalid_request');
    await expect(adminForceNoShow(fdeps(), JEFA, { bookingId: 'b1', reason: 'Esperó 60 min y no contesta (prueba)' }))
      .resolves.toEqual({ status: 'no_show', alreadyApplied: false });
    expect((await doc('bookings/b1'))!.status).toBe('no_show');
    const ev = (await db.collection('bookings/b1/events').get()).docs.map((d) => d.data()).find((e) => e.to === 'no_show');
    expect(ev).toMatchObject({ method: 'admin_force_no_show', actor: { role: 'admin' }, flightStatus: 'delayed' });
    expect(await logs()).toEqual([expect.objectContaining({ operation: 'force_no_show', targetId: 'b1',
      reason: 'Esperó 60 min y no contesta (prueba)' })]);
    expect((await alerts()).some((a) => a.type === 'rider_no_show')).toBe(true);
  });

  it('una reserva sin vuelo se comporta como antes (espera desde la llegada)', async () => {
    await arrived({});
    await db.doc('bookings/b1').update({ flight: admin.firestore.FieldValue.delete(),
      readyAt: admin.firestore.FieldValue.delete() });
    clock += 19 * MIN;
    expect(await reason(noShow())).toBe('no_show_too_early');
    clock += 2 * MIN;
    await expect(noShow()).resolves.toMatchObject({ status: 'no_show' });
  });
});

describe('vuelo cancelado o desviado (A8)', () => {
  it('nada cambia solo; el admin cancela con causa plataforma: retención 0 % y reembolso entero', async () => {
    await airport();
    const r = await createBooking(deps(), 'ana', trip({ flight: FLIGHT }));
    await db.doc('config/ops').update({ cancellationPolicy: POLICY });
    await db.doc(`bookings/${r.bookingId}`).update({ status: 'confirmed', driverId: 'chofer' });
    await db.doc(`bookings/${r.bookingId}/payment/state`).update({ paymentStatus: 'paid', amountPaid: 12000, amountDue: 12000 });
    await adminSetFlightInfo(fdeps(), JEFA, { bookingId: r.bookingId, status: 'cancelled', reason: REASON });
    expect((await doc(`bookings/${r.bookingId}`))!.status).toBe('confirmed');
    await adminUpdateBooking(fdeps(), JEFA, { action: 'cancel', bookingId: r.bookingId, cause: 'platform',
      reason: 'Vuelo cancelado por la aerolínea (prueba)' });
    expect(await doc(`bookings/${r.bookingId}/payment/state`)).toMatchObject({
      paymentStatus: 'refund_pending', amountRetained: 0, refundDue: 12000, retentionBasis: 'platform_cause' });
  });
});

describe('aeropuertos (A9)', () => {
  it('crea y cambia con auditoría; un punto se quita con null y el otro se conserva; lo público, mínimo', async () => {
    await expect(adminUpsertAirport(fdeps(), JEFA, { code: 'VVI', name: 'Aeropuerto Viru Viru (prueba)', city: 'Santa Cruz',
      pickupPoints: { domestic: POINT, international: { ...POINT, name: 'Salida internacional (ficticia)' } },
      reason: 'Alta del aeropuerto (prueba)' })).resolves.toEqual({ code: 'VVI', created: true });
    expect(await doc('airports/VVI')).toMatchObject({ code: 'VVI', timeZone: 'America/La_Paz',
      pickupPoints: { domestic: POINT, international: { name: 'Salida internacional (ficticia)' } } });
    expect(await doc('airportsPublic/VVI')).toEqual({ code: 'VVI', name: 'Aeropuerto Viru Viru (prueba)', city: 'Santa Cruz' });
    await adminUpsertAirport(fdeps(), JEFA, { code: 'VVI', name: 'Aeropuerto Viru Viru (prueba)', city: 'Santa Cruz',
      pickupPoints: { international: null }, reason: 'Se cierra la salida internacional (prueba)' });
    expect((await doc('airports/VVI'))!.pickupPoints).toEqual({ domestic: POINT, international: null });
    expect((await logs()).map((l) => l.operation).sort()).toEqual(['create_airport', 'update_airport']);
  });

  it('coordenadas fuera de rango o (0, 0), y otra zona horaria: rechazadas', async () => {
    for (const p of [{ ...POINT, lat: 95 }, { ...POINT, lng: -190 }, { ...POINT, lat: 0, lng: 0 }]) {
      expect(await reason(adminUpsertAirport(fdeps(), JEFA, { code: 'VVI', name: 'Aeropuerto', city: 'Santa Cruz',
        pickupPoints: { domestic: p }, reason: 'Alta del aeropuerto (prueba)' }))).toBe('invalid_request');
    }
    expect(await reason(adminUpsertAirport(fdeps(), JEFA, { code: 'VVI', name: 'Aeropuerto', city: 'Santa Cruz',
      timeZone: 'America/Lima', pickupPoints: {}, reason: 'Alta del aeropuerto (prueba)' }))).toBe('invalid_request');
    expect(await doc('airports/VVI')).toBeUndefined();
  });
});
