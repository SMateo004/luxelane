/**
 * Política de cancelación y recargo (Parte B, B3). Sin dependencias de
 * trip_flow ni de cancellation: la usan los dos.
 */
import * as admin from 'firebase-admin';
import { z } from 'zod';

// ---------------------------------------------------------------------------
// B3. Política de cancelación: config/ops.cancellationPolicy. Los valores
// los decide el responsable. Si falta, o no es válida, no se calcula ni se
// cobra ningún recargo y el evento lo anota. El recargo se guarda; NO se
// cobra (depende del proveedor de pagos, aún sin decidir).
// ---------------------------------------------------------------------------

const minutes = z.number().finite().min(0).max(100_000);

export const policySchema = z.strictObject({
  /** Gratis si se cancela dentro de estos minutos desde que se reservó. */
  freeWithinMinutesOfBooking: minutes,
  /** Gratis si faltan al menos estos minutos para la hora de recogida. */
  freeBeforePickupMinutes: minutes,
  /** Con la reserva aún sin chófer (pending), ¿hay recargo? */
  chargeWhenNoDriver: z.boolean(),
  /** fixed: importe en Bs; percent: % del precio estimado (0 a 100). */
  feeType: z.enum(['fixed', 'percent']),
  feeValue: z.number().finite().min(0).max(1_000_000),
  /** Minutos que espera el chófer en la recogida antes de «no aparece» (B4). */
  noShowWaitMinutes: minutes,
}).refine((p) => p.feeType !== 'percent' || p.feeValue <= 100, { message: 'percent > 100' });
export type CancellationPolicy = z.infer<typeof policySchema>;

export type PolicyState = 'ok' | 'missing' | 'invalid';

export function readPolicy(ops: Record<string, unknown>): { policy: CancellationPolicy | null; state: PolicyState } {
  if (ops.cancellationPolicy === undefined || ops.cancellationPolicy === null) return { policy: null, state: 'missing' };
  const r = policySchema.safeParse(ops.cancellationPolicy);
  return r.success ? { policy: r.data, state: 'ok' } : { policy: null, state: 'invalid' };
}

export type FeeBasis = 'no_policy' | 'policy_invalid' | 'payment_failed' | 'no_driver' | 'grace' | 'early' | 'late';

const round2 = (v: number) => Math.round(v * 100) / 100;
const ms = (t: unknown) => (t instanceof admin.firestore.Timestamp ? t.toMillis() : null);

/** Recargo de una cancelación del pasajero ahora (función pura). */
export function cancellationFee(policy: CancellationPolicy | null, state: PolicyState,
  b: Record<string, unknown>, now: number, reason: string): { fee: number; basis: FeeBasis } {
  if (!policy) return { fee: 0, basis: state === 'invalid' ? 'policy_invalid' : 'no_policy' };
  // La app cancela sola si la tarjeta no se pudo autorizar: sin recargo.
  if (reason === 'payment_failed' && b.status === 'pending' && !b.stripePaymentIntentId) {
    return { fee: 0, basis: 'payment_failed' };
  }
  if (b.status === 'pending' && !policy.chargeWhenNoDriver) return { fee: 0, basis: 'no_driver' };
  const created = ms(b.createdAt);
  if (created !== null && now - created <= policy.freeWithinMinutesOfBooking * 60_000) return { fee: 0, basis: 'grace' };
  const pickup = ms(b.scheduledAt);
  if (pickup !== null && pickup - now >= policy.freeBeforePickupMinutes * 60_000) return { fee: 0, basis: 'early' };
  const price = Number(b.estimatedPrice ?? 0);
  const raw = policy.feeType === 'fixed' ? policy.feeValue : (price * policy.feeValue) / 100;
  return { fee: round2(Math.min(raw, price > 0 ? price : raw)), basis: 'late' };
}

/** Hora desde la que el chófer puede marcar «no aparece» (B4); null sin política. */
export function noShowAvailableAt(policy: CancellationPolicy | null, arrivedAtMs: number): number | null {
  return policy ? arrivedAtMs + policy.noShowWaitMinutes * 60_000 : null;
}
