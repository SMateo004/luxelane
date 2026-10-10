// Account suspension: admins turn users/{uid}.isActive off from the panel.
// A suspended rider can't quote or book; a suspended chauffeur is taken
// offline and can't go online or take rides. Admins are never suspended.
// A missing isActive means active (older profiles).

export const SUSPENDED = 'account/suspended';

export interface AccountLike {
  role?: string;
  isActive?: boolean;
}

export function isSuspended(user: AccountLike | undefined): boolean {
  return !!user && user.role !== 'admin' && user.isActive === false;
}

export type SuspensionChange = 'suspended' | 'reactivated' | null;

export function suspensionChange(before: AccountLike | undefined, after: AccountLike | undefined): SuspensionChange {
  const was = isSuspended(before);
  const is = isSuspended(after);
  if (!was && is) return 'suspended';
  if (was && !is && after !== undefined) return 'reactivated';
  return null;
}

/** Booking statuses where a chauffeur is committed to a ride. */
export const ASSIGNED_STATUSES = ['confirmed', 'driver_arriving', 'driver_arrived', 'in_progress'] as const;
