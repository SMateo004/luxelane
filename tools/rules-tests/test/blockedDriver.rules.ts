// Chófer bloqueado = users.isActive == false. Aunque documentsVerified sea
// true, no ve solicitudes, no publica su ubicación y no acepta viajes. Cada
// caso tiene su control: el mismo chófer reactivado sí puede.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, serverTimestamp, setDoc, Timestamp, updateDoc, where } from 'firebase/firestore';
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

  // H1: un chófer bloqueado deja de ver lo que tenía asignado.
  describe('lectura de lo asignado (H1)', () => {
    beforeEach(async () => {
      await env.withSecurityRulesDisabled(async (ctx) => {
        const f = ctx.firestore();
        await setDoc(doc(f, 'bookings', 'activaBloq', 'events', 'e1'), { to: 'driver_arriving' });
        await setDoc(doc(f, 'bookings', 'activaBloq', 'tracking', 'driver'), { lat: 1, lng: 1, updatedAt: Timestamp.now() });
        await setDoc(doc(f, 'bookings', 'activaBloq', 'driverContact', 'phone'), { phone: '+59170000556' });
        await setDoc(doc(f, 'rides', 'rBloq'), { riderId: 'ana', driverId: 'bloq', bookingId: 'activaBloq' });
      });
    });

    const reads: [string, () => Promise<unknown>][] = [
      ['la reserva', () => getDoc(doc(db(), 'bookings', 'activaBloq'))],
      ['sus reservas por consulta', () => getDocs(query(collection(db(), 'bookings'), where('driverId', '==', 'bloq')))],
      ['los eventos', () => getDocs(collection(db(), 'bookings', 'activaBloq', 'events'))],
      ['el seguimiento', () => getDoc(doc(db(), 'bookings', 'activaBloq', 'tracking', 'driver'))],
      ['el contacto', () => getDoc(doc(db(), 'bookings', 'activaBloq', 'driverContact', 'phone'))],
      ['rides', () => getDoc(doc(db(), 'rides', 'rBloq'))],
    ];
    test.each(reads)('no lee %s; reactivado, sí', async (_what, read) => {
      await assertFails(read());
      await reactivate();
      await assertSucceeds(read());
    });
  });
});

