/**
 * Pagos A3: la reserva nace en awaiting_payment y no se ofrece a ningún
 * chófer hasta que su pago está confirmado. Contra el emulador.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

// FCM falso: se cuentan los avisos a chóferes.
const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { randomUUID } from 'crypto';
import { HttpsError } from 'firebase-functions/v2/https';
import { acceptBooking, assignNearestDriver, notifyDriversOnPaid, onBookingCreated } from '../index';
import { BookingDeps, createBooking } from '../booking_service';
import { adminUpdateBooking } from '../admin_ops';
import { reconcileOpenRequests } from '../reconcile';
import { isPaymentRef } from '../payment_model';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const NOW = Date.UTC(2026, 9, 26, 12);
const routesOk = (async () => ({ ok: true, json: async () => ({ routes: [{ distanceMeters: 12000 }] }) })) as unknown as typeof fetch;
const deps = (): BookingDeps => ({ db, mapsKey: 'clave-de-prueba', fetchFn: routesOk, now: () => NOW });

// Tarifa de prueba (no es de negocio): 50 + 3/km, mínimo 60.
const RULE = { vehicleClass: 'business', serviceType: 'oneWay', basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true };
// Un método activo con datos de PRUEBA, ficticios: sin él no se reserva (A12).
const OPS = { paymentMethods: { manual_qr: true }, paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', accountNumber: '000-ficticia' } } };
const trip = (over: Record<string, unknown> = {}) => ({
  origin: { name: '', address: 'Calle 1', lat: -17.7834, lng: -63.1821 },
  destination: { name: 'Equipetrol', address: 'Av. 2', lat: -17.765, lng: -63.196 },
  scheduledAt: NOW + 2 * 3600_000, vehicleClass: 'business', serviceType: 'oneWay',
  passengerCount: 1, luggageCount: 0, requestId: randomUUID(), ...over,
});

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'vehicles', 'config', 'pricingRules', 'openRequests', 'adminAlerts',
    'paymentRefs', 'admin_logs', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const exists = async (p: string) => (await db.doc(p).get()).exists;
const pay = (id: string, paymentStatus: string) =>
  db.doc(`bookings/${id}/payment/state`).set({ riderId: 'ana', bookingId: id, paymentStatus, amountDue: 8600, amountPaid: 0 });

beforeEach(async () => {
  await clear();
  sendEachForMulticast.mockClear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/luis').set({ role: 'driver', isActive: true, fcmTokens: ['tok-luis'] });
  await db.doc('driverProfiles/luis').set({ userId: 'luis', isAvailable: true, documentsVerified: true, online: true,
    currentLocation: new admin.firestore.GeoPoint(-17.78, -63.18) });
  await db.doc('vehicles/v1').set({ driverId: 'luis', class: 'business', isActive: true });
  await db.doc('pricingRules/business_oneWay').set(RULE);
  await db.doc('config/ops').set(OPS);
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('createBooking (A3)', () => {
  it('crea la reserva en awaiting_payment, con importe del servidor y referencia, sin openRequests', async () => {
    const r = await createBooking(deps(), 'ana', trip({ quotedPrice: 500 }));
    // El cliente dijo 500: se ignora; se debe lo que calcula el servidor.
    expect(r).toMatchObject({ price: 86, paymentStatus: 'awaiting_payment', amountDue: 8600, paymentDeadline: null });
    expect(isPaymentRef(r.paymentRef!)).toBe(true);
    const state = (await doc(`bookings/${r.bookingId}/payment/state`))!;
    expect(state).toMatchObject({
      riderId: 'ana', paymentStatus: 'awaiting_payment', paymentMethod: null, amountDue: 8600, amountPaid: 0,
      paymentRef: r.paymentRef, paidAt: null, paymentDeadline: null,
    });
    expect(await doc(`paymentRefs/${r.paymentRef}`)).toMatchObject({ bookingId: r.bookingId });
    expect(await exists(`openRequests/${r.bookingId}`)).toBe(false);
    // El chófer no ve nada de pagos en la reserva.
    const b = (await doc(`bookings/${r.bookingId}`))!;
    for (const k of ['paymentStatus', 'amountDue', 'amountPaid', 'paymentRef']) expect(b).not.toHaveProperty(k);
  });

  it('con paymentWindowMinutes, el plazo es la hora del servidor más esos minutos', async () => {
    await db.doc('config/ops').set({ ...OPS, paymentWindowMinutes: 30 });
    const r = await createBooking(deps(), 'ana', trip());
    expect(r.paymentDeadline).toBe(NOW + 30 * 60_000);
  });

  it('idempotente: el mismo requestId da la misma referencia y un solo documento', async () => {
    const same = trip();
    const [a, b] = await Promise.all([createBooking(deps(), 'ana', same), createBooking(deps(), 'ana', same)]);
    expect(a).toEqual(b);
    expect((await db.collection('paymentRefs').get()).size).toBe(1);
    expect(await createBooking(deps(), 'ana', same)).toEqual(a);
  });

  it('onBookingCreated ya no avisa a los chóferes', async () => {
    const { bookingId } = await createBooking(deps(), 'ana', trip());
    const ref = db.doc(`bookings/${bookingId}`);
    await (onBookingCreated as unknown as Runnable).run({ data: await ref.get(), params: { bookingId } });
    expect((await doc(`bookings/${bookingId}`))!.driversNotifiedAt).toBeUndefined();
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });
});

describe('sin ningún método de pago activo no se reserva (A12)', () => {
  it('payments_unavailable y no se crea nada', async () => {
    await db.doc('config/ops').set({ paymentMethods: { manual_qr: true } }); // sin datos de cobro
    expect(await reason(createBooking(deps(), 'ana', trip()))).toBe('payments_unavailable');
    expect((await db.collection('bookings').get()).size).toBe(0);
    expect((await db.collection('paymentRefs').get()).size).toBe(0);
  });
});

describe('nada se ofrece a chóferes sin pago (A3)', () => {
  let id: string;
  beforeEach(async () => { id = (await createBooking(deps(), 'ana', trip())).bookingId; });

  it('acceptBooking: not_paid y la reserva sigue sin chófer', async () => {
    const r = await (acceptBooking as unknown as Runnable).run({ auth: { uid: 'luis', token: {} }, app: {}, data: { bookingId: id } });
    expect(r).toEqual({ accepted: false, reason: 'not_paid' });
    expect((await doc(`bookings/${id}`))!.driverId).toBeNull();
  });

  it('assignNearestDriver: not_paid', async () => {
    const r = await (assignNearestDriver as unknown as Runnable).run({ auth: { uid: 'ana', token: {} }, app: {}, data: { bookingId: id } });
    expect(r).toEqual({ assigned: false, reason: 'not_paid' });
  });

  it('el admin no la asigna: payment_required', async () => {
    expect(await reason(adminUpdateBooking({ db }, { adminId: 'jefa', adminEmail: null },
      { action: 'assign', bookingId: id, driverId: 'luis', reason: 'Asignación de prueba manual' })))
      .toBe('payment_required');
  });

  it('la reconciliación no crea su solicitud y borra una que sobre', async () => {
    await db.doc(`openRequests/${id}`).set({ estimatedPrice: 86 });
    const r = await reconcileOpenRequests(db);
    expect(r).toEqual({ created: [], deleted: [id] });
    expect(await exists(`openRequests/${id}`)).toBe(false);
  });

  it('con el pago confirmado sí: acepta, y la reconciliación crea la que falte', async () => {
    await pay(id, 'paid');
    expect(await reconcileOpenRequests(db)).toEqual({ created: [id], deleted: [] });
    const r = await (acceptBooking as unknown as Runnable).run({ auth: { uid: 'luis', token: {} }, app: {}, data: { bookingId: id } });
    expect(r).toEqual({ accepted: true });
  });

  it('el aviso a los chóferes sale al pasar a paid, una vez', async () => {
    const before = await db.doc(`bookings/${id}/payment/state`).get();
    await pay(id, 'paid');
    const after = await db.doc(`bookings/${id}/payment/state`).get();
    const event = { data: { before, after }, params: { bookingId: id, docId: 'state' } };
    await (notifyDriversOnPaid as unknown as Runnable).run(event);
    await (notifyDriversOnPaid as unknown as Runnable).run(event);
    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
    expect((await doc(`bookings/${id}`))!.driversNotifiedAt).toBeDefined();
  });

  it('otros cambios del pago no avisan', async () => {
    const before = await db.doc(`bookings/${id}/payment/state`).get();
    await pay(id, 'failed');
    const after = await db.doc(`bookings/${id}/payment/state`).get();
    await (notifyDriversOnPaid as unknown as Runnable).run({ data: { before, after }, params: { bookingId: id, docId: 'state' } });
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });
});
