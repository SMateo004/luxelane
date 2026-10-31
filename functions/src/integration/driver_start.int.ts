/**
 * A10: el aspirante abre su solicitud de chófer (startDriverApplication)
 * contra el emulador de Firestore, con Auth simulado: pasajero que inicia,
 * con reservas, sin correo verificado, admin, doble inicio, cuenta
 * bloqueada, claim que faltó y la cuenta de chófer sin perfil de pagos.
 * Datos FICTICIOS de prueba.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { saveDriverStep, startDriverApplication, gcsDocStore } from '../driver_application';
import {
  ensureStripeCustomer as ensureStripeCustomerFn, listPaymentMethods as listPaymentMethodsFn,
  startDriverApplication as startFn,
} from '../index';
import { fakeAuth } from './fake_auth';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const T0 = Date.UTC(2026, 10, 1, 12);
const VERIFIED = { email_verified: true };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

async function clear(): Promise<void> {
  for (const col of ['users', 'driverApplications', 'driverProfiles', 'bookings', 'admin_logs', 'rateLimits', 'vehicles']) {
    await db.recursiveDelete(db.collection(col));
  }
}

const data = async (p: string) => (await db.doc(p).get()).data();
const logs = async () => (await db.collection('admin_logs').get()).docs.map((d) => d.data());

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true, isVerified: true, email: 'ana@prueba.test' });
});
afterAll(async () => { await admin.app().delete(); });

describe('startDriverApplication', () => {
  it('el aspirante pasajero inicia: rol chófer (documento y claim), solicitud en draft, perfil sin verificar y auditoría', async () => {
    const { auth, calls } = fakeAuth({ ana: { emailVerified: true, claims: { role: 'rider' } } });
    await expect(startDriverApplication({ db, auth, now: () => T0 }, 'ana', VERIFIED))
      .resolves.toEqual({ status: 'draft', created: true, roleChanged: true, refreshToken: true });
    expect((await data('users/ana'))?.role).toBe('driver');
    // isVerified es el correo verificado (H6): no lo toca.
    expect((await data('users/ana'))?.isVerified).toBe(true);
    expect(calls).toEqual(['claims:ana:{"role":"driver"}']);
    expect(await data('driverApplications/ana')).toMatchObject({ driverId: 'ana', status: 'draft', step: 'personal' });
    expect(await data('driverProfiles/ana'))
      .toEqual({ userId: 'ana', documentsVerified: false, isAvailable: false, online: false });
    expect(await logs()).toEqual([expect.objectContaining({
      action: 'start_driver_application', targetId: 'ana', actor: { uid: 'ana', role: 'rider' },
      changes: { role: { before: 'rider', after: 'driver' } }, source: 'server',
    })]);
    // Ya puede seguir con su solicitud.
    await expect(saveDriverStep({ db, store: gcsDocStore(admin.storage().bucket('demo-luxelane.appspot.com')) }, 'ana', {
      step: 'personal', fullName: 'Aspirante De Prueba', nationalIdNumber: '0000000-FIC',
      licenseNumber: 'LIC-FICTICIA-2', licenseExpiry: T0 + 400 * 24 * 3600_000,
    })).resolves.toEqual({ step: 'personal', saved: true });
  });

  it('con alguna reserva (de cualquier estado), rechazado y sin cambiar nada', async () => {
    await db.doc('bookings/b1').set({ riderId: 'ana', status: 'cancelled' });
    const { auth, calls } = fakeAuth({ ana: { emailVerified: true } });
    expect(await reason(startDriverApplication({ db, auth }, 'ana', VERIFIED))).toBe('has_bookings');
    expect((await data('users/ana'))?.role).toBe('rider');
    expect(calls).toEqual([]);
    expect(await data('driverApplications/ana')).toBeUndefined();
    expect(await logs()).toEqual([]);
  });

  it('sin correo verificado en el token, rechazado', async () => {
    const { auth, calls } = fakeAuth({ ana: { emailVerified: false } });
    expect(await reason(startDriverApplication({ db, auth }, 'ana', { email_verified: false }))).toBe('email_not_verified');
    expect(await reason(startDriverApplication({ db, auth }, 'ana', {}))).toBe('email_not_verified');
    expect((await data('users/ana'))?.role).toBe('rider');
    expect(calls).toEqual([]);
  });

  it('un admin no se convierte en chófer', async () => {
    await db.doc('users/jefa').set({ role: 'admin', isActive: true });
    const { auth, calls } = fakeAuth({ jefa: { emailVerified: true, claims: { role: 'admin' } } });
    expect(await reason(startDriverApplication({ db, auth }, 'jefa', VERIFIED))).toBe('admin_account');
    expect((await data('users/jefa'))?.role).toBe('admin');
    expect(calls).toEqual([]);
  });

  it('cuenta bloqueada, rechazada', async () => {
    await db.doc('users/ana').update({ isActive: false });
    const { auth, calls } = fakeAuth({ ana: { emailVerified: true } });
    expect(await reason(startDriverApplication({ db, auth }, 'ana', VERIFIED))).toBe('inactive_user');
    expect((await data('users/ana'))?.role).toBe('rider');
    expect(calls).toEqual([]);
  });

  it('doble inicio: idempotente (una solicitud, una auditoría, el estado que tenga)', async () => {
    const { auth } = fakeAuth({ ana: { emailVerified: true } });
    await startDriverApplication({ db, auth, now: () => T0 }, 'ana', VERIFIED);
    await db.doc('driverApplications/ana').update({ status: 'needs_changes' });
    await expect(startDriverApplication({ db, auth, now: () => T0 + 1000 }, 'ana', VERIFIED))
      .resolves.toEqual({ status: 'needs_changes', created: false, roleChanged: false, refreshToken: true });
    expect(await data('driverApplications/ana')).toMatchObject({ status: 'needs_changes', createdAt: admin.firestore.Timestamp.fromMillis(T0) });
    expect(await logs()).toHaveLength(1);
  });

  it('si el claim no se llegó a fijar, el reintento lo fija', async () => {
    const { auth } = fakeAuth({ ana: { emailVerified: true } });
    await startDriverApplication({ db, auth }, 'ana', VERIFIED);
    const second = fakeAuth({ ana: { emailVerified: true, claims: { role: 'rider' } } });
    await startDriverApplication({ db, auth: second.auth }, 'ana', VERIFIED);
    expect(second.calls).toEqual(['claims:ana:{"role":"driver"}']);
  });

  it('chófer dado de alta por el admin sin solicitud: se le abre una, sin tocar su perfil', async () => {
    await db.doc('users/luis').set({ role: 'driver', isActive: true });
    await db.doc('driverProfiles/luis').set({ userId: 'luis', documentsVerified: true, isAvailable: false, online: false });
    const { auth } = fakeAuth({ luis: { emailVerified: true, claims: { role: 'driver' } } });
    await expect(startDriverApplication({ db, auth }, 'luis', VERIFIED))
      .resolves.toMatchObject({ status: 'draft', created: true, roleChanged: false });
    expect((await data('driverProfiles/luis'))?.documentsVerified).toBe(true);
  });

  it('por la callable exportada: sin sesión, unauthenticated', async () => {
    expect(await reason((startFn as unknown as Runnable).run({ app: {}, data: null }))).toBe('unauthenticated');
  });
});

describe('la cuenta de chófer no usa un perfil de pagos (A10)', () => {
  it('ensureStripeCustomer y listPaymentMethods rechazan a un chófer, aunque tuviera cliente de cuando era pasajero', async () => {
    await db.doc('users/ana').set({ role: 'driver', isActive: true, stripeCustomerId: 'cus_ficticio' });
    const req = { auth: { uid: 'ana', token: { role: 'driver' } }, app: {} };
    expect(await reason((ensureStripeCustomerFn as unknown as Runnable).run({ ...req, data: null }))).toBe('driver_account');
    expect(await reason((listPaymentMethodsFn as unknown as Runnable).run({ ...req, data: { customerId: 'cus_ficticio' } })))
      .toBe('driver_account');
  });
});
