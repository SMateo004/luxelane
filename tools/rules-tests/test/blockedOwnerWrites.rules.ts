// D1: una cuenta bloqueada no edita su perfil (salvo quitar tokens de push
// al cerrar sesión) ni el color o la foto de su vehículo. Las cuentas
// activas siguen igual.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { arrayRemove, arrayUnion, doc, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'bloq'), { id: 'bloq', role: 'driver', isActive: false, fcmTokens: ['t1', 't2'] });
    await setDoc(doc(db, 'vehicles', 'v-bloq'), { driverId: 'bloq', color: 'Gris', isActive: true });
    await setDoc(doc(db, 'vehicles', 'v-asig'), { driverId: 'asig', color: 'Gris', isActive: true });
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();

describe('perfil de una cuenta bloqueada', () => {
  test.each([
    ['nombre', { displayName: 'Otro' }],
    ['teléfono', { phone: '+59170000999' }],
    ['token nuevo', { fcmTokens: arrayUnion('t3') }],
    ['quitar un token y cambiar el nombre a la vez', { fcmTokens: arrayRemove('t1'), displayName: 'Otro' }],
  ])('no cambia %s', async (_, data) => {
    await assertFails(updateDoc(doc(db('bloq'), 'users', 'bloq'), data));
  });

  test('sí quita un token de push (cerrar sesión)', async () => {
    await assertSucceeds(updateDoc(doc(db('bloq'), 'users', 'bloq'), { fcmTokens: arrayRemove('t1') }));
  });

  test('una cuenta activa sigue editando su perfil', async () => {
    await assertSucceeds(updateDoc(doc(db('ana'), 'users', 'ana'), { displayName: 'Ana B' }));
  });
});

describe('vehículo de un chófer bloqueado', () => {
  test('no cambia color ni foto', async () => {
    await assertFails(updateDoc(doc(db('bloq'), 'vehicles', 'v-bloq'), { color: 'Negro' }));
    await assertFails(updateDoc(doc(db('bloq'), 'vehicles', 'v-bloq'), { photoUrl: 'https://x/y.jpg' }));
  });

  test('el chófer activo sí', async () => {
    await assertSucceeds(updateDoc(doc(db('asig'), 'vehicles', 'v-asig'), { color: 'Negro' }));
  });
});
