// B6 (decisión 7): la aceptación de los términos (users/{uid}.terms) la
// escribe solo el servidor (acceptTerms), con su hora y la versión vigente.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const terms = { version: '2026-10', acceptedAt: new Date(), appVersion: '1.0.0' };
const signup = (uid: string, extra: Record<string, unknown>) =>
  setDoc(doc(env.authenticatedContext(uid).firestore(), 'users', uid), { id: uid, role: 'rider', isActive: true, ...extra });

describe('términos aceptados (B6)', () => {
  test('el alta propia no trae los términos puestos', async () => {
    await assertSucceeds(signup('nueva1', {}));
    await assertFails(signup('nueva2', { terms }));
  });

  test('el dueño no se los pone ni los cambia', async () => {
    const own = doc(env.authenticatedContext('ana').firestore(), 'users', 'ana');
    await assertFails(updateDoc(own, { terms }));
    await assertFails(updateDoc(own, { 'terms.version': '2099-01' }));
    await assertSucceeds(updateDoc(own, { displayName: 'Ana P.' }));
  });

  test('el admin tampoco', async () => {
    const asAdmin = doc(env.authenticatedContext('admin').firestore(), 'users', 'ana');
    await assertFails(updateDoc(asAdmin, { terms }));
  });
});
