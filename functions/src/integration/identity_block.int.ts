/**
 * B3: setUserBlocked deshabilita en Auth, revoca sesiones, marca isActive,
 * apaga la disponibilidad del chófer y audita; desbloquear lo revierte.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { setUserBlocked } from '../identity';
import { setUserBlocked as setUserBlockedFn } from '../index';
import { fakeAuth } from './fake_auth';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const actor = { adminId: 'jefa', adminEmail: 'jefa@example.com' };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

beforeEach(async () => {
  for (const col of ['users', 'driverProfiles', 'admin_logs', 'rateLimits']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('users/luis').set({ role: 'driver', isActive: true });
  await db.doc('driverProfiles/luis').set({ userId: 'luis', isAvailable: true, online: true });
});
afterAll(async () => { await admin.app().delete(); });

describe('setUserBlocked', () => {
  it('bloquear: Auth deshabilitado, sesiones revocadas, isActive false, sin disponibilidad y auditoría', async () => {
    const { auth, calls } = fakeAuth({ luis: {} });
    await setUserBlocked({ db, auth }, actor, { uid: 'luis', blocked: true, reason: 'Reclamo grave' });
    expect(calls).toEqual(['update:luis:{"disabled":true}', 'revoke:luis']);
    expect((await db.doc('users/luis').get()).data()).toMatchObject({ isActive: false });
    expect((await db.doc('driverProfiles/luis').get()).data()).toMatchObject({ isAvailable: false, online: false });
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({ action: 'block_user', targetId: 'luis', details: 'Reclamo grave', source: 'server' })]);
  });

  it('desbloquear lo revierte (sin revocar)', async () => {
    const { auth, calls } = fakeAuth({ luis: { disabled: true } });
    await db.doc('users/luis').update({ isActive: false });
    await setUserBlocked({ db, auth }, actor, { uid: 'luis', blocked: false });
    expect(calls).toEqual(['update:luis:{"disabled":false}']);
    expect((await db.doc('users/luis').get()).data()).toMatchObject({ isActive: true, blockedAt: null });
  });

  it('nadie se bloquea a sí mismo', async () => {
    const { auth } = fakeAuth({ jefa: {} });
    expect(await reason(setUserBlocked({ db, auth }, actor, { uid: 'jefa', blocked: true }))).toBe('cannot_block_self');
  });

  it('la callable exige rol admin', async () => {
    const run = (uid: string, token: Record<string, unknown>) =>
      (setUserBlockedFn as unknown as Runnable).run({ auth: { uid, token }, app: {}, data: { uid: 'jefa', blocked: true } });
    expect(await reason(run('luis', {}))).toBe('admin_required');
  });
});
