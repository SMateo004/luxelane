// 0.2: qué admin actuó no lo ven el pasajero ni el chófer. El evento de la
// reserva lo leen ellos y no lleva el uid (lo prueba trip_flow.int.ts); el
// uid está en eventDetails y en los eventos del incidente, solo para el
// admin. Estas celdas no cambian de reglas: fijan que siga así.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'bookings/activa/events/ov1'), { to: 'verified', actor: { role: 'admin' }, method: 'admin_override' });
    await setDoc(doc(db, 'bookings/activa/eventDetails/ov1'), { reason: 'Sin batería', actorUid: 'admin' });
    await setDoc(doc(db, 'incidents/inc1'), { reporterId: 'ana', bookingId: 'activa', status: 'closed' });
    await setDoc(doc(db, 'incidents/inc1/events/ev1'), { type: 'closed', actor: { uid: 'admin', role: 'admin' } });
  });
});
afterAll(async () => { await env?.cleanup(); });

const get = (uid: string, path: string) => getDoc(doc(env.authenticatedContext(uid).firestore(), path));

describe('uid del admin solo para el admin (0.2)', () => {
  test('pasajero y chófer leen el evento, pero no eventDetails', async () => {
    for (const uid of ['ana', 'asig']) {
      await assertSucceeds(get(uid, 'bookings/activa/events/ov1'));
      await assertFails(get(uid, 'bookings/activa/eventDetails/ov1'));
    }
    await assertSucceeds(get('admin', 'bookings/activa/eventDetails/ov1'));
  });

  test('quien disparó el SOS lee el incidente, pero no sus eventos', async () => {
    await assertSucceeds(get('ana', 'incidents/inc1'));
    await assertFails(get('ana', 'incidents/inc1/events/ev1'));
    await assertSucceeds(get('admin', 'incidents/inc1/events/ev1'));
  });
});
