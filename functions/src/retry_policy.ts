/**
 * Triggers con `retry: true`: la plataforma repite el evento mientras el
 * handler falle (hasta 7 días). Solo merece la pena repetir lo que puede
 * salir bien la próxima vez; lo demás se registra y se da por terminado,
 * para no generar ruido ni costo.
 *
 * Transitorio (se relanza y se reintenta):
 *  - Firestore/gRPC: DEADLINE_EXCEEDED (4), RESOURCE_EXHAUSTED (8),
 *    ABORTED (10), INTERNAL (13), UNAVAILABLE (14), o sus nombres.
 *  - FCM: messaging/server-unavailable, messaging/internal-error,
 *    messaging/quota-exceeded (y messaging/message-rate-exceeded).
 *  - Red: ECONNRESET, ETIMEDOUT, EAI_AGAIN, ECONNREFUSED, ENOTFOUND.
 * Permanente (se registra y no se relanza): todo lo demás, p. ej. datos
 * inválidos (INVALID_ARGUMENT 3), documento inexistente (NOT_FOUND 5),
 * permisos (7), índice que falta (FAILED_PRECONDITION 9), argumentos de FCM
 * inválidos, o un error de programación (TypeError…): repetir no lo arregla.
 */
import { logger } from './logger';

const TRANSIENT_GRPC = new Set([4, 8, 10, 13, 14]);
const TRANSIENT_NAMES = new Set([
  'deadline-exceeded', 'resource-exhausted', 'aborted', 'internal', 'unavailable',
  'messaging/server-unavailable', 'messaging/internal-error',
  'messaging/quota-exceeded', 'messaging/message-rate-exceeded',
  'ECONNRESET', 'ETIMEDOUT', 'EAI_AGAIN', 'ECONNREFUSED', 'ENOTFOUND',
]);

export function isTransient(e: unknown): boolean {
  if (!e || typeof e !== 'object') return false;
  const err = e as { code?: unknown; errorInfo?: { code?: unknown } };
  const code = err.code ?? err.errorInfo?.code;
  if (typeof code === 'number') return TRANSIENT_GRPC.has(code);
  return typeof code === 'string' && TRANSIENT_NAMES.has(code);
}

/**
 * Ejecuta el cuerpo de un trigger con reintento: relanza solo errores
 * transitorios; los permanentes quedan en el log como error y el evento se
 * da por procesado.
 */
export async function withRetryPolicy(fn: string, ctx: Record<string, unknown>, body: () => Promise<void>): Promise<void> {
  try {
    await body();
  } catch (e) {
    if (isTransient(e)) {
      logger.warn(fn, 'transient error, will retry', { ...ctx, error: String(e) });
      throw e;
    }
    logger.error(fn, 'permanent error, not retried', { ...ctx, error: String(e) });
  }
}
