/**
 * Tarifa de una reserva, sin I/O: la usan quoteBooking y createBooking.
 * Todos los valores de negocio llegan como parámetros (pricingRules y
 * config/pricing); si falta alguno necesario, el cálculo falla cerrado.
 */
import type { FareRule } from './pricing';

export const VEHICLE_CLASSES = ['business', 'firstClass', 'businessVan', 'electric', 'businessSuv'] as const;
export const SERVICE_TYPES = ['oneWay', 'byTheHour'] as const;

/** Recargos opcionales (config/pricing). Sin el campo, no se aplican. */
export interface PricingConfig {
  routeFactor?: number;
  nightSurchargePct?: number;
  nightStartHour?: number;
  nightEndHour?: number;
  /** Clave `${iata}|${ciudad}|${clase}` → importe fijo en Bs. */
  fixedAirportFares?: Record<string, number>;
}

export interface FareInput {
  vehicleClass: string;
  serviceType: string;
  /** Distancia del trayecto (traslados). */
  km?: number;
  /** Horas contratadas (por horas). */
  hours?: number;
  /** Hora local de la recogida, 0–23. */
  localHour: number;
  /** Traslado desde o hacia un aeropuerto, con la ciudad del otro extremo. */
  airportTrip?: { iata: string; city: string } | null;
}

export interface FareBreakdown {
  base: number;
  km: number | null;
  perKm: number;
  hours: number | null;
  perHour: number;
  minimum: number;
  minimumApplied: boolean;
  fixedAirportFare: number | null;
  nightSurchargePct: number | null;
  subtotal: number;
  total: number;
}

export type FareError =
  | 'unknown_class'
  | 'unknown_service'
  | 'pricing_unavailable'
  | 'class_unavailable'
  | 'invalid_hours'
  | 'missing_distance';

export type FareResult =
  | { ok: true; price: number; breakdown: FareBreakdown }
  | { ok: false; error: FareError };

const isNum = (v: unknown): v is number => typeof v === 'number' && Number.isFinite(v);
const nonNegative = (v: unknown): v is number => isNum(v) && v >= 0;

/** Bs enteros, siempre hacia arriba (sin arrastrar errores de coma flotante). */
export const roundUpBs = (v: number): number => Math.ceil(Math.round(v * 100) / 100);

export const fixedFareKey = (iata: string, city: string, vehicleClass: string): string =>
  `${iata}|${city}|${vehicleClass}`;

function nightPct(config: PricingConfig, hour: number): number | null {
  const { nightSurchargePct: pct, nightStartHour: start, nightEndHour: end } = config;
  const validHour = (h: unknown) => Number.isInteger(h) && (h as number) >= 0 && (h as number) <= 23;
  if (!isNum(pct) || pct <= 0 || !validHour(start) || !validHour(end) || start === end) return null;
  const inWindow = start! < end! ? hour >= start! && hour < end! : hour >= start! || hour < end!;
  return inWindow ? pct : null;
}

export function computeFare(input: FareInput, rule: FareRule | undefined, config: PricingConfig): FareResult {
  if (!(VEHICLE_CLASSES as readonly string[]).includes(input.vehicleClass)) {
    return { ok: false, error: 'unknown_class' };
  }
  if (!(SERVICE_TYPES as readonly string[]).includes(input.serviceType)) {
    return { ok: false, error: 'unknown_service' };
  }
  if (!rule || ![rule.basePriceUsd, rule.pricePerKmUsd, rule.pricePerHourUsd, rule.minimumPriceUsd].every(nonNegative)) {
    return { ok: false, error: 'pricing_unavailable' };
  }
  if (rule.isActive === false) return { ok: false, error: 'class_unavailable' };

  const hourly = input.serviceType === 'byTheHour';
  let raw: number;
  let fixed: number | null = null;
  if (hourly) {
    if (!Number.isInteger(input.hours) || (input.hours as number) < 1) return { ok: false, error: 'invalid_hours' };
    raw = rule.basePriceUsd + input.hours! * rule.pricePerHourUsd;
  } else {
    const trip = input.airportTrip;
    const f = trip ? config.fixedAirportFares?.[fixedFareKey(trip.iata, trip.city, input.vehicleClass)] : undefined;
    if (isNum(f) && f > 0) {
      fixed = f;
      raw = f;
    } else {
      if (!nonNegative(input.km)) return { ok: false, error: 'missing_distance' };
      raw = rule.basePriceUsd + input.km * rule.pricePerKmUsd;
    }
  }

  // El mínimo de la tarifa no se aplica a una tarifa fija de aeropuerto.
  const minimumApplied = fixed === null && raw < rule.minimumPriceUsd;
  const subtotal = minimumApplied ? rule.minimumPriceUsd : raw;
  const night = nightPct(config, input.localHour);
  const total = night === null ? subtotal : subtotal * (1 + night / 100);
  const price = roundUpBs(total);

  return {
    ok: true,
    price,
    breakdown: {
      base: rule.basePriceUsd,
      km: hourly ? null : input.km ?? null,
      perKm: rule.pricePerKmUsd,
      hours: hourly ? input.hours! : null,
      perHour: rule.pricePerHourUsd,
      minimum: rule.minimumPriceUsd,
      minimumApplied,
      fixedAirportFare: fixed,
      nightSurchargePct: night,
      subtotal,
      total: price,
    },
  };
}
