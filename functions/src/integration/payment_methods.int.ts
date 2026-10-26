/** A2: un método de pago desactivado en config/ops se rechaza (emulador). */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { createPaymentIntent } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'rateLimits']) await db.recursiveDelete(db.collection(col));
  await db.recursiveDelete(db.collection('bookings'));
}
const intent = () => (createPaymentIntent as unknown as Runnable).run({
  auth: { uid: 'ana', token: {} }, app: {}, data: { bookingId: 'b1' },
});

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('bookings/b1').set({ riderId: 'ana', status: 'pending', estimatedPrice: 100 });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('tarjeta desactivada (Stripe apagado por config/ops)', () => {
  it('sin paymentMethods: createPaymentIntent se rechaza antes de llamar al proveedor', async () => {
    expect(await reason(intent())).toBe('method_disabled');
  });

  it('con card: false también', async () => {
    await db.doc('config/ops').set({ paymentMethods: { card: false }, paymentInstructions: { card: { provider: 'stripe' } } });
    expect(await reason(intent())).toBe('method_disabled');
  });

  it('activada pero sin proveedor elegido, también', async () => {
    await db.doc('config/ops').set({ paymentMethods: { card: true } });
    expect(await reason(intent())).toBe('method_disabled');
  });
});
