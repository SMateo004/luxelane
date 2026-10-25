// /vehicles: datos de cada chófer (placa incluida). Solo los leen el chófer
// dueño y el admin; el chófer lo registra inactivo y lo activa el admin.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, setDoc, updateDoc, where } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const uid of ['asig', 'libre']) {
      await setDoc(doc(ctx.firestore(), 'vehicles', `v-${uid}`), {
        id: `v-${uid}`, driverId: uid, make: 'Toyota', model: 'Camry',
        plate: `PLACA-${uid}`, class: 'business', isActive: true,
      });
    }
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const vehicle = (driverId: string, isActive: boolean) => ({
  id: `nuevo-${driverId}`, driverId, make: 'Kia', model: 'Rio', plate: 'NUEVA', class: 'business', isActive,
});

describe('lectura de /vehicles', () => {
  test('el chófer dueño lee su vehículo (también por consulta)', async () => {
    await assertSucceeds(getDoc(doc(db('asig'), 'vehicles', 'v-asig')));
    await assertSucceeds(getDocs(query(collection(db('asig'), 'vehicles'), where('driverId', '==', 'asig'))));
  });

  test('un chófer no lee el vehículo de otro', async () => {
    await assertFails(getDoc(doc(db('libre'), 'vehicles', 'v-asig')));
    await assertFails(getDocs(collection(db('libre'), 'vehicles')));
  });

  test('un pasajero no lee ningún vehículo', async () => {
    await assertFails(getDoc(doc(db('ana'), 'vehicles', 'v-asig')));
    await assertFails(getDocs(collection(db('ana'), 'vehicles')));
  });

  test('el admin los lee todos', async () => {
    await assertSucceeds(getDocs(collection(db('admin'), 'vehicles')));
  });
});

describe('alta y activación de /vehicles', () => {
  test('un chófer no puede crear su vehículo ya activo', async () => {
    await assertFails(setDoc(doc(db('nover'), 'vehicles', 'nuevo-nover'), vehicle('nover', true)));
  });

  test('un chófer crea su vehículo inactivo', async () => {
    await assertSucceeds(setDoc(doc(db('nover'), 'vehicles', 'nuevo-nover'), vehicle('nover', false)));
  });

  // Parte A: el admin lo activa con adminSetVehicleActive.
  test('ni el chófer ni el admin activan el vehículo desde el cliente', async () => {
    await assertFails(updateDoc(doc(db('asig'), 'vehicles', 'v-asig'), { isActive: false }));
    await assertFails(updateDoc(doc(db('admin'), 'vehicles', 'v-asig'), { isActive: false }));
  });
});
