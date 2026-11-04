/**
 * Ventana del chófer, A2 y A6: resumen del viaje en
 * driverHistory/{chófer}/trips/{reserva}. Un test por cada camino que deja
 * una reserva en estado final (o que la toca ya cerrada), con el
 * disparador real (writeDriverHistoryOnBooking): una sola entrada por
 * reserva, y un segundo disparo no la reescribe (idempotente). Los caminos
 * sin chófer no dejan resumen. Datos FICTICIOS de prueba.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { adminRecordPayment, adminUpdateBooking } from '../admin_ops';
import { cancelBooking, releaseBooking } from '../cancellation';
import { SUMMARY_FIELDS, writeDriverHistory } from '../driver_history';
import { adminForceNoShow } from '../flight';
import { scheduledCleanup, settleBooking, writeDriverHistoryOnBooking } from '../index';
import { advanceBooking } from '../trip_flow';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const T0 = Date.UTC(2026, 10, 20, 15);
let clock = T0;
const MIN = 60_000;
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const HERE = { lat: -17.6448, lng: -63.1353 };
const JEFA = { adminId: 'jefa', adminEmail: 'jefa@prueba.test' };
const REASON = 'Motivo de prueba suficientemente largo';
// Política de PRUEBA, ficticia.
const POLICY = { stages: [{ fromStatus: 'no_show', percent: 0 }], noShowWaitMinutes: 15 };
const tdeps = () => ({ db, pickupSecret: 'secreto', now: () => clock });
const deps = () => ({ db, now: () => clock });

async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'config', 'adminAlerts', 'admin_logs', 'payments', 'openRequests',
    'rateLimits', 'driverHistory']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

/** Reserva FICTICIA de ana con todos los datos personales que podría tener. */
async function booking(id: string, status: string, extra: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', driverId: 'luis', status, serviceType: 'oneWay', vehicleClass: 'business', class: 'business',
    estimatedPrice: 120, finalPrice: null,
    origin: { name: 'Casa de Ana (prueba)', address: 'Calle Exacta 123 (prueba)',
      coordinates: new admin.firestore.GeoPoint(HERE.lat, HERE.lng) },
    destination: { name: 'Oficina (prueba)', address: 'Avenida Exacta 456 (prueba)',
      coordinates: new admin.firestore.GeoPoint(-17.7834, -63.1821) },
    pickupArea: 'Aeropuerto', dropoffArea: 'Santa Cruz de la Sierra',
    notes: 'Toque el timbre (prueba)', guest: { firstName: 'Carla', phone: '+59170000001' },
    flightNumber: 'ZZ123', preferredDriverLanguages: ['es'],
    pricing: { source: 'server', breakdown: { km: 16.4 } },
    scheduledAt: ts(clock + 30 * MIN), createdAt: ts(clock - 120 * MIN), updatedAt: ts(clock - 60 * MIN),
    ...extra,
  });
  await db.doc(`bookings/${id}/payment/state`).set({ bookingId: id, riderId: 'ana', paymentStatus: 'paid',
    paymentMethod: 'manual_qr', amountDue: 12000, amountPaid: 12000 });
}

/** El disparador real, con la reserva como está ahora. */
async function fire(id: string): Promise<void> {
  const snap = await db.doc(`bookings/${id}`).get();
  await (writeDriverHistoryOnBooking as unknown as Runnable).run({ data: { before: snap, after: snap }, params: { bookingId: id } });
}
const trips = async (driver = 'luis') => (await db.collection(`driverHistory/${driver}/trips`).get()).docs;
const summary = async (id: string, driver = 'luis') => (await db.doc(`driverHistory/${driver}/trips/${id}`).get());

/** Una sola entrada, y un segundo disparo no la reescribe. */
async function expectOnce(id: string, status: string) {
  await fire(id);
  const first = await summary(id);
  expect(first.exists).toBe(true);
  expect(first.data()!.status).toBe(status);
  await fire(id);
  const again = await summary(id);
  expect(again.updateTime!.isEqual(first.updateTime!)).toBe(true);
  expect(await writeDriverHistory(db, id)).toBe('unchanged');
  expect((await trips()).map((d) => d.id)).toEqual([id]);
  return first.data()!;
}

beforeEach(async () => {
  await clear();
  clock = T0;
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/luis').set({ role: 'driver', isActive: true });
  await db.doc('driverProfiles/luis').set({ userId: 'luis', isAvailable: false, online: true, documentsVerified: true });
  await db.doc('config/ops').set({ cancellationPolicy: POLICY });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('caminos que cierran la reserva con chófer: un resumen, una vez', () => {
  it('1. advanceBooking a completed (el chófer termina el viaje)', async () => {
    await booking('b1', 'in_progress', { startedAt: ts(T0 - 40 * MIN) });
    await advanceBooking(tdeps(), 'luis', { bookingId: 'b1', to: 'completed', location: HERE });
    const s = await expectOnce('b1', 'completed');
    expect(s.durationMinutes).toBe(40);
    expect(s.endedAt.toMillis()).toBe(T0);
    expect(s.distanceKm).toBe(16.4);
  });

  it('2. advanceBooking a no_show (el chófer marca que no se presentó)', async () => {
    await booking('b1', 'driver_arriving');
    await advanceBooking(tdeps(), 'luis', { bookingId: 'b1', to: 'driver_arrived', location: HERE });
    clock += 20 * MIN;
    await advanceBooking(tdeps(), 'luis', { bookingId: 'b1', to: 'no_show', location: HERE });
    const s = await expectOnce('b1', 'no_show');
    expect(s.endedAt.toMillis()).toBe(clock);
    expect(s.durationMinutes).toBeNull();
  });

  it('3. cancelBooking (el pasajero cancela con el chófer asignado)', async () => {
    await booking('b1', 'driver_arriving');
    await cancelBooking(deps(), 'ana', { bookingId: 'b1', reason: 'changed_plans' });
    await expectOnce('b1', 'cancelled');
  });

  it('4. adminUpdateBooking cancel (central cancela con el chófer asignado)', async () => {
    await booking('b1', 'confirmed');
    await adminUpdateBooking(deps(), JEFA, { action: 'cancel', bookingId: 'b1', reason: REASON, cause: 'platform' });
    await expectOnce('b1', 'cancelled');
  });

  it('5. adminUpdateBooking status a completed (central cierra el viaje en curso)', async () => {
    await booking('b1', 'in_progress');
    await adminUpdateBooking(deps(), JEFA, { action: 'status', bookingId: 'b1', to: 'completed', reason: REASON });
    const s = await expectOnce('b1', 'completed');
    expect(s.finalPrice).toBe(120);
  });

  it('6. adminForceNoShow (central fuerza «no se presentó»)', async () => {
    await booking('b1', 'driver_arrived', { arrivedAt: ts(T0 - 5 * MIN) });
    await adminForceNoShow(deps(), JEFA, { bookingId: 'b1', reason: REASON });
    await expectOnce('b1', 'no_show');
  });

  it('7. adminUpdateBooking cancel de un no_show: el mismo resumen pasa a cancelled', async () => {
    await booking('b1', 'driver_arrived', { arrivedAt: ts(T0 - 5 * MIN) });
    await adminForceNoShow(deps(), JEFA, { bookingId: 'b1', reason: REASON });
    await fire('b1');
    await adminUpdateBooking(deps(), JEFA, { action: 'cancel', bookingId: 'b1', reason: REASON, cause: 'rider' });
    await expectOnce('b1', 'cancelled');
  });
});

describe('datos que llegan después del cierre: se actualiza el mismo resumen', () => {
  it('8. valoración del pasajero: estrellas sí, comentario no', async () => {
    await booking('b1', 'completed', { completedAt: ts(T0) });
    await fire('b1');
    await db.doc('bookings/b1').update({ riderRating: 4, riderComment: 'Muy amable, se llama Luis (prueba)' });
    const s = await expectOnce('b1', 'completed');
    expect(s.riderRating).toBe(4);
    expect(JSON.stringify(s)).not.toContain('amable');
  });

  it('9. settleBooking (reparto al completarse)', async () => {
    await db.doc('config/finance').set({ platformCommissionPct: 20 });
    await booking('b1', 'completed', { completedAt: ts(T0), finalPrice: 120 });
    const snap = await db.doc('bookings/b1').get();
    await (settleBooking as unknown as Runnable).run({ data: { before: snap, after: snap }, params: { bookingId: 'b1' } });
    const s = await expectOnce('b1', 'completed');
    expect(s.settlement).toMatchObject({ amount: 120, commissionPct: 20 });
  });

  it('10. adminRecordPayment corrige el importe de un viaje completado (finalPrice y reparto)', async () => {
    await booking('b1', 'completed', { completedAt: ts(T0), finalPrice: 120,
      settlement: { amount: 120, commissionPct: 20, platformCommission: 24, driverPayout: 96 } });
    await fire('b1');
    await db.doc('payments/p1').set({ bookingId: 'b1', riderId: 'ana', amount: 12000, method: 'manual_qr', status: 'captured',
      manual: true });
    await adminRecordPayment(deps(), JEFA, { action: 'correct', paymentId: 'p1', amountBs: 100, reason: REASON });
    const s = await expectOnce('b1', 'completed');
    expect(s.finalPrice).toBe(100);
    expect(s.settlement).toMatchObject({ amount: 100, commissionPct: 20 });
  });

  it('11. reembolso (refunded): el resumen lo refleja', async () => {
    await booking('b1', 'completed', { completedAt: ts(T0) });
    await fire('b1');
    await db.doc('bookings/b1').update({ refunded: true });
    const s = await expectOnce('b1', 'completed');
    expect(s.refunded).toBe(true);
  });
});

describe('caminos sin chófer: no hay resumen', () => {
  it('12. releaseBooking (el chófer libera: vuelve a pending, sin chófer)', async () => {
    await booking('b1', 'confirmed');
    await releaseBooking(deps(), 'luis', { bookingId: 'b1', reason: 'vehicle_issue', location: HERE });
    await fire('b1');
    expect(await trips()).toHaveLength(0);
  });

  it('13. scheduledCleanup (pendiente sin chófer, vencida)', async () => {
    await booking('b1', 'pending', { driverId: null, scheduledAt: ts(Date.now() - 2 * 60 * MIN) });
    await (scheduledCleanup as unknown as Runnable).run({});
    expect((await db.doc('bookings/b1').get()).data()!.status).toBe('cancelled');
    await fire('b1');
    expect(await trips()).toHaveLength(0);
  });

  it('14. cancelBooking de una pendiente sin chófer', async () => {
    await booking('b1', 'pending', { driverId: null });
    await cancelBooking(deps(), 'ana', { bookingId: 'b1', reason: 'changed_plans' });
    await fire('b1');
    expect(await trips()).toHaveLength(0);
  });
});

describe('privacidad del resumen (A5)', () => {
  it('solo los campos de la lista cerrada; ningún dato del pasajero', async () => {
    await booking('b1', 'in_progress', { startedAt: ts(T0 - 10 * MIN) });
    await advanceBooking(tdeps(), 'luis', { bookingId: 'b1', to: 'completed', location: HERE });
    await db.doc('bookings/b1').update({ riderRating: 5, riderComment: 'Comentario de prueba con nombre Carla' });
    await fire('b1');
    const s = (await summary('b1')).data()!;
    expect(Object.keys(s).sort()).toEqual([...SUMMARY_FIELDS].sort());
    const text = JSON.stringify(s);
    for (const pii of ['ana', 'Ana', 'Carla', '+591', 'Exacta', 'timbre', 'ZZ123', 'Comentario', 'Oficina', '-17.6448']) {
      expect(text).not.toContain(pii);
    }
    expect(s.pickupApprox).toEqual({ lat: -17.64, lng: -63.14 });
  });
});
