import { describe, it, expect } from '@jest/globals';
import {
  DriverCandidate,
  OFFER_TIMEOUT_MS,
  advanceOffer,
  dispatchMode,
  initialDispatch,
  rankDrivers,
} from './dispatch';

const pickup = { lat: -17.7833, lng: -63.1821 };
const now = new Date('2026-10-07T12:00:00Z');
const fresh = new Date('2026-10-07T11:58:00Z');

const driver = (id: string, lat: number, lng: number, extra: Partial<DriverCandidate> = {}): DriverCandidate => ({
  driverId: id,
  location: { lat, lng },
  locationUpdatedAt: fresh,
  vehicleClass: 'business',
  isAvailable: true,
  documentsVerified: true,
  ...extra,
});

describe('rankDrivers', () => {
  it('orders suitable drivers by distance', () => {
    const ranked = rankDrivers(
      [driver('far', -17.70, -63.18), driver('near', -17.785, -63.183), driver('mid', -17.76, -63.18)],
      pickup,
      'business',
      now,
    );
    expect(ranked.map((r) => r.driverId)).toEqual(['near', 'mid', 'far']);
    expect(ranked[0].distanceKm).toBeLessThan(1);
  });

  it('skips unavailable, unverified, wrong-class, stale, excluded and distant drivers', () => {
    const ranked = rankDrivers(
      [
        driver('busy', -17.784, -63.182, { isAvailable: false }),
        driver('unverified', -17.784, -63.182, { documentsVerified: false }),
        driver('van', -17.784, -63.182, { vehicleClass: 'businessVan' }),
        driver('stale', -17.784, -63.182, { locationUpdatedAt: new Date('2026-10-07T10:00:00Z') }),
        driver('nolocation', 0, 0, { location: null }),
        driver('declined', -17.784, -63.182),
        driver('lapaz', -16.5, -68.15),
        driver('ok', -17.79, -63.19),
      ],
      pickup,
      'business',
      now,
      ['declined'],
    );
    expect(ranked.map((r) => r.driverId)).toEqual(['ok']);
  });
});

describe('dispatch flow', () => {
  const nowMs = now.getTime();

  it('targets imminent pickups and broadcasts advance bookings', () => {
    expect(dispatchMode(new Date(nowMs + 30 * 60000), now)).toBe('targeted');
    expect(dispatchMode(new Date(nowMs + 5 * 3600000), now)).toBe('broadcast');
  });

  it('offers to the nearest first, then the next, then everyone', () => {
    let s = initialDispatch(
      [
        { driverId: 'a', distanceKm: 1 },
        { driverId: 'b', distanceKm: 2 },
      ],
      'targeted',
      nowMs,
    );
    expect(s.offeredTo).toBe('a');
    expect(s.offerExpiresAtMs).toBe(nowMs + OFFER_TIMEOUT_MS);

    s = advanceOffer(s, nowMs + 61000, 'a');
    expect(s.offeredTo).toBe('b');
    expect(s.declined).toEqual(['a']);

    s = advanceOffer(s, nowMs + 122000);
    expect(s.mode).toBe('broadcast');
    expect(s.offeredTo).toBeNull();
  });

  it('broadcasts immediately when nobody is nearby', () => {
    expect(initialDispatch([], 'targeted', nowMs).mode).toBe('broadcast');
  });
});
