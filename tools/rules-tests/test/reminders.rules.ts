// Prompt 18, A1: `reminders` de la reserva lo escribe solo el servidor. Ni el
// pasajero (al valorar) ni el chófer (al aceptar) pueden colarlo. Datos
// FICTICIOS.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { bookingDoc, seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'bookings', 'hecha'), bookingDoc({ status: 'completed', driverId: 'asig' })));
});
afterAll(async () => { await env?.cleanup(); });

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const reminders = { nextAt: null, sent: ['rider:30'], skipped: [] };

test('el pasajero valora, pero no puede tocar reminders', async () => {
  await assertFails(updateDoc(doc(as('ana'), 'bookings', 'hecha'),
    { riderRating: 5, updatedAt: Timestamp.now(), reminders }));
  await assertSucceeds(updateDoc(doc(as('ana'), 'bookings', 'hecha'), { riderRating: 5, updatedAt: Timestamp.now() }));
});

test('el chófer acepta, pero no puede tocar reminders', async () => {
  await assertFails(updateDoc(doc(as('libre'), 'bookings', 'pend'),
    { driverId: 'libre', status: 'confirmed', updatedAt: Timestamp.now(), reminders }));
});

test('ni el admin desde el cliente', async () => {
  await assertFails(updateDoc(doc(as('admin'), 'bookings', 'pend'), { reminders }));
});
