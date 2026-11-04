import { describe, it, expect } from '@jest/globals';
import {
  computeReadyAt, effectiveArrival, exitMinutesFor, localDate, localToUtcMs, noShowEligibleAt,
  normalizeFlightNumber, readExitMinutes, FlightType,
} from './flight_time';

// Minutos de salida FICTICIOS de prueba (los reales los carga el responsable).
const OPS = {
  flightExitMinutes: {
    domestic: { noCheckedBag: 10, checkedBag: 25 },
    international: { noCheckedBag: 30, checkedBag: 50 },
  },
};
const EXIT = readExitMinutes(OPS)!;
const MIN = 60_000;

describe('normalizeFlightNumber', () => {
  it.each([
    ['ob 0760', 'OB760'], ['OB760', 'OB760'], ['Z8-0301', 'Z8301'], ['aal 12', 'AAL12'],
    ['2z 7', '2Z7'], ['ob760a', 'OB760A'], ['  OB 7 6 0  ', 'OB760'], ['OB0001', 'OB1'],
  ])('%s → %s', (raw, want) => expect(normalizeFlightNumber(raw)).toBe(want));

  it.each(['OB0000', 'OB', '12345', 'O', 'OB12345', 'OB76AB', '', 'https://x.test/OB760'])(
    '%s no es un número de vuelo', (raw) => expect(normalizeFlightNumber(raw)).toBeNull());
});

describe('hora local de La Paz (UTC-4 fijo)', () => {
  it('23:50 del 20 de noviembre es 03:50 UTC del 21', () => {
    expect(localToUtcMs('2026-11-20', '23:50')).toBe(Date.UTC(2026, 10, 21, 3, 50));
  });
  it('fechas u horas inválidas: null', () => {
    for (const [d, h] of [['2026-02-30', '10:00'], ['2026-11-20', '24:00'], ['20-11-2026', '10:00'], ['2026-11-20', '9:5']]) {
      expect(localToUtcMs(d, h)).toBeNull();
    }
  });
  it('fecha local de un instante', () => {
    expect(localDate(Date.UTC(2026, 10, 21, 3, 50))).toBe('2026-11-20');
    expect(localDate(Date.UTC(2026, 10, 21, 4, 20))).toBe('2026-11-21');
  });
});

describe('effectiveArrival', () => {
  const s = Date.UTC(2026, 10, 20, 14);
  it('real > estimada > programada', () => {
    expect(effectiveArrival({ scheduledArrival: s })).toBe(s);
    expect(effectiveArrival({ scheduledArrival: s, estimatedArrival: s + 30 * MIN })).toBe(s + 30 * MIN);
    expect(effectiveArrival({ scheduledArrival: s, estimatedArrival: s + 30 * MIN, actualArrival: s + 20 * MIN }))
      .toBe(s + 20 * MIN);
  });
  it('sin ninguna hora: null', () => {
    expect(effectiveArrival({})).toBeNull();
    expect(effectiveArrival({ scheduledArrival: null, estimatedArrival: null, actualArrival: null })).toBeNull();
  });
});

describe('computeReadyAt', () => {
  const s = Date.UTC(2026, 10, 20, 14);
  it.each<[FlightType, boolean, number]>([
    ['domestic', false, 10], ['domestic', true, 25], ['international', false, 30], ['international', true, 50],
  ])('%s, equipaje facturado %s: +%i min', (type, bag, minutes) => {
    expect(computeReadyAt({ scheduledArrival: s, flightType: type, hasCheckedBag: bag }, EXIT)).toBe(s + minutes * MIN);
    expect(exitMinutesFor(EXIT, type, bag)).toBe(minutes);
  });

  it('la hora real sustituye a la estimada', () => {
    expect(computeReadyAt({ scheduledArrival: s, estimatedArrival: s + 60 * MIN, actualArrival: s + 45 * MIN,
      flightType: 'domestic', hasCheckedBag: true }, EXIT)).toBe(s + 70 * MIN);
  });

  it('vuelo que cruza la medianoche: programado 23:50, estimado 00:20; la fecha del vuelo no cambia', () => {
    const scheduled = localToUtcMs('2026-11-20', '23:50')!;
    const estimated = localToUtcMs('2026-11-21', '00:20')!;
    const ready = computeReadyAt({ scheduledArrival: scheduled, estimatedArrival: estimated,
      flightType: 'international', hasCheckedBag: false }, EXIT)!;
    expect(ready).toBe(estimated + 30 * MIN);
    expect(localDate(scheduled)).toBe('2026-11-20');
    expect(localDate(ready)).toBe('2026-11-21');
  });

  it('sin hora o sin minutos configurados: null (no se inventan)', () => {
    expect(computeReadyAt({ flightType: 'domestic', hasCheckedBag: true }, EXIT)).toBeNull();
    expect(computeReadyAt({ scheduledArrival: s, flightType: 'domestic', hasCheckedBag: true }, null)).toBeNull();
  });

  it('config/ops.flightExitMinutes incompleta o inválida: null', () => {
    expect(readExitMinutes({})).toBeNull();
    expect(readExitMinutes({ flightExitMinutes: { domestic: { noCheckedBag: 10, checkedBag: 25 } } })).toBeNull();
    expect(readExitMinutes({ flightExitMinutes: { ...OPS.flightExitMinutes,
      international: { noCheckedBag: -5, checkedBag: 50 } } })).toBeNull();
    expect(readExitMinutes({ flightExitMinutes: { ...OPS.flightExitMinutes,
      domestic: { noCheckedBag: '10', checkedBag: 25 } } })).toBeNull();
  });
});

describe('noShowEligibleAt', () => {
  it('readyAt + espera; null sin readyAt o sin espera', () => {
    expect(noShowEligibleAt(1_000_000, 15)).toBe(1_000_000 + 15 * MIN);
    expect(noShowEligibleAt(null, 15)).toBeNull();
    expect(noShowEligibleAt(1_000_000, undefined)).toBeNull();
  });
});
