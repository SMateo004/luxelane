// /bookings y /users. La reserva completa (direcciones, notas, preferencias
// y datos del tercero) solo la leen el pasajero, el chófer asignado y el
// admin; nunca un chófer antes de aceptar.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => { await seed(env); });
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string | null) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const read = (uid: string | null, id: string) => getDoc(doc(db(uid), 'bookings', id));

// Reserva válida según las reglas de creación, salvo por su riderId.
function newBooking(riderId: string, extra: Record<string, unknown> = {}) {
  return {
    riderId,
    status: 'pending',
    estimatedPrice: 100,
    scheduledAt: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
    ...extra,
  };
}

describe('lectura de /bookings', () => {
  test('un usuario sin sesión no puede leer una reserva', async () => {
    await assertFails(read(null, 'pend'));
  });

  test('un pasajero no puede leer la reserva de otro', async () => {
    await assertFails(read('beto', 'pend'));
  });

  test('el pasajero dueño sí puede leer su reserva', async () => {
    await assertSucceeds(read('ana', 'pend'));
    await assertSucceeds(read('ana', 'activa'));
  });

  test('un chófer no verificado no lee una reserva pendiente', async () => {
    await assertFails(read('nover', 'pend'));
  });

  test('un chófer verificado sin asignar no lee la reserva pendiente (preferencias y tercero ocultos)', async () => {
    await assertFails(read('libre', 'pend'));
    await assertFails(read('asig', 'pend'));
  });

  test('un chófer bloqueado no lee una reserva pendiente', async () => {
    await assertFails(read('bloq', 'pend'));
  });

  test('un chófer no puede listar las reservas pendientes', async () => {
    await assertFails(getDocs(query(collection(db('libre'), 'bookings'),
      where('status', '==', 'pending'))));
  });

  test('el chófer asignado lee su reserva; otro chófer no', async () => {
    await assertSucceeds(read('asig', 'activa'));
    await assertFails(read('libre', 'activa'));
  });

  test('el admin lee cualquier reserva', async () => {
    await assertSucceeds(read('admin', 'pend'));
  });
});

describe('aceptar una reserva pendiente', () => {
  const accept = (uid: string) => updateDoc(doc(db(uid), 'bookings', 'pend'), {
    driverId: uid,
    status: 'confirmed',
    updatedAt: Timestamp.now(),
  });

  test('un chófer verificado la acepta y entonces ve los datos completos', async () => {
    await assertSucceeds(accept('libre'));
    await assertSucceeds(read('libre', 'pend'));
  });

  test('quien la liberó no la vuelve a aceptar; otro chófer sí (0.3)', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'bookings', 'pend'), { releasedBy: ['libre'] }));
    await assertFails(accept('libre'));
    await assertSucceeds(accept('asig'));
  });

  test('un chófer no verificado o bloqueado no la acepta', async () => {
    await assertFails(accept('nover'));
    await assertFails(accept('bloq'));
  });
});

describe('creación de /bookings (solo el servidor, createBooking)', () => {
  test('un pasajero no puede crear una reserva, ni con precio ni sin él', async () => {
    await assertFails(setDoc(doc(db('ana'), 'bookings', 'b2'), newBooking('ana')));
    const { estimatedPrice: _p, ...sinPrecio } = newBooking('ana');
    await assertFails(setDoc(doc(db('ana'), 'bookings', 'b3'), sinPrecio));
  });

  test('un chófer no puede crear una reserva a nombre de otro', async () => {
    await assertFails(setDoc(doc(db('libre'), 'bookings', 'b2'), newBooking('ana')));
  });

  test('ni siquiera el admin crea reservas desde la app', async () => {
    await assertFails(setDoc(doc(db('admin'), 'bookings', 'b2'), newBooking('ana')));
  });
});

describe('el precio de una reserva no se toca desde la app', () => {
  const ref = (uid: string, id: string) => doc(db(uid), 'bookings', id);

  test('el pasajero no cambia estimatedPrice ni pricing', async () => {
    await assertFails(updateDoc(ref('ana', 'pend'), { estimatedPrice: 1 }));
    await assertFails(updateDoc(ref('ana', 'pend'), { pricing: { source: 'client' } }));
    await assertFails(updateDoc(ref('ana', 'pend'),
      { status: 'cancelled', estimatedPrice: 1, updatedAt: Timestamp.now() }));
  });

  test('el chófer no cambia el precio al aceptar ni durante el viaje', async () => {
    await assertFails(updateDoc(ref('libre', 'pend'),
      { driverId: 'libre', status: 'confirmed', estimatedPrice: 1, updatedAt: Timestamp.now() }));
    await assertFails(updateDoc(ref('asig', 'activa'),
      { status: 'driver_arrived', pricing: {}, updatedAt: Timestamp.now() }));
  });

  test('la app no escribe openRequests', async () => {
    await assertFails(setDoc(doc(db('ana'), 'openRequests', 'pend'), { estimatedPrice: 1 }));
  });
});

describe('/adminAlerts', () => {
  test('solo el admin lee las alertas y nadie las escribe desde la app', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'adminAlerts', 'a1'), { type: 'distance_fallback' }));
    await assertSucceeds(getDoc(doc(db('admin'), 'adminAlerts', 'a1')));
    await assertFails(getDoc(doc(db('ana'), 'adminAlerts', 'a1')));
    await assertFails(getDoc(doc(db('asig'), 'adminAlerts', 'a1')));
    await assertFails(setDoc(doc(db('admin'), 'adminAlerts', 'a2'), { type: 'x' }));
  });

  test('ni el admin marca una alerta como revisada desde la app (solo resolveAlert)', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'adminAlerts', 'a1'), { type: 'distance_fallback', resolved: false }));
    await assertFails(updateDoc(doc(db('admin'), 'adminAlerts', 'a1'), { resolved: true }));
    await assertFails(getDoc(doc(db('libre'), 'adminAlerts', 'a1')));
    await assertFails(getDoc(doc(db(null), 'adminAlerts', 'a1')));
  });
});

describe('reglas de /users', () => {
  test('un usuario no puede darse el rol de admin', async () => {
    await assertFails(updateDoc(doc(db('ana'), 'users', 'ana'), { role: 'admin' }));
  });

  test('un usuario no puede registrarse ya como admin', async () => {
    await assertFails(setDoc(doc(db('nuevo'), 'users', 'nuevo'), {
      id: 'nuevo',
      role: 'admin',
      isActive: true,
    }));
  });

  test('un usuario sí puede editar sus campos no privilegiados', async () => {
    await assertSucceeds(updateDoc(doc(db('ana'), 'users', 'ana'), { name: 'Ana' }));
  });
});
