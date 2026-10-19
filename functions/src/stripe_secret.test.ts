import { describe, it, expect, beforeEach } from '@jest/globals';
import { createIntent, requireStripeKey } from './stripe_service';

describe('clave secreta de Stripe', () => {
  beforeEach(() => {
    delete process.env.STRIPE_SECRET_KEY;
  });

  it('rechaza una clave ausente o vacía', () => {
    for (const value of [undefined, '', '   ']) {
      expect(() => requireStripeKey(value)).toThrow(/STRIPE_SECRET_KEY no está configurada/);
    }
  });

  it('devuelve la clave cuando existe', () => {
    expect(requireStripeKey(' sk_test_abc ')).toBe('sk_test_abc');
  });

  it('sin el secreto, una llamada a Stripe falla con un error claro', async () => {
    await expect(
      createIntent({ amount: 100, currency: 'bob', customerId: 'cus_x', bookingId: 'b1' }),
    ).rejects.toThrow(/STRIPE_SECRET_KEY no está configurada/);
  });
});
