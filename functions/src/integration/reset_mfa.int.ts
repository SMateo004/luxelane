/**
 * C4: quitar el segundo factor de una cuenta que perdió el teléfono, contra
 * el emulador de Firestore (Auth simulado).
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { resetMfa } from '../migrations/reset_mfa';
import { fakeAuth } from './fake_auth';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const args = { email: 'luis@example.com', reason: 'perdió el teléfono', operator: 'Responsable' };

async function clear(): Promise<void> {
  for (const col of ['users', 'admin_logs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

beforeEach(async () => {
  await clear();
  await db.doc('users/luis').set({ role: 'driver', isActive: true });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

const withTotp = () => fakeAuth({ luis: { email: 'luis@example.com', factors: [{ uid: 'f1', factorId: 'totp' }] } });

describe('resetMfa', () => {
  it('DRY-RUN: informa y no toca nada', async () => {
    const { auth, calls } = withTotp();
    expect(await resetMfa({ db, auth }, args, false)).toEqual({ uid: 'luis', role: 'driver', factors: ['totp'] });
    expect(calls).toEqual([]);
    expect((await db.collection('admin_logs').get()).size).toBe(0);
  });

  it('apply: quita los factores, revoca sesiones y deja auditoría', async () => {
    const { auth, calls } = withTotp();
    await resetMfa({ db, auth }, args, true);
    expect(calls).toEqual(['update:luis:{"multiFactor":{"enrolledFactors":null}}', 'revoke:luis']);
    expect((await auth.getUser('luis')).multiFactor?.enrolledFactors).toEqual([]);
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toHaveLength(1);
    expect(logs[0]).toMatchObject({ action: 'reset_mfa', targetId: 'luis', source: 'script' });
    expect(logs[0].details).toContain('perdió el teléfono');
    expect(logs[0].details).toContain('Responsable');
  });

  it('sin segundo factor: no hay nada que quitar', async () => {
    const { auth, calls } = fakeAuth({ luis: { email: 'luis@example.com' } });
    expect((await resetMfa({ db, auth }, args, true)).factors).toEqual([]);
    expect(calls).toEqual([]);
  });

  it('correo sin cuenta: error, sin auditoría', async () => {
    const { auth } = withTotp();
    await expect(resetMfa({ db, auth }, { ...args, email: 'nadie@example.com' }, true)).rejects.toThrow();
    expect((await db.collection('admin_logs').get()).size).toBe(0);
  });
});
