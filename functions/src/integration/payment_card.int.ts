/**
 * Pagos A5: empezar a pagar y tarjeta con un proveedor SIMULADO (el real no
 * está decidido). La firma del webhook es un HMAC con un secreto de prueba.
 */
import { describe, it, expect, beforeEach, afterAll, jest } from '@jest/globals';
import { createHmac } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { handlePaymentWebhook, startPayment } from '../payment_card';
import type { ChargeRequest, PaymentProvider } from '../payment_provider';
import '../index'; // initializeApp

const db = admin.firestore();
const NOW = Date.UTC(2026, 9, 26, 12);
const SECRET = 'secreto-de-prueba-ficticio';
const sign = (raw: Buffer) => createHmac('sha256', SECRET).update(raw).digest('hex');

const createCharge = jest.fn(async (req: ChargeRequest) => ({
  kind: 'client_secret' as const, clientSecret: `cs_${req.idempotencyKey}`, externalRef: `ch_${req.idempotencyKey}`,
}));
const simulated: PaymentProvider = {
  method: 'card',
  createCharge,
  confirm: (i) => ({ amount: i.amountReceived, externalRef: i.externalRef }),
  refund: async () => ({ status: 'succeeded', externalRef: 're_1' }),
  verifyWebhook(raw, signature) {
    if (signature !== sign(raw)) throw new Error('bad_signature');
    return JSON.parse(raw.toString());
  },
};
const deps = { db, now: () => NOW, providers: { card: simulated } };
const OPS = {
  paymentMethods: { manual_qr: true, card: true },
  paymentInstructions: { manual_qr: { holderName: 'Titular ficticio', qrImageUrl: 'https://qr.example/ficticio.png' }, card: { provider: 'stripe' } },
};

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}
async function clear(): Promise<void> {
  for (const col of ['users', 'config', 'openRequests', 'adminAlerts', 'payments', 'rateLimits']) await db.recursiveDelete(db.collection(col));
  await db.recursiveDelete(db.collection('bookings'));
}
const doc = async (p: string) => (await db.doc(p).get()).data();
const all = async (col: string) => (await db.collection(col).get()).docs.map((d) => ({ id: d.id, ...d.data() }));
const hook = (event: Record<string, unknown>, signature?: string) => {
  const raw = Buffer.from(JSON.stringify(event));
  return handlePaymentWebhook(deps, raw, signature ?? sign(raw));
};
const succeeded = (over: Record<string, unknown> = {}) =>
  ({ type: 'charge.succeeded', bookingId: 'b1', amount: 10000, externalRef: 'ch_charge:b1:0', ...over });

beforeEach(async () => {
  await clear();
  createCharge.mockClear();
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('config/ops').set(OPS);
  await db.doc('bookings/b1').set({ riderId: 'ana', status: 'pending', driverId: null, class: 'business', estimatedPrice: 100 });
  await db.doc('bookings/b1/payment/state').set({
    bookingId: 'b1', riderId: 'ana', paymentStatus: 'awaiting_payment', paymentMethod: null, amountDue: 10000,
    amountPaid: 0, paymentRef: 'ABCD2345', paidAt: null, paymentDeadline: null,
  });
});
afterAll(async () => { await clear(); await admin.app().delete(); });

describe('startPayment', () => {
  it('manual: instrucciones de config/ops, importe exacto y referencia', async () => {
    await expect(startPayment(deps, 'ana', { bookingId: 'b1', method: 'manual_qr' })).resolves.toEqual({
      method: 'manual_qr', amountDue: 10000, currency: 'bob', paymentRef: 'ABCD2345', paymentDeadline: null,
      instructions: OPS.paymentInstructions.manual_qr,
    });
    expect(createCharge).not.toHaveBeenCalled();
  });

  it('tarjeta: el importe es el del servidor y el cliente no puede mandar otro', async () => {
    expect(await reason(startPayment(deps, 'ana', { bookingId: 'b1', method: 'card', amount: 1 }))).toBe('invalid_request');
    await expect(startPayment(deps, 'ana', { bookingId: 'b1', method: 'card' }))
      .resolves.toMatchObject({ method: 'card', amountDue: 10000, clientSecret: 'cs_charge:b1:0' });
    expect(createCharge.mock.calls[0][0]).toMatchObject({ amount: 10000, currency: 'bob', idempotencyKey: 'charge:b1:0' });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentMethod: 'card', providerChargeRef: 'ch_charge:b1:0' });
  });

  it('reintento del mismo intento: misma clave de idempotencia (sin doble cargo)', async () => {
    await startPayment(deps, 'ana', { bookingId: 'b1', method: 'card' });
    await startPayment(deps, 'ana', { bookingId: 'b1', method: 'card' });
    expect(createCharge.mock.calls.map((c) => c[0].idempotencyKey)).toEqual(['charge:b1:0', 'charge:b1:0']);
  });

  it('tarjeta desactivada: method_disabled', async () => {
    await db.doc('config/ops').set({ ...OPS, paymentMethods: { manual_qr: true } });
    expect(await reason(startPayment(deps, 'ana', { bookingId: 'b1', method: 'card' }))).toBe('method_disabled');
  });

  it('usuario ajeno: not_owner; ya pagada: already_paid', async () => {
    await db.doc('users/beto').set({ role: 'rider', isActive: true });
    expect(await reason(startPayment(deps, 'beto', { bookingId: 'b1', method: 'manual_qr' }))).toBe('not_owner');
    await db.doc('bookings/b1/payment/state').update({ paymentStatus: 'paid', amountPaid: 10000 });
    expect(await reason(startPayment(deps, 'ana', { bookingId: 'b1', method: 'manual_qr' }))).toBe('already_paid');
  });
});

describe('webhook del proveedor (simulado)', () => {
  beforeEach(async () => { await startPayment(deps, 'ana', { bookingId: 'b1', method: 'card' }); });

  it('firma inválida: 400 y no cambia nada', async () => {
    await expect(hook(succeeded(), 'firma-falsa')).resolves.toMatchObject({ status: 400 });
    expect((await doc('bookings/b1/payment/state'))!.paymentStatus).toBe('awaiting_payment');
  });

  it('cobro correcto: paid, asiento del cargo con la referencia del proveedor, solicitud abierta', async () => {
    await expect(hook(succeeded())).resolves.toEqual({ status: 200, body: { applied: true, paymentStatus: 'paid' } });
    expect(await doc('bookings/b1/payment/state')).toMatchObject({ paymentStatus: 'paid', amountPaid: 10000, paymentMethod: 'card' });
    expect(await all('payments')).toEqual([expect.objectContaining({
      id: 'charge_b1', type: 'charge', amount: 10000, method: 'card', externalRef: 'ch_charge:b1:0', actor: { role: 'provider' },
    })]);
    expect((await db.doc('openRequests/b1').get()).exists).toBe(true);
  });

  it('el mismo evento dos veces: un solo cargo', async () => {
    await hook(succeeded());
    await expect(hook(succeeded())).resolves.toMatchObject({ body: { applied: false, reason: 'already_paid' } });
    expect(await all('payments')).toHaveLength(1);
  });

  it('importe distinto: no confirma y avisa a central', async () => {
    await expect(hook(succeeded({ amount: 9000 }))).resolves.toMatchObject({ body: { reason: 'amount_mismatch' } });
    expect((await doc('bookings/b1/payment/state'))!.paymentStatus).toBe('awaiting_payment');
    expect(await all('adminAlerts')).toEqual([expect.objectContaining({ type: 'payment_amount_mismatch', severity: 'high' })]);
  });

  it('un cobro que esta reserva no pidió se ignora', async () => {
    await expect(hook(succeeded({ externalRef: 'ch_otro' }))).resolves.toMatchObject({ body: { reason: 'unknown_charge' } });
    expect((await doc('bookings/b1/payment/state'))!.paymentStatus).toBe('awaiting_payment');
  });

  it('cobro fallido: failed; el reintento usa una clave nueva', async () => {
    await hook({ type: 'charge.failed', bookingId: 'b1', amount: 10000, externalRef: 'ch_charge:b1:0' });
    expect((await doc('bookings/b1/payment/state'))!.paymentStatus).toBe('failed');
    await startPayment(deps, 'ana', { bookingId: 'b1', method: 'card' });
    expect(createCharge.mock.calls.at(-1)![0].idempotencyKey).toBe('charge:b1:1');
  });

  it('sin tarjeta activada el webhook responde 404', async () => {
    await db.doc('config/ops').set({ paymentMethods: { manual_qr: true }, paymentInstructions: OPS.paymentInstructions });
    await expect(hook(succeeded())).resolves.toMatchObject({ status: 404 });
  });
});
