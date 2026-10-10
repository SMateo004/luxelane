import { refundError, refundable } from './refunds';

const base = { paid: 250, refunded: 0, amount: 50, method: 'qr', reason: 'Chófer llegó tarde', status: 'completed', corporate: false };

describe('refunds', () => {
  it('accepts a partial or full refund of a completed ride', () => {
    expect(refundError(base)).toBeNull();
    expect(refundError({ ...base, amount: 250 })).toBeNull();
    expect(refundError({ ...base, amount: 12.5 })).toBeNull();
    for (const cents of [19.99, 4.35, 1.13, 0.29, 0.57]) expect(refundError({ ...base, amount: cents })).toBeNull();
  });

  it('never more than what is left', () => {
    expect(refundable(250, 100)).toBe(150);
    expect(refundError({ ...base, refunded: 220, amount: 50 })).toBe('refund/too-much');
    expect(refundError({ ...base, refunded: 250, amount: 1 })).toBe('refund/too-much');
  });

  it('validates amount, method, reason and status', () => {
    expect(refundError({ ...base, amount: 0 })).toBe('refund/amount');
    expect(refundError({ ...base, amount: 'x' })).toBe('refund/amount');
    expect(refundError({ ...base, amount: 10.555 })).toBe('refund/amount');
    expect(refundError({ ...base, method: 'card' })).toBe('refund/method');
    expect(refundError({ ...base, method: 'invoiceCredit' })).toBe('refund/method');
    expect(refundError({ ...base, corporate: true })).toBe('refund/method');
    expect(refundError({ ...base, corporate: true, method: 'invoiceCredit' })).toBeNull();
    expect(refundError({ ...base, reason: ' ' })).toBe('refund/reason');
    expect(refundError({ ...base, status: 'cancelled' })).toBe('refund/not-completed');
  });
});
