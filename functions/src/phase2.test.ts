import { describe, it, expect } from '@jest/globals';
import { buildChauffeur, displayName, isValidRating, nextAverage } from './chauffeur';
import {
  adjustedPickup,
  normalizeFlightNumber,
  parseAeroDataBox,
  parseTime,
  shouldTrack,
} from './flights';

describe('chauffeur snapshot', () => {
  it('shortens the surname', () => {
    expect(displayName('María Fernanda Rojas')).toBe('María Fernanda R.');
    expect(displayName('Carlos')).toBe('Carlos');
    expect(displayName('')).toBe('Tu chófer');
  });

  it('builds the rider-facing card', () => {
    const c = buildChauffeur(
      'd1',
      { displayName: 'Luis Alberto Vaca', phone: '+59170000000' },
      { rating: 4.876, ratingCount: 12, totalRides: 40 },
      { make: 'Mercedes-Benz', model: 'E 300', color: 'Negro', plate: 'abc-123' },
    );
    expect(c).toMatchObject({
      name: 'Luis Alberto V.',
      rating: 4.9,
      vehicle: 'Mercedes-Benz E 300',
      plate: 'ABC-123',
      phone: '+59170000000',
      photoUrl: null,
    });
  });

  it('hides the rating until someone has rated', () => {
    expect(buildChauffeur('d1', {}, { rating: 5, ratingCount: 0 }, {}).rating).toBeNull();
  });
});

describe('ratings', () => {
  it('computes a running average', () => {
    expect(nextAverage(0, 0, 4)).toEqual({ rating: 4, count: 1 });
    expect(nextAverage(4, 1, 5)).toEqual({ rating: 4.5, count: 2 });
  });

  it('accepts integers 1–5 only', () => {
    expect(isValidRating(5)).toBe(true);
    expect(isValidRating(0)).toBe(false);
    expect(isValidRating(4.5)).toBe(false);
  });
});

describe('flight numbers and times', () => {
  it('normalises flight numbers', () => {
    expect(normalizeFlightNumber('ob 760')).toBe('OB760');
    expect(normalizeFlightNumber('LA-2400')).toBe('LA2400');
    expect(normalizeFlightNumber('hello')).toBeNull();
  });

  it('parses provider times', () => {
    expect(parseTime({ utc: '2026-10-07 14:05Z' })?.toISOString()).toBe('2026-10-07T14:05:00.000Z');
    expect(parseTime('bad')).toBeNull();
  });
});

describe('parseAeroDataBox', () => {
  const expected = new Date('2026-10-07T14:05:00Z');
  const sample = [
    {
      number: 'OB 760',
      status: 'Delayed',
      arrival: {
        airport: { iata: 'VVI' },
        scheduledTime: { utc: '2026-10-07 14:05Z' },
        revisedTime: { utc: '2026-10-07 14:50Z' },
        terminal: 'N',
        gate: '4',
      },
    },
    {
      number: 'OB 760',
      status: 'Expected',
      arrival: { scheduledTime: { utc: '2026-10-07 22:00Z' } },
    },
  ];

  it('picks the matching leg and uses the revised time', () => {
    const f = parseAeroDataBox(sample, 'OB760', expected)!;
    expect(f.status).toBe('Delayed');
    expect(f.estimatedArrival?.toISOString()).toBe('2026-10-07T14:50:00.000Z');
    expect(f.terminal).toBe('N');
    expect(f.airportIata).toBe('VVI');
    expect(f.arrived).toBe(false);
  });

  it('handles empty or malformed responses', () => {
    expect(parseAeroDataBox(null, 'OB760', expected)).toBeNull();
    expect(parseAeroDataBox([{ foo: 1 }], 'OB760', expected)).toBeNull();
  });
});

describe('adjustedPickup', () => {
  const pickup = new Date('2026-10-07T14:20:00Z');
  const sched = new Date('2026-10-07T14:05:00Z');

  it('moves the pickup by the delay', () => {
    const r = adjustedPickup(pickup, sched, new Date('2026-10-07T14:50:00Z'));
    expect(r.delayMin).toBe(45);
    expect(r.pickup.toISOString()).toBe('2026-10-07T15:05:00.000Z');
  });

  it('ignores small delays and early arrivals', () => {
    expect(adjustedPickup(pickup, sched, new Date('2026-10-07T14:10:00Z')).pickup).toEqual(pickup);
    expect(adjustedPickup(pickup, sched, new Date('2026-10-07T13:40:00Z')).pickup).toEqual(pickup);
  });

  it('tracks only pickups in the next 24 h (or just passed)', () => {
    const now = new Date('2026-10-07T12:00:00Z');
    expect(shouldTrack(new Date('2026-10-07T20:00:00Z'), now)).toBe(true);
    expect(shouldTrack(new Date('2026-10-09T20:00:00Z'), now)).toBe(false);
  });
});
