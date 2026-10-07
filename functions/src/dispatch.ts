// Proximity dispatch: offer an imminent booking to the nearest suitable
// chauffeur first, then the next one, falling back to broadcasting it to all.

import { haversineKm, LatLng } from './pricing';

export const OFFER_TIMEOUT_MS = 60 * 1000;
export const MAX_CANDIDATES = 5;
/** Pickups further away than this are broadcast so drivers can plan ahead. */
export const TARGETED_WINDOW_MS = 90 * 60 * 1000;
/** Ignore drivers whose last position is older than this. */
export const LOCATION_MAX_AGE_MS = 10 * 60 * 1000;
/** Don't offer to drivers this far from the pickup (km). */
export const MAX_RADIUS_KM = 25;

export interface DriverCandidate {
  driverId: string;
  location: LatLng | null;
  locationUpdatedAt: Date | null;
  vehicleClass: string | null;
  isAvailable: boolean;
  documentsVerified: boolean;
}

export interface RankedDriver {
  driverId: string;
  distanceKm: number;
}

export function rankDrivers(
  candidates: DriverCandidate[],
  pickup: LatLng,
  vehicleClass: string,
  now: Date,
  exclude: string[] = [],
): RankedDriver[] {
  return candidates
    .filter(
      (c) =>
        c.isAvailable &&
        c.documentsVerified &&
        c.location !== null &&
        c.locationUpdatedAt !== null &&
        now.getTime() - c.locationUpdatedAt.getTime() <= LOCATION_MAX_AGE_MS &&
        c.vehicleClass === vehicleClass &&
        !exclude.includes(c.driverId),
    )
    .map((c) => ({ driverId: c.driverId, distanceKm: haversineKm(pickup, c.location!) }))
    .filter((r) => r.distanceKm <= MAX_RADIUS_KM)
    .sort((a, b) => a.distanceKm - b.distanceKm)
    .slice(0, MAX_CANDIDATES);
}

export type DispatchMode = 'targeted' | 'broadcast';

export function dispatchMode(pickup: Date, now: Date): DispatchMode {
  return pickup.getTime() - now.getTime() <= TARGETED_WINDOW_MS ? 'targeted' : 'broadcast';
}

export interface DispatchState {
  mode: DispatchMode;
  candidates: string[];
  index: number;
  offeredTo: string | null;
  offerExpiresAtMs: number | null;
  declined: string[];
}

/** Moves to the next candidate, or opens the booking to everyone. */
export function advanceOffer(state: DispatchState, nowMs: number, declinedBy?: string): DispatchState {
  const declined = declinedBy && !state.declined.includes(declinedBy) ? [...state.declined, declinedBy] : state.declined;
  let index = state.index + 1;
  while (index < state.candidates.length && declined.includes(state.candidates[index])) index++;
  if (index >= state.candidates.length) {
    return { ...state, mode: 'broadcast', index, offeredTo: null, offerExpiresAtMs: null, declined };
  }
  return {
    ...state,
    index,
    offeredTo: state.candidates[index],
    offerExpiresAtMs: nowMs + OFFER_TIMEOUT_MS,
    declined,
  };
}

export function initialDispatch(ranked: RankedDriver[], mode: DispatchMode, nowMs: number): DispatchState {
  if (mode === 'broadcast' || ranked.length === 0) {
    return { mode: 'broadcast', candidates: [], index: 0, offeredTo: null, offerExpiresAtMs: null, declined: [] };
  }
  return {
    mode: 'targeted',
    candidates: ranked.map((r) => r.driverId),
    index: 0,
    offeredTo: ranked[0].driverId,
    offerExpiresAtMs: nowMs + OFFER_TIMEOUT_MS,
    declined: [],
  };
}
