/**
 * B2: setUserRole (solo admin, auditoría en el servidor, sesiones revocadas)
 * y el rol por claim con respaldo en Firestore. Auth simulado.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { requireRole, resolveRole, setUserRole } from '../identity';
import { resolveAlert as resolveAlertFn } from '../index';
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
  for (const col of ['users', 'admin_logs', 'adminAlerts', 'rateLimits', 'config']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('users/bloqueada').set({ role: 'admin', isActive: false });
});
afterAll(async () => { await admin.app().delete(); });

describe('setUserRole', () => {
  it('fija claim y documento, revoca sesiones y audita en el servidor', async () => {
    const { auth, calls } = fakeAuth({ ana: { claims: { otro: 1 } } });
    expect(await setUserRole({ db, auth }, actor, { uid: 'ana', role: 'driver' }))
      .toEqual({ uid: 'ana', role: 'driver', previous: 'rider' });
    expect(calls).toEqual(['claims:ana:{"otro":1,"role":"driver"}', 'revoke:ana']);
    expect((await db.doc('users/ana').get()).data()?.role).toBe('driver');
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({
      adminId: 'jefa', action: 'set_role', targetId: 'ana', details: 'rider → driver', source: 'server',
    })]);
  });

  it('nadie cambia su propio rol', async () => {
    const { auth, calls } = fakeAuth({ jefa: {} });
    expect(await reason(setUserRole({ db, auth }, actor, { uid: 'jefa', role: 'rider' }))).toBe('cannot_change_own_role');
    expect(calls).toEqual([]);
  });

  it('usuario inexistente', async () => {
    const { auth } = fakeAuth({});
    expect(await reason(setUserRole({ db, auth }, actor, { uid: 'nadie', role: 'rider' }))).toBe('user_not_found');
  });
});

describe('rol por claim (transición)', () => {
  it('el claim manda; sin claim, Firestore', async () => {
    expect(await resolveRole(db, { uid: 'ana', token: { role: 'admin' } })).toMatchObject({ role: 'admin', source: 'claim' });
    expect(await resolveRole(db, { uid: 'ana', token: {} })).toMatchObject({ role: 'rider', source: 'firestore' });
  });

  it('isActive sale de Firestore aunque el claim diga admin', async () => {
    expect(await reason(requireRole(db, { uid: 'bloqueada', token: { role: 'admin' } }, 'admin'))).toBe('inactive_user');
  });

  it('una callable de admin rechaza a un pasajero con el claim rider aunque Firestore diga admin', async () => {
    await db.doc('adminAlerts/a1').set({ type: 'x', resolved: false });
    const run = (uid: string, token: Record<string, unknown>) =>
      (resolveAlertFn as unknown as Runnable).run({
        auth: { uid, token: { ...token, auth_time: Math.floor(Date.now() / 1000) } }, app: {}, data: { alertId: 'a1' },
      });
    expect(await reason(run('jefa', { role: 'rider' }))).toBe('admin_required');
    expect(await reason(run('ana', { role: 'admin' }))).toBe('ok');
  });
});
