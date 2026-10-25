/**
 * B6 (decisión 7): acceptTerms guarda la versión vigente con la hora del
 * servidor, y createBooking exige haberla aceptado cuando
 * config/global.legalVersion existe. Firestore, en el emulador.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { acceptTerms as acceptTermsFn, createBooking as createBookingFn } from '../index';
import { acceptTerms } from '../identity';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const token = { email_verified: true };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

const book = () => (createBookingFn as unknown as Runnable).run({ auth: { uid: 'ana', token }, app: {}, data: {} });
const accept = (data: unknown) =>
  (acceptTermsFn as unknown as Runnable).run({ auth: { uid: 'ana', token }, app: {}, data });

beforeEach(async () => {
  for (const col of ['users', 'rateLimits']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.doc('config/global').delete();
  await db.doc('users/ana').set({ role: 'rider', isActive: true, isVerified: true });
});
afterAll(async () => { await db.doc('config/global').delete(); await admin.app().delete(); });

describe('acceptTerms', () => {
  it('guarda la versión vigente, la hora del servidor y la versión de la app', async () => {
    await db.doc('config/global').set({ legalVersion: '2026-10' });
    await expect(accept({ version: '2026-10', appVersion: '1.4.0' })).resolves.toEqual({ version: '2026-10' });
    const t = (await db.doc('users/ana').get()).data()!.terms;
    expect(t.version).toBe('2026-10');
    expect(t.appVersion).toBe('1.4.0');
    expect(t.acceptedAt).toBeInstanceOf(admin.firestore.Timestamp);
  });

  it('una versión que no es la vigente: terms_outdated, no guarda nada', async () => {
    await db.doc('config/global').set({ legalVersion: '2026-10' });
    expect(await reason(acceptTerms(db, 'ana', { version: '2026-01', appVersion: '1.4.0' }))).toBe('terms_outdated');
    expect(await reason(acceptTerms(db, 'ana', { appVersion: '1.4.0' }))).toBe('terms_outdated');
    expect((await db.doc('users/ana').get()).data()!.terms).toBeUndefined();
  });

  it('sin versión vigente configurada: se anota sin versión', async () => {
    await expect(accept({ appVersion: '1.4.0' })).resolves.toEqual({ version: null });
    expect((await db.doc('users/ana').get()).data()!.terms.version).toBeNull();
  });

  it('sin sesión: no', async () => {
    const r = (acceptTermsFn as unknown as Runnable).run({ app: {}, data: { appVersion: '1' } });
    expect(await reason(r)).toBe('unauthenticated');
  });
});

describe('createBooking exige los términos vigentes', () => {
  it('sin legalVersion: no se exige', async () => {
    expect(await reason(book())).not.toBe('terms_required');
  });

  it('con legalVersion y sin aceptar: terms_required', async () => {
    await db.doc('config/global').set({ legalVersion: '2026-10' });
    expect(await reason(book())).toBe('terms_required');
  });

  it('aceptada una versión anterior: terms_required', async () => {
    await db.doc('config/global').set({ legalVersion: '2026-10' });
    await db.doc('users/ana').update({ terms: { version: '2026-01' } });
    expect(await reason(book())).toBe('terms_required');
  });

  it('aceptada la vigente: pasa a la validación de la reserva', async () => {
    await db.doc('config/global').set({ legalVersion: '2026-10' });
    await accept({ version: '2026-10', appVersion: '1.4.0' });
    expect(await reason(book())).not.toBe('terms_required');
  });
});
