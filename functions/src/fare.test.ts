import { describe, it, expect } from '@jest/globals';
import { computeFare, FareInput, fixedFareKey, PricingConfig, roundUpBs } from './fare';
import type { FareRule } from './pricing';

// Tarifas de prueba (no son las de negocio).
const oneWay: FareRule = { basePriceUsd: 50, pricePerKmUsd: 3, pricePerHourUsd: 0, minimumPriceUsd: 60, isActive: true };
const hourly: FareRule = { basePriceUsd: 0, pricePerKmUsd: 0, pricePerHourUsd: 80, minimumPriceUsd: 160, isActive: true };
const base: FareInput = { vehicleClass: 'business', serviceType: 'oneWay', km: 10, localHour: 12 };
const night: PricingConfig = { nightSurchargePct: 20, nightStartHour: 22, nightEndHour: 6 };

type Row = [string, FareInput, FareRule | undefined, PricingConfig, number | string];

const table: Row[] = [
  ['traslado por distancia: 50 + 10 km × 3', base, oneWay, {}, 80],
  ['mínimo aplicado en un trayecto corto', { ...base, km: 2 }, oneWay, {}, 60],
  ['redondeo hacia arriba a Bs enteros', { ...base, km: 10.01 }, oneWay, {}, 81],
  ['por horas: 3 h × 80', { ...base, serviceType: 'byTheHour', hours: 3, km: undefined }, hourly, {}, 240],
  ['por horas con el mínimo de la tarifa', { ...base, serviceType: 'byTheHour', hours: 1 }, hourly, {}, 160],
  ['horas no enteras', { ...base, serviceType: 'byTheHour', hours: 2.5 }, hourly, {}, 'invalid_hours'],
  ['horas en cero', { ...base, serviceType: 'byTheHour', hours: 0 }, hourly, {}, 'invalid_hours'],
  ['clase inexistente', { ...base, vehicleClass: 'limousine' }, oneWay, {}, 'unknown_class'],
  ['servicio inexistente', { ...base, serviceType: 'shuttle' }, oneWay, {}, 'unknown_service'],
  ['sin tarifa en Firestore: falla cerrada', base, undefined, {}, 'pricing_unavailable'],
  ['tarifa incompleta: falla cerrada', base, { ...oneWay, pricePerKmUsd: undefined as unknown as number }, {}, 'pricing_unavailable'],
  ['tarifa desactivada', base, { ...oneWay, isActive: false }, {}, 'class_unavailable'],
  ['traslado sin distancia', { ...base, km: undefined }, oneWay, {}, 'missing_distance'],
  ['recargo nocturno ausente: sin recargo de noche', { ...base, localHour: 23 }, oneWay, {}, 80],
  ['recargo nocturno presente, dentro de la franja (23 h)', { ...base, localHour: 23 }, oneWay, night, 96],
  ['recargo nocturno presente, cruzando medianoche (5 h)', { ...base, localHour: 5 }, oneWay, night, 96],
  ['recargo nocturno presente, fuera de la franja (6 h)', { ...base, localHour: 6 }, oneWay, night, 80],
  ['recargo nocturno incompleto (sin hora de fin): no se aplica', { ...base, localHour: 23 }, oneWay, { nightSurchargePct: 20, nightStartHour: 22 }, 80],
  ['tarifa fija de aeropuerto ausente: por distancia',
    { ...base, airportTrip: { iata: 'VVI', city: 'Santa Cruz de la Sierra' } }, oneWay, {}, 80],
  ['tarifa fija de aeropuerto presente',
    { ...base, airportTrip: { iata: 'VVI', city: 'Santa Cruz de la Sierra' } }, oneWay,
    { fixedAirportFares: { [fixedFareKey('VVI', 'Santa Cruz de la Sierra', 'business')]: 150 } }, 150],
  ['tarifa fija de otra clase no se aplica',
    { ...base, airportTrip: { iata: 'VVI', city: 'Santa Cruz de la Sierra' } }, oneWay,
    { fixedAirportFares: { [fixedFareKey('VVI', 'Santa Cruz de la Sierra', 'firstClass')]: 150 } }, 80],
];

describe('computeFare', () => {
  it.each(table)('%s', (_name, input, rule, config, expected) => {
    const r = computeFare(input, rule, config);
    if (typeof expected === 'number') {
      expect(r).toMatchObject({ ok: true, price: expected });
    } else {
      expect(r).toEqual({ ok: false, error: expected });
    }
  });

  it('el desglose dice si se aplicó el mínimo y el recargo', () => {
    const r = computeFare({ ...base, km: 2, localHour: 23 }, oneWay, night);
    expect(r.ok && r.breakdown).toMatchObject({ minimumApplied: true, nightSurchargePct: 20, subtotal: 60, total: 72 });
  });

  it('roundUpBs no sube un entero por error de coma flotante', () => {
    expect(roundUpBs(0.1 * 3 * 100)).toBe(30);
    expect(roundUpBs(160.0000000001)).toBe(160);
    expect(roundUpBs(160.01)).toBe(161);
  });
});
