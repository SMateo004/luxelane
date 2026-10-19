/**
 * Handlers reales de onBookingCreated y closeOpenRequest ejecutados contra
 * el emulador de Firestore. El emulador de Functions no puede registrar
 * triggers en este entorno (ver DEPLOY.md), así que se invoca cada handler
 * con el mismo evento que le daría la plataforma.
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { closeOpenRequest, onBookingCreated } from '../index';

const db = admin.firestore();

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (event: any) => Promise<unknown> };

async function create(id: string, data: Record<string, unknown>): Promise<void> {
  const ref = db.collection('bookings').doc(id);
  await ref.set(data);
  await (onBookingCreated as unknown as Runnable).run({ data: await ref.get(), params: { bookingId: id } });
}

async function update(id: string, change: Record<string, unknown>): Promise<void> {
  const ref = db.collection('bookings').doc(id);
  const before = await ref.get();
  await ref.update(change);
  const after = await ref.get();
  await (closeOpenRequest as unknown as Runnable).run({ data: { before, after }, params: { bookingId: id } });
}

const openRequest = async (id: string) => (await db.collection('openRequests').doc(id).get());

const fullBooking = () => ({
  riderId: 'ana',
  status: 'pending',
  class: 'business',
  vehicleClass: 'business',
  serviceType: 'oneWay',
  estimatedPrice: 500,
  scheduledAt: admin.firestore.Timestamp.fromMillis(Date.now() + 2 * 60 * 60 * 1000),
  passengerCount: 2,
  luggageCount: 1,
  pickupArea: 'Santa Cruz de la Sierra',
  dropoffArea: 'Santa Cruz de la Sierra',
  origin: { name: '', address: 'Calle Exacta 123', coordinates: new admin.firestore.GeoPoint(-17.78339, -63.18211) },
  destination: { name: '', address: 'Avenida Exacta 456', coordinates: new admin.firestore.GeoPoint(-17.75, -63.2) },
  notes: 'Toque el timbre',
  flightNumber: 'AA922',
  riderPreferences: { music: 'jazz' },
  guest: { firstName: 'Carla', phone: '+59170000001', email: 'carla@example.com' },
});

async function clear(): Promise<void> {
  for (const col of ['bookings', 'openRequests']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
}

beforeEach(clear);
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('onBookingCreated → openRequests', () => {
  it('una reserva pendiente crea su solicitud abierta sin datos personales', async () => {
    await create('r1', fullBooking());
    const snap = await openRequest('r1');
    expect(snap.exists).toBe(true);
    expect(snap.data()).toMatchObject({
      vehicleClass: 'business',
      estimatedPrice: 500,
      pickupArea: 'Santa Cruz de la Sierra',
      pickupApprox: { lat: -17.78, lng: -63.18 },
    });
    const text = JSON.stringify(snap.data());
    for (const secret of ['ana', 'Exacta', 'timbre', 'AA922', 'jazz', 'Carla', '+5917', 'example.com']) {
      expect(text).not.toContain(secret);
    }
  });

  it('una reserva que no nace pendiente no crea solicitud', async () => {
    await create('r2', { ...fullBooking(), status: 'confirmed' });
    expect((await openRequest('r2')).exists).toBe(false);
  });
});

describe('closeOpenRequest', () => {
  for (const status of ['confirmed', 'cancelled']) {
    it(`al pasar a ${status} la solicitud se borra`, async () => {
      await create('r3', fullBooking());
      expect((await openRequest('r3')).exists).toBe(true);
      await update('r3', { status });
      expect((await openRequest('r3')).exists).toBe(false);
    });
  }

  it('otros cambios en una reserva pendiente no la borran', async () => {
    await create('r5', fullBooking());
    await update('r5', { updatedAt: admin.firestore.Timestamp.now() });
    expect((await openRequest('r5')).exists).toBe(true);
  });
});

describe('reserva con datos incompletos', () => {
  it('sin origen, destino, hora ni clase: se publica igual, con valores vacíos y sin revisión', async () => {
    await create('r4', { riderId: 'ana', status: 'pending', estimatedPrice: 50 });
    const snap = await openRequest('r4');
    const booking = (await db.collection('bookings').doc('r4').get()).data();
    expect(snap.exists).toBe(true);
    expect(snap.data()).toMatchObject({
      vehicleClass: 'business',
      serviceType: 'oneWay',
      scheduledAt: null,
      pickupArea: null,
      pickupApprox: null,
      dropoffApprox: null,
      tripKm: null,
    });
    // Hallazgo: 50 iguala el mínimo de business_oneWay y el control solo
    // compara con ese mínimo, así que nada marca la reserva incompleta.
    expect(booking?.pricingReview).toBeUndefined();
  });

  it('un precio por debajo del mínimo se marca para revisión y aun así se publica', async () => {
    await create('r6', { ...fullBooking(), estimatedPrice: 10 });
    const booking = (await db.collection('bookings').doc('r6').get()).data();
    expect(booking?.pricingReview).toEqual({ reason: 'below_fare', expectedMinimum: 50 });
    expect((await openRequest('r6')).exists).toBe(true);
  });
});
