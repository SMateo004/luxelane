/**
 * Notificaciones al pasajero con el flujo nuevo: los cambios de estado los
 * escribe el servidor (advanceBooking, verifyPickup) y los triggers de
 * siempre siguen avisando. verified no genera aviso. FCM va simulado.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { onBookingStatusChanged } from '../index';
import { advanceBooking, getPickupCode, TripDeps, verifyPickup } from '../trip_flow';

const db = admin.firestore();
const deps: TripDeps = { db, pickupSecret: 'secreto-de-prueba' };
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

async function clear(): Promise<void> {
  const bookings = await db.collection('bookings').get();
  for (const b of bookings.docs) await db.recursiveDelete(b.ref);
  for (const col of ['users', 'config', 'adminAlerts']) {
    const snap = await db.collection(col).get();
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
  }
}

const ref = db.doc('bookings/viaje');

/** Ejecuta un paso del servidor y pasa el cambio al trigger de avisos. */
async function step(fn: () => Promise<unknown>): Promise<void> {
  const before = await ref.get();
  await fn();
  await (onBookingStatusChanged as unknown as Runnable).run({
    data: { before, after: await ref.get() },
    params: { bookingId: 'viaje' },
  });
}

const notifications = async () =>
  (await db.collection('users/ana/notifications').orderBy('createdAt').get()).docs.map((d) => d.data());

beforeEach(async () => {
  sendEachForMulticast.mockClear();
  await clear();
  await db.doc('users/ana').set({ role: 'rider', fcmTokens: ['token-ana'] });
  await db.doc('users/chofer').set({ role: 'driver', isActive: true });
  await ref.set({
    riderId: 'ana',
    driverId: 'chofer',
    status: 'confirmed',
    estimatedPrice: 100,
    origin: { address: 'Recogida', coordinates: new admin.firestore.GeoPoint(-17.78, -63.18) },
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('avisos al pasajero con el flujo del servidor', () => {
  it('en camino, llegó, iniciado y completado avisan; verificada no', async () => {
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'driver_arriving' }));
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'driver_arrived' }));
    const { code } = await getPickupCode(deps, 'ana', { bookingId: 'viaje' });
    await step(() => verifyPickup(deps, 'chofer', { bookingId: 'viaje', code }));
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'in_progress' }));
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'completed' }));

    expect((await notifications()).map((n) => n.type)).toEqual([
      'driver_arriving',
      'driver_arrived',
      'ride_started',
      'ride_completed',
    ]);
    // Un push por aviso: ninguno por la verificación.
    expect(sendEachForMulticast).toHaveBeenCalledTimes(4);
  });

  it('al llegar, el aviso pide abrir la app y dar el código', async () => {
    await ref.update({ status: 'driver_arriving' });
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'driver_arrived' }));
    const [n] = await notifications();
    expect(n.body).toContain('código de recogida');
    const push = (sendEachForMulticast.mock.calls[0] as unknown as [{ notification: { body: string } }])[0];
    expect(push.notification.body).toContain('código de recogida');
    // El código nunca va en el aviso.
    const { code } = await getPickupCode(deps, 'ana', { bookingId: 'viaje' });
    expect(JSON.stringify(push)).not.toContain(code);
  });

  it('un paso repetido (doble envío) no repite el aviso', async () => {
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'driver_arriving' }));
    await step(() => advanceBooking(deps, 'chofer', { bookingId: 'viaje', to: 'driver_arriving' }));
    expect(await notifications()).toHaveLength(1);
    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
  });
});
