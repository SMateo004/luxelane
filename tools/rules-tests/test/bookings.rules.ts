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

  test('un chófer no verificado o bloqueado no la acepta', async () => {
    await assertFails(accept('nover'));
    await assertFails(accept('bloq'));
  });
});

describe('creación de /bookings', () => {
  test('un chófer no puede crear una reserva a nombre de otro', async () => {
    await assertFails(setDoc(doc(db('libre'), 'bookings', 'b2'), newBooking('ana')));
  });

  test('un pasajero sí puede crear una reserva a su nombre', async () => {
    await assertSucceeds(setDoc(doc(db('ana'), 'bookings', 'b2'), newBooking('ana')));
  });

  test('los datos del tercero van en guest con campos acotados', async () => {
    const guest = { title: 'Sra.', firstName: 'Carla', phone: '+59170000001', language: 'Español' };
    await assertSucceeds(setDoc(doc(db('ana'), 'bookings', 'b2'), newBooking('ana', { guest })));
    await assertFails(setDoc(doc(db('ana'), 'bookings', 'b3'),
      newBooking('ana', { guest: { ...guest, passport: 'X123' } })));
    await assertFails(setDoc(doc(db('ana'), 'bookings', 'b4'),
      newBooking('ana', { guest: { ...guest, firstName: '' } })));
  });

  test('el pasajero no puede cambiar los datos del tercero después', async () => {
    await assertFails(updateDoc(doc(db('ana'), 'bookings', 'pend'),
      { 'guest.phone': '+59170000999' }));
  });

  test('la zona de recogida y destino es un texto corto', async () => {
    await assertSucceeds(setDoc(doc(db('ana'), 'bookings', 'b2'),
      newBooking('ana', { pickupArea: 'Santa Cruz de la Sierra', dropoffArea: 'La Paz' })));
    await assertFails(setDoc(doc(db('ana'), 'bookings', 'b3'),
      newBooking('ana', { pickupArea: 'x'.repeat(81) })));
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
