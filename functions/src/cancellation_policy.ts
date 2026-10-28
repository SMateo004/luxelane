/**
 * Política de cancelación con retención (pagos, A7). Sustituye a la de B3.
 * Sin dependencias de trip_flow ni de cancellation: la usan los dos.
 *
 * config/ops.cancellationPolicy es una lista de etapas
 * {fromStatus, percent, graceMinutes?}. Los porcentajes los pone el
 * responsable; aquí solo se validan (0 a 100).
 *
 * - Antes de asignar chófer: siempre 0 % (no es configurable).
 * - Etapas configurables: chófer asignado (confirmed), en camino
 *   (driver_arriving), llegado (driver_arrived) y no se presentó (no_show).
 * - graceMinutes: minutos desde que la reserva entró en esa etapa durante
 *   los que la retención es 0 %.
 * - Sin política (o no válida): 0 % en todo y el evento lo anota.
 * - Cancelaciones por causa del chófer, del sistema o de la plataforma:
 *   siempre 0 %.
 *
 * La retención es porcentaje × importe PAGADO, redondeada a favor del
 * cliente (hacia abajo, al céntimo) y nunca mayor que lo pagado.
 */
import { z } from 'zod';

const minutes = z.number().finite().min(0).max(100_000);

/** Etapas con chófer en las que puede haber retención. */
export const RETENTION_STAGES = ['confirmed', 'driver_arriving', 'driver_arrived', 'no_show'] as const;
export type RetentionStage = (typeof RETENTION_STAGES)[number];

export const stageSchema = z.strictObject({
  fromStatus: z.enum(RETENTION_STAGES),
  percent: z.number().finite().min(0).max(100),
  graceMinutes: minutes.optional(),
});

export const policySchema = z.strictObject({
  stages: z.array(stageSchema).max(RETENTION_STAGES.length)
    .refine((s) => new Set(s.map((x) => x.fromStatus)).size === s.length, { message: 'etapa repetida' }),
  /** Minutos que espera el chófer en la recogida antes de «no se presentó» (B4). */
  noShowWaitMinutes: minutes.optional(),
});
export type CancellationPolicy = z.infer<typeof policySchema>;

export type PolicyState = 'ok' | 'missing' | 'invalid';

export function readPolicy(ops: Record<string, unknown>): { policy: CancellationPolicy | null; state: PolicyState } {
  if (ops.cancellationPolicy === undefined || ops.cancellationPolicy === null) return { policy: null, state: 'missing' };
  const r = policySchema.safeParse(ops.cancellationPolicy);
  return r.success ? { policy: r.data, state: 'ok' } : { policy: null, state: 'invalid' };
}

/** Quién causa la cancelación. Solo la del pasajero puede retener. */
export type CancelCause = 'rider' | 'driver' | 'system' | 'platform';

export type RetentionBasis =
  | 'no_policy' | 'policy_invalid' | 'no_driver' | 'no_stage' | 'grace' | 'stage'
  | 'driver_cause' | 'system_cause' | 'platform_cause';

export interface RetentionInput {
  status: string;
  cause: CancelCause;
  /** Cuándo entró la reserva en su estado actual (ms); null si no se sabe. */
  stageEnteredMs: number | null;
  now: number;
}

/** Porcentaje que se retiene y por qué (función pura). */
export function retentionFor(policy: CancellationPolicy | null, state: PolicyState, i: RetentionInput):
  { percent: number; basis: RetentionBasis } {
  if (i.cause !== 'rider') return { percent: 0, basis: `${i.cause}_cause` as RetentionBasis };
  if (!policy) return { percent: 0, basis: state === 'invalid' ? 'policy_invalid' : 'no_policy' };
  if (!(RETENTION_STAGES as readonly string[]).includes(i.status)) return { percent: 0, basis: 'no_driver' };
  const stage = policy.stages.find((s) => s.fromStatus === i.status);
  if (!stage) return { percent: 0, basis: 'no_stage' };
  // Sin hora de entrada en la etapa no se puede medir la gracia: a favor del
  // cliente, se considera dentro de ella.
  if (stage.graceMinutes !== undefined &&
    (i.stageEnteredMs === null || i.now - i.stageEnteredMs <= stage.graceMinutes * 60_000)) {
    return { percent: 0, basis: 'grace' };
  }
  return { percent: stage.percent, basis: 'stage' };
}

/**
 * Céntimos retenidos: porcentaje del importe pagado, hacia abajo (a favor
 * del cliente) y nunca más que lo pagado.
 */
export function retainedCents(paidCents: number, percent: number): number {
  const paid = Math.max(0, Math.floor(paidCents));
  const raw = Math.floor((paid * percent) / 100 + 1e-9);
  return Math.min(paid, Math.max(0, raw));
}

/** Hora desde la que el chófer puede marcar «no aparece» (B4); null sin política o sin espera. */
export function noShowAvailableAt(policy: CancellationPolicy | null, arrivedAtMs: number): number | null {
  return policy && policy.noShowWaitMinutes !== undefined ? arrivedAtMs + policy.noShowWaitMinutes * 60_000 : null;
}
