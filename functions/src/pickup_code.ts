/**
 * Código de recogida (4 dígitos). Nunca se guarda: se recalcula con HMAC a
 * partir del secreto PICKUP_CODE_SECRET y de una sal aleatoria por reserva
 * que solo lee el servidor. Sin el secreto no hay código (falla cerrado).
 */
import { createHmac, randomBytes, timingSafeEqual } from 'crypto';

/** Intentos fallidos antes de bloquear la verificación de la reserva. */
export const MAX_PICKUP_ATTEMPTS = 5;

/** El código vence a las 4 horas de marcar «Llegué». */
export const PICKUP_CODE_TTL_MS = 4 * 60 * 60 * 1000;

export const newPickupSalt = (): string => randomBytes(16).toString('hex');

export function pickupCode(secret: string, bookingId: string, salt: string): string {
  if (!secret) throw new Error('PICKUP_CODE_SECRET missing');
  const mac = createHmac('sha256', secret).update(`pickup:${bookingId}:${salt}`).digest();
  return String(mac.readUInt32BE(0) % 10000).padStart(4, '0');
}

/** Comparación en tiempo constante (mismo largo siempre: 4 dígitos). */
export function codesMatch(expected: string, given: string): boolean {
  const a = Buffer.from(expected.padEnd(8, ' ').slice(0, 8));
  const b = Buffer.from(given.padEnd(8, ' ').slice(0, 8));
  return timingSafeEqual(a, b) && expected.length === given.length;
}

export const pickupExpired = (arrivedAtMs: number, nowMs: number): boolean =>
  nowMs - arrivedAtMs > PICKUP_CODE_TTL_MS;
