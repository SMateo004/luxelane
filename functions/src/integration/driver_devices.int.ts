/**
 * B7 (decisión 5): el dispositivo del chófer se anota sin bloquear. El
 * primero es el alta normal; uno nuevo deja evento y alerta baja.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { registerDriverDevice as registerFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const PHONE_A = 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa';
const PHONE_B = 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb';

const register = (uid: string, installationId: string, role = 'driver') =>
  (registerFn as unknown as Runnable).run({
    auth: { uid, token: { role } }, app: {},
    data: { installationId, platform: 'android', appVersion: '1.4.0' },
  });

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

async function clear(): Promise<void> {
  for (const col of ['users', 'rateLimits', 'adminAlerts']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.recursiveDelete(db.collection('driverDevices'));
}

const alerts = async () => (await db.collection('adminAlerts').where('type', '==', 'new_driver_device').get()).docs
  .map((d) => d.data());
const events = async (uid: string) => (await db.collection(`driverDevices/${uid}/events`).get()).docs
  .map((d) => d.data().type);

beforeEach(async () => {
  await clear();
  await db.doc('users/luis').set({ role: 'driver', isActive: true });
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('registerDriverDevice', () => {
  it('primer dispositivo: lo anota con un evento y sin alerta', async () => {
    await expect(register('luis', PHONE_A)).resolves.toEqual({ isNew: true });
    const d = (await db.doc(`driverDevices/luis/devices/${PHONE_A}`).get()).data()!;
    expect(d).toMatchObject({ platform: 'android', appVersion: '1.4.0' });
    expect(d.firstSeenAt).toBeInstanceOf(admin.firestore.Timestamp);
    expect(await events('luis')).toEqual(['first_device']);
    expect(await alerts()).toHaveLength(0);
  });

  it('el mismo dispositivo otra vez: solo actualiza lastSeenAt', async () => {
    await register('luis', PHONE_A);
    await expect(register('luis', PHONE_A)).resolves.toEqual({ isNew: false });
    expect(await events('luis')).toHaveLength(1);
    expect(await alerts()).toHaveLength(0);
  });

  it('un dispositivo nuevo: evento y alerta de severidad baja, sin bloquear', async () => {
    await register('luis', PHONE_A);
    await expect(register('luis', PHONE_B)).resolves.toEqual({ isNew: true });
    expect((await events('luis')).sort()).toEqual(['first_device', 'new_device']);
    const a = await alerts();
    expect(a).toHaveLength(1);
    expect(a[0]).toMatchObject({ severity: 'low', driverId: 'luis', resolved: false });
    // La alerta no lleva el identificador de instalación.
    expect(JSON.stringify(a[0])).not.toContain(PHONE_B);
    expect((await db.doc('driverDevices/luis').get()).data()?.deviceCount).toBe(2);
  });

  it('solo chóferes', async () => {
    expect(await reason(register('ana', PHONE_A, 'rider'))).toBe('driver_required');
    expect((await db.collection('driverDevices').get()).size).toBe(0);
  });

  it('identificador inválido: invalid_request', async () => {
    expect(await reason(register('luis', '../otro'))).toBe('invalid_request');
  });
});
