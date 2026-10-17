import { describe, it, expect } from '@jest/globals';
import { checkBookingPrice, DEFAULT_FARES, fareId } from './pricing';

describe('checkBookingPrice', () => {
  const rule = DEFAULT_FARES[fareId('business', 'oneWay')];

  it('acepta un precio que respeta el mínimo', () => {
    expect(checkBookingPrice({ estimatedPrice: 125, serviceType: 'oneWay' }, rule).ok).toBe(true);
  });

  it('marca un precio por debajo del mínimo', () => {
    const r = checkBookingPrice({ estimatedPrice: 10, serviceType: 'oneWay' }, rule);
    expect(r).toEqual({ ok: false, reason: 'below_fare', expectedMinimum: 50 });
  });

  it('exige horas × tarifa en servicios por horas', () => {
    const hourly = DEFAULT_FARES[fareId('business', 'byTheHour')];
    expect(checkBookingPrice({ estimatedPrice: 240, serviceType: 'byTheHour', hours: 3 }, hourly).ok).toBe(true);
    expect(checkBookingPrice({ estimatedPrice: 200, serviceType: 'byTheHour', hours: 3 }, hourly).reason).toBe('below_fare');
  });

  it('rechaza servicios desactivados por el admin', () => {
    expect(checkBookingPrice({ estimatedPrice: 999 }, { ...rule, isActive: false }).reason).toBe('fare_disabled');
  });

  it('tiene tarifa de fábrica para todas las clases que se reservan', () => {
    for (const vc of ['business', 'businessSuv', 'firstClass', 'businessVan', 'electric']) {
      for (const st of ['oneWay', 'byTheHour']) {
        expect(DEFAULT_FARES[fareId(vc, st)]).toBeDefined();
      }
    }
    expect(DEFAULT_FARES[fareId('businessSuv', 'oneWay')].minimumPriceUsd).toBe(70);
  });

  it('rechaza combinaciones sin tarifa', () => {
    expect(checkBookingPrice({ estimatedPrice: 999 }, undefined).reason).toBe('unknown_fare');
  });
});
