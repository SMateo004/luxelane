import { adjustmentError } from './adjustments';

const base = { status: 'completed', base: 250, adjusted: 0, refunded: 0, cardPayment: false, type: 'toll', amount: 15, note: '' };

describe('adjustments', () => {
  it('adds charges from arrival to completion', () => {
    expect(adjustmentError(base)).toBeNull();
    expect(adjustmentError({ ...base, status: 'in_progress', type: 'waiting', amount: 30.5 })).toBeNull();
    expect(adjustmentError({ ...base, status: 'confirmed' })).toBe('adjust/status');
    expect(adjustmentError({ ...base, status: 'cancelled' })).toBe('adjust/status');
  });

  it('only a correction lowers the price, with a note, never below zero or refunds', () => {
    expect(adjustmentError({ ...base, amount: -10 })).toBe('adjust/amount');
    expect(adjustmentError({ ...base, type: 'correction', amount: -10 })).toBe('adjust/note');
    expect(adjustmentError({ ...base, type: 'correction', amount: -10, note: 'Ruta más corta' })).toBeNull();
    expect(adjustmentError({ ...base, type: 'correction', amount: -260, note: 'Error' })).toBe('adjust/below-zero');
    expect(adjustmentError({ ...base, refunded: 245, type: 'correction', amount: -10, note: 'Error' })).toBe('adjust/below-zero');
  });

  it('guards amounts, types and card payments', () => {
    expect(adjustmentError({ ...base, amount: 0 })).toBe('adjust/amount');
    expect(adjustmentError({ ...base, amount: 2500 })).toBe('adjust/amount');
    expect(adjustmentError({ ...base, amount: 1.234 })).toBe('adjust/amount');
    expect(adjustmentError({ ...base, type: 'tip' })).toBe('adjust/type');
    expect(adjustmentError({ ...base, cardPayment: true })).toBe('adjust/card');
  });
});
