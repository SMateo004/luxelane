// A8.8: pricingRules es público (la web lo lee sin sesión): solo admite los
// campos de la tarifa; nada interno como margen, pago al chófer o comisión.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'pricingRules', 'business_oneWay'), rule()));
});
afterAll(async () => { await env?.cleanup(); });

function rule(extra: Record<string, unknown> = {}) {
  return {
    id: 'business_oneWay', vehicleClass: 'business', serviceType: 'oneWay',
    basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true, ...extra,
  };
}
const ref = () => doc(env.authenticatedContext('admin').firestore(), 'pricingRules', 'business_oneWay');

describe('campos de pricingRules (A8.8)', () => {
  test('el admin guarda la tarifa como el panel (con updatedAt)', async () => {
    await assertSucceeds(setDoc(ref(), rule({ updatedAt: serverTimestamp() })));
  });

  // C3: el documento es público; quién la cambió va solo en admin_logs.
  test('rechaza updatedBy (uid del admin a la vista de todos)', async () => {
    await assertFails(setDoc(ref(), rule({ updatedAt: serverTimestamp(), updatedBy: 'admin' })));
    await assertFails(updateDoc(ref(), { updatedBy: 'admin' }));
  });

  test.each([
    ['margen', { marginPct: 30 }],
    ['pago al chófer', { driverPayoutPct: 70 }],
    ['comisión', { platformCommissionPct: 20 }],
    ['coste interno', { costUsd: 10 }],
  ])('rechaza un campo interno: %s', async (_w, extra) => {
    await assertFails(setDoc(ref(), rule(extra)));
    await assertFails(updateDoc(ref(), extra));
  });
});
