/**
 * Reconciliación de openRequests y reintento idempotente de
 * onBookingCreated, contra el emulador de Firestore.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

// FCM falso: se cuentan los avisos que se enviarían a los chóferes.
const sendEachForMulticast = jest.fn(async () => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { onBookingCreated } from '../index';
import { reconcileOpenRequests } from '../reconcile';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (event: any) => Promise<any> };

const booking = (status: string) => ({
  riderId: 'ana',
  status,
  class: 'business',
  serviceType: 'oneWay',
  estimatedPrice: 100,
  origin: { address: 'Calle Exacta 1', coordinates: new admin.firestore.GeoPoint(-17.78, -63.18) },
});

async function clear(): Promise<void> {
  for (const col of ['bookings', 'openRequests', 'adminAlerts', 'driverProfiles', 'users']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

const ids = async (col: string) => (await db.collection(col).get()).docs.map((d) => d.id).sort();

beforeEach(async () => {
  await clear();
  sendEachForMulticast.mockClear();
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('reconcileOpenRequests', () => {
  it('crea la que falta, borra las huérfanas y escribe una alerta', async () => {
    await db.doc('bookings/sinSolicitud').set(booking('pending'));
    await db.doc('bookings/conSolicitud').set(booking('pending'));
    await db.doc('openRequests/conSolicitud').set({ estimatedPrice: 100 });
    await db.doc('bookings/cancelada').set(booking('cancelled'));
    await db.doc('openRequests/cancelada').set({ estimatedPrice: 100 }); // huérfana (carrera de cancelación)
    await db.doc('openRequests/sinReserva').set({ estimatedPrice: 100 }); // huérfana (reserva borrada)

    const result = await reconcileOpenRequests(db);

    expect(result).toEqual({ created: ['sinSolicitud'], deleted: ['cancelada', 'sinReserva'] });
    expect(await ids('openRequests')).toEqual(['conSolicitud', 'sinSolicitud']);
    const created = (await db.doc('openRequests/sinSolicitud').get()).data();
    expect(JSON.stringify(created)).not.toContain('Exacta');
    const alerts = (await db.collection('adminAlerts').get()).docs.map((d) => d.data());
    expect(alerts).toEqual([expect.objectContaining({
      type: 'open_requests_reconciled', created: ['sinSolicitud'], deleted: ['cancelada', 'sinReserva'],
    })]);
  });

  it('es idempotente: la segunda pasada no cambia nada ni escribe otra alerta', async () => {
    await db.doc('bookings/sinSolicitud').set(booking('pending'));
    await db.doc('openRequests/huerfana').set({ estimatedPrice: 100 });
    await reconcileOpenRequests(db);
    const second = await reconcileOpenRequests(db);
    expect(second).toEqual({ created: [], deleted: [] });
    expect((await db.collection('adminAlerts').get()).size).toBe(1);
  });

  it('sin nada que arreglar no escribe alertas', async () => {
    await db.doc('bookings/ok').set(booking('pending'));
    await db.doc('openRequests/ok').set({ estimatedPrice: 100 });
    expect(await reconcileOpenRequests(db)).toEqual({ created: [], deleted: [] });
    expect((await db.collection('adminAlerts').get()).size).toBe(0);
  });
});

describe('onBookingCreated con reintento', () => {
  it('un reintento no avisa dos veces a los chóferes', async () => {
    await db.doc('users/luis').set({ role: 'driver', fcmTokens: ['token-luis'] });
    await db.doc('driverProfiles/luis').set({ isAvailable: true, documentsVerified: true });
    const ref = db.doc('bookings/r1');
    await ref.set(booking('pending'));
    const event = { data: await ref.get(), params: { bookingId: 'r1' } };
    await (onBookingCreated as unknown as Runnable).run(event);
    await (onBookingCreated as unknown as Runnable).run(event); // reintento de la plataforma
    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
    expect((await ref.get()).data()?.driversNotifiedAt).toBeDefined();
  });
});

describe('reintentos: errores transitorios frente a permanentes', () => {
  const run = (event: unknown) => (onBookingCreated as unknown as Runnable).run(event);

  beforeEach(async () => {
    await db.doc('users/luis').set({ role: 'driver', fcmTokens: ['token-luis'] });
    await db.doc('driverProfiles/luis').set({ isAvailable: true, documentsVerified: true });
  });

  it('FCM caído (transitorio): falla para reintentar y el reintento sí avisa', async () => {
    const ref = db.doc('bookings/t1');
    await ref.set(booking('pending'));
    const event = { data: await ref.get(), params: { bookingId: 't1' } };
    sendEachForMulticast.mockRejectedValueOnce(Object.assign(new Error('fcm'), { code: 'messaging/server-unavailable' }));
    await expect(run(event)).rejects.toThrow();
    expect((await ref.get()).data()?.driversNotifiedAt).toBeUndefined();
    await run(event); // reintento de la plataforma
    expect(sendEachForMulticast).toHaveBeenCalledTimes(2);
    expect((await ref.get()).data()?.driversNotifiedAt).toBeDefined();
  });

  it('argumento de FCM inválido (permanente): no relanza ni se repite', async () => {
    const ref = db.doc('bookings/p1');
    await ref.set(booking('pending'));
    const event = { data: await ref.get(), params: { bookingId: 'p1' } };
    sendEachForMulticast.mockRejectedValueOnce(Object.assign(new Error('fcm'), { code: 'messaging/invalid-argument' }));
    await expect(run(event)).resolves.toBeUndefined();
    await run(event);
    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
  });

  it('reserva borrada antes de procesarla (NOT_FOUND, permanente): no relanza', async () => {
    const ref = db.doc('bookings/borrada');
    await ref.set({ ...booking('pending'), estimatedPrice: 10 }); // fuerza escribir pricingReview
    const event = { data: await ref.get(), params: { bookingId: 'borrada' } };
    await ref.delete();
    await expect(run(event)).resolves.toBeUndefined();
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('reserva que no está pendiente (datos que no sirven): no avisa ni falla', async () => {
    const ref = db.doc('bookings/conf');
    await ref.set(booking('confirmed'));
    await expect(run({ data: await ref.get(), params: { bookingId: 'conf' } })).resolves.toBeUndefined();
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });
});
