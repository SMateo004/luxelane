// B3 (parte de D10): rol, bloqueo y sus marcas los escribe solo el servidor;
// el admin ya no los cambia desde el cliente. El resto, sí.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const asAdmin = (target: string) => doc(env.authenticatedContext('admin').firestore(), 'users', target);

describe('escrituras directas del admin en users (B3)', () => {
  test.each([
    ['role', { role: 'admin' }],
    ['isActive', { isActive: false }],
    ['roleUpdatedAt', { roleUpdatedAt: new Date() }],
    ['blockedAt', { blockedAt: new Date() }],
    ['emailVerifiedAt', { emailVerifiedAt: new Date() }],
  ])('el admin no cambia %s', async (_f, change) => {
    await assertFails(updateDoc(asAdmin('ana'), change));
  });

  test('el admin sí corrige otros datos', async () => {
    await assertSucceeds(updateDoc(asAdmin('ana'), { displayName: 'Ana P.' }));
  });
});
