import { describe, it, expect } from '@jest/globals';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { checkBookingPrice, FareRule } from './pricing';

// Tarifas de prueba (no son las de negocio).
const rule: FareRule = { basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 50, isActive: true };
const hourly: FareRule = { basePriceUsd: 0, pricePerKmUsd: 0, pricePerHourUsd: 80, minimumPriceUsd: 160, isActive: true };

describe('checkBookingPrice', () => {
  it('acepta un precio que respeta el mínimo', () => {
    expect(checkBookingPrice({ estimatedPrice: 125, serviceType: 'oneWay' }, rule).ok).toBe(true);
  });

  it('marca un precio por debajo del mínimo', () => {
    const r = checkBookingPrice({ estimatedPrice: 10, serviceType: 'oneWay' }, rule);
    expect(r).toEqual({ ok: false, reason: 'below_fare', expectedMinimum: 50 });
  });

  it('exige horas × tarifa en servicios por horas', () => {
    expect(checkBookingPrice({ estimatedPrice: 240, serviceType: 'byTheHour', hours: 3 }, hourly).ok).toBe(true);
    expect(checkBookingPrice({ estimatedPrice: 200, serviceType: 'byTheHour', hours: 3 }, hourly).reason).toBe('below_fare');
  });

  it('rechaza servicios desactivados por el admin', () => {
    expect(checkBookingPrice({ estimatedPrice: 999 }, { ...rule, isActive: false }).reason).toBe('fare_disabled');
  });

  it('no hay tarifas en el código del servidor (D20)', () => {
    const src = ['pricing.ts', 'fare.ts', 'booking_service.ts', 'index.ts']
      .map((f) => readFileSync(resolve(__dirname, f), 'utf8')).join('\n');
    expect(src).not.toMatch(/DEFAULT_FARES|fallbackFare|factoryFare/);
  });

  it('rechaza combinaciones sin tarifa', () => {
    expect(checkBookingPrice({ estimatedPrice: 999 }, undefined).reason).toBe('unknown_fare');
  });
});
