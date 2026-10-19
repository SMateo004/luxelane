// D16: teléfono del chófer en bookings/{id}/driverContact/phone. El pasajero
// solo lo ve mientras el viaje está activo; nunca en el historial.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const ref = (uid: string, booking: string) =>
  doc(env.authenticatedContext(uid).firestore(), 'bookings', booking, 'driverContact', 'phone');

describe('lectura del teléfono del chófer', () => {
  test('el pasajero dueño lo ve dentro de la ventana activa', async () => {
    await assertSucceeds(getDoc(ref('ana', 'activa')));
  });

  test('el pasajero dueño no lo ve fuera de la ventana (confirmada o terminada)', async () => {
    await assertFails(getDoc(ref('ana', 'conf')));
    await assertFails(getDoc(ref('ana', 'fin')));
  });

  test('el pasajero de otra reserva no lo ve', async () => {
    await assertFails(getDoc(ref('beto', 'activa')));
    await assertFails(getDoc(ref('ana', 'beto1')));
  });

  test('un chófer no asignado no lo ve', async () => {
    await assertFails(getDoc(ref('libre', 'activa')));
    await assertFails(getDoc(ref('nover', 'activa')));
  });

  test('el chófer asignado y el admin lo ven', async () => {
    await assertSucceeds(getDoc(ref('asig', 'activa')));
    await assertSucceeds(getDoc(ref('admin', 'activa')));
    await assertSucceeds(getDoc(ref('admin', 'fin')));
  });
});

describe('escritura del teléfono del chófer', () => {
  test('solo el servidor lo escribe', async () => {
    for (const uid of ['asig', 'ana', 'admin']) {
      await assertFails(setDoc(ref(uid, 'activa'), { phone: '+59170000999' }));
    }
  });
});
