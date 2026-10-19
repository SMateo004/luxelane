// Programa para empresas: reglas puras (sin Firestore) que usa index.ts.
//
// Una empresa se registra (queda pendiente), un admin de Luxelane la aprueba,
// su administrador invita a empleados y estos reservan con "Cuenta de
// empresa". Nada se cobra por viaje: cada mes se genera un extracto con los
// viajes completados, el admin lo ajusta (descuentos, cargos o abonos), lo
// emite con fecha de vencimiento y lo marca pagado cuando llega el pago.

import { toCents, fromCents } from './money';

export type CompanyStatus = 'pending' | 'active' | 'suspended' | 'rejected';
export type CompanyRole = 'admin' | 'employee';
export type StatementStatus = 'draft' | 'issued' | 'paid';

/** Bolivia no cambia de horario: siempre UTC-4. */
export const LA_PAZ_OFFSET_HOURS = -4;

// ---------------------------------------------------------------------------
// Periodos mensuales ("2026-10")
// ---------------------------------------------------------------------------

export function isPeriod(p: unknown): p is string {
  return typeof p === 'string' && /^\d{4}-(0[1-9]|1[0-2])$/.test(p);
}

/** Inicio (incluido) y fin (excluido) del mes en hora de Bolivia, en ms UTC. */
export function periodBounds(period: string): { startMs: number; endMs: number } {
  const [y, m] = period.split('-').map(Number);
  const offsetMs = -LA_PAZ_OFFSET_HOURS * 3600e3; // medianoche en La Paz = 04:00 UTC
  return {
    startMs: Date.UTC(y, m - 1, 1) + offsetMs,
    endMs: Date.UTC(y, m, 1) + offsetMs,
  };
}

/** Mes (en hora de Bolivia) al que pertenece un instante. */
export function periodOf(ms: number): string {
  const d = new Date(ms + LA_PAZ_OFFSET_HOURS * 3600e3);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

/** Mes anterior al del instante dado: el que se factura el día 1. */
export function previousPeriod(nowMs: number): string {
  const [y, m] = periodOf(nowMs).split('-').map(Number);
  return m === 1 ? `${y - 1}-12` : `${y}-${String(m - 1).padStart(2, '0')}`;
}

export const statementId = (companyId: string, period: string) => `${companyId}_${period}`;

// ---------------------------------------------------------------------------
// Alta de empresa
// ---------------------------------------------------------------------------

export interface CompanyInput {
  name: string;
  taxId: string;
  billingEmail: string;
  contactName: string;
  phone: string;
  address: string;
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

/** Limpia los datos de alta; devuelve el primer error legible o los datos. */
export function validateCompanyInput(raw: Partial<Record<keyof CompanyInput, unknown>>):
  { error: string } | { data: CompanyInput } {
  const s = (v: unknown) => (typeof v === 'string' ? v.trim() : '');
  const data: CompanyInput = {
    name: s(raw.name),
    taxId: s(raw.taxId).replace(/\s+/g, ''),
    billingEmail: s(raw.billingEmail).toLowerCase(),
    contactName: s(raw.contactName),
    phone: s(raw.phone),
    address: s(raw.address),
  };
  if (data.name.length < 2 || data.name.length > 120) return { error: 'Nombre de empresa no válido.' };
  if (!/^\d{5,15}$/.test(data.taxId)) return { error: 'El NIT debe tener entre 5 y 15 dígitos.' };
  if (!EMAIL.test(data.billingEmail)) return { error: 'Correo de facturación no válido.' };
  if (data.contactName.length < 2 || data.contactName.length > 80) return { error: 'Indica la persona de contacto.' };
  const digits = data.phone.replace(/\D/g, '').length;
  if (digits < 7 || digits > 15 || data.phone.length > 20) return { error: 'Teléfono no válido.' };
  if (data.address.length < 5 || data.address.length > 200) return { error: 'Indica la dirección fiscal.' };
  return { data };
}

/** Límite mensual en Bs: null (sin límite) o un número positivo razonable. */
export function parseLimit(v: unknown): number | null | undefined {
  if (v === undefined) return undefined;
  if (v === null || v === '' || v === 0) return null;
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0 || n > 1_000_000) return undefined;
  return Math.round(n * 100) / 100;
}

// ---------------------------------------------------------------------------
// Reserva con cuenta de empresa
// ---------------------------------------------------------------------------

export interface CorporateContext {
  company?: { status?: string; monthlyBudgetBs?: number | null } | null;
  member?: { active?: boolean; monthlyLimitBs?: number | null } | null;
  userCompanyId?: string | null;
  bookingCompanyId?: string | null;
  /** Gasto del mes ya comprometido (sin esta reserva). */
  memberSpentBs: number;
  companySpentBs: number;
  priceBs: number;
}

export type CorporateRejection =
  | 'not_member'
  | 'company_inactive'
  | 'member_inactive'
  | 'member_limit'
  | 'company_budget';

/** Por qué una reserva no puede cargarse a la empresa, o null si puede. */
export function corporateRejection(c: CorporateContext): CorporateRejection | null {
  if (!c.bookingCompanyId || c.userCompanyId !== c.bookingCompanyId || !c.member) return 'not_member';
  if (c.company?.status !== 'active') return 'company_inactive';
  if (c.member.active === false) return 'member_inactive';
  const lim = c.member.monthlyLimitBs;
  if (lim != null && c.memberSpentBs + c.priceBs > lim + 0.005) return 'member_limit';
  const budget = c.company.monthlyBudgetBs;
  if (budget != null && c.companySpentBs + c.priceBs > budget + 0.005) return 'company_budget';
  return null;
}

export const CORPORATE_REJECTION_MESSAGES: Record<CorporateRejection, string> = {
  not_member: 'Tu cuenta no pertenece a esta empresa.',
  company_inactive: 'La cuenta de tu empresa no está activa. Reserva con otro método de pago.',
  member_inactive: 'Tu empresa desactivó tu acceso a la cuenta corporativa.',
  member_limit: 'Superarías tu límite mensual de la cuenta de empresa.',
  company_budget: 'Tu empresa alcanzó su presupuesto mensual.',
};

// ---------------------------------------------------------------------------
// Extracto mensual
// ---------------------------------------------------------------------------

export interface StatementBooking {
  id: string;
  status: string;
  riderId: string;
  riderName?: string;
  scheduledAtMs: number;
  completedAtMs?: number | null;
  origin?: string;
  destination?: string;
  vehicleClass?: string;
  serviceType?: string;
  costCenter?: string | null;
  estimatedPrice: number;
  finalPrice?: number | null;
}

export interface StatementLine {
  bookingId: string;
  dateMs: number;
  riderId: string;
  riderName: string;
  origin: string;
  destination: string;
  vehicleClass: string;
  serviceType: string;
  costCenter: string;
  amountBs: number;
}

export interface Adjustment {
  id: string;
  concept: string;
  amountBs: number;
}

export interface StatementTotals {
  lines: StatementLine[];
  tripCount: number;
  subtotalBs: number;
  discountPct: number;
  discountBs: number;
  adjustmentsBs: number;
  totalBs: number;
}

const round2 = (n: number) => Math.round(n * 100) / 100;

/**
 * Extracto de un mes: solo viajes completados cuya fecha de servicio cae en
 * el periodo, más el descuento pactado y los ajustes manuales del admin. El
 * total nunca es negativo (un abono mayor queda a favor y se anota aparte).
 */
export function buildStatement(
  period: string,
  bookings: StatementBooking[],
  discountPct: number,
  adjustments: Adjustment[],
  /**
   * Viajes de meses anteriores aún sin facturar (p. ej. completados después
   * de emitir su extracto) entran desde este instante; el llamador solo pasa
   * reservas sin extracto asignado.
   */
  carryFromMs?: number,
): StatementTotals {
  const { startMs, endMs } = periodBounds(period);
  const from = carryFromMs != null ? Math.min(carryFromMs, startMs) : startMs;
  const lines = bookings
    .filter((b) => b.status === 'completed')
    .map((b) => ({ b, dateMs: b.scheduledAtMs }))
    .filter(({ dateMs }) => dateMs >= from && dateMs < endMs)
    .sort((a, b) => a.dateMs - b.dateMs)
    .map(({ b, dateMs }) => ({
      bookingId: b.id,
      dateMs,
      riderId: b.riderId,
      riderName: b.riderName ?? '',
      origin: b.origin ?? '',
      destination: b.destination ?? '',
      vehicleClass: b.vehicleClass ?? 'business',
      serviceType: b.serviceType ?? 'oneWay',
      costCenter: b.costCenter ?? '',
      amountBs: round2(b.finalPrice ?? b.estimatedPrice),
    }));
  const subtotalBs = round2(lines.reduce((s, l) => s + l.amountBs, 0));
  const pct = Math.min(100, Math.max(0, discountPct || 0));
  const discountBs = round2((subtotalBs * pct) / 100);
  const adjustmentsBs = round2(adjustments.reduce((s, a) => s + a.amountBs, 0));
  const totalBs = Math.max(0, round2(subtotalBs - discountBs + adjustmentsBs));
  return { lines, tripCount: lines.length, subtotalBs, discountPct: pct, discountBs, adjustmentsBs, totalBs };
}

/**
 * Nombre legible de un lugar para el extracto: "Equipetrol · Av. …". Se
 * descarta la dirección cuando Google solo da un código plus ("6RH4+M7W, …").
 */
export function placeLabel(p?: { name?: string; address?: string } | null): string {
  const name = (p?.name ?? '').trim();
  const raw = (p?.address ?? '').trim();
  const plusCode = /^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{2,}/i.test(raw);
  const address = plusCode && name ? '' : raw;
  if (name && address && !address.startsWith(name)) return `${name} · ${address}`;
  return name || address;
}

/** Valida un ajuste manual: concepto y un importe distinto de cero. */
export function validateAdjustment(concept: unknown, amount: unknown): { error: string } | { concept: string; amountBs: number } {
  const c = typeof concept === 'string' ? concept.trim() : '';
  if (c.length < 3 || c.length > 120) return { error: 'Describe el ajuste (3 a 120 caracteres).' };
  const n = Number(amount);
  if (!Number.isFinite(n) || n === 0 || Math.abs(n) > 1_000_000) return { error: 'Importe no válido.' };
  return { concept: c, amountBs: round2(n) };
}

/**
 * Reparte el total cobrado entre los viajes del extracto (en centavos), en
 * proporción a su importe, para registrar un pago por reserva. La suma es
 * exactamente el total; el redondeo lo absorbe el último viaje.
 */
export function allocatePayment(lines: { bookingId: string; amountBs: number }[], totalBs: number): { bookingId: string; cents: number }[] {
  const subtotal = lines.reduce((s, l) => s + toCents(l.amountBs), 0);
  const total = toCents(totalBs);
  if (!lines.length) return [];
  if (subtotal === 0) return lines.map((l, i) => ({ bookingId: l.bookingId, cents: i === lines.length - 1 ? total : 0 }));
  let used = 0;
  return lines.map((l, i) => {
    const cents = i === lines.length - 1 ? total - used : Math.floor((toCents(l.amountBs) * total) / subtotal);
    used += cents;
    return { bookingId: l.bookingId, cents };
  });
}

/** Fecha de vencimiento: emisión + días de plazo (por defecto 15). */
export function dueDateMs(issuedMs: number, termsDays?: number | null): number {
  const d = Number.isInteger(termsDays) && termsDays! >= 0 && termsDays! <= 120 ? termsDays! : 15;
  return issuedMs + d * 86400e3;
}

export { fromCents };
