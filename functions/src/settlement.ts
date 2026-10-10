// Reparto de cada viaje completado entre la plataforma y el chófer.
//
// Se calcula en servidor y se guarda en `bookings/{id}.settlement`, así la app
// del chófer y el panel admin muestran exactamente las mismas cifras, aunque
// el chófer no pueda leer la comisión (config/finance es solo para el admin).

export const DEFAULT_COMMISSION_PCT = 20;

export interface Settlement {
  amount: number;
  commissionPct: number;
  platformCommission: number;
  driverPayout: number;
}

interface SettlementInput {
  status?: string;
  estimatedPrice?: number;
  finalPrice?: number | null;
  settlement?: Settlement | null;
}

const round2 = (v: number): number => Math.round(v * 100) / 100;

export function clampPct(v: unknown): number {
  const n = typeof v === 'number' && Number.isFinite(v) ? v : DEFAULT_COMMISSION_PCT;
  return Math.min(100, Math.max(0, n));
}

/**
 * Reparto que debe tener la reserva, o null si no hay que escribir nada
 * (no está completada o ya tiene el reparto de su importe actual).
 *
 * La comisión queda fijada al completarse: si luego el admin ajusta el precio
 * final se recalcula el reparto con el mismo porcentaje, no con el vigente.
 */
export function computeSettlement(
  booking: SettlementInput,
  currentCommissionPct: number,
): Settlement | null {
  if (booking.status !== 'completed') return null;
  const amount = round2(Number(booking.finalPrice ?? booking.estimatedPrice ?? 0));
  const prev = booking.settlement;
  if (prev && prev.amount === amount) return null;

  const commissionPct = clampPct(prev?.commissionPct ?? currentCommissionPct);
  const platformCommission = round2((amount * commissionPct) / 100);
  return {
    amount,
    commissionPct,
    platformCommission,
    driverPayout: round2(amount - platformCommission),
  };
}
