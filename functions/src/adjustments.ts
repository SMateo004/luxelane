// Price adjustments: extra charges agreed during a ride (waiting beyond the
// free time, tolls, parking, an extra stop) or a correction, added by an
// admin. The booking keeps the quoted price (estimatedPrice) and the list of
// adjustments; finalPrice = quote + adjustments, which receipts, reports,
// company statements and chauffeur settlements already use. Pure helpers.

import { hasCents } from './refunds';

export const ADJUSTMENT_TYPES = ['waiting', 'toll', 'parking', 'extraStop', 'correction'] as const;
export type AdjustmentType = (typeof ADJUSTMENT_TYPES)[number];

/** Largest single adjustment, in Bs (a typo guard, not a business rule). */
export const MAX_ADJUSTMENT = 2000;
export const MAX_NOTE = 200;

/** From the chauffeur's arrival until the ride is completed. */
export const ADJUSTABLE_STATUSES = ['driver_arrived', 'in_progress', 'completed'];

export interface AdjustmentInput {
  status: string;
  /** Quoted price. */
  base: number;
  /** Sum of the adjustments already on the booking. */
  adjusted: number;
  refunded: number;
  /** A card payment can't be charged more after capture. */
  cardPayment: boolean;
  type: unknown;
  amount: unknown;
  note: unknown;
}

export function round2(v: number): number {
  return Math.round(v * 100) / 100;
}

export function adjustmentError(a: AdjustmentInput): string | null {
  if (!ADJUSTABLE_STATUSES.includes(a.status)) return 'adjust/status';
  if (a.cardPayment) return 'adjust/card';
  if (!(ADJUSTMENT_TYPES as readonly unknown[]).includes(a.type)) return 'adjust/type';
  const amount = Number(a.amount);
  if (!Number.isFinite(amount) || amount === 0 || !hasCents(amount)) return 'adjust/amount';
  if (Math.abs(amount) > MAX_ADJUSTMENT) return 'adjust/amount';
  // Only a correction lowers the price (refunds are recorded separately).
  if (amount < 0 && a.type !== 'correction') return 'adjust/amount';
  const total = round2(a.base + a.adjusted + amount);
  if (total < 0 || total < a.refunded) return 'adjust/below-zero';
  const note = typeof a.note === 'string' ? a.note.trim() : '';
  if (a.type === 'correction' && note.length < 3) return 'adjust/note';
  return null;
}
