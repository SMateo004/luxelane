// Ubicación en vivo del chófer en bookings/{id}/tracking/driver.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const ref = (uid: string, booking: string) =>
  doc(env.authenticatedContext(uid).firestore(), 'bookings', booking, 'tracking', 'driver');
const position = (extra: Record<string, unknown> = {}) =>
  ({ lat: -17.75, lng: -63.15, updatedAt: serverTimestamp(), ...extra });

describe('lectura de la ubicación en vivo', () => {
  test('el pasajero dueño la ve mientras el viaje está activo', async () => {
    await assertSucceeds(getDoc(ref('ana', 'activa')));
  });

  test('el pasajero dueño no la ve antes ni después del viaje activo', async () => {
    await assertFails(getDoc(ref('ana', 'conf')));
    await assertFails(getDoc(ref('ana', 'fin')));
  });

  test('el chófer asignado y el admin la ven', async () => {
    await assertSucceeds(getDoc(ref('asig', 'activa')));
    await assertSucceeds(getDoc(ref('admin', 'activa')));
  });

  test('un pasajero ajeno y otros chóferes no la ven', async () => {
    await assertFails(getDoc(ref('beto', 'activa')));
    await assertFails(getDoc(ref('libre', 'activa')));
    await assertFails(getDoc(ref('nover', 'activa')));
  });
});

describe('escritura de la ubicación en vivo', () => {
  test('el chófer asignado la publica durante el viaje activo', async () => {
    await assertSucceeds(setDoc(ref('asig', 'activa'), position()));
  });

  test('no se publica fuera del viaje activo', async () => {
    await assertFails(setDoc(ref('asig', 'conf'), position()));
    await assertFails(setDoc(ref('asig', 'fin'), position()));
  });

  test('solo lat, lng y hora del servidor', async () => {
    await assertFails(setDoc(ref('asig', 'activa'), position({ speed: 40 })));
  });

  test('otro chófer, el pasajero o un chófer bloqueado no la publican', async () => {
    await assertFails(setDoc(ref('libre', 'activa'), position()));
    await assertFails(setDoc(ref('ana', 'activa'), position()));
    await assertFails(setDoc(ref('bloq', 'activaBloq'), position()));
  });
});
