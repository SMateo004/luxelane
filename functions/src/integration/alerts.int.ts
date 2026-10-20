/** resolveAlert contra el emulador de Firestore. */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { resolveAlert } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const run = (req: any) => (resolveAlert as unknown as { run: (r: any) => Promise<any> }).run(req);

async function code(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    return (e as HttpsError).code;
  }
  throw new Error('se esperaba un error');
}

async function clear(): Promise<void> {
  for (const col of ['adminAlerts', 'admin_logs', 'users']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

beforeEach(async () => {
  await clear();
  await db.doc('users/jefa').set({ role: 'admin' });
  await db.doc('users/ana').set({ role: 'rider' });
  await db.doc('adminAlerts/a1').set({ type: 'distance_fallback', bookingId: 'b1', resolved: false });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('resolveAlert', () => {
  it('el admin la marca revisada y queda auditado en el servidor', async () => {
    const res = await run({ auth: { uid: 'jefa', token: { email: 'jefa@example.com' } }, data: { alertId: 'a1', note: 'Ruta revisada a mano' } });
    expect(res).toEqual({ resolved: true, alreadyResolved: false });
    const alert = (await db.doc('adminAlerts/a1').get()).data()!;
    expect(alert).toMatchObject({ resolved: true, resolvedBy: 'jefa', resolutionNote: 'Ruta revisada a mano' });
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    expect(logs).toEqual([expect.objectContaining({
      adminId: 'jefa', action: 'resolve_alert', targetId: 'a1', targetType: 'alert',
    })]);
  });

  it('marcarla dos veces no duplica la auditoría', async () => {
    const req = { auth: { uid: 'jefa', token: {} }, data: { alertId: 'a1' } };
    await run(req);
    expect(await run(req)).toEqual({ resolved: true, alreadyResolved: true });
    expect((await db.collection('admin_logs').get()).size).toBe(1);
  });

  it('solo el admin: un pasajero o alguien sin sesión no puede', async () => {
    expect(await code(run({ auth: { uid: 'ana', token: {} }, data: { alertId: 'a1' } }))).toBe('permission-denied');
    expect(await code(run({ data: { alertId: 'a1' } }))).toBe('unauthenticated');
    expect((await db.doc('adminAlerts/a1').get()).data()?.resolved).toBe(false);
  });

  it('alerta inexistente o datos inválidos', async () => {
    expect(await code(run({ auth: { uid: 'jefa', token: {} }, data: { alertId: 'no-existe' } }))).toBe('not-found');
    expect(await code(run({ auth: { uid: 'jefa', token: {} }, data: { alertId: 'a1', resolved: false } }))).toBe('invalid-argument');
  });
});
