import { describe, it, expect } from '@jest/globals';
import { cents, isPaymentRef, newPaymentRef, PAYMENT_STATUSES, REF_ALPHABET, REF_LENGTH } from './payment_model';

describe('modelo de pagos (A1)', () => {
  it('los estados son los acordados, en este orden', () => {
    expect(PAYMENT_STATUSES).toEqual([
      'awaiting_payment', 'paid', 'refund_pending', 'refunded', 'partially_refunded', 'failed', 'expired',
    ]);
  });

  it('la referencia no tiene caracteres que se confundan', () => {
    for (const c of '0O1IL UV') expect(REF_ALPHABET).not.toContain(c);
  });

  it('la referencia tiene la longitud fija y solo letras del alfabeto', () => {
    for (let i = 0; i < 200; i++) {
      const r = newPaymentRef();
      expect(r).toHaveLength(REF_LENGTH);
      expect(isPaymentRef(r)).toBe(true);
    }
    expect(isPaymentRef('ABCD0123')).toBe(false);
    expect(isPaymentRef('abcd2345')).toBe(false);
  });

  it('céntimos enteros desde bolivianos', () => {
    expect(cents(52)).toBe(5200);
    expect(cents(48.8)).toBe(4880);
    expect(cents(0.1 + 0.2)).toBe(30);
  });
});
