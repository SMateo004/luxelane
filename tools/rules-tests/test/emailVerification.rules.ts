// B1 (H6): el alta propia no se marca verificada; isVerified, phoneVerified
// y emailVerifiedAt los escribe solo el servidor.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const signup = (uid: string, extra: Record<string, unknown>) =>
  setDoc(doc(env.authenticatedContext(uid).firestore(), 'users', uid), { id: uid, role: 'rider', isActive: true, ...extra });

describe('alta propia (H6)', () => {
  test('sin verificar: se acepta', async () => {
    await assertSucceeds(signup('nueva1', { isVerified: false, phoneVerified: false }));
    await assertSucceeds(signup('nueva2', {}));
  });

  test('marcada verificada por el cliente: se rechaza', async () => {
    await assertFails(signup('nueva3', { isVerified: true }));
    await assertFails(signup('nueva4', { phoneVerified: true }));
    await assertFails(signup('nueva5', { emailVerifiedAt: new Date() }));
  });

  test('después, el dueño tampoco se los pone', async () => {
    const own = doc(env.authenticatedContext('ana').firestore(), 'users', 'ana');
    await assertFails(updateDoc(own, { phoneVerified: true }));
    await assertFails(updateDoc(own, { emailVerifiedAt: new Date() }));
  });
});
