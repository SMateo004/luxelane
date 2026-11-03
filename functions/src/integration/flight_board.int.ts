/**
 * A6: la caché flightBoard/{aeropuerto_fecha} contra el emulador de
 * Firestore, y las fuentes manual y de prueba. Vuelos FICTICIOS.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { boardId, FakeFlightProvider, ManualFlightProvider, readBoard, writeBoard } from '../flight_provider';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const Q = { airportCode: 'VVI', flightNumber: 'ZZ123', flightDate: '2026-11-20' };
const T = Date.UTC(2026, 10, 20, 14);

beforeEach(async () => { await db.recursiveDelete(db.collection('flightBoard')); });
afterAll(async () => { await admin.app().delete(); });

describe('flightBoard', () => {
  it('guarda y lee una llegada por aeropuerto, fecha y número', async () => {
    expect(await readBoard(db, Q)).toBeNull();
    await writeBoard(db, Q, { kind: 'found', status: 'delayed', scheduled: T, estimated: T + 1_800_000, actual: null,
      observedAt: T - 3_600_000, sourceLabel: 'fake' });
    await writeBoard(db, { ...Q, flightNumber: 'ZZ9' }, { kind: 'found', status: 'landed', scheduled: T, estimated: null,
      actual: T, observedAt: T, sourceLabel: 'fake' });
    expect(await readBoard(db, Q)).toEqual({ kind: 'found', status: 'delayed', scheduled: T, estimated: T + 1_800_000,
      actual: null, observedAt: T - 3_600_000, sourceLabel: 'fake' });
    expect((await readBoard(db, { ...Q, flightNumber: 'ZZ9' }))?.status).toBe('landed');
    expect((await db.doc(`flightBoard/${boardId('VVI', '2026-11-20')}`).get()).data()?.airportCode).toBe('VVI');
    expect(await readBoard(db, { ...Q, flightDate: '2026-11-21' })).toBeNull();
  });
});

describe('fuentes', () => {
  it('manual: no aporta datos nuevos; de prueba: lo fijado o notFound', async () => {
    expect(await new ManualFlightProvider().getArrival()).toEqual({ kind: 'notFound' });
    const fake = new FakeFlightProvider();
    fake.set(Q, { kind: 'unavailable' });
    expect(await fake.getArrival(Q)).toEqual({ kind: 'unavailable' });
    expect(await fake.getArrival({ ...Q, flightNumber: 'ZZ1' })).toEqual({ kind: 'notFound' });
    expect(fake.calls).toHaveLength(2);
  });
});
