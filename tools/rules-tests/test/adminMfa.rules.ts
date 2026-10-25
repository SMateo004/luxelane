// B4 (decisión 3): con config/security.mfaEnforced true, las escrituras
// directas del admin exigen un token con segundo factor. Las lecturas no.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'config', 'global'), { x: 1 }));
});
afterAll(async () => { await env?.cleanup(); });

const enforce = (on: boolean) => env.withSecurityRulesDisabled((ctx) =>
  setDoc(doc(ctx.firestore(), 'config', 'security'), { mfaEnforced: on }));
const TOTP = { firebase: { sign_in_provider: 'password', sign_in_second_factor: 'totp' } };
const db = (claims?: Record<string, unknown>) => env.authenticatedContext('admin', claims).firestore();
const write = (claims?: Record<string, unknown>) => updateDoc(doc(db(claims), 'config', 'global'), { x: 2 });
const cancel = (claims?: Record<string, unknown>) =>
  updateDoc(doc(db(claims), 'bookings', 'pend'), { status: 'cancelled', updatedAt: new Date() });

describe('segundo factor en escrituras del admin', () => {
  test('fase 1 (sin config/security): basta con ser admin', async () => {
    await assertSucceeds(write());
  });

  test('mfaEnforced false: basta con ser admin', async () => {
    await enforce(false);
    await assertSucceeds(write());
  });

  test('mfaEnforced true: sin segundo factor no escribe', async () => {
    await enforce(true);
    await assertFails(write());
    await assertFails(cancel());
  });

  test('mfaEnforced true: con TOTP sí escribe', async () => {
    await enforce(true);
    await assertSucceeds(write(TOTP));
    await assertSucceeds(cancel(TOTP));
  });

  test('las lecturas del admin no lo exigen', async () => {
    await enforce(true);
    await assertSucceeds(getDoc(doc(db(), 'bookings', 'pend')));
  });

  test('no afecta a pasajeros ni chóferes en las reglas', async () => {
    await enforce(true);
    await assertSucceeds(updateDoc(doc(env.authenticatedContext('ana').firestore(), 'bookings', 'pend'),
      { status: 'cancelled', updatedAt: new Date() }));
  });
});
