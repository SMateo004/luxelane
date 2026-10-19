// Chófer bloqueado = users.isActive == false. Aunque documentsVerified sea
// true, no ve solicitudes, no publica su ubicación y no acepta viajes. Cada
// caso tiene su control: el mismo chófer reactivado sí puede.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const db = () => env.authenticatedContext('bloq').firestore();
const reactivate = () => env.withSecurityRulesDisabled((ctx) =>
  updateDoc(doc(ctx.firestore(), 'users', 'bloq'), { isActive: true }));

const readRequest = () => getDoc(doc(db(), 'openRequests', 'pend'));
const publishLocation = () => setDoc(doc(db(), 'bookings', 'activaBloq', 'tracking', 'driver'),
  { lat: -17.75, lng: -63.15, updatedAt: serverTimestamp() });
const accept = () => updateDoc(doc(db(), 'bookings', 'pend'),
  { driverId: 'bloq', status: 'confirmed', updatedAt: Timestamp.now() });

describe('chófer verificado con isActive == false', () => {
  test('la premisa: tiene documentsVerified == true e isActive == false', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const profile = await getDoc(doc(ctx.firestore(), 'driverProfiles', 'bloq'));
      const user = await getDoc(doc(ctx.firestore(), 'users', 'bloq'));
      expect(profile.data()?.documentsVerified).toBe(true);
      expect(user.data()?.isActive).toBe(false);
    });
  });

  test('no lee openRequests; reactivado, sí', async () => {
    await assertFails(readRequest());
    await reactivate();
    await assertSucceeds(readRequest());
  });

  test('no escribe tracking de su viaje activo; reactivado, sí', async () => {
    await assertFails(publishLocation());
    await reactivate();
    await assertSucceeds(publishLocation());
  });

  test('no puede aceptar una reserva pendiente; reactivado, sí', async () => {
    await assertFails(accept());
    await reactivate();
    await assertSucceeds(accept());
  });
});
