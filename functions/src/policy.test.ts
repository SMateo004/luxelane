import { describe, it, expect } from '@jest/globals';
import {
  canCapture,
  chunk,
  formatMoney,
  freeWaitEnd,
  isStalePending,
  isValidAmount,
  isValidDriverTransition,
  MAX_CHARGE_MINOR,
  toMinorUnits,
} from './policy';

describe('toMinorUnits / isValidAmount', () => {
  it('rounds to cents', () => {
    expect(toMinorUnits(75.505)).toBe(7551);
    expect(toMinorUnits(10)).toBe(1000);
  });

  it('rejects non-positive, fractional and excessive amounts', () => {
    expect(isValidAmount(0)).toBe(false);
    expect(isValidAmount(-100)).toBe(false);
    expect(isValidAmount(10.5)).toBe(false);
    expect(isValidAmount('100')).toBe(false);
    expect(isValidAmount(MAX_CHARGE_MINOR + 1)).toBe(false);
    expect(isValidAmount(7500)).toBe(true);
  });
});

describe('isValidDriverTransition', () => {
  it('allows the forward lifecycle', () => {
    expect(isValidDriverTransition('confirmed', 'driver_arriving')).toBe(true);
    expect(isValidDriverTransition('driver_arriving', 'driver_arrived')).toBe(true);
    expect(isValidDriverTransition('driver_arrived', 'in_progress')).toBe(true);
    expect(isValidDriverTransition('in_progress', 'completed')).toBe(true);
  });

  it('allows same-status refreshes', () => {
    expect(isValidDriverTransition('confirmed', 'confirmed')).toBe(true);
  });

  it('blocks skipping steps and going backwards', () => {
    expect(isValidDriverTransition('confirmed', 'completed')).toBe(false);
    expect(isValidDriverTransition('in_progress', 'pending')).toBe(false);
    expect(isValidDriverTransition('completed', 'in_progress')).toBe(false);
    expect(isValidDriverTransition('in_progress', 'cancelled')).toBe(false);
  });
});

describe('isStalePending', () => {
  const now = new Date('2026-10-06T12:00:00Z');

  it('keeps future scheduled bookings', () => {
    expect(
      isStalePending(
        {
          status: 'pending',
          scheduledAt: new Date('2026-10-10T09:00:00Z'),
          createdAt: new Date('2026-10-01T09:00:00Z'),
        },
        now,
      ),
    ).toBe(false);
  });

  it('flags pending bookings whose pickup passed the grace period', () => {
    expect(
      isStalePending({ status: 'pending', scheduledAt: new Date('2026-10-06T11:00:00Z') }, now),
    ).toBe(true);
  });

  it('ignores non-pending bookings', () => {
    expect(
      isStalePending({ status: 'confirmed', scheduledAt: new Date('2026-10-01T00:00:00Z') }, now),
    ).toBe(false);
  });
});

describe('canCapture', () => {
  it('allows admins and the assigned driver only', () => {
    expect(canCapture({ uid: 'a', role: 'admin' }, { driverId: 'd' })).toBe(true);
    expect(canCapture({ uid: 'd', role: 'driver' }, { driverId: 'd' })).toBe(true);
    expect(canCapture({ uid: 'x', role: 'driver' }, { driverId: 'd' })).toBe(false);
    expect(canCapture({ uid: 'r', role: 'rider' }, { driverId: 'd' })).toBe(false);
  });
});

describe('helpers', () => {
  it('chunks lists', () => {
    expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]]);
  });

  it('formats money with currency code', () => {
    expect(formatMoney(75, 'usd')).toBe('USD 75.00');
  });
});

describe('freeWaitEnd', () => {
  const pickup = new Date('2026-10-07T14:00:00Z');

  it('gives 15 min in the city from pickup time', () => {
    expect(freeWaitEnd({ pickup, isAirport: false }).toISOString()).toBe('2026-10-07T14:15:00.000Z');
  });

  it('starts the city clock when a late chauffeur arrives', () => {
    const arrived = new Date('2026-10-07T14:05:00Z');
    expect(freeWaitEnd({ pickup, isAirport: false, driverArrivedAt: arrived }).toISOString()).toBe(
      '2026-10-07T14:20:00.000Z',
    );
  });

  it('gives 60 min at the airport from landing', () => {
    const landing = new Date('2026-10-07T14:40:00Z');
    expect(freeWaitEnd({ pickup, isAirport: true, landing }).toISOString()).toBe('2026-10-07T15:40:00.000Z');
    expect(freeWaitEnd({ pickup, isAirport: true }).toISOString()).toBe('2026-10-07T15:00:00.000Z');
  });
});
