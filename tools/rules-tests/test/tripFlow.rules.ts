// Pasos del viaje desde la recogida (D1): solo el servidor cambia el estado
// a driver_arriving, driver_arrived, verified, in_progress y completed; la
// sal del código no la lee nadie desde la app; events es solo anexado.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { bookingDoc, seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    // Además de conf (confirmed) y activa (driver_arriving) del seed.
    for (const [id, status] of [['llego', 'driver_arrived'], ['verif', 'verified'], ['curso', 'in_progress']]) {
      await setDoc(doc(db, 'bookings', id), bookingDoc({ status, driverId: 'asig' }));
    }
    await setDoc(doc(db, 'bookings', 'llego', 'private', 'pickup'), { salt: 'abc', failedAttempts: 0 });
    await setDoc(doc(db, 'bookings', 'llego', 'events', 'e1'), {
      type: 'transition', from: 'driver_arriving', to: 'driver_arrived', source: 'driver_app',
    });
    await setDoc(doc(db, 'bookings', 'llego', 'eventLocations', 'e1'), { lat: -17.6, lng: -63.1 });
    await setDoc(doc(db, 'bookings', 'verif', 'tracking', 'driver'), { lat: -17.7, lng: -63.1, updatedAt: Timestamp.now() });
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const setStatus = (uid: string, id: string, status: string) =>
  updateDoc(doc(db(uid), 'bookings', id), { status, updatedAt: Timestamp.now() });

describe('el cliente no escribe los pasos del viaje (solo advanceBooking)', () => {
  test.each([
    ['conf', 'driver_arriving'],
    ['activa', 'driver_arrived'],
    ['llego', 'verified'],
    ['llego', 'in_progress'],
    ['verif', 'in_progress'],
    ['curso', 'completed'],
  ])('el chófer asignado no pasa %s a %s', async (id, to) => {
    await assertFails(setStatus('asig', id, to));
  });

  test.each([
    ['conf', 'driver_arriving'],
    ['activa', 'driver_arrived'],
    ['llego', 'verified'],
    ['verif', 'in_progress'],
    ['curso', 'completed'],
  ])('la pasajera dueña no pasa %s a %s', async (id, to) => {
    await assertFails(setStatus('ana', id, to));
  });

  test('el admin no fija verified ni in_progress desde el panel', async () => {
    await assertFails(setStatus('admin', 'llego', 'verified'));
    await assertFails(setStatus('admin', 'llego', 'in_progress'));
    await assertFails(setStatus('admin', 'verif', 'in_progress'));
  });

  // Parte A: completar y las demás transiciones del panel van por
  // adminUpdateBooking (admin_booking.int.ts).
  test('el admin no completa desde el cliente, tampoco un viaje en curso', async () => {
    for (const id of ['conf', 'activa', 'llego', 'verif', 'pend', 'curso']) {
      await assertFails(setStatus('admin', id, 'completed'));
    }
  });

  test('el panel ya no escribe transiciones ni cancela desde el cliente', async () => {
    await assertFails(setStatus('admin', 'activa', 'driver_arrived'));
    await assertFails(setStatus('admin', 'conf', 'cancelled'));
  });

  test('la pasajera cancela hasta driver_arrived, no después de verificar', async () => {
    await assertSucceeds(setStatus('ana', 'llego', 'cancelled'));
    await assertFails(setStatus('ana', 'verif', 'cancelled'));
    await assertFails(setStatus('ana', 'curso', 'cancelled'));
    await assertFails(setStatus('ana', 'fin', 'cancelled'));
  });
});

describe('campos del servidor y sal del código', () => {
  test.each(['ana', 'asig', 'admin'])('%s no toca pickupLocked ni las horas del viaje', async (uid) => {
    const ref = (id: string) => doc(db(uid), 'bookings', id);
    await assertFails(updateDoc(ref('llego'), { pickupLocked: false }));
    await assertFails(updateDoc(ref('llego'), { pickupLocked: true }));
    await assertFails(updateDoc(ref('llego'), { arrivedAt: Timestamp.now() }));
    await assertFails(updateDoc(ref('verif'), { verifiedBy: 'pickup_code' }));
  });

  test.each(['asig', 'ana', 'admin', 'libre'])('%s no lee ni escribe la sal (private)', async (uid) => {
    const ref = doc(db(uid), 'bookings', 'llego', 'private', 'pickup');
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(db(uid), 'bookings', 'llego', 'private')));
    await assertFails(setDoc(ref, { salt: 'mia', failedAttempts: 0 }));
    await assertFails(updateDoc(ref, { failedAttempts: 0 }));
  });
});

describe('registro de eventos (solo anexado, solo el servidor)', () => {
  test('lo leen la pasajera, el chófer asignado y el admin; nadie más', async () => {
    for (const uid of ['ana', 'asig', 'admin']) {
      await assertSucceeds(getDocs(collection(db(uid), 'bookings', 'llego', 'events')));
    }
    for (const uid of ['beto', 'libre']) {
      await assertFails(getDoc(doc(db(uid), 'bookings', 'llego', 'events', 'e1')));
    }
  });

  test.each(['ana', 'asig', 'admin'])('%s no crea, edita ni borra eventos', async (uid) => {
    const events = collection(db(uid), 'bookings', 'llego', 'events');
    await assertFails(addDoc(events, { type: 'transition', from: 'driver_arrived', to: 'verified' }));
    await assertFails(updateDoc(doc(events, 'e1'), { to: 'verified' }));
    await assertFails(deleteDoc(doc(events, 'e1')));
  });

  test('la ubicación del chófer en los eventos solo la lee el admin', async () => {
    await assertSucceeds(getDoc(doc(db('admin'), 'bookings', 'llego', 'eventLocations', 'e1')));
    for (const uid of ['ana', 'asig']) {
      await assertFails(getDoc(doc(db(uid), 'bookings', 'llego', 'eventLocations', 'e1')));
    }
    await assertFails(setDoc(doc(db('admin'), 'bookings', 'llego', 'eventLocations', 'e2'), { lat: 0, lng: 0 }));
  });
});

describe('verified sigue en la ventana en vivo', () => {
  test('la pasajera ve al chófer en el mapa con la reserva verificada', async () => {
    await assertSucceeds(getDoc(doc(db('ana'), 'bookings', 'verif', 'tracking', 'driver')));
  });

  test('el chófer publica su ubicación con la reserva verificada', async () => {
    await assertSucceeds(setDoc(doc(db('asig'), 'bookings', 'verif', 'tracking', 'driver'),
      { lat: -17.71, lng: -63.12, updatedAt: serverTimestamp() }));
  });
});
