/** C3: borrar updatedBy de pricingRules, contra el emulador de Firestore. */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { removePricingUpdatedBy } from '../migrations/pricing_updated_by';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const fare = { basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true };

async function clear(): Promise<void> {
  for (const col of ['pricingRules', 'admin_logs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

beforeEach(async () => {
  await clear();
  await db.doc('pricingRules/business_oneWay').set({ ...fare, updatedBy: 'uid-de-la-jefa' });
  await db.doc('pricingRules/first_oneWay').set(fare);
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('removePricingUpdatedBy', () => {
  it('DRY-RUN: lista lo que cambiaría y no escribe', async () => {
    expect(await removePricingUpdatedBy(db, false, 'Responsable'))
      .toEqual([{ id: 'business_oneWay', updatedBy: 'uid-de-la-jefa' }]);
    expect((await db.doc('pricingRules/business_oneWay').get()).data()?.updatedBy).toBe('uid-de-la-jefa');
    expect((await db.collection('admin_logs').get()).size).toBe(0);
  });

  it('apply: borra el campo, conserva la tarifa y deja auditoría con el uid anterior', async () => {
    await removePricingUpdatedBy(db, true, 'Responsable');
    const d = (await db.doc('pricingRules/business_oneWay').get()).data()!;
    expect('updatedBy' in d).toBe(false);
    expect(d.basePriceUsd).toBe(50);
    const logs = (await db.collection('admin_logs').get()).docs.map((x) => x.data());
    expect(logs).toHaveLength(1);
    expect(logs[0]).toMatchObject({ action: 'remove_pricing_updated_by', targetId: 'business_oneWay', source: 'script' });
    expect(logs[0].details).toContain('uid-de-la-jefa');
    expect(logs[0].details).toContain('Responsable');
    // Segunda vez: nada que hacer.
    expect(await removePricingUpdatedBy(db, true, 'Responsable')).toEqual([]);
  });
});
