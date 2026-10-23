// SOS (D1, F9): el incidente lo leen quien lo disparó y el admin; la
// contraparte del viaje y terceros, nunca. Solo el servidor cambia su
// estado. Quien lo disparó publica su ubicación, acotada, mientras siga
// abierto.
import { assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { seed, startEnv } from './setup';

let env: RulesTestEnvironment;
beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  await seed(env);
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    // activa: pasajera ana, chófer asig.
    const base = { bookingId: 'activa', count: 1 };
    await setDoc(doc(db, 'incidents', 'deAna'), { ...base, reporterId: 'ana', reporterRole: 'rider', status: 'open' });
    await setDoc(doc(db, 'incidents', 'deAsig'), { ...base, reporterId: 'asig', reporterRole: 'driver', status: 'open' });
    await setDoc(doc(db, 'incidents', 'reconocido'), { ...base, reporterId: 'ana', reporterRole: 'rider', status: 'acknowledged' });
    await setDoc(doc(db, 'incidents', 'cerrado'), { ...base, reporterId: 'ana', reporterRole: 'rider', status: 'closed' });
    await setDoc(doc(db, 'incidents', 'cancelado'), { ...base, reporterId: 'ana', reporterRole: 'rider', status: 'cancel_requested', cancelledByReporter: true });
    await setDoc(doc(db, 'incidents', 'canceladoReconocido'),
      { ...base, reporterId: 'ana', reporterRole: 'rider', status: 'acknowledged', cancelledByReporter: true });
    await setDoc(doc(db, 'incidents', 'deAna', 'events', 'e1'), { type: 'raised' });
    await setDoc(doc(db, 'bookings', 'activa', 'adminOnly', 'incident'), { incidentOpen: true, activeIncidentId: 'deAna' });
  });
});
afterAll(async () => { await env?.cleanup(); });

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const slot = () => String(Math.floor(Date.now() / 10000));
const loc = (uid: string, incident: string, data: Record<string, unknown> = {}, id = slot()) =>
  setDoc(doc(db(uid), 'incidents', incident, 'locations', id),
    { lat: -17.78, lng: -63.18, at: serverTimestamp(), ...data });

describe('lectura de /incidents', () => {
  test('quien lo disparó lo lee (y su lista)', async () => {
    await assertSucceeds(getDoc(doc(db('ana'), 'incidents', 'deAna')));
    await assertSucceeds(getDocs(query(collection(db('ana'), 'incidents'),
      where('reporterId', '==', 'ana'), where('bookingId', '==', 'activa'))));
    await assertSucceeds(getDoc(doc(db('asig'), 'incidents', 'deAsig')));
  });

  test('la contraparte del viaje no lo lee: ni el chófer el del pasajero ni al revés', async () => {
    await assertFails(getDoc(doc(db('asig'), 'incidents', 'deAna')));
    await assertFails(getDoc(doc(db('ana'), 'incidents', 'deAsig')));
    await assertFails(getDocs(query(collection(db('asig'), 'incidents'), where('bookingId', '==', 'activa'))));
  });

  test('un tercero no lo lee', async () => {
    for (const uid of ['beto', 'libre']) {
      await assertFails(getDoc(doc(db(uid), 'incidents', 'deAna')));
    }
  });

  test('el admin lee incidentes, su registro y el estado de la reserva', async () => {
    await assertSucceeds(getDoc(doc(db('admin'), 'incidents', 'deAna')));
    await assertSucceeds(getDocs(collection(db('admin'), 'incidents', 'deAna', 'events')));
    await assertSucceeds(getDoc(doc(db('admin'), 'bookings', 'activa', 'adminOnly', 'incident')));
  });

  test('el estado de incidentes de la reserva no lo leen pasajero ni chófer', async () => {
    for (const uid of ['ana', 'asig']) {
      await assertFails(getDoc(doc(db(uid), 'bookings', 'activa', 'adminOnly', 'incident')));
    }
  });

  test('el registro del incidente no lo lee ni quien lo disparó', async () => {
    await assertFails(getDocs(collection(db('ana'), 'incidents', 'deAna', 'events')));
  });
});

describe('escritura de /incidents (solo el servidor)', () => {
  test.each(['ana', 'asig', 'admin'])('%s no crea incidentes ni cambia status, ack o cierre', async (uid) => {
    await assertFails(addDoc(collection(db(uid), 'incidents'),
      { bookingId: 'activa', reporterId: uid, status: 'open' }));
    const ref = doc(db(uid), 'incidents', 'deAna');
    await assertFails(updateDoc(ref, { status: 'acknowledged' }));
    await assertFails(updateDoc(ref, { status: 'closed', closeNote: 'cerrado desde la app' }));
    await assertFails(updateDoc(ref, { acknowledgedBy: uid }));
    await assertFails(deleteDoc(ref));
  });

  test('nadie escribe el registro, el estado de la reserva ni los límites', async () => {
    for (const uid of ['ana', 'admin']) {
      await assertFails(addDoc(collection(db(uid), 'incidents', 'deAna', 'events'), { type: 'closed' }));
      await assertFails(setDoc(doc(db(uid), 'bookings', 'activa', 'adminOnly', 'incident'), { incidentOpen: false }));
      await assertFails(setDoc(doc(db(uid), 'incidentRateLimits', uid), { recent: [] }));
    }
  });

  test.each(['ana', 'asig', 'admin'])('%s no marca incidentOpen ni activeIncidentId en la reserva', async (uid) => {
    await assertFails(updateDoc(doc(db(uid), 'bookings', 'activa'), { incidentOpen: true }));
    await assertFails(updateDoc(doc(db(uid), 'bookings', 'activa'), { activeIncidentId: 'x' }));
  });
});

describe('ubicación en vivo del incidente', () => {
  test('quien lo disparó publica su ubicación con incidente abierto o reconocido', async () => {
    await assertSucceeds(loc('ana', 'deAna'));
    await assertSucceeds(loc('ana', 'reconocido'));
    await assertSucceeds(getDocs(collection(db('ana'), 'incidents', 'deAna', 'locations')));
    await assertSucceeds(getDocs(collection(db('admin'), 'incidents', 'deAna', 'locations')));
  });

  test('la contraparte, un tercero ni el admin publican en el incidente de otro', async () => {
    for (const uid of ['asig', 'beto', 'admin']) await assertFails(loc(uid, 'deAna'));
    await assertFails(getDocs(collection(db('asig'), 'incidents', 'deAna', 'locations')));
  });

  test('cerrado o cancelado: no admite más ubicaciones', async () => {
    await assertFails(loc('ana', 'cerrado'));
    await assertFails(loc('ana', 'cancelado'));
  });

  test('cancelado por quien lo disparó y luego reconocido: sigue sin admitir ubicaciones', async () => {
    await assertFails(loc('ana', 'canceladoReconocido'));
  });

  test('campos acotados: solo lat, lng y la hora del servidor', async () => {
    await assertFails(loc('ana', 'deAna', { nota: 'x' }));
    await assertFails(loc('ana', 'deAna', { lat: 200 }));
    await assertFails(loc('ana', 'deAna', { lng: 'oeste' }));
    await assertFails(loc('ana', 'deAna', { at: new Date(0) }));
  });

  test('frecuencia limitada: un documento por tramo de 10 s, sin reescribir ni tramos lejanos', async () => {
    await assertSucceeds(loc('ana', 'deAna'));
    await assertFails(loc('ana', 'deAna'));
    await assertFails(updateDoc(doc(db('ana'), 'incidents', 'deAna', 'locations', slot()), { lat: -17.7 }));
    await assertFails(loc('ana', 'deAna', {}, String(Number(slot()) + 50)));
    await assertFails(loc('ana', 'deAna', {}, 'cualquiera'));
    await assertFails(deleteDoc(doc(db('ana'), 'incidents', 'deAna', 'locations', slot())));
  });
});
