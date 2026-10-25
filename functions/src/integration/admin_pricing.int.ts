/** A4: adminUpdatePricingRule contra el emulador de Firestore. */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminUpdatePricingRule } from '../admin_ops';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const jefa = { adminId: 'jefa', adminEmail: null };
const REASON = 'Tarifa revisada por el responsable';
const run = (data: unknown) => adminUpdatePricingRule({ db }, jefa, data);
// Importes de prueba, no reales.
const fare = (over: Record<string, unknown> = {}) => ({
  action: 'upsert', vehicleClass: 'business', serviceType: 'oneWay',
  basePriceUsd: 1, pricePerKmUsd: 2, pricePerHourUsd: 0, minimumPriceUsd: 3, isActive: true, reason: REASON, ...over,
});

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['pricingRules', 'admin_logs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const logs = async () => (await db.collection('admin_logs').get()).docs.map((d) => d.data());

beforeEach(clear);
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('adminUpdatePricingRule', () => {
  it('crea con los campos públicos (sin updatedBy) y audita', async () => {
    await run(fare());
    const d = (await doc('pricingRules/business_oneWay'))!;
    expect(d).toMatchObject({ id: 'business_oneWay', basePriceUsd: 1, pricePerKmUsd: 2, minimumPriceUsd: 3, isActive: true });
    expect(d).not.toHaveProperty('updatedBy');
    expect(JSON.stringify(d)).not.toContain('jefa');
    expect((await logs())[0]).toMatchObject({ operation: 'create_pricing', changes: { basePriceUsd: { before: null, after: 1 } } });
  });

  it('cambia: la auditoría solo lleva lo que cambió', async () => {
    await run(fare());
    await run(fare({ pricePerKmUsd: 5 }));
    const u = (await logs()).find((l) => l.operation === 'update_pricing')!;
    expect(u.changes).toEqual({ pricePerKmUsd: { before: 2, after: 5 } });
  });

  it('rechaza importes no válidos', async () => {
    expect(await reason(run(fare({ basePriceUsd: -1 })))).toBe('invalid_request');
    expect(await reason(run(fare({ basePriceUsd: 0, pricePerKmUsd: 0, minimumPriceUsd: 0 })))).toBe('invalid_fare');
    expect(await reason(run(fare({ serviceType: 'byTheHour', pricePerHourUsd: 0 })))).toBe('invalid_fare');
    expect(await logs()).toHaveLength(0);
  });

  it('desactivar en vez de borrar: el documento sigue', async () => {
    await run(fare());
    await run({ action: 'deactivate', vehicleClass: 'business', serviceType: 'oneWay', reason: REASON });
    expect((await doc('pricingRules/business_oneWay'))?.isActive).toBe(false);
    expect(await reason(run({ action: 'deactivate', vehicleClass: 'business', serviceType: 'oneWay', reason: REASON })))
      .toBe('no_change');
    expect(await reason(run({ action: 'deactivate', vehicleClass: 'electric', serviceType: 'oneWay', reason: REASON })))
      .toBe('fare_not_found');
  });
});
