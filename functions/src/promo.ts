// Promo codes: validation and discount math, kept pure for unit tests.
// Codes live in promoCodes/{CODE}; per-rider use in
// promoCodes/{CODE}/redemptions/{uid}.

export type PromoType = 'percent' | 'fixed';

export interface PromoDoc {
  code: string;
  type: PromoType;
  /** Percent (1–100) or Bs amount. */
  value: number;
  /** Cap for percent discounts, in Bs (0 = no cap). */
  maxDiscount?: number;
  /** Minimum fare before discount, in Bs. */
  minFare?: number;
  validFrom?: Date | null;
  validUntil?: Date | null;
  /** Total uses across all riders (0 = unlimited). */
  maxRedemptions?: number;
  redemptions?: number;
  /** Uses per rider (default 1). */
  perUserLimit?: number;
  firstRideOnly?: boolean;
  /** Empty = every class. */
  vehicleClasses?: string[];
  active: boolean;
}

export interface PromoContext {
  now: Date;
  fare: number;
  vehicleClass: string;
  /** Times this rider already used the code (active bookings). */
  userRedemptions: number;
  /** Rider has at least one completed ride. */
  hasCompletedRide: boolean;
}

export type PromoResult = { ok: true; discount: number } | { ok: false; error: string };

/** Codes are case-insensitive: stored and compared upper-case, no spaces. */
export function normalizeCode(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  const c = v.replace(/\s+/g, '').toUpperCase();
  return /^[A-Z0-9_-]{3,20}$/.test(c) ? c : null;
}

/** Rounds down to whole Bolivianos so the fare stays a round number. */
export function discountFor(promo: PromoDoc, fare: number): number {
  let d = promo.type === 'percent' ? (fare * promo.value) / 100 : promo.value;
  if (promo.type === 'percent' && promo.maxDiscount && promo.maxDiscount > 0) d = Math.min(d, promo.maxDiscount);
  d = Math.min(d, fare);
  return Math.max(0, Math.floor(d));
}

export function evaluatePromo(promo: PromoDoc | null, ctx: PromoContext): PromoResult {
  if (!promo || !promo.active) return { ok: false, error: 'promo/invalid' };
  if (promo.validFrom && ctx.now < promo.validFrom) return { ok: false, error: 'promo/not-started' };
  if (promo.validUntil && ctx.now > promo.validUntil) return { ok: false, error: 'promo/expired' };
  if (promo.maxRedemptions && (promo.redemptions ?? 0) >= promo.maxRedemptions) {
    return { ok: false, error: 'promo/exhausted' };
  }
  if (ctx.userRedemptions >= (promo.perUserLimit ?? 1)) return { ok: false, error: 'promo/already-used' };
  if (promo.firstRideOnly && ctx.hasCompletedRide) return { ok: false, error: 'promo/first-ride-only' };
  if (promo.vehicleClasses?.length && !promo.vehicleClasses.includes(ctx.vehicleClass)) {
    return { ok: false, error: 'promo/vehicle-class' };
  }
  if (promo.minFare && ctx.fare < promo.minFare) return { ok: false, error: 'promo/min-fare' };
  const discount = discountFor(promo, ctx.fare);
  if (discount <= 0) return { ok: false, error: 'promo/invalid' };
  return { ok: true, discount };
}

/** Validates an admin's promo definition. Returns an error code or null. */
export function promoDefinitionError(p: Partial<PromoDoc>): string | null {
  if (!normalizeCode(p.code)) return 'promo/bad-code';
  if (p.type !== 'percent' && p.type !== 'fixed') return 'promo/bad-type';
  const v = Number(p.value);
  if (!Number.isFinite(v) || v <= 0) return 'promo/bad-value';
  if (p.type === 'percent' && v > 100) return 'promo/bad-value';
  if (p.validFrom && p.validUntil && p.validUntil <= p.validFrom) return 'promo/bad-dates';
  return null;
}
