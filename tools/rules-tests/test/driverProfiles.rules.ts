// D4: la licencia y los datos de verificación de un chófer solo los ven él
// mismo y el admin.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const read = (uid: string | null, target: string) => {
  const ctx = uid ? env.authenticatedContext(uid) : env.unauthenticatedContext();
  return getDoc(doc(ctx.firestore(), 'driverProfiles', target));
};

describe('reglas de /driverProfiles', () => {
  test('el propio chófer lee su perfil', async () => {
    await assertSucceeds(read('asig', 'asig'));
    await assertSucceeds(read('nover', 'nover'));
  });

  test('el admin lee cualquier perfil', async () => {
    await assertSucceeds(read('admin', 'asig'));
  });

  test('un chófer no lee el perfil de otro chófer', async () => {
    await assertFails(read('libre', 'asig'));
    await assertFails(read('nover', 'asig'));
    await assertFails(read('asig', 'libre'));
  });

  test('un chófer no lee driverProfiles de un pasajero', async () => {
    await assertFails(read('asig', 'ana'));
  });

  test('el pasajero dueño no lee el perfil de su chófer asignado', async () => {
    await assertFails(read('ana', 'asig'));
  });

  test('un pasajero ajeno y un usuario sin sesión no leen perfiles', async () => {
    await assertFails(read('beto', 'asig'));
    await assertFails(read(null, 'asig'));
  });
});
