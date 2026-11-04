// Ventana del chófer (decisiones 1 a 3). El chófer asignado y activo lee la
// reserva y sus subcolecciones solo entre confirmed e in_progress; su
// historial sale de driverHistory/{uid}/trips, que lee él y el admin y que
// nadie escribe desde el cliente. La matriz (matrix.ts) cubre cada estado
// por rol; aquí, los casos que no caben en ella. Datos FICTICIOS.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  collection, doc, getDoc, getDocs, orderBy, query, setDoc, Timestamp, updateDoc, where,
} from 'firebase/firestore';
import { bookingDoc, seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    // Una reserva de asig en cada estado final, y una liberada por asig.
    for (const status of ['completed', 'cancelled', 'no_show']) {
      await setDoc(doc(f, 'bookings', `v_${status}`), bookingDoc({ status, driverId: 'asig' }));
      await setDoc(doc(f, 'bookings', `v_${status}`, 'events', 'e1'), { to: status });
    }
    await setDoc(doc(f, 'bookings', 'v_liberada'), bookingDoc({ status: 'pending', driverId: null, releasedBy: ['asig'] }));
    await setDoc(doc(f, 'driverHistory', 'asig', 'trips', 'fin'),
      { bookingId: 'fin', status: 'completed', endedAt: Timestamp.now() });
    await setDoc(doc(f, 'driverHistory', 'libre', 'trips', 'otro'),
      { bookingId: 'otro', status: 'completed', endedAt: Timestamp.now() });
  });
});
afterAll(async () => { await env?.cleanup(); });

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const WINDOW = ['confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress'];

describe('consultas del chófer sobre sus reservas', () => {
  test('la consulta antigua (solo driverId, sin estado) se rechaza entera: la app anterior deja de ver sus viajes', async () => {
    await assertFails(getDocs(query(collection(as('asig'), 'bookings'), where('driverId', '==', 'asig'))));
  });

  test('la consulta con el filtro de la ventana pasa y no trae las terminadas', async () => {
    const snap = await assertSucceeds(getDocs(query(collection(as('asig'), 'bookings'),
      where('driverId', '==', 'asig'), where('status', 'in', WINDOW))));
    const ids = snap.docs.map((d) => d.id).sort();
    expect(ids).toEqual(['activa', 'conf']);
  });

  test('pedir sus reservas terminadas por consulta se rechaza', async () => {
    await assertFails(getDocs(query(collection(as('asig'), 'bookings'),
      where('driverId', '==', 'asig'), where('status', '==', 'completed'))));
  });
});

describe('fuera de la ventana', () => {
  test.each(['completed', 'cancelled', 'no_show'])('asignado y activo: no lee la reserva %s ni sus eventos', async (s) => {
    await assertFails(getDoc(doc(as('asig'), 'bookings', `v_${s}`)));
    await assertFails(getDocs(collection(as('asig'), 'bookings', `v_${s}`, 'events')));
  });

  test('chófer liberado: no lee la reserva que liberó', async () => {
    await assertFails(getDoc(doc(as('asig'), 'bookings', 'v_liberada')));
  });

  test('chófer ajeno: no lee la reserva de otro, ni en la ventana', async () => {
    await assertFails(getDoc(doc(as('libre'), 'bookings', 'activa')));
    await assertFails(getDoc(doc(as('libre'), 'bookings', 'v_completed')));
  });

  test('pasajero dueño y admin: siguen leyendo la reserva terminada', async () => {
    await assertSucceeds(getDoc(doc(as('ana'), 'bookings', 'v_completed')));
    await assertSucceeds(getDoc(doc(as('admin'), 'bookings', 'v_completed')));
  });

  test('dentro de la ventana: el asignado la lee; bloqueado, no', async () => {
    await assertSucceeds(getDoc(doc(as('asig'), 'bookings', 'activa')));
    await assertFails(getDoc(doc(as('bloq'), 'bookings', 'activaBloq')));
  });
});

describe('driverHistory/{uid}/trips', () => {
  test('el chófer dueño lee y lista su historial, del más reciente al más antiguo', async () => {
    await assertSucceeds(getDoc(doc(as('asig'), 'driverHistory', 'asig', 'trips', 'fin')));
    await assertSucceeds(getDocs(query(collection(as('asig'), 'driverHistory', 'asig', 'trips'),
      where('status', '==', 'completed'), orderBy('endedAt', 'desc'))));
  });

  test('otro chófer no lee el resumen ajeno', async () => {
    await assertFails(getDoc(doc(as('asig'), 'driverHistory', 'libre', 'trips', 'otro')));
    await assertFails(getDocs(collection(as('asig'), 'driverHistory', 'libre', 'trips')));
  });

  test('el pasajero no lee el historial del chófer', async () => {
    await assertFails(getDoc(doc(as('ana'), 'driverHistory', 'asig', 'trips', 'fin')));
  });

  test('el admin lo lee', async () => {
    await assertSucceeds(getDoc(doc(as('admin'), 'driverHistory', 'asig', 'trips', 'fin')));
  });

  test('nadie lo escribe desde el cliente, ni el dueño ni el admin', async () => {
    for (const uid of ['asig', 'admin']) {
      await assertFails(setDoc(doc(as(uid), 'driverHistory', 'asig', 'trips', 'nuevo'), { status: 'completed' }));
      await assertFails(updateDoc(doc(as(uid), 'driverHistory', 'asig', 'trips', 'fin'), { riderRating: 5 }));
    }
  });

  test('el documento padre driverHistory/{uid} no se lee ni se escribe', async () => {
    await assertFails(getDoc(doc(as('asig'), 'driverHistory', 'asig')));
    await assertFails(setDoc(doc(as('asig'), 'driverHistory', 'asig'), { x: 1 }));
  });
});
