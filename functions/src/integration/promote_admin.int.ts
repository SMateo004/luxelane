/**
 * B9: promote_admin contra el emulador de Firestore (Auth simulado):
 * DRY-RUN no escribe; con apply fija claim y documento, revoca sesiones y
 * deja la auditoría.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { promoteAdmin } from '../migrations/promote_admin';
import { fakeAuth } from './fake_auth';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const args = { email: 'ana@example.com', reason: 'primer admin del piloto', operator: 'Responsable' };

async function clear(): Promise<void> {
  for (const col of ['users', 'admin_logs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

beforeEach(async () => {
  await clear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('promoteAdmin', () => {
  it('DRY-RUN: informa y no escribe nada', async () => {
    const { auth, calls } = fakeAuth({ ana: { email: 'ana@example.com', claims: { role: 'rider' } } });
    const plan = await promoteAdmin({ db, auth }, args, false);
    expect(plan).toEqual({ uid: 'ana', fromRole: 'rider', fromClaim: 'rider', changes: true });
    expect(calls).toEqual([]);
    expect((await db.doc('users/ana').get()).data()?.role).toBe('rider');
    expect((await db.collection('admin_logs').get()).size).toBe(0);
  });

  it('apply: claim, documento, sesiones revocadas y auditoría', async () => {
    const { auth, calls } = fakeAuth({ ana: { email: 'ana@example.com', claims: { otra: 1 } } });
    await promoteAdmin({ db, auth }, args, true);
    expect(calls).toEqual(['claims:ana:{"otra":1,"role":"admin"}', 'revoke:ana']);
    expect((await db.doc('users/ana').get()).data()?.role).toBe('admin');
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toHaveLength(1);
    expect(logs[0]).toMatchObject({ action: 'promote_admin', targetId: 'ana', source: 'script' });
    expect(logs[0].details).toContain('primer admin del piloto');
    expect(logs[0].details).toContain('Responsable');
  });

  it('ya es admin: no cambia nada', async () => {
    await db.doc('users/ana').update({ role: 'admin' });
    const { auth, calls } = fakeAuth({ ana: { email: 'ana@example.com', claims: { role: 'admin' } } });
    expect((await promoteAdmin({ db, auth }, args, true)).changes).toBe(false);
    expect(calls).toEqual([]);
  });

  it('cuenta bloqueada o sin perfil: se niega', async () => {
    const { auth } = fakeAuth({ ana: { email: 'ana@example.com' }, sin: { email: 'sin@example.com' } });
    await db.doc('users/ana').update({ isActive: false });
    await expect(promoteAdmin({ db, auth }, args, true)).rejects.toThrow('bloqueada');
    await expect(promoteAdmin({ db, auth }, { ...args, email: 'sin@example.com' }, true)).rejects.toThrow('perfil');
    expect((await db.collection('admin_logs').get()).size).toBe(0);
  });
});
