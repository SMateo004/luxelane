// Chauffeur verification: which documents are required, when they expire and
// when a chauffeur counts as verified. Pure so it can be unit-tested.

export const DOC_TYPES = ['license', 'idCard', 'criminalRecord', 'soat', 'vehicleRegistration'] as const;
export type DocType = (typeof DOC_TYPES)[number];

export type DocStatus = 'pending' | 'approved' | 'rejected' | 'expired';

/** Documents that carry an expiry date (the rest are valid until replaced). */
export const EXPIRING: ReadonlySet<DocType> = new Set<DocType>(['license', 'idCard', 'criminalRecord', 'soat']);

/** Reminder windows before expiry, in days (largest first). */
export const REMINDER_DAYS = [30, 7] as const;

const DAY_MS = 24 * 60 * 60 * 1000;

export interface DriverDoc {
  status: DocStatus;
  expiresAt?: Date | null;
  /** Smallest reminder window already sent (30, 7…), to avoid repeats. */
  remindedDays?: number | null;
}

export function isDocType(v: unknown): v is DocType {
  return typeof v === 'string' && (DOC_TYPES as readonly string[]).includes(v);
}

export function isExpired(doc: DriverDoc, now: Date): boolean {
  return !!doc.expiresAt && doc.expiresAt.getTime() <= now.getTime();
}

/** Approved and not expired. */
export function isValid(doc: DriverDoc | undefined, now: Date): boolean {
  return !!doc && doc.status === 'approved' && !isExpired(doc, now);
}

/** A chauffeur is verified when every required document is valid. */
export function isFullyVerified(docs: Partial<Record<DocType, DriverDoc>>, now: Date): boolean {
  return DOC_TYPES.every((t) => isValid(docs[t], now));
}

/**
 * Checks an admin's approval: expiring documents need a future expiry date.
 * Returns an error code or null.
 */
export function approvalError(type: DocType, expiresAt: Date | null | undefined, now: Date): string | null {
  if (!EXPIRING.has(type)) return null;
  if (!expiresAt) return 'documents/expiry-required';
  if (expiresAt.getTime() <= now.getTime()) return 'documents/already-expired';
  return null;
}

/**
 * Which reminder (30 or 7 days) is due now for an approved document, given the
 * last one sent. Null when nothing is due.
 */
export function reminderDue(doc: DriverDoc, now: Date): number | null {
  if (doc.status !== 'approved' || !doc.expiresAt || isExpired(doc, now)) return null;
  const daysLeft = (doc.expiresAt.getTime() - now.getTime()) / DAY_MS;
  let due: number | null = null;
  for (const w of REMINDER_DAYS) if (daysLeft <= w) due = w;
  if (due === null) return null;
  if (doc.remindedDays != null && doc.remindedDays <= due) return null;
  return due;
}

export function daysLeft(expiresAt: Date, now: Date): number {
  return Math.max(0, Math.ceil((expiresAt.getTime() - now.getTime()) / DAY_MS));
}
