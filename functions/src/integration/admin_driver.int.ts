/** A5: verificar chófer, cambiar datos sensibles y activar vehículos (emulador). */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { adminSetVehicleActive, adminUpdateDriverSensitive, adminVerifyDriver } from '../admin_ops';

if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const db = admin.firestore();
const jefa = { adminId: 'jefa', adminEmail: null };
const REASON = 'Documentos revisados en persona';
const deps = { db };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['driverProfiles', 'vehicles', 'admin_logs']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const ops = async () => (await db.collection('admin_logs').get()).docs.map((d) => d.data().operation).sort();

beforeEach(async () => {
  await clear();
  await db.doc('driverProfiles/luis').set({ userId: 'luis', documentsVerified: false, licenseNumber: 'L-1' });
  await db.doc('vehicles/v1').set({ driverId: 'luis', isActive: false, plate: 'ABC', class: 'business', capacity: 3, year: 2020 });
  await db.doc('vehicles/otro').set({ driverId: 'pedro', isActive: false, plate: 'XYZ' });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('adminVerifyDriver', () => {
  it('sin revisar el vehículo: verifica y deja el vehículo inactivo', async () => {
    await adminVerifyDriver(deps, jefa, { driverId: 'luis', vehicleReviewed: false, reason: REASON });
    expect((await doc('driverProfiles/luis'))?.documentsVerified).toBe(true);
    expect((await doc('vehicles/v1'))?.isActive).toBe(false);
    expect(await ops()).toEqual(['verify_driver']);
  });

  it('con el vehículo revisado: lo activa (solo los suyos) y lo audita', async () => {
    await adminVerifyDriver(deps, jefa, { driverId: 'luis', vehicleReviewed: true, vehicleNote: 'Sin golpes', reason: REASON });
    expect((await doc('vehicles/v1'))?.isActive).toBe(true);
    expect((await doc('vehicles/otro'))?.isActive).toBe(false);
    expect(await ops()).toEqual(['enable_vehicle', 'verify_driver']);
  });

  it('ya verificado y sin vehículo que revisar: no_change', async () => {
    await db.doc('driverProfiles/luis').update({ documentsVerified: true });
    expect(await reason(adminVerifyDriver(deps, jefa, { driverId: 'luis', vehicleReviewed: false, reason: REASON }))).toBe('no_change');
  });
});

describe('adminUpdateDriverSensitive', () => {
  it('licencia y vehículo: solo los campos cambiados, con antes y después', async () => {
    await adminUpdateDriverSensitive(deps, jefa, {
      driverId: 'luis', profile: { licenseNumber: 'L-2', licenseExpiry: Date.UTC(2030, 0, 1) },
      vehicle: { vehicleId: 'v1', plate: 'ABC', vehicleClass: 'businessVan' }, reason: 'Cambio pedido por el chófer',
    });
    expect((await doc('driverProfiles/luis'))?.licenseNumber).toBe('L-2');
    expect(await doc('vehicles/v1')).toMatchObject({ class: 'businessVan', capacity: 7, plate: 'ABC' });
    const logs = (await db.collection('admin_logs').get()).docs.map((d) => d.data());
    const v = logs.find((l) => l.operation === 'update_vehicle_documents')!;
    expect(v.changes).toEqual({ class: { before: 'business', after: 'businessVan' }, capacity: { before: 3, after: 7 } });
    expect(logs.find((l) => l.operation === 'update_driver_documents')!.changes.licenseNumber)
      .toEqual({ before: 'L-1', after: 'L-2' });
  });

  it('el vehículo de otro chófer: vehicle_not_found', async () => {
    expect(await reason(adminUpdateDriverSensitive(deps, jefa, {
      driverId: 'luis', vehicle: { vehicleId: 'otro', plate: 'NEW' }, reason: 'Cambio pedido por el chófer',
    }))).toBe('vehicle_not_found');
    expect((await doc('vehicles/otro'))?.plate).toBe('XYZ');
  });

  it('campos que no son de documentos (valoración, verificación): invalid_request', async () => {
    expect(await reason(adminUpdateDriverSensitive(deps, jefa, {
      driverId: 'luis', profile: { documentsVerified: true }, reason: 'Cambio pedido por el chófer',
    }))).toBe('invalid_request');
  });
});

describe('adminSetVehicleActive', () => {
  it('activa y desactiva con auditoría; repetir no escribe', async () => {
    await adminSetVehicleActive(deps, jefa, { vehicleId: 'v1', active: true, reason: 'Revisado en el taller' });
    expect((await doc('vehicles/v1'))?.isActive).toBe(true);
    expect(await reason(adminSetVehicleActive(deps, jefa, { vehicleId: 'v1', active: true, reason: 'Revisado en el taller' })))
      .toBe('no_change');
    await adminSetVehicleActive(deps, jefa, { vehicleId: 'v1', active: false, reason: 'Vehículo en el taller' });
    expect(await ops()).toEqual(['disable_vehicle', 'enable_vehicle']);
  });
});
