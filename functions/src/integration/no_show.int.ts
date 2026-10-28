/**
 * B4: «el pasajero no aparece» (advanceBooking a no_show) contra el
 * emulador. Solo con política, pasado el tiempo de espera y con ubicación;
 * evento, alerta a central, chófer libre y ningún cobro.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { advanceBooking } from '../trip_flow';
import { adminUpdateBooking } from '../admin_ops';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const T0 = Date.UTC(2026, 9, 25, 12);
let clock = T0;
const deps = () => ({ db, pickupSecret: 'secreto', now: () => clock });
const HERE = { lat: -17.6448, lng: -63.1353 };
// Valores de PRUEBA, ficticios: los de negocio los pone el responsable.
const POLICY = { stages: [{ fromStatus: 'no_show', percent: 30 }], noShowWaitMinutes: 15 };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'config', 'adminAlerts', 'admin_logs', 'payments']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const events = async (id: string) => (await db.collection(`bookings/${id}/events`).get()).docs.map((d) => d.data());
const arrive = () => advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'driver_arrived', location: HERE });
const noShow = (location: typeof HERE | null = HERE) =>
  advanceBooking(deps(), 'chofer', { bookingId: 'b1', to: 'no_show', ...(location ? { location } : {}) });

beforeEach(async () => {
  await clear();
  clock = T0;
  await db.doc('users/chofer').set({ role: 'driver', isActive: true });
  await db.doc('driverProfiles/chofer').set({ userId: 'chofer', isAvailable: false, online: true });
  await db.doc('bookings/b1').set({
    riderId: 'ana', driverId: 'chofer', status: 'driver_arriving', estimatedPrice: 100,
    stripePaymentIntentId: 'pi_hold',
    origin: { address: 'Aeropuerto', coordinates: new admin.firestore.GeoPoint(HERE.lat, HERE.lng) },
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('no_show sin política', () => {
  it('no se ofrece (sin noShowAvailableAt) y el servidor lo rechaza', async () => {
    await arrive();
    expect(await doc('bookings/b1')).not.toHaveProperty('noShowAvailableAt');
    clock += 60 * 60_000;
    expect(await reason(noShow())).toBe('no_show_disabled');
    expect((await doc('bookings/b1'))?.status).toBe('driver_arrived');
  });
});

describe('no_show con política', () => {
  beforeEach(async () => { await db.doc('config/ops').set({ cancellationPolicy: POLICY }); });

  it('al llegar, la reserva dice desde cuándo; antes de la espera, too_early', async () => {
    await arrive();
    const at = (await doc('bookings/b1'))?.noShowAvailableAt as admin.firestore.Timestamp;
    expect(at.toMillis()).toBe(T0 + 15 * 60_000);
    clock += 14 * 60_000;
    expect(await reason(noShow())).toBe('no_show_too_early');
  });

  it('pasada la espera: evento con ubicación, alerta a central, chófer libre y sin cobro', async () => {
    await arrive();
    clock += 16 * 60_000;
    expect(await reason(noShow(null))).toBe('location_required');
    await expect(noShow()).resolves.toEqual({ status: 'no_show', alreadyApplied: false });
    const b = (await doc('bookings/b1'))!;
    expect(b.status).toBe('no_show');
    expect(b).not.toHaveProperty('cancellationFee');
    expect(b.stripePaymentIntentId).toBe('pi_hold');
    const e = (await events('b1')).find((x) => x.to === 'no_show')!;
    expect(e).toMatchObject({ from: 'driver_arrived', method: 'driver_no_show', hasLocation: true, waitedMinutes: 16 });
    const alerts = (await db.collection('adminAlerts').where('type', '==', 'rider_no_show').get()).docs.map((d) => d.data());
    expect(alerts).toEqual([expect.objectContaining({ bookingId: 'b1', severity: 'medium', resolved: false })]);
    expect((await doc('driverProfiles/chofer'))?.isAvailable).toBe(true);
    // Repetirlo no duplica nada.
    await expect(noShow()).resolves.toEqual({ status: 'no_show', alreadyApplied: true });
    expect((await db.collection('adminAlerts').where('type', '==', 'rider_no_show').get()).size).toBe(1);
  });

  it('solo desde driver_arrived', async () => {
    clock += 60 * 60_000;
    expect(await reason(noShow())).toBe('invalid_transition');
  });

  it('el admin decide la causa; con causa del pasajero se retiene el % de la etapa no_show sobre lo pagado', async () => {
    await db.doc('bookings/b1/payment/state').set({
      bookingId: 'b1', riderId: 'ana', paymentStatus: 'paid', paymentMethod: 'manual_qr', amountDue: 10000, amountPaid: 10000,
    });
    await arrive();
    clock += 16 * 60_000;
    await noShow();
    const jefa = { adminId: 'jefa', adminEmail: null };
    await expect(adminUpdateBooking({ db }, jefa, {
      action: 'cancel', bookingId: 'b1', reason: 'Pasajero no se presentó, confirmado', cause: 'rider',
    })).resolves.toMatchObject({ status: 'cancelled', retained: 3000, refund: 7000, retentionBasis: 'stage' });
    expect(await doc('bookings/b1')).toMatchObject({ status: 'cancelled', cancelledBy: 'admin' });
    expect(await doc('bookings/b1')).not.toHaveProperty('cancellationFee');
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'refund_pending', amountRetained: 3000, refundDue: 7000 });
  });

  it('si el admin decide que fue culpa del chófer: 0 %', async () => {
    await db.doc('bookings/b1/payment/state').set({
      bookingId: 'b1', riderId: 'ana', paymentStatus: 'paid', paymentMethod: 'manual_qr', amountDue: 10000, amountPaid: 10000,
    });
    await arrive();
    clock += 16 * 60_000;
    await noShow();
    await expect(adminUpdateBooking({ db }, { adminId: 'jefa', adminEmail: null }, {
      action: 'cancel', bookingId: 'b1', reason: 'El chófer esperó en otro punto', cause: 'driver',
    })).resolves.toMatchObject({ retained: 0, refund: 10000, retentionBasis: 'driver_cause' });
  });

  it('el admin no puede fijar un importe: el campo antiguo se rechaza', async () => {
    const jefa = { adminId: 'jefa', adminEmail: null };
    expect(await reason(adminUpdateBooking({ db }, jefa, {
      action: 'cancel', bookingId: 'b1', reason: 'Cancelada por central hoy', cause: 'rider', cancellationFee: 10,
    }))).toBe('invalid_request');
  });
});
