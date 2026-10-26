/**
 * Pagos A7: causas que no retienen nada (decisión 2). Sin chófer a tiempo,
 * el chófer libera, la plataforma cancela: devolución entera. Contra el
 * emulador; porcentajes de PRUEBA, ficticios.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { scheduledCleanup } from '../index';
import { releaseBooking } from '../cancellation';
import { adminUpdateBooking } from '../admin_ops';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const NOW = Date.now();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
// Todo al 100 % para que se note si alguna causa ajena al pasajero retuviera.
const POLICY = {
  stages: ['confirmed', 'driver_arriving', 'driver_arrived', 'no_show'].map((fromStatus) => ({ fromStatus, percent: 100 })),
};

async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'config', 'openRequests', 'adminAlerts', 'payments', 'admin_logs', 'rateLimits']) {
    await db.recursiveDelete(db.collection(col));
  }
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const ledger = async () => (await db.collection('payments').get()).docs.map((d) => ({ id: d.id, ...d.data() }));

async function booking(id: string, status: string, paymentStatus: string, extra: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', status, class: 'business', estimatedPrice: 80, scheduledAt: ts(NOW + 3600_000), ...extra,
  });
  await db.doc(`bookings/${id}/payment/state`).set({
    bookingId: id, riderId: 'ana', paymentStatus, paymentMethod: 'manual_qr', amountDue: 8000,
    amountPaid: paymentStatus === 'paid' ? 8000 : 0,
  });
}

beforeEach(async () => {
  await clear();
  await db.doc('config/ops').set({ cancellationPolicy: POLICY });
  await db.doc('users/luis').set({ role: 'driver', isActive: true });
  await db.doc('driverProfiles/luis').set({ userId: 'luis', isAvailable: false, online: true, documentsVerified: true });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('sin chófer a tiempo (scheduledCleanup)', () => {
  it('pagada: se cancela y se devuelve el 100 %', async () => {
    await booking('vieja', 'pending', 'paid', { scheduledAt: ts(NOW - 2 * 3600_000) });
    await (scheduledCleanup as unknown as Runnable).run({});
    expect(await doc('bookings/vieja')).toMatchObject({ status: 'cancelled', cancelledBy: 'system', cancellationReason: 'no_driver_found' });
    expect(await doc('bookings/vieja/payment/state')).toMatchObject({
      paymentStatus: 'refund_pending', amountRetained: 0, refundDue: 8000, retentionBasis: 'system_cause',
    });
    expect(await ledger()).toEqual([expect.objectContaining({ id: 'refund_vieja', type: 'refund', amount: 8000, status: 'pending' })]);
  });

  it('sin pagar: se cancela y el pedido de pago deja de valer, sin asientos', async () => {
    await booking('impaga', 'pending', 'awaiting_payment', { scheduledAt: ts(NOW - 2 * 3600_000) });
    await (scheduledCleanup as unknown as Runnable).run({});
    expect(await doc('bookings/impaga/payment/state')).toMatchObject({ paymentStatus: 'expired' });
    expect(await ledger()).toEqual([]);
  });

  it('las que aún están a tiempo no se tocan', async () => {
    await booking('futura', 'pending', 'paid');
    await (scheduledCleanup as unknown as Runnable).run({});
    expect((await doc('bookings/futura'))!.status).toBe('pending');
  });
});

describe('el chófer libera la reserva', () => {
  it('vuelve a buscar chófer; el pago sigue íntegro y no hay asientos', async () => {
    await booking('b1', 'confirmed', 'paid', { driverId: 'luis' });
    await releaseBooking({ db }, 'luis', { bookingId: 'b1', reason: 'vehicle_issue' });
    expect((await doc('bookings/b1'))!.status).toBe('pending');
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'paid', amountPaid: 8000 });
    expect(await ledger()).toEqual([]);
  });
});

describe('cancela la plataforma o el chófer (admin)', () => {
  it.each(['platform', 'driver'])('causa %s: 0 % aunque la política diga 100 %', async (cause) => {
    await booking('b1', 'driver_arrived', 'paid', { driverId: 'luis' });
    await expect(adminUpdateBooking({ db }, { adminId: 'jefa', adminEmail: null }, {
      action: 'cancel', bookingId: 'b1', reason: 'Incidencia de la plataforma', cause,
    })).resolves.toMatchObject({ retained: 0, refund: 8000, retentionBasis: `${cause}_cause` });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'refund_pending', refundDue: 8000 });
  });
});
