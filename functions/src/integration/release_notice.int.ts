/**
 * 0.5: reserva liberada por el chófer a 45 min de la recogida y sin nuevo
 * chófer. El pasajero recibe «Buscamos otro chófer» (aviso en la app y
 * push) y central una alerta que dice cuánto falta para la recogida.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { onBookingStatusChanged } from '../index';
import { releaseBooking } from '../cancellation';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const T0 = Date.UTC(2026, 9, 25, 12);
const ref = db.doc('bookings/b1');

async function clear(): Promise<void> {
  for (const col of ['bookings', 'users', 'driverProfiles', 'adminAlerts', 'openRequests']) {
    await db.recursiveDelete(db.collection(col));
  }
}

beforeEach(async () => {
  sendEachForMulticast.mockClear();
  await clear();
  await db.doc('users/ana').set({ role: 'rider', fcmTokens: ['token-ana'] });
  await db.doc('driverProfiles/chofer').set({ userId: 'chofer', isAvailable: false, online: true });
  await ref.set({
    riderId: 'ana', driverId: 'chofer', status: 'confirmed', estimatedPrice: 100, class: 'business',
    scheduledAt: admin.firestore.Timestamp.fromMillis(T0 + 45 * 60_000),
    origin: { address: 'Calle 1', coordinates: new admin.firestore.GeoPoint(-17.7, -63.1) },
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('reserva liberada cerca de la hora y sin nuevo chófer', () => {
  it('el pasajero recibe «Buscamos otro chófer» y central la alerta con los minutos', async () => {
    const before = await ref.get();
    await releaseBooking({ db, now: () => T0 }, 'chofer', { bookingId: 'b1', reason: 'personal_emergency' });
    await (onBookingStatusChanged as unknown as Runnable).run({
      data: { before, after: await ref.get() }, params: { bookingId: 'b1' },
    });

    const notes = (await db.collection('users/ana/notifications').get()).docs.map((d) => d.data());
    expect(notes).toEqual([expect.objectContaining({
      title: 'Buscamos otro chófer', type: 'booking_driver_released', bookingId: 'b1', isRead: false,
    })]);
    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
    expect(sendEachForMulticast.mock.calls[0]).toEqual([expect.objectContaining({
      tokens: ['token-ana'],
      notification: expect.objectContaining({ title: 'Buscamos otro chófer' }),
    })]);

    const alerts = (await db.collection('adminAlerts').get()).docs.map((d) => d.data());
    expect(alerts).toEqual([expect.objectContaining({
      type: 'driver_released_booking', severity: 'high', minutesToPickup: 45, resolved: false,
    })]);
    expect(alerts[0].message).toContain('faltan 45 min');

    // Sin nuevo chófer la reserva queda buscando: la app lo explica (ver
    // pending_status_test.dart) y no hay otro aviso hasta asignar o cancelar.
    expect((await ref.get()).data()).toMatchObject({ status: 'pending', lastRelease: { reason: 'personal_emergency' } });
  });
});
