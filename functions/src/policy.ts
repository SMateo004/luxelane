// Pure business rules shared by the Cloud Functions. Kept free of Firebase
// imports so they can be unit-tested directly.

export type BookingStatus =
  | 'pending'
  | 'confirmed'
  | 'driver_arriving'
  | 'driver_arrived'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

export type UserRole = 'rider' | 'driver' | 'admin';

// Hard ceiling for a single authorisation, in minor units (e.g. cents).
export const MAX_CHARGE_MINOR = 5_000_000;

// A pending booking whose pickup time passed this long ago is considered stale.
export const STALE_PENDING_GRACE_MS = 30 * 60 * 1000;

/** Converts a major-unit price (e.g. 75.5) to minor units (7550). */
export function toMinorUnits(amount: number): number {
  return Math.round(amount * 100);
}

export function isValidAmount(amountMinor: unknown): amountMinor is number {
  return (
    typeof amountMinor === 'number' &&
    Number.isInteger(amountMinor) &&
    amountMinor > 0 &&
    amountMinor <= MAX_CHARGE_MINOR
  );
}

/** Mirrors `isValidDriverTransition` in firestore.rules. */
export function isValidDriverTransition(from: BookingStatus, to: BookingStatus): boolean {
  if (from === to) return true;
  const next: Partial<Record<BookingStatus, BookingStatus[]>> = {
    confirmed: ['driver_arriving', 'cancelled'],
    driver_arriving: ['driver_arrived'],
    driver_arrived: ['in_progress'],
    in_progress: ['completed'],
  };
  return next[from]?.includes(to) ?? false;
}

/**
 * Only pending bookings whose scheduled pickup is already in the past (plus a
 * grace period) are stale. Advance bookings for next week must survive.
 */
export function isStalePending(
  booking: { status: BookingStatus; scheduledAt?: Date | null; createdAt?: Date | null },
  now: Date,
): boolean {
  if (booking.status !== 'pending') return false;
  const reference = booking.scheduledAt ?? booking.createdAt;
  if (!reference) return false;
  return now.getTime() - reference.getTime() > STALE_PENDING_GRACE_MS;
}

/** Who may capture the payment of a completed booking. */
export function canCapture(
  caller: { uid: string; role?: UserRole },
  booking: { driverId?: string },
): boolean {
  return caller.role === 'admin' || (caller.role === 'driver' && booking.driverId === caller.uid);
}

/** Splits a list into chunks (Firestore batches are limited to 500 writes). */
export function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

export function formatMoney(amountMajor: number, currency: string): string {
  return `${currency.toUpperCase()} ${amountMajor.toFixed(2)}`;
}

// ---------------------------------------------------------------------------
// Free waiting time (mirrors lib/core/utils/waiting_policy.dart)
// ---------------------------------------------------------------------------

export const AIRPORT_FREE_WAIT_MIN = 60;
export const CITY_FREE_WAIT_MIN = 15;

/**
 * Airport pickups (with a flight number): 60 min from landing.
 * City pickups: 15 min from the later of the pickup time and the moment the
 * chauffeur arrived.
 */
export function freeWaitEnd(params: {
  pickup: Date;
  isAirport: boolean;
  landing?: Date | null;
  driverArrivedAt?: Date | null;
}): Date {
  const { pickup, isAirport, landing, driverArrivedAt } = params;
  if (isAirport) {
    const start = landing ?? pickup;
    return new Date(start.getTime() + AIRPORT_FREE_WAIT_MIN * 60000);
  }
  const start = driverArrivedAt && driverArrivedAt > pickup ? driverArrivedAt : pickup;
  return new Date(start.getTime() + CITY_FREE_WAIT_MIN * 60000);
}
