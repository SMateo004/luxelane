// H9: config/* se actualiza pero ningún cliente la borra, ni el admin.
// H8: un chófer bloqueado no registra vehículos; reactivado, sí.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const id of ['global', 'finance', 'pricing']) {
      await setDoc(doc(ctx.firestore(), 'config', id), { x: 1 });
    }
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();

describe('config/* no se borra (H9)', () => {
  test.each(['global', 'finance', 'pricing'])('el admin no borra config/%s', async (id) => {
    await assertFails(deleteDoc(doc(db('admin'), 'config', id)));
  });

  test.each(['global', 'pricing'])('el admin sí actualiza config/%s', async (id) => {
    await assertSucceeds(updateDoc(doc(db('admin'), 'config', id), { x: 2 }));
  });

  test('nadie más la borra', async () => {
    await assertFails(deleteDoc(doc(db('ana'), 'config', 'global')));
    await assertFails(deleteDoc(doc(env.unauthenticatedContext().firestore(), 'config', 'global')));
  });
});

describe('vehículos de un chófer bloqueado (H8)', () => {
  const vehicle = { driverId: 'bloq', make: 'Kia', model: 'Rio', plate: 'NUEVA', class: 'business', isActive: false };
  const create = () => setDoc(doc(db('bloq'), 'vehicles', 'nuevo-bloq'), vehicle);

  test('bloqueado no registra; reactivado, sí', async () => {
    await assertFails(create());
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'users', 'bloq'), { isActive: true }));
    await assertSucceeds(create());
  });
});
