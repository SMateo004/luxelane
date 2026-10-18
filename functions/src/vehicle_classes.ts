// Vehicle types: what each one costs and carries. Built-in types have the
// defaults below; an admin document in vehicleClasses/{id} (written only by
// the saveVehicleClass callable) overrides them, and new ids add new types.
// Mirrors lib/core/vehicles/vehicle_catalog.dart.
import { DEFAULT_RULES, PriceRule, ServiceType, SERVICE_TYPES } from './pricing';
import type { Lang } from './messages';

export const LANGS: Lang[] = ['es', 'en', 'pt'];
export const ID_PATTERN = /^[a-zA-Z][a-zA-Z0-9_-]{1,39}$/;
export const ICONS = ['car', 'star', 'van', 'electric', 'suv'] as const;
const MAX_PRICE = 100000;
const MAX_SLIDES = 8;

export function isVehicleClassId(v: unknown): v is string {
  return typeof v === 'string' && ID_PATTERN.test(v);
}

type Texts = Partial<Record<Lang, string>>;

export interface ResolvedVehicleClass {
  id: string;
  active: boolean;
  capacity: number;
  name: Texts;
  services: Partial<Record<ServiceType, PriceRule>>;
}

interface BuiltIn {
  name: Texts;
  capacity: number;
  active: boolean;
}

export const BUILT_IN: Record<string, BuiltIn> = {
  business: { name: { es: 'Business Class', en: 'Business Class', pt: 'Business Class' }, capacity: 3, active: true },
  firstClass: { name: { es: 'First Class', en: 'First Class', pt: 'First Class' }, capacity: 3, active: true },
  businessVan: { name: { es: 'Business Van', en: 'Business Van', pt: 'Business Van' }, capacity: 7, active: true },
  // Not offered to riders until an admin turns it on (as before the catalog).
  electric: { name: { es: 'Eléctrico', en: 'Electric', pt: 'Elétrico' }, capacity: 3, active: false },
};

export function nameIn(cls: ResolvedVehicleClass | null, id: string, lang: Lang): string {
  return cls?.name[lang] ?? cls?.name.es ?? id;
}

function num(v: unknown): number | null {
  return typeof v === 'number' && Number.isFinite(v) && v >= 0 && v <= MAX_PRICE ? v : null;
}

function rule(v: unknown): PriceRule | null {
  if (!v || typeof v !== 'object') return null;
  const r = v as Record<string, unknown>;
  const min = num(r.min);
  if (min === null) return null;
  return { base: num(r.base) ?? 0, perKm: num(r.perKm) ?? 0, perHour: num(r.perHour) ?? 0, min };
}

function texts(v: unknown): Texts {
  const out: Texts = {};
  if (v && typeof v === 'object') {
    for (const l of LANGS) {
      const s = (v as Record<string, unknown>)[l];
      if (typeof s === 'string' && s.trim()) out[l] = s.trim();
    }
  }
  return out;
}

/**
 * The type in effect for [id]: the admin document if there is one, else the
 * built-in defaults (with any old pricingRules/{id}_{service} overrides,
 * read with [legacyRule]). Null when the id is unknown.
 */
export function resolveVehicleClass(
  id: string,
  doc: Record<string, unknown> | undefined,
  legacyRule: (st: ServiceType, fallback: PriceRule) => PriceRule,
): ResolvedVehicleClass | null {
  if (doc) {
    const services: Partial<Record<ServiceType, PriceRule>> = {};
    const raw = (doc.services ?? {}) as Record<string, unknown>;
    for (const st of SERVICE_TYPES) {
      const r = rule(raw[st]);
      if (r) services[st] = r;
    }
    const cap = Number(doc.capacity);
    return {
      id,
      active: doc.active === true,
      capacity: Number.isInteger(cap) && cap >= 1 && cap <= 60 ? cap : BUILT_IN[id]?.capacity ?? 3,
      name: { ...BUILT_IN[id]?.name, ...texts(doc.name) },
      services,
    };
  }
  const b = BUILT_IN[id];
  if (!b) return null;
  const defaults = DEFAULT_RULES[id as keyof typeof DEFAULT_RULES];
  return {
    id,
    active: b.active,
    capacity: b.capacity,
    name: b.name,
    services: {
      oneWay: legacyRule('oneWay', defaults.oneWay),
      byTheHour: legacyRule('byTheHour', defaults.byTheHour),
    },
  };
}

export type SaveResult = { ok: true; doc: Record<string, unknown> } | { ok: false; error: string };

/** Checks what an admin sends to saveVehicleClass; returns the document to store. */
export function validateVehicleClassInput(id: unknown, input: unknown): SaveResult {
  if (!isVehicleClassId(id)) return { ok: false, error: 'vehicle/id' };
  if (!input || typeof input !== 'object') return { ok: false, error: 'vehicle/data' };
  const d = input as Record<string, unknown>;

  const name = texts(d.name);
  if (LANGS.some((l) => !name[l])) return { ok: false, error: 'vehicle/name' };
  const description = texts(d.description);
  if (Object.values(name).some((s) => s.length > 40) || Object.values(description).some((s) => s.length > 120)) {
    return { ok: false, error: 'vehicle/length' };
  }

  const int = (v: unknown, min: number, max: number) => (Number.isInteger(v) && (v as number) >= min && (v as number) <= max ? (v as number) : null);
  const capacity = int(d.capacity, 1, 60);
  const carryOn = int(d.carryOn, 0, 60);
  const checked = int(d.checked, 0, 60);
  const extraLarge = int(d.extraLarge, 0, 60);
  const order = int(d.order, 0, 9999);
  if (capacity === null || carryOn === null || checked === null || extraLarge === null || order === null) {
    return { ok: false, error: 'vehicle/numbers' };
  }
  if (typeof d.active !== 'boolean' || typeof d.childSeat !== 'boolean') return { ok: false, error: 'vehicle/data' };
  if (typeof d.icon !== 'string' || !(ICONS as readonly string[]).includes(d.icon)) return { ok: false, error: 'vehicle/icon' };
  if (typeof d.color !== 'string' || !/^#[0-9A-Fa-f]{6}$/.test(d.color)) return { ok: false, error: 'vehicle/color' };

  const https = (v: unknown) => typeof v === 'string' && /^https:\/\/\S{1,1000}$/.test(v);
  if (d.imageUrl !== undefined && d.imageUrl !== null && !https(d.imageUrl)) return { ok: false, error: 'vehicle/image' };
  const slidesIn = Array.isArray(d.slides) ? d.slides : [];
  if (slidesIn.length > MAX_SLIDES) return { ok: false, error: 'vehicle/slides' };
  const slides = [];
  for (const s of slidesIn) {
    const o = (s ?? {}) as Record<string, unknown>;
    if (!https(o.url)) return { ok: false, error: 'vehicle/image' };
    const caption = texts(o.caption);
    if (Object.values(caption).some((c) => c.length > 120)) return { ok: false, error: 'vehicle/length' };
    slides.push({ url: o.url as string, caption });
  }

  const services: Record<string, PriceRule> = {};
  const raw = (d.services ?? {}) as Record<string, unknown>;
  for (const st of SERVICE_TYPES) {
    if (raw[st] === undefined || raw[st] === null) continue;
    const r = rule(raw[st]);
    if (!r || r.min <= 0) return { ok: false, error: 'vehicle/price' };
    if (st === 'byTheHour' && r.perHour <= 0) return { ok: false, error: 'vehicle/price' };
    services[st] = r;
  }
  if (!Object.keys(services).length) return { ok: false, error: 'vehicle/services' };

  return {
    ok: true,
    doc: {
      name,
      description,
      active: d.active,
      order,
      capacity,
      carryOn,
      checked,
      extraLarge,
      childSeat: d.childSeat,
      icon: d.icon,
      color: d.color.toUpperCase(),
      imageUrl: https(d.imageUrl) ? d.imageUrl : null,
      slides,
      services,
    },
  };
}
