/**
 * A1: adminUpdateBooking contra el emulador de Firestore. Cada operación
 * valida el estado actual, escribe evento (sin el uid del admin) y deja la
 * auditoría en la misma transacción.
 */
import { describe, it, expect, beforeEach, afterAll, afterEach, jest } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import * as audit from '../admin_audit';
import { ADMIN_TRANSITIONS, adminUpdateBooking } from '../admin_ops';
import { adminUpdateBooking as adminUpdateBookingFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const jefa = { adminId: 'jefa', adminEmail: 'jefa@example.com' };
const REASON = 'Pedido por el pasajero por teléfono';
const NOW = Date.UTC(2026, 9, 25, 12);
const deps = () => ({ db, now: () => NOW });
const run = (data: unknown) => adminUpdateBooking(deps(), jefa, data);

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

async function clear(): Promise<void> {
  for (const col of ['users', 'driverProfiles', 'admin_logs', 'config', 'rateLimits']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.recursiveDelete(db.collection('bookings'));
}

async function booking(id: string, status: string, extra: Record<string, unknown> = {}) {
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana', status, estimatedPrice: 100, finalPrice: null,
    scheduledAt: admin.firestore.Timestamp.fromMillis(NOW + 30 * 60 * 1000), ...extra,
  });
  // Pagada: sin pago confirmado no se asigna (pagos, A3; ver payment_dispatch.int.ts).
  await db.doc(`bookings/${id}/payment/state`).set({ riderId: 'ana', paymentStatus: 'paid' });
}
async function driver(id: string, over: { verified?: boolean; available?: boolean; active?: boolean } = {}) {
  await db.doc(`users/${id}`).set({ role: 'driver', isActive: over.active ?? true });
  await db.doc(`driverProfiles/${id}`).set({
    userId: id, documentsVerified: over.verified ?? true, isAvailable: over.available ?? true, online: true,
  });
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const events = async (id: string) => (await db.collection(`bookings/${id}/events`).get()).docs.map((d) => ({ id: d.id, ...d.data() }));
const logs = async () => (await db.collection('admin_logs').get()).docs.map((d) => d.data());

beforeEach(async () => {
  await clear();
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
});
afterEach(() => { jest.restoreAllMocks(); });
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('asignar y reasignar', () => {
  it('asigna una pendiente: confirmada, chófer ocupado, evento y auditoría', async () => {
    await booking('b1', 'pending');
    await driver('luis');
    await expect(run({ action: 'assign', bookingId: 'b1', driverId: 'luis', reason: REASON }))
      .resolves.toEqual({ status: 'confirmed', driverId: 'luis' });
    expect(await doc('bookings/b1')).toMatchObject({ status: 'confirmed', driverId: 'luis' });
    expect((await doc('driverProfiles/luis'))?.isAvailable).toBe(false);
    const [e] = await events('b1');
    expect(e).toMatchObject({ from: 'pending', to: 'confirmed', method: 'admin_assign', actor: { role: 'admin' } });
    expect(JSON.stringify(e)).not.toContain('jefa');
    expect(await doc(`bookings/b1/eventDetails/${e.id}`)).toMatchObject({ reason: REASON, actorUid: 'jefa' });
    const [l] = await logs();
    expect(l).toMatchObject({
      operation: 'assign_driver', action: 'assign_driver', actor: { uid: 'jefa', role: 'admin' },
      collection: 'bookings', docPath: 'bookings/b1', reason: REASON, source: 'server',
      changes: { driverId: { before: null, after: 'luis' }, status: { before: 'pending', after: 'confirmed' } },
    });
    expect(l.createdAt).toBeInstanceOf(admin.firestore.Timestamp);
  });

  it('reasigna: libera al anterior', async () => {
    await booking('b1', 'confirmed', { driverId: 'luis' });
    await driver('luis', { available: false });
    await driver('pedro');
    await run({ action: 'assign', bookingId: 'b1', driverId: 'pedro', reason: REASON });
    expect((await doc('driverProfiles/luis'))?.isAvailable).toBe(true);
    expect((await doc('driverProfiles/pedro'))?.isAvailable).toBe(false);
    expect((await logs())[0]).toMatchObject({ operation: 'reassign_driver' });
  });

  it.each([
    ['sin verificar', { verified: false }, 'driver_not_verified'],
    ['bloqueado', { active: false }, 'driver_inactive'],
    ['ocupado', { available: false }, 'driver_busy'],
  ])('rechaza un chófer %s y no escribe nada', async (_w, over, why) => {
    await booking('b1', 'pending');
    await driver('luis', over);
    expect(await reason(run({ action: 'assign', bookingId: 'b1', driverId: 'luis', reason: REASON }))).toBe(why);
    expect((await doc('bookings/b1'))?.status).toBe('pending');
    expect(await logs()).toHaveLength(0);
  });

  it('no asigna en un viaje que ya llegó o empezó', async () => {
    await booking('b1', 'in_progress', { driverId: 'luis' });
    await driver('pedro');
    expect(await reason(run({ action: 'assign', bookingId: 'b1', driverId: 'pedro', reason: REASON }))).toBe('not_assignable');
  });
});

describe('cancelar', () => {
  it('deja evento (antes no lo había) y el motivo solo para central', async () => {
    await booking('b1', 'confirmed', { driverId: 'luis' });
    await run({ action: 'cancel', bookingId: 'b1', reason: REASON, cause: 'platform' });
    const b = (await doc('bookings/b1'))!;
    expect(b).toMatchObject({ status: 'cancelled', cancelledBy: 'admin' });
    expect(b.cancelledAt).toBeInstanceOf(admin.firestore.Timestamp);
    expect(JSON.stringify(b)).not.toContain(REASON);
    const [e] = await events('b1');
    expect(e).toMatchObject({ from: 'confirmed', to: 'cancelled', method: 'admin_cancel', actor: { role: 'admin' } });
    expect(await doc(`bookings/b1/eventDetails/${e.id}`)).toMatchObject({ reason: REASON });
    expect((await logs())[0]).toMatchObject({ operation: 'cancel_booking', changes: { status: { before: 'confirmed', after: 'cancelled' } } });
  });

  it('desde verificada sí; desde en curso o completada, no', async () => {
    await booking('v', 'verified');
    await booking('p', 'in_progress');
    await booking('c', 'completed');
    expect(await reason(run({ action: 'cancel', bookingId: 'v', reason: REASON, cause: 'platform' }))).toBe('ok');
    expect(await reason(run({ action: 'cancel', bookingId: 'p', reason: REASON, cause: 'platform' }))).toBe('not_cancellable');
    expect(await reason(run({ action: 'cancel', bookingId: 'c', reason: REASON, cause: 'platform' }))).toBe('not_cancellable');
  });

  it('sin motivo suficiente: invalid_request', async () => {
    await booking('b1', 'confirmed');
    expect(await reason(run({ action: 'cancel', bookingId: 'b1', reason: 'porque sí', cause: 'platform' }))).toBe('invalid_request');
  });
});

describe('mover el estado', () => {
  it('solo los pasos del panel; completar fija el importe estimado', async () => {
    await booking('a', 'confirmed');
    await booking('b', 'in_progress');
    expect(await reason(run({ action: 'status', bookingId: 'a', to: 'completed', reason: REASON }))).toBe('invalid_transition');
    await run({ action: 'status', bookingId: 'a', to: 'driver_arriving', reason: REASON });
    await run({ action: 'status', bookingId: 'b', to: 'completed', reason: REASON });
    expect((await doc('bookings/a'))?.status).toBe('driver_arriving');
    expect(await doc('bookings/b')).toMatchObject({ status: 'completed', finalPrice: 100 });
  });
});

describe('acción status: transiciones exactas (D2)', () => {
  const ALL = ['pending', 'confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress', 'completed', 'cancelled'];

  it('la tabla del servidor: solo tres pasos por esta acción', () => {
    const viaStatus = Object.entries(ADMIN_TRANSITIONS)
      .flatMap(([from, tos]) => (tos ?? []).filter((t) => t !== 'cancelled').map((t) => `${from}→${t}`)).sort();
    expect(viaStatus).toEqual(['confirmed→driver_arriving', 'driver_arriving→driver_arrived', 'in_progress→completed']);
  });

  it('completed solo desde in_progress', async () => {
    for (const from of ALL) {
      await booking(`c_${from}`, from);
      const r = await reason(run({ action: 'status', bookingId: `c_${from}`, to: 'completed', reason: REASON }));
      expect([from, r]).toEqual([from, from === 'in_progress' ? 'ok' : 'invalid_transition']);
    }
  });

  it('verified e in_progress no se alcanzan por esta acción (solo adminOverrideVerify y advanceBooking)', async () => {
    for (const from of ALL) {
      await booking(`v_${from}`, from);
      for (const to of ['verified', 'in_progress', 'cancelled', 'pending', 'confirmed']) {
        expect(await reason(run({ action: 'status', bookingId: `v_${from}`, to, reason: REASON }))).toBe('invalid_request');
      }
      expect((await doc(`bookings/v_${from}`))?.status).toBe(from);
    }
  });

  it('una transición inválida no deja evento ni auditoría', async () => {
    await booking('b1', 'driver_arrived');
    expect(await reason(run({ action: 'status', bookingId: 'b1', to: 'completed', reason: REASON }))).toBe('invalid_transition');
    expect(await reason(run({ action: 'status', bookingId: 'b1', to: 'driver_arriving', reason: REASON }))).toBe('invalid_transition');
    expect((await doc('bookings/b1'))?.status).toBe('driver_arrived');
    expect(await events('b1')).toHaveLength(0);
    expect(await logs()).toHaveLength(0);
  });
});

describe('ajustar el importe final', () => {
  it('sin config/ops.maxPriceAdjustmentPercent: rechazado, sin escribir', async () => {
    await booking('b1', 'confirmed');
    expect(await reason(run({ action: 'adjust_price', bookingId: 'b1', finalPrice: 101, reason: REASON })))
      .toBe('price_adjustment_disabled');
    expect((await doc('bookings/b1'))?.finalPrice).toBeNull();
    expect(await logs()).toHaveLength(0);
  });

  it('con el límite: dentro pasa y conserva el importe original en la auditoría; fuera, no', async () => {
    await db.doc('config/ops').set({ maxPriceAdjustmentPercent: 10 });
    await booking('b1', 'confirmed');
    expect(await reason(run({ action: 'adjust_price', bookingId: 'b1', finalPrice: 111, reason: REASON })))
      .toBe('price_adjustment_too_large');
    await run({ action: 'adjust_price', bookingId: 'b1', finalPrice: 90, reason: REASON });
    expect((await doc('bookings/b1'))?.finalPrice).toBe(90);
    const [l] = await logs();
    expect(l).toMatchObject({
      operation: 'adjust_price', changes: { finalPrice: { before: null, after: 90 } },
      context: { originalPrice: 100, previousFinalPrice: null, maxPercent: 10 },
    });
  });

  it('solo antes de completar', async () => {
    await db.doc('config/ops').set({ maxPriceAdjustmentPercent: 10 });
    await booking('b1', 'completed');
    expect(await reason(run({ action: 'adjust_price', bookingId: 'b1', finalPrice: 100, reason: REASON }))).toBe('price_locked');
  });
});

describe('atomicidad y acceso', () => {
  it('si la auditoría falla, el cambio no ocurre', async () => {
    await booking('b1', 'confirmed');
    jest.spyOn(audit, 'writeAudit').mockImplementation(() => { throw new Error('auditoría caída'); });
    await expect(run({ action: 'cancel', bookingId: 'b1', reason: REASON, cause: 'platform' })).rejects.toThrow('auditoría caída');
    expect((await doc('bookings/b1'))?.status).toBe('confirmed');
    expect(await events('b1')).toHaveLength(0);
  });

  it('por la callable: solo admin', async () => {
    await booking('b1', 'confirmed');
    const call = (uid: string) => (adminUpdateBookingFn as unknown as Runnable).run({
      auth: { uid, token: { auth_time: Math.floor(Date.now() / 1000) } }, app: {},
      data: { action: 'cancel', bookingId: 'b1', reason: REASON, cause: 'platform' },
    });
    expect(await reason(call('ana'))).toBe('admin_required');
    expect(await reason(call('jefa'))).toBe('ok');
  });
});
