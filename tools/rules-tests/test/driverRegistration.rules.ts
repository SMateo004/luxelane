// Registro de chóferes (A1, A6, A7): la solicitud y sus documentos los
// escribe el servidor; el chófer lee su estado; con documentos obligatorios
// vencidos y el bloqueo activo (docsBlocked), no se pone en línea ni acepta.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const f = ctx.firestore();
    await setDoc(doc(f, 'driverApplications', 'libre'), { driverId: 'libre', status: 'submitted' });
    await setDoc(doc(f, 'driverApplications', 'libre', 'documents', 'license_front'),
      { status: 'rejected', rejectReason: 'illegible', version: 1 });
    await setDoc(doc(f, 'driverApplications', 'libre', 'private', 'data'),
      { personal: { nationalIdNumber: '0000000 (ficticio)' } });
    await setDoc(doc(f, 'driverApplications', 'libre', 'documentFiles', 'license_front'),
      { path: 'driverDocs/libre/license_front/1' });
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();

describe('driverApplications', () => {
  test('el chófer lee su estado y el motivo de rechazo, no sus datos personales ni las rutas', async () => {
    await assertSucceeds(getDoc(doc(db('libre'), 'driverApplications', 'libre')));
    await assertSucceeds(getDoc(doc(db('libre'), 'driverApplications', 'libre', 'documents', 'license_front')));
    await assertFails(getDoc(doc(db('libre'), 'driverApplications', 'libre', 'private', 'data')));
    await assertFails(getDoc(doc(db('libre'), 'driverApplications', 'libre', 'documentFiles', 'license_front')));
  });

  test('otro chófer o un pasajero no la leen; el admin sí', async () => {
    for (const uid of ['asig', 'ana']) {
      await assertFails(getDoc(doc(db(uid), 'driverApplications', 'libre')));
      await assertFails(getDoc(doc(db(uid), 'driverApplications', 'libre', 'documents', 'license_front')));
    }
    await assertSucceeds(getDoc(doc(db('admin'), 'driverApplications', 'libre', 'private', 'data')));
    await assertSucceeds(getDoc(doc(db('admin'), 'driverApplications', 'libre', 'documentFiles', 'license_front')));
  });

  test('nadie la escribe desde el cliente (ni para aprobarse)', async () => {
    for (const uid of ['libre', 'admin']) {
      await assertFails(updateDoc(doc(db(uid), 'driverApplications', 'libre'), { status: 'approved' }));
      await assertFails(updateDoc(doc(db(uid), 'driverApplications', 'libre', 'documents', 'license_front'),
        { status: 'approved' }));
      await assertFails(setDoc(doc(db(uid), 'driverApplications', 'libre', 'private', 'data'), { x: 1 }));
    }
  });
});

describe('bloqueo en línea por documentos vencidos (docsBlocked)', () => {
  const block = (v: boolean) => env.withSecurityRulesDisabled((ctx) =>
    updateDoc(doc(ctx.firestore(), 'driverProfiles', 'libre'), { docsBlocked: v, isAvailable: false, online: false }));

  test('sin bloqueo se pone en línea; con bloqueo, no', async () => {
    await block(false);
    await assertSucceeds(updateDoc(doc(db('libre'), 'driverProfiles', 'libre'), { isAvailable: true, online: true }));
    await block(true);
    await assertFails(updateDoc(doc(db('libre'), 'driverProfiles', 'libre'), { isAvailable: true, online: true }));
    await assertFails(updateDoc(doc(db('libre'), 'driverProfiles', 'libre'), { online: true }));
  });

  test('bloqueado puede salir de línea y no puede quitarse el bloqueo', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'driverProfiles', 'libre'), { docsBlocked: true, isAvailable: true, online: true }));
    await assertSucceeds(updateDoc(doc(db('libre'), 'driverProfiles', 'libre'), { isAvailable: false, online: false }));
    await assertFails(updateDoc(doc(db('libre'), 'driverProfiles', 'libre'), { docsBlocked: false }));
  });

  test('bloqueado no acepta una reserva pagada', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'driverProfiles', 'libre'), { docsBlocked: true }));
    await assertFails(updateDoc(doc(db('libre'), 'bookings', 'pend'),
      { driverId: 'libre', status: 'confirmed', updatedAt: Timestamp.now() }));
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'driverProfiles', 'libre'), { docsBlocked: false }));
    await assertSucceeds(updateDoc(doc(db('libre'), 'bookings', 'pend'),
      { driverId: 'libre', status: 'confirmed', updatedAt: Timestamp.now() }));
  });
});
