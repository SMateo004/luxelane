// Vuelos (A2, A9): la copia del vuelo para el chófer (driverView/flight) con
// la misma ventana que las preferencias; aeropuertos y la caché de la fuente.
// Datos FICTICIOS de prueba.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    for (const id of ['pend', 'activa', 'conf', 'fin']) {
      await setDoc(doc(f, 'bookings', id, 'driverView', 'flight'), { flightNumber: 'ZZ123', status: 'scheduled' });
    }
    await setDoc(doc(f, 'airports', 'VVI'), { code: 'VVI', name: 'Aeropuerto (prueba)', pickupPoints: {} });
    await setDoc(doc(f, 'airportsPublic', 'VVI'), { code: 'VVI', name: 'Aeropuerto (prueba)', city: 'Santa Cruz' });
    await setDoc(doc(f, 'flightBoard', 'VVI_2026-11-20'), { flights: { ZZ123: { status: 'landed' } } });
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string | null) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const flight = (uid: string | null, booking: string) => doc(db(uid), 'bookings', booking, 'driverView', 'flight');

describe('driverView/flight', () => {
  test('el chófer asignado lo lee de confirmed a in_progress; no después de completar', async () => {
    await assertSucceeds(getDoc(flight('asig', 'conf')));
    await assertSucceeds(getDoc(flight('asig', 'activa')));
    await assertFails(getDoc(flight('asig', 'fin')));
  });

  test('pasajero dueño y admin lo leen; otro chófer o pasajero, no; nadie lo escribe', async () => {
    await assertSucceeds(getDoc(flight('ana', 'activa')));
    await assertSucceeds(getDoc(flight('admin', 'activa')));
    for (const uid of ['libre', 'beto', null]) await assertFails(getDoc(flight(uid, 'activa')));
    for (const uid of ['asig', 'ana', 'admin']) {
      await assertFails(updateDoc(flight(uid, 'activa'), { status: 'landed' }));
      await assertFails(setDoc(flight(uid, 'pend'), { status: 'landed' }));
    }
  });
});

describe('aeropuertos y caché', () => {
  test('airports: con sesión se lee; sin sesión, no; nadie escribe desde el cliente', async () => {
    await assertSucceeds(getDoc(doc(db('ana'), 'airports', 'VVI')));
    await assertFails(getDoc(doc(db(null), 'airports', 'VVI')));
    for (const uid of ['ana', 'admin']) {
      await assertFails(updateDoc(doc(db(uid), 'airports', 'VVI'), { name: 'otro' }));
    }
  });

  test('airportsPublic: lo lee cualquiera, nadie lo escribe', async () => {
    await assertSucceeds(getDoc(doc(db(null), 'airportsPublic', 'VVI')));
    await assertFails(setDoc(doc(db('admin'), 'airportsPublic', 'ZZZ'), { code: 'ZZZ' }));
  });

  test('flightBoard: ni lectura ni escritura desde el cliente (ni el admin)', async () => {
    for (const uid of ['ana', 'asig', 'admin', null]) {
      await assertFails(getDoc(doc(db(uid), 'flightBoard', 'VVI_2026-11-20')));
    }
    await assertFails(setDoc(doc(db('admin'), 'flightBoard', 'VVI_2026-11-21'), { flights: {} }));
  });
});
