import { describe, it, expect } from '@jest/globals';
import { HttpsError } from 'firebase-functions/v2/https';
import { readPaymentSettings } from './payment_config';
import { manualProvider, PaymentProvider, providerFor, stripeProvider } from './payment_provider';

// Datos de cobro de prueba, ficticios.
const MANUAL = { holderName: 'Titular de prueba', accountNumber: '000-ficticia' };

const reason = (f: () => unknown): string | undefined => {
  try { f(); } catch (e) { return ((e as HttpsError).details as { reason?: string })?.reason; }
  return 'ok';
};

describe('config/ops de pagos (A2)', () => {
  it('sin claves no se ofrece ningún método ni hay plazo', () => {
    expect(readPaymentSettings({})).toEqual({ enabled: [], manual: null, cardProvider: null, windowMinutes: null, invalid: [] });
  });

  it('manual activado pero sin datos de cobro: no se ofrece', () => {
    expect(readPaymentSettings({ paymentMethods: { manual_qr: true } }).enabled).toEqual([]);
  });

  it('manual activado y con datos: se ofrece', () => {
    const s = readPaymentSettings({ paymentMethods: { manual_qr: true }, paymentInstructions: { manual_qr: MANUAL } });
    expect(s.enabled).toEqual(['manual_qr']);
    expect(s.manual).toEqual(MANUAL);
  });

  it('datos sin cuenta ni QR, o QR sin https: no son válidos y no se ofrece', () => {
    for (const manual_qr of [{ holderName: 'X' }, { holderName: 'X', qrImageUrl: 'http://qr.example/x.png' }]) {
      const s = readPaymentSettings({ paymentMethods: { manual_qr: true }, paymentInstructions: { manual_qr } });
      expect(s.enabled).toEqual([]);
      expect(s.invalid).toEqual(['paymentInstructions']);
    }
  });

  it('tarjeta: hace falta activarla y elegir proveedor', () => {
    expect(readPaymentSettings({ paymentMethods: { card: true } }).enabled).toEqual([]);
    expect(readPaymentSettings({ paymentInstructions: { card: { provider: 'stripe' } } }).enabled).toEqual([]);
    expect(readPaymentSettings({
      paymentMethods: { card: true }, paymentInstructions: { card: { provider: 'stripe' } },
    }).enabled).toEqual(['card']);
  });

  it('un proveedor que no existe en el código no se acepta', () => {
    const s = readPaymentSettings({ paymentMethods: { card: true }, paymentInstructions: { card: { provider: 'otro' } } });
    expect(s.enabled).toEqual([]);
    expect(s.invalid).toEqual(['paymentInstructions']);
  });

  it('campos desconocidos se rechazan (estricto)', () => {
    expect(readPaymentSettings({ paymentMethods: { manual_qr: true, wallet: true } }).invalid).toEqual(['paymentMethods']);
  });

  it('plazo: minutos enteros dentro de un rango', () => {
    expect(readPaymentSettings({ paymentWindowMinutes: 30 }).windowMinutes).toBe(30);
    for (const v of [0, -5, 1.5, '30', 20000]) {
      expect(readPaymentSettings({ paymentWindowMinutes: v }).windowMinutes).toBeNull();
    }
  });
});

describe('proveedor de pago (A2)', () => {
  const settings = readPaymentSettings({ paymentMethods: { manual_qr: true }, paymentInstructions: { manual_qr: MANUAL } });

  it('un método desactivado se rechaza', () => {
    expect(reason(() => providerFor('card', settings))).toBe('method_disabled');
    expect(reason(() => providerFor('manual_qr', readPaymentSettings({})))).toBe('method_disabled');
  });

  it('manual: devuelve las instrucciones de config/ops', async () => {
    const p = providerFor('manual_qr', settings);
    await expect(p.createCharge({ bookingId: 'b', riderId: 'r', amount: 100, currency: 'bob', paymentRef: 'X', idempotencyKey: 'k' }))
      .resolves.toEqual({ kind: 'manual', instructions: MANUAL });
  });

  it('confirmar exige el importe exacto', () => {
    const p = manualProvider(MANUAL);
    expect(reason(() => p.confirm({ amountReceived: 9999, amountDue: 10000, externalRef: 'op' }))).toBe('amount_mismatch');
    expect(p.confirm({ amountReceived: 10000, amountDue: 10000, externalRef: 'op' })).toEqual({ amount: 10000, externalRef: 'op' });
  });

  it('el reembolso manual queda pendiente de central', async () => {
    await expect(manualProvider(MANUAL).refund({ bookingId: 'b', amount: 1, currency: 'bob', chargeRef: null, idempotencyKey: 'k' }))
      .resolves.toEqual({ status: 'pending_manual' });
  });

  it('Stripe no acepta webhooks sin secreto configurado', () => {
    expect(reason(() => stripeProvider().verifyWebhook!(Buffer.from('{}'), 'x'))).toBe('webhook_not_configured');
  });

  it('los tests pueden sustituir el proveedor solo si el método está activado', () => {
    const fake = { method: 'card' } as PaymentProvider;
    const card = readPaymentSettings({ paymentMethods: { card: true }, paymentInstructions: { card: { provider: 'stripe' } } });
    expect(providerFor('card', card, { card: fake })).toBe(fake);
    expect(reason(() => providerFor('card', settings, { card: fake }))).toBe('method_disabled');
  });
});
