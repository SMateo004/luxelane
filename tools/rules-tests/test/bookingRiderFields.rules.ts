// A8.6: al valorar, el pasajero dueño solo cambia la valoración
// (riderRating, riderComment) y updatedAt. Campo por campo: cualquier otro,
// junto a un cambio válido, se rechaza. Cancelar ya no se escribe desde la
// app (Parte B, B7): solo con la callable cancelBooking.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { bookingDoc, seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'bookings', 'hecha'), bookingDoc({ status: 'completed', driverId: 'asig', finalPrice: 100 })));
});
afterAll(async () => { await env?.cleanup(); });

const ref = (id: string) => doc(env.authenticatedContext('ana').firestore(), 'bookings', id);
const now = () => Timestamp.now();

/** Campos de una reserva que el pasajero nunca cambia. */
const OTHER: [string, unknown][] = [
  ['riderId', 'beto'], ['driverId', 'libre'], ['estimatedPrice', 1], ['finalPrice', 1],
  ['quotedPrice', 1], ['class', 'firstClass'], ['vehicleClass', 'firstClass'], ['serviceType', 'byTheHour'],
  ['hours', 9], ['scheduledAt', Timestamp.fromMillis(0)], ['origin', { address: 'x' }], ['destination', { address: 'x' }],
  ['notes', 'otra nota'], ['guest', { firstName: 'X' }], ['riderPreferences', { music: 'rock' }],
  ['paymentId', 'p_falso'], ['stripePaymentIntentId', 'pi_falso'], ['stripePaymentMethodId', 'pm_falso'],
  ['cardPayment', false], ['settlement', { driverPayout: 1 }], ['pricingReview', null], ['driverInfo', { name: 'x' }],
  ['pickupLocked', false], ['arrivedAt', Timestamp.fromMillis(0)], ['verifiedAt', Timestamp.fromMillis(0)],
  ['completedAt', Timestamp.fromMillis(0)], ['incidentOpen', false], ['requestId', 'otro'], ['createdAt', Timestamp.fromMillis(0)],
  ['cancelReason', 'x'], ['cancelledBy', 'admin'], ['campoNuevo', 1],
];

describe('cancelar (pasajero dueño): solo por cancelBooking', () => {
  // B7: antes se permitía; ahora la reserva cancelada sin motivo, recargo
  // ni evento ya no puede escribirse desde la app.
  test.each([['pend'], ['activa']])('no pasa %s a cancelled escribiendo la reserva', async (id) => {
    await assertFails(updateDoc(ref(id), { status: 'cancelled', updatedAt: now() }));
  });

  test('tampoco puede anotarse un recargo o motivo', async () => {
    await assertFails(updateDoc(ref('pend'), { cancellationFee: 0, cancellationReason: 'other', updatedAt: now() }));
  });

  test.each(OTHER)('no cambia %s al cancelar', async (field, value) => {
    await assertFails(updateDoc(ref('pend'), { status: 'cancelled', updatedAt: now(), [field]: value }));
  });

  test.each([['completed'], ['in_progress'], ['pending']])('no pone status %s', async (to) => {
    await assertFails(updateDoc(ref('activa'), { status: to, updatedAt: now() }));
  });

  test('updatedAt debe ser una hora cercana a la del servidor', async () => {
    await assertFails(updateDoc(ref('pend'), { status: 'cancelled', updatedAt: 'ayer' }));
    await assertFails(updateDoc(ref('pend'), { status: 'cancelled', updatedAt: Timestamp.fromMillis(0) }));
  });

  test('tampoco valora al cancelar', async () => {
    await assertFails(updateDoc(ref('pend'), { status: 'cancelled', updatedAt: now(), riderRating: 5 }));
  });
});

describe('valorar (pasajero dueño)', () => {
  test('control: nota y comentario', async () => {
    await assertSucceeds(updateDoc(ref('hecha'), { riderRating: 5, riderComment: 'Muy bien', updatedAt: now() }));
  });

  test.each(OTHER)('no cambia %s al valorar', async (field, value) => {
    await assertFails(updateDoc(ref('hecha'), { riderRating: 5, updatedAt: now(), [field]: value }));
  });

  test('no cambia el status al valorar', async () => {
    await assertFails(updateDoc(ref('hecha'), { riderRating: 5, updatedAt: now(), status: 'cancelled' }));
  });

  test('nota entera de 1 a 5 y comentario de texto acotado', async () => {
    await assertFails(updateDoc(ref('hecha'), { riderRating: 6, updatedAt: now() }));
    await assertFails(updateDoc(ref('hecha'), { riderRating: 4.5, updatedAt: now() }));
    await assertFails(updateDoc(ref('hecha'), { riderRating: 5, riderComment: { html: '<b>' }, updatedAt: now() }));
    await assertFails(updateDoc(ref('hecha'), { riderRating: 5, riderComment: 'x'.repeat(1001), updatedAt: now() }));
  });

  test('una sola vez', async () => {
    await assertSucceeds(updateDoc(ref('hecha'), { riderRating: 4, updatedAt: now() }));
    await assertFails(updateDoc(ref('hecha'), { riderRating: 5, updatedAt: now() }));
  });
});
