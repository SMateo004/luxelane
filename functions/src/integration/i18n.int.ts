/**
 * Idiomas (A4) contra el emulador: cada aviso del servidor sale en el idioma
 * de quien lo recibe (users/{uid}.locale; sin él, español). FCM simulado.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import * as admin from 'firebase-admin';

const sendEachForMulticast = jest.fn(async (_m: unknown) => ({ responses: [] }));
jest.spyOn(admin, 'messaging').mockReturnValue({ sendEachForMulticast } as unknown as admin.messaging.Messaging);

import { onBookingStatusChanged } from '../index';
import { pushToAdmins } from '../incidents';
import { cancelBooking } from '../cancellation';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

async function clear(): Promise<void> {
  await db.recursiveDelete(db.collection('bookings'));
  for (const col of ['users', 'config', 'adminAlerts', 'payments']) {
    const snap = await db.collection(col).get();
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
  }
}

const ref = db.doc('bookings/viaje');
const sent = () => sendEachForMulticast.mock.calls.map((c) =>
  (c[0] as { notification: { title: string; body: string } }).notification);

async function change(to: Record<string, unknown>): Promise<void> {
  const before = await ref.get();
  await ref.update(to);
  await (onBookingStatusChanged as unknown as Runnable).run({
    data: { before, after: await ref.get() }, params: { bookingId: 'viaje' },
  });
}

beforeEach(async () => {
  sendEachForMulticast.mockClear();
  await clear();
  await db.doc('users/chofer').set({ role: 'driver', isActive: true, fcmTokens: ['t-chofer'], locale: 'en' });
  await ref.set({ riderId: 'ana', driverId: 'chofer', status: 'confirmed', estimatedPrice: 100 });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('avisos al pasajero en su idioma', () => {
  it.each([
    ['pt', 'Seu motorista está a caminho', 'Seu motorista está indo até o ponto de embarque.'],
    ['en', 'Your chauffeur is on the way', 'Your chauffeur is heading to the pickup point.'],
    [undefined, 'El chófer está en camino', 'Tu chófer va hacia el punto de recogida.'],
    ['fr', 'El chófer está en camino', 'Tu chófer va hacia el punto de recogida.'],
  ])('locale %s: bandeja y push', async (locale, title, body) => {
    await db.doc('users/ana').set({ role: 'rider', fcmTokens: ['t-ana'], ...(locale ? { locale } : {}) });
    await change({ status: 'driver_arriving' });
    const inbox = (await db.collection('users/ana/notifications').get()).docs.map((d) => d.data());
    expect(inbox).toEqual([expect.objectContaining({ title, body, type: 'driver_arriving' })]);
    expect(sent()).toEqual([{ title, body }]);
  });
});

describe('avisos al chófer en su idioma', () => {
  it('cancelación del pasajero: bandeja y push del chófer en inglés', async () => {
    await db.doc('users/ana').set({ role: 'rider', isActive: true, locale: 'pt' });
    await db.doc('config/ops').set({});
    await cancelBooking({ db }, 'ana', { bookingId: 'viaje' });
    const inbox = (await db.collection('users/chofer/notifications').get()).docs.map((d) => d.data());
    expect(inbox).toEqual([expect.objectContaining({
      title: 'Booking cancelled', body: 'The passenger cancelled the booking. You are available again.', locale: 'en',
    })]);
  });
});

describe('SOS a los admin: un envío por idioma', () => {
  it('admin en español y admin en inglés reciben cada uno el suyo', async () => {
    await db.doc('users/jefa').set({ role: 'admin', fcmTokens: ['t-es'] });
    await db.doc('users/boss').set({ role: 'admin', fcmTokens: ['t-en'], locale: 'en' });
    const push = jest.fn(async (_t: string[], _a: string, _b: string, _d: Record<string, string>) => undefined);
    const n = await pushToAdmins({ db, push }, 'incident_raised', { ref: 'ABC123' }, { incidentId: 'i1' });
    expect(n).toBe(2);
    const byToken = Object.fromEntries(push.mock.calls.map((c) => [c[0].join(), c[1]]));
    expect(byToken).toEqual({ 't-es': 'SOS en un viaje', 't-en': 'SOS during a trip' });
  });
});
