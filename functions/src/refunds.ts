// Refunds: Luxelane charges in Bolivianos without card processing, so a
// refund is paid outside the app (QR, bank transfer, cash or a credit on a
// company's invoice). The recordRefund callable records it on the booking,
// tells the rider and keeps the audit trail. Pure helpers for unit tests.

export const REFUND_METHODS = ['qr', 'transfer', 'cash', 'invoiceCredit'] as const;
export type RefundMethod = (typeof REFUND_METHODS)[number];

export const MAX_REASON = 300;

/** At most two decimals, tolerant of binary floating point (19.99 * 100). */
export function hasCents(v: number): boolean {
  return Math.abs(v * 100 - Math.round(v * 100)) < 1e-6;
}

export interface RefundInput {
  /** What the rider paid for the ride (final price, or the quote). */
  paid: number;
  /** Already refunded on this booking. */
  refunded: number;
  amount: unknown;
  method: unknown;
  reason: unknown;
  status: string;
  corporate: boolean;
}

/** Left to refund, in Bs with cents. */
export function refundable(paid: number, refunded: number): number {
  return Math.max(0, Math.round((paid - refunded) * 100) / 100);
}

export function refundError(r: RefundInput): string | null {
  if (r.status !== 'completed') return 'refund/not-completed';
  const amount = Number(r.amount);
  if (!Number.isFinite(amount) || amount <= 0) return 'refund/amount';
  if (!hasCents(amount)) return 'refund/amount';
  if (amount > refundable(r.paid, r.refunded)) return 'refund/too-much';
  if (!(REFUND_METHODS as readonly unknown[]).includes(r.method)) return 'refund/method';
  // Company rides are invoiced: credit the invoice; riders get money back.
  if ((r.method === 'invoiceCredit') !== r.corporate) return 'refund/method';
  if (typeof r.reason !== 'string' || r.reason.trim().length < 3) return 'refund/reason';
  return null;
}
