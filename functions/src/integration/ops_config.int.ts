/**
 * config/ops (A8.9): las claves de operación del servidor se leen de ops; si
 * un proyecto aún las tiene en config/global, se usan y se avisa en el log.
 */
import { describe, it, expect, beforeEach, afterAll, afterEach, jest } from '@jest/globals';
import * as admin from 'firebase-admin';
import { opsConfig, OPS_KEYS, securityConfig } from '../ops_config';

// Sin importar index.ts (que inicializa la app), se inicializa aquí.
if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const clear = async () => {
  const snap = await db.collection('config').get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
};
beforeEach(clear);
afterEach(() => { jest.restoreAllMocks(); });
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('opsConfig', () => {
  it('lee config/ops', async () => {
    await db.doc('config/ops').set({ arrivalRadiusMeters: 250, incidentAckSeconds: 60 });
    expect(await opsConfig(db)).toMatchObject({ arrivalRadiusMeters: 250, incidentAckSeconds: 60 });
  });

  it('ops manda sobre global', async () => {
    await db.doc('config/ops').set({ arrivalRadiusMeters: 250 });
    await db.doc('config/global').set({ arrivalRadiusMeters: 999 });
    expect((await opsConfig(db)).arrivalRadiusMeters).toBe(250);
  });

  it('transición: una clave que sigue en global se usa y se avisa', async () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    await db.doc('config/global').set({ incidentLocationRetentionDays: 30, isMaintenanceMode: false });
    const ops = await opsConfig(db);
    expect(ops.incidentLocationRetentionDays).toBe(30);
    // Solo las claves de operación, no el resto de global.
    expect(ops).not.toHaveProperty('isMaintenanceMode');
    expect(warn.mock.calls.map((c) => String(c[0])).join('\n')).toContain('incidentLocationRetentionDays');
  });

  it('las cuatro claves que se movieron', () => {
    expect([...OPS_KEYS]).toEqual([
      'incidentAckSeconds', 'incidentEscalateEverySeconds', 'incidentLocationRetentionDays', 'arrivalRadiusMeters',
    ]);
  });

  it('securityConfig lee config/security', async () => {
    await db.doc('config/security').set({ mfaEnforced: true });
    expect(await securityConfig(db)).toEqual({ mfaEnforced: true });
  });
});
