// Preferencias del pasajero (A1): el perfil (tripPreferences) solo lo
// escribe updatePreferences.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const PREFS = { conversation: 'quiet', note: 'Hola', preferredDriverLanguages: ['es'] };

describe('perfil: tripPreferences no se escribe desde el cliente', () => {
  test('el dueño no las cambia', async () => {
    await assertFails(updateDoc(doc(db('ana'), 'users', 'ana'), { tripPreferences: PREFS }));
  });

  test('el dueño no cambia las ridePreferences antiguas', async () => {
    await assertFails(updateDoc(doc(db('ana'), 'users', 'ana'), { ridePreferences: { quiet: true } }));
  });

  test('el dueño sigue cambiando su nombre aunque mande las mismas ridePreferences', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'users', 'ana'), { ridePreferences: { quiet: false } }));
    await assertSucceeds(updateDoc(doc(db('ana'), 'users', 'ana'),
      { displayName: 'Ana', ridePreferences: { quiet: false } }));
  });

  test('el alta no trae tripPreferences', async () => {
    await assertFails(setDoc(doc(db('nueva'), 'users', 'nueva'),
      { id: 'nueva', role: 'rider', isActive: true, tripPreferences: PREFS }));
    await assertSucceeds(setDoc(doc(db('nueva2'), 'users', 'nueva2'), { id: 'nueva2', role: 'rider', isActive: true }));
  });

  test('tampoco el admin desde el cliente', async () => {
    await assertFails(updateDoc(doc(db('admin'), 'users', 'ana'), { tripPreferences: PREFS }));
  });
});
