// Flight tracking for airport pickups. Provider: AeroDataBox
// (GET /flights/number/{flight}/{yyyy-mm-dd}). Response parsing is defensive
// because only the fields below are used.

export interface FlightStatus {
  flightNumber: string;
  status: string; // provider status, e.g. Expected, Delayed, Arrived, Canceled
  scheduledArrival: Date | null;
  estimatedArrival: Date | null; // best known arrival time (actual > revised > predicted > scheduled)
  arrived: boolean;
  cancelled: boolean;
  terminal: string | null;
  gate: string | null;
  airportIata: string | null;
}

/** "ob 760" → "OB760". Returns null for anything that isn't a flight number. */
export function normalizeFlightNumber(raw: unknown): string | null {
  const s = String(raw ?? '').toUpperCase().replace(/[\s-]/g, '');
  return /^[A-Z0-9]{2,3}\d{1,4}[A-Z]?$/.test(s) ? s : null;
}

/** Parses AeroDataBox time strings like "2026-10-07 14:05Z" or ISO. */
export function parseTime(v: unknown): Date | null {
  const raw = typeof v === 'object' && v !== null ? (v as Record<string, unknown>).utc : v;
  if (typeof raw !== 'string' || !raw) return null;
  const iso = raw.includes('T') ? raw : raw.replace(' ', 'T');
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? null : d;
}

/**
 * Picks the leg arriving closest to [expectedArrival] (a flight number can
 * operate several legs per day) and normalises it.
 */
export function parseAeroDataBox(json: unknown, flightNumber: string, expectedArrival: Date): FlightStatus | null {
  const list = Array.isArray(json) ? json : [];
  let best: FlightStatus | null = null;
  let bestDiff = Infinity;
  for (const item of list) {
    if (!item || typeof item !== 'object') continue;
    const f = item as Record<string, unknown>;
    const arr = (f.arrival ?? {}) as Record<string, unknown>;
    const scheduled = parseTime(arr.scheduledTime);
    const actual = parseTime(arr.actualTime) ?? parseTime(arr.runwayTime);
    const revised = parseTime(arr.revisedTime) ?? parseTime(arr.predictedTime);
    const estimated = actual ?? revised ?? scheduled;
    const ref = scheduled ?? estimated;
    if (!ref) continue;
    const diff = Math.abs(ref.getTime() - expectedArrival.getTime());
    if (diff >= bestDiff) continue;
    const status = String(f.status ?? 'Unknown');
    const airport = (arr.airport ?? {}) as Record<string, unknown>;
    bestDiff = diff;
    best = {
      flightNumber,
      status,
      scheduledArrival: scheduled,
      estimatedArrival: estimated,
      arrived: /arrived|landed/i.test(status) || actual !== null,
      cancelled: /cancel/i.test(status),
      terminal: typeof arr.terminal === 'string' ? arr.terminal : null,
      gate: typeof arr.gate === 'string' ? arr.gate : null,
      airportIata: typeof airport.iata === 'string' ? airport.iata : null,
    };
  }
  return best;
}

/** Minimum change before we move a pickup and notify people. */
export const ADJUST_THRESHOLD_MIN = 10;

/**
 * The rider booked [originalPickup] for a flight scheduled at
 * [scheduledArrival]. If the flight now lands later, the pickup moves by the
 * same delay; it never moves earlier than what the rider chose.
 */
export function adjustedPickup(
  originalPickup: Date,
  scheduledArrival: Date | null,
  estimatedArrival: Date | null,
): { pickup: Date; delayMin: number } {
  if (!scheduledArrival || !estimatedArrival) return { pickup: originalPickup, delayMin: 0 };
  const delayMin = Math.round((estimatedArrival.getTime() - scheduledArrival.getTime()) / 60000);
  if (delayMin < ADJUST_THRESHOLD_MIN) return { pickup: originalPickup, delayMin: Math.max(0, delayMin) };
  return { pickup: new Date(originalPickup.getTime() + delayMin * 60000), delayMin };
}

/** Bookings whose pickup is within this window are tracked. */
export function shouldTrack(pickup: Date, now: Date): boolean {
  const diff = pickup.getTime() - now.getTime();
  return diff > -3 * 3600_000 && diff < 24 * 3600_000;
}

export function flightDateUtc(d: Date): string {
  return d.toISOString().slice(0, 10);
}
