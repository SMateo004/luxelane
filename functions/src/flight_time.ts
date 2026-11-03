/**
 * Horas de un vuelo de llegada (prompt de vuelos, A3). Funciones puras.
 *
 * Un solo instante gobierna la recogida (decisión 1):
 *   readyAt = hora efectiva de aterrizaje + minutos de salida,
 *   hora efectiva = real si existe, si no estimada, si no programada.
 * Los minutos de salida salen de config/ops.flightExitMinutes (los carga el
 * responsable); si faltan, no se inventan: computeReadyAt devuelve null.
 *
 * Todo en UTC (milisegundos). La hora local es America/La_Paz, fija en
 * UTC-4 (Bolivia no tiene horario de verano).
 */

export const LA_PAZ_OFFSET_MS = -4 * 60 * 60 * 1000;
export const DEFAULT_TIME_ZONE = 'America/La_Paz';

export type FlightType = 'domestic' | 'international';
export type FlightStatus = 'scheduled' | 'delayed' | 'landed' | 'cancelled' | 'diverted' | 'unknown';
export const FLIGHT_STATUSES: readonly FlightStatus[] = ['scheduled', 'delayed', 'landed', 'cancelled', 'diverted', 'unknown'];

/**
 * Número de vuelo normalizado: mayúsculas, sin espacios, guiones ni puntos, y
 * sin ceros a la izquierda en la parte numérica. Regla:
 *   designador de la aerolínea: 2 caracteres (letra+letra, letra+cifra o
 *     cifra+letra) o 3 letras;
 *   número: 1 a 4 cifras que no sean todas cero (los ceros iniciales se quitan);
 *   sufijo opcional: una letra.
 * «ob 0760» → «OB760», «Z8-0301» → «Z8301», «AAL 12» → «AAL12».
 * Devuelve null si no cumple la regla («OB0000», «OB», «12345»…).
 */
export function normalizeFlightNumber(raw: string): string | null {
  const s = raw.toUpperCase().replace(/[\s.\-_/]/g, '');
  const m = /^([A-Z]{2}|[A-Z][0-9]|[0-9][A-Z]|[A-Z]{3})([0-9]{1,4})([A-Z]?)$/.exec(s);
  if (!m) return null;
  const digits = m[2].replace(/^0+/, '');
  if (digits === '') return null;
  return `${m[1]}${digits}${m[3]}`;
}

/** «2026-11-20» + «23:50» (hora local de La Paz) → instante UTC en ms. null si no es válida. */
export function localToUtcMs(flightDate: string, hhmm: string): number | null {
  const d = /^(\d{4})-(\d{2})-(\d{2})$/.exec(flightDate);
  const t = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(hhmm);
  if (!d || !t) return null;
  const [y, mo, da] = [Number(d[1]), Number(d[2]), Number(d[3])];
  const utc = Date.UTC(y, mo - 1, da, Number(t[1]), Number(t[2]));
  // Rechaza fechas que no existen (2026-02-30 se iría al 2 de marzo).
  const check = new Date(Date.UTC(y, mo - 1, da));
  if (check.getUTCFullYear() !== y || check.getUTCMonth() !== mo - 1 || check.getUTCDate() !== da) return null;
  return utc - LA_PAZ_OFFSET_MS;
}

/** Fecha local (La Paz) de un instante: «AAAA-MM-DD». */
export function localDate(ms: number): string {
  return new Date(ms + LA_PAZ_OFFSET_MS).toISOString().slice(0, 10);
}

export interface ArrivalTimes {
  scheduledArrival?: number | null;
  estimatedArrival?: number | null;
  actualArrival?: number | null;
}

/** Real si existe; si no, estimada; si no, programada. null sin ninguna. */
export function effectiveArrival(f: ArrivalTimes): number | null {
  for (const v of [f.actualArrival, f.estimatedArrival, f.scheduledArrival]) {
    if (typeof v === 'number' && Number.isFinite(v)) return v;
  }
  return null;
}

/** config/ops.flightExitMinutes: minutos desde el aterrizaje hasta salir. */
export interface FlightExitMinutes {
  domestic: { noCheckedBag: number; checkedBag: number };
  international: { noCheckedBag: number; checkedBag: number };
}

const minutesOk = (v: unknown): v is number => typeof v === 'number' && Number.isInteger(v) && v >= 0 && v <= 600;

/** Lee config/ops.flightExitMinutes; null si falta o tiene algún valor inválido. */
export function readExitMinutes(ops: Record<string, unknown>): FlightExitMinutes | null {
  const raw = ops.flightExitMinutes as Record<string, Record<string, unknown> | undefined> | undefined;
  if (!raw || typeof raw !== 'object') return null;
  const out: Partial<FlightExitMinutes> = {};
  for (const t of ['domestic', 'international'] as const) {
    const v = raw[t];
    if (!v || !minutesOk(v.noCheckedBag) || !minutesOk(v.checkedBag)) return null;
    out[t] = { noCheckedBag: v.noCheckedBag, checkedBag: v.checkedBag };
  }
  return out as FlightExitMinutes;
}

/** Minutos de salida para ese tipo y equipaje; null sin configuración. */
export function exitMinutesFor(exit: FlightExitMinutes | null, type: FlightType, hasCheckedBag: boolean): number | null {
  if (!exit) return null;
  return hasCheckedBag ? exit[type].checkedBag : exit[type].noCheckedBag;
}

/** readyAt = hora efectiva + minutos de salida. null si falta la hora o la configuración. */
export function computeReadyAt(f: ArrivalTimes & { flightType: FlightType; hasCheckedBag: boolean },
  exit: FlightExitMinutes | null): number | null {
  const arrival = effectiveArrival(f);
  const minutes = exitMinutesFor(exit, f.flightType, f.hasCheckedBag);
  if (arrival === null || minutes === null) return null;
  return arrival + minutes * 60_000;
}

/** Desde cuándo se puede marcar «no se presentó»: readyAt + espera gratuita. */
export function noShowEligibleAt(readyAt: number | null, waitMinutes: number | null | undefined): number | null {
  if (readyAt === null || typeof waitMinutes !== 'number') return null;
  return readyAt + waitMinutes * 60_000;
}
