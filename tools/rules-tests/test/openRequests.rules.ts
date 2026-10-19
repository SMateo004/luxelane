// /openRequests: lo que un chófer verificado ve antes de aceptar. Solo la
// escribe el servidor.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, deleteDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string | null) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const read = (uid: string | null) => getDoc(doc(db(uid), 'openRequests', 'pend'));

describe('lectura de /openRequests', () => {
  test('un chófer verificado y activo las ve (asignado o no)', async () => {
    await assertSucceeds(read('libre'));
    await assertSucceeds(read('asig'));
    await assertSucceeds(getDocs(collection(db('libre'), 'openRequests')));
  });

  test('un chófer no verificado no las ve', async () => {
    await assertFails(read('nover'));
    await assertFails(getDocs(collection(db('nover'), 'openRequests')));
  });

  test('un chófer bloqueado no las ve', async () => {
    await assertFails(read('bloq'));
  });

  test('los pasajeros y usuarios sin sesión no las ven', async () => {
    await assertFails(read('ana'));
    await assertFails(read('beto'));
    await assertFails(read(null));
  });

  test('el admin las ve', async () => {
    await assertSucceeds(read('admin'));
  });
});

describe('escritura de /openRequests', () => {
  test('nadie las escribe desde la app', async () => {
    for (const uid of ['libre', 'ana', 'admin']) {
      await assertFails(setDoc(doc(db(uid), 'openRequests', 'x'), { estimatedPrice: 1 }));
      await assertFails(deleteDoc(doc(db(uid), 'openRequests', 'pend')));
    }
  });
});
