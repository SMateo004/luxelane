/** A3: adminUpdateConfig contra el emulador de Firestore. */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminUpdateConfig } from '../admin_ops';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const jefa = { adminId: 'jefa', adminEmail: null };
const REASON = 'Ajuste pedido por el responsable';
const run = (data: unknown) => adminUpdateConfig({ db }, jefa, data);

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['config', 'admin_logs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const logs = async () => (await db.collection('admin_logs').get()).docs.map((d) => d.data());

beforeEach(async () => {
  await clear();
  await db.doc('config/global').set({ isMaintenanceMode: false, firstClassEnabled: true, dispatchPhone: '+591 0' });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('adminUpdateConfig', () => {
  it('global: solo las claves de la lista; conserva el resto; auditoría con antes y después', async () => {
    await run({ doc: 'global', changes: { isMaintenanceMode: true }, reason: REASON });
    expect(await doc('config/global')).toMatchObject({ isMaintenanceMode: true, firstClassEnabled: true, dispatchPhone: '+591 0' });
    expect((await logs())[0]).toMatchObject({
      operation: 'update_config_global', docPath: 'config/global', reason: REASON,
      changes: { isMaintenanceMode: { before: false, after: true } },
    });
  });

  it('global: rechaza claves fuera de la lista (versión mínima, teléfonos, legalVersion)', async () => {
    for (const changes of [{ minAppVersion: '9.9.9' }, { dispatchPhone: '+1' }, { legalVersion: 'x' }]) {
      expect(await reason(run({ doc: 'global', changes, reason: REASON }))).toBe('invalid_request');
    }
    expect((await doc('config/global'))?.dispatchPhone).toBe('+591 0');
  });

  it('finance: comisión entre 0 y 100', async () => {
    expect(await reason(run({ doc: 'finance', changes: { platformCommissionPct: 101 }, reason: REASON }))).toBe('invalid_request');
    await run({ doc: 'finance', changes: { platformCommissionPct: 12.5 }, reason: REASON });
    expect((await doc('config/finance'))?.platformCommissionPct).toBe(12.5);
  });

  it('ops: tipos y signo; también el límite de ajuste de importe', async () => {
    expect(await reason(run({ doc: 'ops', changes: { incidentAckSeconds: -1 }, reason: REASON }))).toBe('invalid_request');
    await run({ doc: 'ops', changes: { incidentAckSeconds: 90, maxPriceAdjustmentPercent: 10 }, reason: REASON });
    expect(await doc('config/ops')).toMatchObject({ incidentAckSeconds: 90, maxPriceAdjustmentPercent: 10 });
  });

  it('ops: política de cancelación validada (B3)', async () => {
    const policy = { freeWithinMinutesOfBooking: 5, freeBeforePickupMinutes: 60, chargeWhenNoDriver: false,
      feeType: 'percent', feeValue: 10, noShowWaitMinutes: 15 };
    expect(await reason(run({ doc: 'ops', changes: { cancellationPolicy: { ...policy, feeValue: 150 } }, reason: REASON })))
      .toBe('invalid_request');
    expect(await reason(run({ doc: 'ops', changes: { cancellationPolicy: { feeType: 'fixed' } }, reason: REASON })))
      .toBe('invalid_request');
    await run({ doc: 'ops', changes: { cancellationPolicy: policy }, reason: REASON });
    expect((await doc('config/ops'))?.cancellationPolicy).toEqual(policy);
  });

  it('config/security: nunca', async () => {
    expect(await reason(run({ doc: 'security', changes: { mfaEnforced: false }, reason: REASON }))).toBe('invalid_request');
    expect(await doc('config/security')).toBeUndefined();
  });

  it('sin cambio real: no escribe ni audita', async () => {
    expect(await reason(run({ doc: 'global', changes: { isMaintenanceMode: false }, reason: REASON }))).toBe('no_change');
    expect(await logs()).toHaveLength(0);
  });
});
