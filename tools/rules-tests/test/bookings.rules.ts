// Prueba de humo de las reglas actuales, contra el emulador de Firestore con
// el proyecto ficticio demo-luxelane (nunca el proyecto real).
// RULES_PATH permite apuntar a otro archivo de reglas (prueba negativa).
import { readFileSync } from 'fs';
import { resolve } from 'path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-luxelane';
const RULES_PATH =
  process.env.RULES_PATH ?? resolve(__dirname, '../../../firestore.rules');
let env: RulesTestEnvironment;

// Reserva válida según las reglas de creación, salvo por su riderId.
function newBooking(riderId: string) {
  return {
    riderId,
    status: 'pending',
    estimatedPrice: 100,
    scheduledAt: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000),
  };
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(RULES_PATH, 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  // Datos sembrados saltándose las reglas: dos pasajeros, un chófer y una
  // reserva de Ana.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [uid, role] of [
      ['ana', 'rider'],
      ['beto', 'rider'],
      ['carla', 'driver'],
    ]) {
      await setDoc(doc(db, 'users', uid), { id: uid, role, isActive: true });
    }
    await setDoc(doc(db, 'bookings', 'b1'), {
      riderId: 'ana',
      status: 'confirmed',
      estimatedPrice: 100,
      scheduledAt: Timestamp.now(),
    });
  });
});

afterAll(async () => {
  await env?.cleanup();
});

describe('reglas de /bookings (humo)', () => {
  test('un usuario sin sesión no puede leer una reserva', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'bookings', 'b1')));
  });

  test('un pasajero no puede leer la reserva de otro', async () => {
    const db = env.authenticatedContext('beto').firestore();
    await assertFails(getDoc(doc(db, 'bookings', 'b1')));
  });

  test('el pasajero dueño sí puede leer su reserva', async () => {
    const db = env.authenticatedContext('ana').firestore();
    await assertSucceeds(getDoc(doc(db, 'bookings', 'b1')));
  });

  test('un chófer no puede crear una reserva a nombre de otro', async () => {
    const db = env.authenticatedContext('carla').firestore();
    await assertFails(setDoc(doc(db, 'bookings', 'b2'), newBooking('ana')));
  });

  test('un pasajero sí puede crear una reserva a su nombre', async () => {
    const db = env.authenticatedContext('ana').firestore();
    await assertSucceeds(setDoc(doc(db, 'bookings', 'b2'), newBooking('ana')));
  });
});

describe('reglas de /users (humo)', () => {
  test('un usuario no puede darse el rol de admin', async () => {
    const db = env.authenticatedContext('ana').firestore();
    await assertFails(updateDoc(doc(db, 'users', 'ana'), { role: 'admin' }));
  });

  test('un usuario no puede registrarse ya como admin', async () => {
    const db = env.authenticatedContext('nuevo').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'nuevo'), {
        id: 'nuevo',
        role: 'admin',
        isActive: true,
      }),
    );
  });

  test('un usuario sí puede editar sus campos no privilegiados', async () => {
    const db = env.authenticatedContext('ana').firestore();
    await assertSucceeds(updateDoc(doc(db, 'users', 'ana'), { name: 'Ana' }));
  });
});
