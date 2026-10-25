import { describe, it, expect } from '@jest/globals';
import * as admin from 'firebase-admin';
import { cancellationFee, CancellationPolicy, readPolicy } from './cancellation';

const NOW = Date.UTC(2026, 9, 25, 12);
const ts = (offsetMin: number) => admin.firestore.Timestamp.fromMillis(NOW + offsetMin * 60_000);
// Valores de prueba, no de negocio.
const policy: CancellationPolicy = {
  freeWithinMinutesOfBooking: 5, freeBeforePickupMinutes: 60, chargeWhenNoDriver: false,
  feeType: 'percent', feeValue: 10, noShowWaitMinutes: 15,
};
const booking = (over: Record<string, unknown> = {}) => ({
  status: 'confirmed', estimatedPrice: 200, createdAt: ts(-120), scheduledAt: ts(30), ...over,
});
const fee = (p: CancellationPolicy | null, b: Record<string, unknown>, reason = 'other', state: 'ok' | 'missing' | 'invalid' = 'ok') =>
  cancellationFee(p, p ? 'ok' : state, b, NOW, reason);

describe('readPolicy', () => {
  it('sin política o con una inválida: null y su estado', () => {
    expect(readPolicy({})).toEqual({ policy: null, state: 'missing' });
    expect(readPolicy({ cancellationPolicy: { feeType: 'fixed' } })).toEqual({ policy: null, state: 'invalid' });
    expect(readPolicy({ cancellationPolicy: { ...policy, feeValue: 150 } }).state).toBe('invalid');
    expect(readPolicy({ cancellationPolicy: policy }).state).toBe('ok');
  });
});

describe('cancellationFee', () => {
  it('sin política: nunca hay recargo y queda anotado por qué', () => {
    expect(fee(null, booking())).toEqual({ fee: 0, basis: 'no_policy' });
    expect(fee(null, booking(), 'other', 'invalid')).toEqual({ fee: 0, basis: 'policy_invalid' });
  });

  it('sin chófer, dentro del plazo de gracia o con antelación: gratis', () => {
    expect(fee(policy, booking({ status: 'pending' }))).toEqual({ fee: 0, basis: 'no_driver' });
    expect(fee(policy, booking({ createdAt: ts(-3) }))).toEqual({ fee: 0, basis: 'grace' });
    expect(fee(policy, booking({ scheduledAt: ts(90) }))).toEqual({ fee: 0, basis: 'early' });
  });

  it('tarde: porcentaje del estimado o importe fijo, nunca más que el precio', () => {
    expect(fee(policy, booking())).toEqual({ fee: 20, basis: 'late' });
    expect(fee({ ...policy, feeType: 'fixed', feeValue: 35 }, booking())).toEqual({ fee: 35, basis: 'late' });
    expect(fee({ ...policy, feeType: 'fixed', feeValue: 500 }, booking())).toEqual({ fee: 200, basis: 'late' });
  });

  it('la tarjeta no se autorizó: la cancelación automática no tiene recargo', () => {
    expect(fee({ ...policy, chargeWhenNoDriver: true }, booking({ status: 'pending' }), 'payment_failed'))
      .toEqual({ fee: 0, basis: 'payment_failed' });
  });
});
