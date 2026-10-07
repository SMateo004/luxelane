import { describe, it, expect } from '@jest/globals';
import {
  DEFAULT_RULES,
  clampDays,
  computeCharterPrice,
  clampHours,
  computePrice,
  haversineKm,
  isLatLng,
  resolveDistanceKm,
  ruleFromDoc,
} from './pricing';

// Santa Cruz de la Sierra: Plaza 24 de Septiembre → Viru Viru airport (~15 km straight)
const plaza = { lat: -17.7833, lng: -63.1821 };
const viruViru = { lat: -17.6448, lng: -63.1354 };

describe('haversineKm', () => {
  it('measures straight-line distance', () => {
    const km = haversineKm(plaza, viruViru);
    expect(km).toBeGreaterThan(15);
    expect(km).toBeLessThan(17);
  });
});

describe('resolveDistanceKm', () => {
  it('accepts a plausible client route distance', () => {
    expect(resolveDistanceKm(plaza, viruViru, 19.4)).toBe(19.4);
  });

  it('rejects a route shorter than the straight line', () => {
    const km = resolveDistanceKm(plaza, viruViru, 2);
    expect(km).toBeGreaterThan(20);
  });

  it('rejects absurdly long routes and missing values', () => {
    expect(resolveDistanceKm(plaza, viruViru, 500)).toBeLessThan(25);
    expect(resolveDistanceKm(plaza, viruViru, undefined)).toBeLessThan(25);
  });
});

describe('computePrice', () => {
  it('prices one-way trips with base + per-km, rounded up', () => {
    expect(computePrice(DEFAULT_RULES.business.oneWay, 'oneWay', { km: 19.4 })).toBe(Math.ceil(50 + 19.4 * 3));
  });

  it('applies the minimum fare', () => {
    expect(computePrice(DEFAULT_RULES.firstClass.oneWay, 'oneWay', { km: 0 })).toBe(80);
  });

  it('prices hourly charters with a 2-hour minimum', () => {
    expect(computePrice(DEFAULT_RULES.business.byTheHour, 'byTheHour', { hours: 1 })).toBe(160);
    expect(computePrice(DEFAULT_RULES.business.byTheHour, 'byTheHour', { hours: 5 })).toBe(400);
  });
});

describe('validation helpers', () => {
  it('clamps hours to 2–24', () => {
    expect(clampHours(0)).toBe(2);
    expect(clampHours(30)).toBe(24);
    expect(clampHours('3')).toBe(2);
  });

  it('rejects placeholder 0,0 coordinates', () => {
    expect(isLatLng({ lat: 0, lng: 0 })).toBe(false);
    expect(isLatLng({ lat: -17.7, lng: -63.1 })).toBe(true);
    expect(isLatLng({ lat: 'x', lng: 1 })).toBe(false);
  });

  it('reads admin rules with fallback for bad fields', () => {
    const rule = ruleFromDoc(
      { basePriceUsd: 70, pricePerKmUsd: -1, pricePerHourUsd: 0, minimumPriceUsd: 70 },
      DEFAULT_RULES.business.oneWay,
    );
    expect(rule).toEqual({ base: 70, perKm: 3, perHour: 0, min: 70 });
  });
});

describe('chauffeur by the day', () => {
  const rule = DEFAULT_RULES.business.byTheHour;
  it('multiplies the daily hourly price, each day with its minimum', () => {
    expect(computeCharterPrice(rule, 8, 1)).toBe(640);
    expect(computeCharterPrice(rule, 8, 3)).toBe(1920);
    // 1 h/day is clamped to the 2 h minimum per day.
    expect(computeCharterPrice(rule, 1, 2)).toBe(2 * 160);
  });
  it('clamps days to 1–7', () => {
    expect(clampDays(0)).toBe(1);
    expect(clampDays(3.4)).toBe(3);
    expect(clampDays(30)).toBe(7);
    expect(clampDays('x')).toBe(1);
  });
});
