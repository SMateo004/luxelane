// Idioma de la cuenta (idiomas, A2): users/{uid}.locale y localeSource los
// escribe solo updatePreferences; ningún cliente, ni en el alta.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();

describe('users/{uid}.locale no se escribe desde el cliente', () => {
  test('el pasajero no cambia su idioma directo', async () => {
    await assertFails(updateDoc(doc(db('ana'), 'users', 'ana'), { locale: 'en' }));
    await assertFails(updateDoc(doc(db('ana'), 'users', 'ana'), { localeSource: 'user' }));
  });

  test('el chófer tampoco', async () => {
    await assertFails(updateDoc(doc(db('asig'), 'users', 'asig'), { locale: 'pt', localeSource: 'user' }));
  });

  test('el alta no trae idioma', async () => {
    await assertFails(setDoc(doc(db('nueva'), 'users', 'nueva'),
      { id: 'nueva', role: 'rider', isActive: true, locale: 'en' }));
    await assertFails(setDoc(doc(db('nueva'), 'users', 'nueva'),
      { id: 'nueva', role: 'rider', isActive: true, localeSource: 'system' }));
  });

  test('el admin desde el cliente, tampoco', async () => {
    await assertFails(updateDoc(doc(db('admin'), 'users', 'ana'), { locale: 'en' }));
  });

  test('el dueño lo lee y sigue editando su nombre con el idioma guardado', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'users', 'ana'), { locale: 'pt', localeSource: 'user' }));
    await assertSucceeds(getDoc(doc(db('ana'), 'users', 'ana')));
    await assertSucceeds(updateDoc(doc(db('ana'), 'users', 'ana'), { displayName: 'Ana' }));
  });
});
