// Prueba de humo de las reglas actuales de /bookings, contra el emulador de
// Firestore con el proyecto ficticio demo-luxelane (nunca el proyecto real).
import { readFileSync } from 'fs';
import { resolve } from 'path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';

const PROJECT_ID = 'demo-luxelane';
let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  // Datos sembrados saltándose las reglas: dos pasajeros y una reserva de Ana.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const uid of ['ana', 'beto']) {
      await setDoc(doc(db, 'users', uid), {
        id: uid,
        role: 'rider',
        isActive: true,
      });
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
  test('un usuario no autenticado no puede leer una reserva', async () => {
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
});
