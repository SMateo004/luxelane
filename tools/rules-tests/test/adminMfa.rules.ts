// B4 (decisión 3) y Parte A: el admin ya no escribe desde el cliente, con o
// sin segundo factor; sus cambios van por callables, que exigen el segundo
// factor con mfaEnforced (mfa_gate.int.ts). Las lecturas no lo exigen.
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

describe('escrituras del admin desde el cliente (Parte A)', () => {
  test('sin config/security: no escribe', async () => {
    await assertFails(write());
    await assertFails(cancel());
  });

  test('mfaEnforced false: no escribe', async () => {
    await enforce(false);
    await assertFails(write());
  });

  test('mfaEnforced true: sin segundo factor no escribe', async () => {
    await enforce(true);
    await assertFails(write());
    await assertFails(cancel());
  });

  test('mfaEnforced true: con TOTP tampoco (va por callables)', async () => {
    await enforce(true);
    await assertFails(write(TOTP));
    await assertFails(cancel(TOTP));
  });

  test('las lecturas del admin no lo exigen', async () => {
    await enforce(true);
    await assertSucceeds(getDoc(doc(db(), 'bookings', 'pend')));
  });

  test('no afecta a pasajeros ni chóferes en las reglas', async () => {
    await enforce(true);
    // El pasajero ya no cancela desde las reglas (B7): edita su perfil.
    await assertSucceeds(updateDoc(doc(env.authenticatedContext('ana').firestore(), 'users', 'ana'), { name: 'Ana' }));
  });
});
