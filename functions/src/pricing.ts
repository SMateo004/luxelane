// Server-side pricing. Prices are in Bolivianos (BOB) and mirror
// `DefaultPricing` in lib/core/models/models.dart. Admins override them with
// /pricingRules/{vehicleClass}_{serviceType} documents.

export const CURRENCY = 'bob';
export const QUOTE_TTL_MS = 15 * 60 * 1000;
export const MIN_HOURS = 2;
export const MAX_HOURS = 24;

export const VEHICLE_CLASSES = ['business', 'firstClass', 'businessVan', 'electric'] as const;
export const SERVICE_TYPES = ['oneWay', 'byTheHour'] as const;

export type VehicleClass = (typeof VEHICLE_CLASSES)[number];
export type ServiceType = (typeof SERVICE_TYPES)[number];

export const CAPACITY: Record<VehicleClass, number> = {
  business: 3,
  firstClass: 3,
  businessVan: 7,
  electric: 3,
};

export interface PriceRule {
  base: number;
  perKm: number;
  perHour: number;
  min: number;
}

export const DEFAULT_RULES: Record<VehicleClass, Record<ServiceType, PriceRule>> = {
  business: {
    oneWay: { base: 50, perKm: 3.0, perHour: 0, min: 50 },
    byTheHour: { base: 0, perKm: 0, perHour: 80, min: 160 },
  },
  firstClass: {
    oneWay: { base: 80, perKm: 4.0, perHour: 0, min: 80 },
    byTheHour: { base: 0, perKm: 0, perHour: 120, min: 240 },
  },
  businessVan: {
    oneWay: { base: 90, perKm: 5.0, perHour: 0, min: 90 },
    byTheHour: { base: 0, perKm: 0, perHour: 150, min: 300 },
  },
  electric: {
    oneWay: { base: 60, perKm: 3.5, perHour: 0, min: 60 },
    byTheHour: { base: 0, perKm: 0, perHour: 90, min: 180 },
  },
};

export interface LatLng {
  lat: number;
  lng: number;
}

export function isVehicleClass(v: unknown): v is VehicleClass {
  return typeof v === 'string' && (VEHICLE_CLASSES as readonly string[]).includes(v);
}

export function isServiceType(v: unknown): v is ServiceType {
  return typeof v === 'string' && (SERVICE_TYPES as readonly string[]).includes(v);
}

export function isLatLng(p: unknown): p is LatLng {
  if (!p || typeof p !== 'object') return false;
  const { lat, lng } = p as Record<string, unknown>;
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Math.abs(lat) <= 90 &&
    Math.abs(lng) <= 180 &&
    !(lat === 0 && lng === 0)
  );
}

/** Great-circle distance in km. */
export function haversineKm(a: LatLng, b: LatLng): number {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Typical ratio between road distance and straight-line distance in cities. */
export const ROAD_FACTOR = 1.35;

/**
 * The client sends the Google route distance, but it can't be trusted blindly.
 * A road route can't be shorter than the straight line, and is rarely more
 * than 2.5× longer. Outside that window we fall back to an estimate.
 */
export function resolveDistanceKm(origin: LatLng, destination: LatLng, clientKm?: unknown): number {
  const straight = haversineKm(origin, destination);
  const lower = straight * 0.95;
  const upper = straight * 2.5 + 5;
  if (typeof clientKm === 'number' && Number.isFinite(clientKm) && clientKm >= lower && clientKm <= upper) {
    return round1(clientKm);
  }
  return round1(straight * ROAD_FACTOR);
}

export function clampHours(hours: unknown): number {
  const h = typeof hours === 'number' && Number.isFinite(hours) ? Math.round(hours) : MIN_HOURS;
  return Math.min(MAX_HOURS, Math.max(MIN_HOURS, h));
}

/** Price in whole Bolivianos (rounded up). */
export function computePrice(
  rule: PriceRule,
  serviceType: ServiceType,
  params: { km?: number; hours?: number },
): number {
  const raw =
    serviceType === 'byTheHour'
      ? rule.base + clampHours(params.hours) * rule.perHour
      : rule.base + (params.km ?? 0) * rule.perKm;
  return Math.ceil(Math.max(rule.min, raw));
}

/** Reads an admin rule document (fields are named *Usd but hold Bs). */
export function ruleFromDoc(doc: Record<string, unknown> | undefined, fallback: PriceRule): PriceRule {
  if (!doc) return fallback;
  const num = (k: string, d: number) => {
    const v = doc[k];
    return typeof v === 'number' && Number.isFinite(v) && v >= 0 ? v : d;
  };
  return {
    base: num('basePriceUsd', fallback.base),
    perKm: num('pricePerKmUsd', fallback.perKm),
    perHour: num('pricePerHourUsd', fallback.perHour),
    min: num('minimumPriceUsd', fallback.min),
  };
}

function round1(n: number): number {
  return Math.round(n * 10) / 10;
}
