// Preferencias del pasajero (A1, A3): el perfil (tripPreferences) solo lo
// escribe updatePreferences; la copia de cada reserva
// (bookings/{id}/driverView/preferences) solo el servidor, y el chófer la
// lee siendo el asignado, activo y entre confirmed e in_progress.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
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

describe('copia por reserva: bookings/{id}/driverView/preferences', () => {
  const VIEW = { riderId: 'ana', conversation: 'quiet', note: 'Llevo un carrito', preferredDriverLanguages: ['es'] };
  const IN_WINDOW = ['confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress'];
  const OUT_OF_WINDOW = ['completed', 'cancelled', 'no_show'];

  const view = (uid: string, booking: string) =>
    doc(db(uid), 'bookings', booking, 'driverView', 'preferences');

  // Una reserva de ana asignada a asig en cada etapa, y una pendiente que
  // asig liberó.
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const f = ctx.firestore();
      for (const st of [...IN_WINDOW, ...OUT_OF_WINDOW]) {
        await setDoc(doc(f, 'bookings', `b_${st}`), { riderId: 'ana', driverId: 'asig', status: st });
        await setDoc(doc(f, 'bookings', `b_${st}`, 'driverView', 'preferences'), VIEW);
      }
      await setDoc(doc(f, 'bookings', 'liberada'), { riderId: 'ana', driverId: null, status: 'pending', releasedBy: ['asig'] });
      await setDoc(doc(f, 'bookings', 'liberada', 'driverView', 'preferences'), VIEW);
      await setDoc(doc(f, 'bookings', 'pend', 'driverView', 'preferences'), VIEW);
      await setDoc(doc(f, 'bookings', 'activaBloq', 'driverView', 'preferences'), VIEW);
    });
  });

  test.each(IN_WINDOW)('chófer asignado y activo, etapa %s: la lee', async (st) => {
    await assertSucceeds(getDoc(view('asig', `b_${st}`)));
  });

  test.each(OUT_OF_WINDOW)('chófer asignado, etapa %s (después de la ventana): no la lee', async (st) => {
    await assertFails(getDoc(view('asig', `b_${st}`)));
  });

  test('antes de la ventana (pendiente, sin chófer) y tras liberarla: no la lee ningún chófer', async () => {
    for (const uid of ['asig', 'libre', 'nover']) {
      await assertFails(getDoc(view(uid, 'pend')));
      await assertFails(getDoc(view(uid, 'liberada')));
    }
  });

  test('chófer ajeno (verificado o no) en plena ventana: no la lee', async () => {
    await assertFails(getDoc(view('libre', 'b_driver_arriving')));
    await assertFails(getDoc(view('nover', 'b_in_progress')));
  });

  test('chófer asignado pero bloqueado: no la lee', async () => {
    await assertFails(getDoc(view('bloq', 'activaBloq')));
  });

  test('el pasajero dueño la lee en cualquier etapa; otro pasajero, nunca', async () => {
    for (const id of ['pend', 'b_confirmed', 'b_completed', 'b_cancelled']) {
      await assertSucceeds(getDoc(view('ana', id)));
      await assertFails(getDoc(view('beto', id)));
    }
  });

  test('el admin la lee', async () => {
    await assertSucceeds(getDoc(view('admin', 'b_completed')));
  });

  test('nadie la escribe desde el cliente', async () => {
    for (const uid of ['ana', 'asig', 'admin']) {
      await assertFails(setDoc(view(uid, 'b_confirmed'), { ...VIEW, note: 'Otra' }));
      await assertFails(updateDoc(view(uid, 'b_confirmed'), { note: 'Otra' }));
      await assertFails(setDoc(doc(db(uid), 'bookings', 'b_confirmed', 'driverView', 'nuevo'), VIEW));
    }
  });
});
