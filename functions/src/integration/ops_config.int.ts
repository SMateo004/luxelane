/**
 * config/ops (A8.9): las claves de operación del servidor se leen de ops; si
 * un proyecto aún las tiene en config/global, se usan y se avisa en el log.
 */
import { describe, it, expect, beforeEach, afterAll, afterEach, jest } from '@jest/globals';
import * as admin from 'firebase-admin';
import { opsConfig, OPS_KEYS, resetLegacyAlertForTests, securityConfig } from '../ops_config';

// Sin importar index.ts (que inicializa la app), se inicializa aquí.
if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const clear = async () => {
  for (const col of ['config', 'adminAlerts']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  resetLegacyAlertForTests();
};
const legacyAlerts = async () => (await db.collection('adminAlerts').where('type', '==', 'ops_config_in_global').get())
  .docs.map((d) => d.data());
const DAY1 = Date.UTC(2026, 9, 25, 10);
const DAY1_LATER = Date.UTC(2026, 9, 25, 23, 59);
const DAY2 = Date.UTC(2026, 9, 26, 0, 1);
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

  describe('alerta para mover las claves (0.3)', () => {
    beforeEach(() => { jest.spyOn(console, 'warn').mockImplementation(() => undefined); });

    it('si usa un valor de config/global: una alerta baja con las claves', async () => {
      await db.doc('config/global').set({ arrivalRadiusMeters: 300, incidentAckSeconds: 90 });
      await opsConfig(db, DAY1);
      const a = await legacyAlerts();
      expect(a).toHaveLength(1);
      expect(a[0]).toMatchObject({ severity: 'low', resolved: false, keys: ['incidentAckSeconds', 'arrivalRadiusMeters'] });
    });

    it('como mucho una por día, también entre instancias', async () => {
      await db.doc('config/global').set({ arrivalRadiusMeters: 300 });
      await opsConfig(db, DAY1);
      await opsConfig(db, DAY1_LATER);
      resetLegacyAlertForTests(); // otra instancia, sin memoria
      await opsConfig(db, DAY1_LATER);
      expect(await legacyAlerts()).toHaveLength(1);
      await opsConfig(db, DAY2);
      expect(await legacyAlerts()).toHaveLength(2);
    });

    it('con todo en config/ops: ninguna alerta', async () => {
      await db.doc('config/ops').set({ arrivalRadiusMeters: 300 });
      await db.doc('config/global').set({ arrivalRadiusMeters: 999 });
      await opsConfig(db, DAY1);
      expect(await legacyAlerts()).toHaveLength(0);
    });
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
