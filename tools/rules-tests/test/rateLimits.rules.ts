// Contadores de límites de tasa: ningún cliente los lee ni los escribe.
import { assertFails, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'rateLimits', 'createBooking__ana'), { uid: 'ana', count: 3 });
  });
});
afterAll(async () => { await env?.cleanup(); });

test.each(['ana', 'asig', 'admin'])('%s no lee, lista, crea ni borra contadores', async (uid) => {
  const db = env.authenticatedContext(uid).firestore();
  const ref = doc(db, 'rateLimits', 'createBooking__ana');
  await assertFails(getDoc(ref));
  await assertFails(getDocs(collection(db, 'rateLimits')));
  await assertFails(setDoc(ref, { uid: 'ana', count: 0 }));
  await assertFails(setDoc(doc(db, 'rateLimits', `createBooking__${uid}`), { count: 0 }));
  await assertFails(deleteDoc(ref));
});
