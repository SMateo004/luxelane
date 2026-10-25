/**
 * B1 (H6): el correo verificado lo decide Auth, no el cliente. Auth va
 * simulado; Firestore, en el emulador.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { createBooking as createBookingFn } from '../index';
import { syncEmailVerification } from '../identity';
import { fakeAuth } from './fake_auth';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

beforeEach(async () => {
  for (const col of ['users', 'rateLimits']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.doc('users/ana').set({ role: 'rider', isActive: true, isVerified: false });
});
afterAll(async () => { await admin.app().delete(); });

describe('syncEmailVerification', () => {
  it('sin verificar en Auth: no cambia nada', async () => {
    const { auth } = fakeAuth({ ana: { emailVerified: false } });
    expect(await syncEmailVerification({ db, auth }, 'ana')).toEqual({ verified: false });
    expect((await db.doc('users/ana').get()).data()?.isVerified).toBe(false);
  });

  it('verificado en Auth: el servidor marca isVerified', async () => {
    const { auth } = fakeAuth({ ana: { emailVerified: true } });
    expect(await syncEmailVerification({ db, auth }, 'ana')).toEqual({ verified: true });
    const d = (await db.doc('users/ana').get()).data()!;
    expect(d.isVerified).toBe(true);
    expect(d.emailVerifiedAt).toBeInstanceOf(admin.firestore.Timestamp);
  });
});

describe('createBooking exige el correo verificado (decisión 1)', () => {
  const run = (token: Record<string, unknown>) =>
    (createBookingFn as unknown as Runnable).run({ auth: { uid: 'ana', token }, app: {}, data: {} });

  it('sin email_verified en el token: email_not_verified', async () => {
    expect(await reason(run({}))).toBe('email_not_verified');
    expect(await reason(run({ email_verified: false }))).toBe('email_not_verified');
  });

  it('verificado: pasa a la validación de la reserva', async () => {
    expect(await reason(run({ email_verified: true }))).not.toBe('email_not_verified');
  });
});
