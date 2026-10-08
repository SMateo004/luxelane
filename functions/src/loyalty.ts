// Loyalty program ("Luxelane Circle"): tiers by completed rides in the last
// 12 months, each with a discount set by Luxelane admins in config/loyalty.
// Off until an admin enables it. Pure helpers for unit tests.

export const TIER_IDS = ['silver', 'gold', 'platinum'] as const;
export type TierId = (typeof TIER_IDS)[number];

export const MAX_TIER_DISCOUNT = 20;
export const WINDOW_MS = 365 * 24 * 60 * 60 * 1000;

export interface Tier {
  id: TierId;
  minRides: number;
  discountPct: number;
}

export interface LoyaltyConfig {
  enabled: boolean;
  tiers: Tier[];
}

export const DISABLED: LoyaltyConfig = { enabled: false, tiers: [] };

/**
 * Reads config/loyalty defensively: unknown or invalid tiers are dropped and
 * the rest sorted by minRides. A config that doesn't validate is off.
 */
export function parseConfig(doc: Record<string, unknown> | undefined): LoyaltyConfig {
  if (!doc || doc.enabled !== true || !Array.isArray(doc.tiers)) return DISABLED;
  const tiers: Tier[] = [];
  for (const raw of doc.tiers as unknown[]) {
    const t = raw as Record<string, unknown>;
    const id = t?.id;
    const minRides = Number(t?.minRides);
    const discountPct = Number(t?.discountPct);
    if (!(TIER_IDS as readonly unknown[]).includes(id)) continue;
    if (!Number.isInteger(minRides) || minRides < 1) continue;
    if (!Number.isFinite(discountPct) || discountPct < 0 || discountPct > MAX_TIER_DISCOUNT) continue;
    tiers.push({ id: id as TierId, minRides, discountPct });
  }
  tiers.sort((a, b) => a.minRides - b.minRides);
  return configError(tiers) ? DISABLED : { enabled: true, tiers };
}

/** Tiers must climb: more rides and at least as much discount each step. */
export function configError(tiers: Tier[]): string | null {
  if (tiers.length === 0) return 'loyalty/no-tiers';
  for (let i = 1; i < tiers.length; i++) {
    if (tiers[i].minRides <= tiers[i - 1].minRides) return 'loyalty/thresholds-order';
    if (tiers[i].discountPct < tiers[i - 1].discountPct) return 'loyalty/discounts-order';
  }
  return null;
}

export function tierFor(rides: number, config: LoyaltyConfig): Tier | null {
  if (!config.enabled) return null;
  let current: Tier | null = null;
  for (const t of config.tiers) if (rides >= t.minRides) current = t;
  return current;
}

export function nextTier(rides: number, config: LoyaltyConfig): Tier | null {
  if (!config.enabled) return null;
  return config.tiers.find((t) => rides < t.minRides) ?? null;
}

/** Whole Bolivianos, rounded down, never above the fare. */
export function loyaltyDiscount(fare: number, tier: Tier | null): number {
  if (!tier || tier.discountPct <= 0) return 0;
  return Math.max(0, Math.min(fare, Math.floor((fare * tier.discountPct) / 100)));
}

/** Discounts don't stack: the larger one applies (promo wins ties). */
export function bestDiscount(promo: number, loyalty: number): { source: 'promo' | 'loyalty' | null; amount: number } {
  if (promo <= 0 && loyalty <= 0) return { source: null, amount: 0 };
  return promo >= loyalty ? { source: 'promo', amount: promo } : { source: 'loyalty', amount: loyalty };
}
