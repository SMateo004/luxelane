import { PromoContext, PromoDoc, discountFor, evaluatePromo, normalizeCode, promoDefinitionError } from './promo';

const now = new Date('2026-10-07T12:00:00Z');
const base: PromoDoc = { code: 'BIENVENIDO', type: 'percent', value: 20, active: true };
const ctx: PromoContext = { now, fare: 500, vehicleClass: 'business', userRedemptions: 0, hasCompletedRide: false };

describe('normalizeCode', () => {
  it('upper-cases and strips spaces', () => {
    expect(normalizeCode(' bien venido ')).toBe('BIENVENIDO');
    expect(normalizeCode('ab')).toBeNull();
    expect(normalizeCode('NO!')).toBeNull();
    expect(normalizeCode(7)).toBeNull();
  });
});

describe('discountFor', () => {
  it('percent with cap, fixed, never above the fare, whole Bs', () => {
    expect(discountFor(base, 500)).toBe(100);
    expect(discountFor({ ...base, maxDiscount: 60 }, 500)).toBe(60);
    expect(discountFor({ ...base, value: 15 }, 333)).toBe(49); // 49.95 → 49
    expect(discountFor({ ...base, type: 'fixed', value: 80 }, 500)).toBe(80);
    expect(discountFor({ ...base, type: 'fixed', value: 800 }, 500)).toBe(500);
  });
});

describe('evaluatePromo', () => {
  it('applies a valid code', () => {
    expect(evaluatePromo(base, ctx)).toEqual({ ok: true, discount: 100 });
  });

  it('rejects inactive, unknown, out of dates and exhausted codes', () => {
    expect(evaluatePromo(null, ctx)).toEqual({ ok: false, error: 'promo/invalid' });
    expect(evaluatePromo({ ...base, active: false }, ctx)).toEqual({ ok: false, error: 'promo/invalid' });
    expect(evaluatePromo({ ...base, validFrom: new Date('2026-11-01') }, ctx)).toEqual({ ok: false, error: 'promo/not-started' });
    expect(evaluatePromo({ ...base, validUntil: new Date('2026-10-01') }, ctx)).toEqual({ ok: false, error: 'promo/expired' });
    expect(evaluatePromo({ ...base, maxRedemptions: 10, redemptions: 10 }, ctx)).toEqual({ ok: false, error: 'promo/exhausted' });
  });

  it('per-rider limit, first ride, class and minimum fare', () => {
    expect(evaluatePromo(base, { ...ctx, userRedemptions: 1 })).toEqual({ ok: false, error: 'promo/already-used' });
    expect(evaluatePromo({ ...base, perUserLimit: 3 }, { ...ctx, userRedemptions: 2 })).toEqual({ ok: true, discount: 100 });
    expect(evaluatePromo({ ...base, firstRideOnly: true }, { ...ctx, hasCompletedRide: true })).toEqual({
      ok: false,
      error: 'promo/first-ride-only',
    });
    expect(evaluatePromo({ ...base, vehicleClasses: ['firstClass'] }, ctx)).toEqual({ ok: false, error: 'promo/vehicle-class' });
    expect(evaluatePromo({ ...base, minFare: 600 }, ctx)).toEqual({ ok: false, error: 'promo/min-fare' });
  });
});

describe('promoDefinitionError', () => {
  it('validates what admins create', () => {
    expect(promoDefinitionError(base)).toBeNull();
    expect(promoDefinitionError({ ...base, code: 'x' })).toBe('promo/bad-code');
    expect(promoDefinitionError({ ...base, value: 120 })).toBe('promo/bad-value');
    expect(promoDefinitionError({ ...base, type: 'fixed', value: 0 })).toBe('promo/bad-value');
    expect(
      promoDefinitionError({ ...base, validFrom: new Date('2026-10-10'), validUntil: new Date('2026-10-01') }),
    ).toBe('promo/bad-dates');
  });
});
