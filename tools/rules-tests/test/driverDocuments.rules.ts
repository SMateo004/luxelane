// H4: tras la verificación, el chófer no cambia su licencia ni los datos
// sensibles del vehículo (placa, clase, marca, modelo, año); color y foto,
// sí. Los cambia un admin.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    for (const uid of ['asig', 'nover']) {
      await setDoc(doc(ctx.firestore(), 'vehicles', `v_${uid}`), {
        id: `v_${uid}`, driverId: uid, make: 'Toyota', model: 'Camry', year: 2022,
        plate: `P-${uid}`, class: 'business', color: 'Negro', capacity: 3, isActive: uid === 'asig',
      });
    }
  });
});
afterAll(async () => { await env?.cleanup(); });

const profile = (uid: string, target: string) => doc(env.authenticatedContext(uid).firestore(), 'driverProfiles', target);
const vehicle = (uid: string, target: string) => doc(env.authenticatedContext(uid).firestore(), 'vehicles', target);

const LICENSE_CHANGES: [string, Record<string, unknown>][] = [
  ['licenseNumber', { licenseNumber: 'LIC-OTRA' }],
  ['licenseExpiry', { licenseExpiry: Timestamp.fromDate(new Date(2031, 0, 1)) }],
  ['vehicleId', { vehicleId: 'v_otro' }],
];

const VEHICLE_CHANGES: [string, Record<string, unknown>][] = [
  ['plate', { plate: 'OTRA' }],
  ['class', { class: 'firstClass' }],
  ['make', { make: 'Kia' }],
  ['model', { model: 'Rio' }],
  ['year', { year: 2015 }],
];

describe('licencia tras la verificación (H4)', () => {
  test.each(LICENSE_CHANGES)('el chófer verificado no cambia %s', async (_f, change) => {
    await assertFails(updateDoc(profile('asig', 'asig'), change));
  });

  test.each(LICENSE_CHANGES)('el admin sí cambia %s', async (_f, change) => {
    await assertSucceeds(updateDoc(profile('admin', 'asig'), change));
  });

  test.each(LICENSE_CHANGES)('antes de verificar, el chófer aún corrige %s', async (_f, change) => {
    await assertSucceeds(updateDoc(profile('nover', 'nover'), change));
  });

  test('el chófer verificado sigue cambiando su disponibilidad', async () => {
    await assertSucceeds(updateDoc(profile('asig', 'asig'), { isAvailable: false, online: false }));
  });
});

describe('datos sensibles del vehículo (H4)', () => {
  test.each(VEHICLE_CHANGES)('el chófer no cambia %s', async (_f, change) => {
    await assertFails(updateDoc(vehicle('asig', 'v_asig'), change));
    await assertFails(updateDoc(vehicle('nover', 'v_nover'), change));
  });

  test.each(VEHICLE_CHANGES)('el admin sí cambia %s', async (_f, change) => {
    await assertSucceeds(updateDoc(vehicle('admin', 'v_asig'), change));
  });

  test('el chófer cambia color y foto', async () => {
    await assertSucceeds(updateDoc(vehicle('asig', 'v_asig'), { color: 'Gris' }));
    await assertSucceeds(updateDoc(vehicle('asig', 'v_asig'), { photoUrl: 'https://example.com/a.jpg' }));
  });
});

// A8.5: el dueño solo escribe su lista de campos; los demás (documentos,
// fotos, datos de pago, verificación, valoración) no, antes ni después.
describe('campos del perfil del chófer (A8.5)', () => {
  const OTHER: [string, Record<string, unknown>][] = [
    ['una foto de documento', { documentPhotoUrl: 'https://example.com/dni.jpg' }],
    ['datos de pago', { bankAccount: 'ES00 0000' }],
    ['la valoración', { rating: 5 }],
    ['el contador de viajes', { totalRides: 999 }],
    ['su userId', { userId: 'otro' }],
  ];

  test.each(OTHER)('el chófer verificado no escribe %s', async (_w, change) => {
    await assertFails(updateDoc(profile('asig', 'asig'), change));
  });

  test.each(OTHER)('el chófer sin verificar tampoco escribe %s', async (_w, change) => {
    await assertFails(updateDoc(profile('nover', 'nover'), change));
  });

  test('nadie se cambia la verificación: ni desverificarse ni verificarse', async () => {
    await assertFails(updateDoc(profile('asig', 'asig'), { documentsVerified: false }));
    await assertFails(updateDoc(profile('nover', 'nover'), { documentsVerified: true }));
  });

  test('el alta solo admite sus campos y su propio userId', async () => {
    await env.withSecurityRulesDisabled((ctx) => deleteDoc(doc(ctx.firestore(), 'driverProfiles', 'nover')));
    const base = { userId: 'nover', licenseNumber: 'LIC', licenseExpiry: Timestamp.fromDate(new Date(2030, 0, 1)), vehicleId: 'v_nover' };
    await assertFails(setDoc(profile('nover', 'nover'), { ...base, documentPhotoUrl: 'x' }));
    await assertFails(setDoc(profile('nover', 'nover'), { ...base, userId: 'asig' }));
    await assertSucceeds(setDoc(profile('nover', 'nover'), base));
  });

  test('el chófer verificado sigue publicando disponibilidad y ubicación', async () => {
    await assertSucceeds(updateDoc(profile('asig', 'asig'), { isAvailable: true, online: true, currentLocation: { lat: 1, lng: 1 } }));
  });

  test('el admin sí escribe los demás campos', async () => {
    await assertSucceeds(updateDoc(profile('admin', 'asig'), { documentPhotoUrl: 'https://example.com/dni.jpg' }));
  });
});

