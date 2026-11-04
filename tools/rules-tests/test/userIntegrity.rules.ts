// Huecos 7, 8 y 12 (cierre/reglas-usuarios): el dueño no cambia su correo
// ni su fecha de alta ni se asigna a una empresa; el nombre va de 1 a 80
// caracteres en el alta y al editarlo; el chófer verificado solo registra
// desde el cliente su vehículo v_<uid>.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', 'ana'), {
      id: 'ana', role: 'rider', isActive: true, displayName: 'Ana',
      email: 'ana@example.com', createdAt: Timestamp.fromMillis(1_700_000_000_000),
    });
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const own = () => doc(db('ana'), 'users', 'ana');
const signup = (uid: string, extra: Record<string, unknown>) =>
  setDoc(doc(db(uid), 'users', uid), { id: uid, role: 'rider', isActive: true, displayName: 'Nueva', ...extra });

describe('hueco 7: correo, fecha de alta y empresa', () => {
  test.each([
    ['su correo', { email: 'otra@example.com' }],
    ['su fecha de alta', { createdAt: Timestamp.fromMillis(0) }],
    ['una empresa', { companyId: 'acme' }],
    ['un rol de empresa', { companyRole: 'admin' }],
  ])('el dueño no cambia %s', async (_, data) => {
    await assertFails(updateDoc(own(), data));
  });

  test.each([
    ['una empresa', { companyId: 'acme' }],
    ['un rol de empresa', { companyRole: 'admin' }],
  ])('el alta propia no trae %s', async (_, data) => {
    await assertFails(signup('nueva1', data));
  });

  test('reescribir el mismo correo no cuenta como cambio', async () => {
    await assertSucceeds(updateDoc(own(), { email: 'ana@example.com', displayName: 'Ana B' }));
  });
});

describe('hueco 8: nombre de 1 a 80 caracteres', () => {
  test.each([
    ['vacío', ''],
    ['de 81 caracteres', 'x'.repeat(81)],
    ['que no es texto', 42],
  ])('el alta con un nombre %s se rechaza', async (_, name) => {
    await assertFails(signup('nueva2', { displayName: name }));
  });

  test('el alta sin nombre se rechaza', async () => {
    await assertFails(setDoc(doc(db('nueva3'), 'users', 'nueva3'), { id: 'nueva3', role: 'rider', isActive: true }));
  });

  test.each([
    ['vacío', ''],
    ['de 81 caracteres', 'x'.repeat(81)],
    ['que no es texto', 42],
  ])('editar con un nombre %s se rechaza', async (_, name) => {
    await assertFails(updateDoc(own(), { displayName: name }));
  });

  test('1 y 80 caracteres se aceptan, en el alta y al editar', async () => {
    await assertSucceeds(signup('nueva4', { displayName: 'A' }));
    await assertSucceeds(signup('nueva5', { displayName: 'x'.repeat(80) }));
    await assertSucceeds(updateDoc(own(), { displayName: 'A' }));
    await assertSucceeds(updateDoc(own(), { displayName: 'x'.repeat(80) }));
  });

  test('cambiar otro campo no exige tocar el nombre', async () => {
    await assertSucceeds(updateDoc(own(), { phone: '+59170000111' }));
  });
});

describe('hueco 12: vehículo v_<uid>', () => {
  const vehicle = (uid: string) => ({ driverId: uid, make: 'Kia', model: 'Rio', plate: 'NUEVA', isActive: false });

  test('el chófer verificado registra su vehículo v_<uid>', async () => {
    await assertSucceeds(setDoc(doc(db('libre'), 'vehicles', 'v_libre'), vehicle('libre')));
  });

  test.each([
    ['un id libre', 'otro'],
    ['el id de otro chófer', 'v_asig'],
    ['un id parecido', 'v_libre2'],
  ])('no registra uno con %s', async (_, id) => {
    await assertFails(setDoc(doc(db('libre'), 'vehicles', id), vehicle('libre')));
  });
});
