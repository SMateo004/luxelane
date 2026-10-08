import { DISABLED, bestDiscount, configError, loyaltyDiscount, nextTier, parseConfig, tierFor } from './loyalty';

const doc = {
  enabled: true,
  tiers: [
    { id: 'gold', minRides: 15, discountPct: 7 },
    { id: 'silver', minRides: 5, discountPct: 3 },
    { id: 'platinum', minRides: 40, discountPct: 10 },
  ],
};

describe('parseConfig', () => {
  it('sorts tiers and keeps valid ones', () => {
    const c = parseConfig(doc);
    expect(c.enabled).toBe(true);
    expect(c.tiers.map((t) => t.id)).toEqual(['silver', 'gold', 'platinum']);
  });

  it('is off when disabled, missing or inconsistent', () => {
    expect(parseConfig(undefined)).toEqual(DISABLED);
    expect(parseConfig({ ...doc, enabled: false })).toEqual(DISABLED);
    expect(parseConfig({ enabled: true, tiers: [{ id: 'silver', minRides: 5, discountPct: 50 }] })).toEqual(DISABLED);
    // Gold gives less than silver → invalid.
    expect(
      parseConfig({ enabled: true, tiers: [{ id: 'silver', minRides: 5, discountPct: 8 }, { id: 'gold', minRides: 10, discountPct: 5 }] }),
    ).toEqual(DISABLED);
  });

  it('configError explains why', () => {
    expect(configError([])).toBe('loyalty/no-tiers');
    expect(configError([{ id: 'silver', minRides: 5, discountPct: 3 }, { id: 'gold', minRides: 5, discountPct: 4 }])).toBe(
      'loyalty/thresholds-order',
    );
  });
});

describe('tiers and discounts', () => {
  const c = parseConfig(doc);
  it('tier by rides in the window, and the next one', () => {
    expect(tierFor(4, c)).toBeNull();
    expect(tierFor(5, c)?.id).toBe('silver');
    expect(tierFor(39, c)?.id).toBe('gold');
    expect(tierFor(100, c)?.id).toBe('platinum');
    expect(nextTier(7, c)?.id).toBe('gold');
    expect(nextTier(100, c)).toBeNull();
    expect(tierFor(100, DISABLED)).toBeNull();
  });

  it('discount in whole Bs; promo and loyalty do not stack', () => {
    expect(loyaltyDiscount(333, tierFor(15, c))).toBe(23); // 7 % of 333 = 23.31
    expect(loyaltyDiscount(333, null)).toBe(0);
    expect(bestDiscount(50, 23)).toEqual({ source: 'promo', amount: 50 });
    expect(bestDiscount(10, 23)).toEqual({ source: 'loyalty', amount: 23 });
    expect(bestDiscount(0, 0)).toEqual({ source: null, amount: 0 });
  });
});
