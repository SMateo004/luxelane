/**
 * Vuelos, Parte B (decisión 3 de la aprobación): cuando readyAt cambia,
 * scheduledAt cambia con él y los seis usos de la hora de recogida lo
 * siguen. El precio no cambia. Datos FICTICIOS de prueba.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';

// Stripe falso: ningún cobro real.
jest.mock('../stripe_service', () => ({
  STRIPE_SECRET_KEY: { value: () => 'sk_test_falsa' },
  createIntent: async () => ({ id: 'pi_test', clientSecret: 'secret' }),
  paymentMethodCustomer: async () => 'cus_ana',
}));

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminUpdateBooking } from '../admin_ops';
import { releaseBooking } from '../cancellation';
import { adminSetFlightInfo } from '../flight';
import { createPaymentIntent, scheduledCleanup } from '../index';
import { adminPaymentInbox } from '../payment_inbox';
import { canReactivate } from '../payment_manual';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const MIN = 60_000;
const JEFA = { adminId: 'jefa', adminEmail: 'jefa@prueba.test' };
const REASON = 'Confirmado con la aerolínea (prueba)';
const EXIT = { domestic: { noCheckedBag: 10, checkedBag: 25 }, international: { noCheckedBag: 30, checkedBag: 50 } };
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const doc = async (p: string) => (await db.doc(p).get()).data();

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'config', 'adminAlerts', 'admin_logs', 'openRequests', 'payments', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

/** Reserva con vuelo cuya recogida (readyAt = scheduledAt) es [ready]. */
async function flightBooking(id: string, ready: number, over: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', driverId: null, status: 'pending', estimatedPrice: 150, flightActive: true,
    readyAt: ts(ready), scheduledAt: ts(ready),
    pricing: { source: 'server', breakdown: { nightSurchargePct: 20 } },
    flight: { airportCode: 'VVI', flightType: 'domestic', airline: null, flightNumber: 'ZZ123', flightDate: '2026-11-20',
      scheduledArrival: ts(ready - 25 * MIN), hasCheckedBag: true, estimatedArrival: null, actualArrival: null,
      status: 'scheduled', source: 'passenger', lastObservedAt: null, lastChangeAt: ts(ready), dataQuality: 'none',
      manualLock: false },
    ...over,
  });
}
/** El admin fija una llegada estimada: readyAt = estimada + 25 min. */
const delay = (id: string, estimated: number, now = Date.now()) =>
  adminSetFlightInfo({ db, now: () => now }, JEFA, { bookingId: id, status: 'delayed', estimatedArrival: estimated, reason: REASON });

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true, stripeCustomerId: 'cus_ana' });
  // Tarjeta activa (Stripe está simulado arriba: ningún cobro real).
  await db.doc('config/ops').set({ flightExitMinutes: EXIT, paymentMethods: { card: true },
    paymentInstructions: { card: { provider: 'stripe' } } });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('scheduledAt sigue a readyAt; el precio no', () => {
  it('el cambio mueve readyAt y scheduledAt y deja precio y desglose como al reservar', async () => {
    const now = Date.now();
    await flightBooking('b1', now + 3 * 60 * MIN);
    await delay('b1', now + 6 * 60 * MIN, now);
    const b = (await doc('bookings/b1'))!;
    expect(b.readyAt.toMillis()).toBe(now + 6 * 60 * MIN + 25 * MIN);
    expect(b.scheduledAt.toMillis()).toBe(b.readyAt.toMillis());
    expect(b.estimatedPrice).toBe(150);
    expect(b.pricing.breakdown.nightSurchargePct).toBe(20);
  });
});

describe('los seis usos de la hora de recogida', () => {
  it('1. scheduledCleanup: no cancela una reserva cuyo vuelo se retrasó (y sí la que sigue vencida)', async () => {
    const now = Date.now();
    await flightBooking('vencida', now - 2 * 60 * MIN);
    await flightBooking('retrasada', now - 2 * 60 * MIN);
    await delay('retrasada', now + 3 * 60 * MIN, now);
    await (scheduledCleanup as unknown as Runnable).run({});
    expect((await doc('bookings/vencida'))!.status).toBe('cancelled');
    expect((await doc('bookings/retrasada'))!.status).toBe('pending');
  });

  it('2. adminUpdateBooking: con la recogida movida a más de una hora, asignar no deja ocupado al chófer', async () => {
    const T = Date.UTC(2026, 10, 20, 12);
    await db.doc('users/luis').set({ role: 'driver', isActive: true });
    await db.doc('driverProfiles/luis').set({ userId: 'luis', documentsVerified: true, isAvailable: true });
    await flightBooking('b2', T + 30 * MIN);
    await db.doc('bookings/b2/payment/state').set({ bookingId: 'b2', riderId: 'ana', paymentStatus: 'paid', amountDue: 15000,
      amountPaid: 15000 });
    await delay('b2', T + 4 * 60 * MIN, T);
    await adminUpdateBooking({ db, now: () => T }, JEFA, { action: 'assign', bookingId: 'b2', driverId: 'luis',
      reason: 'Asignación de prueba (ficticia)' });
    expect((await doc('driverProfiles/luis'))!.isAvailable).toBe(true);
  });

  it('3. createPaymentIntent: si la recogida pasa a más de 7 días, guarda la tarjeta en vez de retener', async () => {
    const now = Date.now();
    await flightBooking('b3', now + 2 * 60 * MIN);
    await delay('b3', now + 8 * 24 * 60 * MIN, now);
    const req = { auth: { uid: 'ana', token: {} }, app: {}, data: { bookingId: 'b3' } };
    expect(await reason((createPaymentIntent as unknown as Runnable).run(req))).toBe('payment_method_required');
  });

  it('4. releaseBooking: el aviso a central cuenta los minutos hasta la nueva recogida', async () => {
    const T = Date.UTC(2026, 10, 20, 12);
    await db.doc('users/luis').set({ role: 'driver', isActive: true });
    await db.doc('driverProfiles/luis').set({ userId: 'luis', documentsVerified: true, isAvailable: false, online: true });
    await flightBooking('b4', T + 60 * MIN, { status: 'confirmed', driverId: 'luis' });
    await delay('b4', T + 3 * 60 * MIN, T);
    await releaseBooking({ db, now: () => T }, 'luis', { bookingId: 'b4', reason: 'vehicle_issue' });
    const a = (await db.collection('adminAlerts').where('type', '==', 'driver_released_booking').get()).docs[0].data();
    expect(a.minutesToPickup).toBe(3 * 60 + 25);
  });

  it('5. canReactivate y la bandeja de pagos: siguen la recogida nueva', async () => {
    const now = Date.now();
    await flightBooking('b5', now - 30 * MIN, { status: 'cancelled', cancellationReason: 'payment_expired' });
    expect(canReactivate((await doc('bookings/b5'))!, ts(now))).toBe(false);
    await delay('b5', now + 2 * 60 * MIN, now);
    const b = (await doc('bookings/b5'))!;
    expect(canReactivate(b, ts(now))).toBe(true);
    await db.doc('bookings/b5/payment/state').set({ bookingId: 'b5', riderId: 'ana', paymentStatus: 'awaiting_payment',
      amountDue: 15000, amountPaid: 0, paymentDeadline: null });
    const inbox = await adminPaymentInbox(db, { kind: 'awaiting', limit: 20 });
    expect(inbox.items.find((i) => i.bookingId === 'b5')?.booking.scheduledAt).toBe(b.scheduledAt.toMillis());
  });

  it('6. openRequests: la solicitud abierta lleva la hora nueva', async () => {
    const now = Date.now();
    await flightBooking('b6', now + 60 * MIN);
    await db.doc('openRequests/b6').set({ scheduledAt: ts(now + 60 * MIN), pickupAirport: 'VVI', flightType: 'domestic' });
    await delay('b6', now + 5 * 60 * MIN, now);
    expect((await doc('openRequests/b6'))!.scheduledAt.toMillis()).toBe(now + 5 * 60 * MIN + 25 * MIN);
  });
});
