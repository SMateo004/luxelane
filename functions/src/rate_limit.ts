/**
 * Límites de tasa por usuario y callable. Contador de ventana fija en
 * rateLimits/{clave}__{uid}, en una transacción; solo lo escribe el
 * servidor y ningún cliente lo lee. expireAt permite una política TTL.
 *
 * Son valores de operación (proteger cuota, Stripe y fuerza bruta), no de
 * negocio: se pueden ajustar sin decisión comercial.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { logger } from './logger';

export interface RateRule {
  limit: number;
  windowSeconds: number;
  /** Si el contador falla, se deja pasar (solo el SOS). */
  failOpen?: boolean;
}

const per10min = (limit: number): RateRule => ({ limit, windowSeconds: 600 });
const perHour = (limit: number): RateRule => ({ limit, windowSeconds: 3600 });

/** Una fila por callable. Un test exige que todas las callables tengan la suya. */
export const RATE_LIMITS: Record<string, RateRule> = {
  // Se cotiza al cambiar fecha, clase u origen: margen amplio.
  quoteBooking: per10min(60),
  // Una reserva real por intento, más reintentos sin red.
  createBooking: per10min(10),
  // Pasos del viaje con reintentos sin red; un viaje usa 4.
  advanceBooking: per10min(60),
  // La tarjeta del código se recarga al volver a la pantalla.
  getPickupCode: per10min(30),
  // Además del bloqueo a los 5 fallos por reserva: frena probar en varias.
  verifyPickup: per10min(20),
  // Excepción manual del admin.
  adminOverrideVerify: perHour(30),
  // El límite de negocio (5/h, sin bloquear reabrir) sigue en incidents.ts;
  // este solo frena inundaciones y nunca bloquea si el contador falla.
  raiseIncident: { ...perHour(30), failOpen: true },
  cancelIncident: perHour(20),
  // Trabajo del panel durante una guardia.
  acknowledgeIncident: per10min(120),
  closeIncident: per10min(120),
  resolveAlert: per10min(120),
  // Llamadas a Stripe: pocas por reserva.
  createPaymentIntent: per10min(10),
  capturePayment: per10min(10),
  refundPayment: perHour(30),
  listPaymentMethods: per10min(60),
  setDefaultPaymentMethod: per10min(20),
  attachPaymentMethod: per10min(20),
  detachPaymentMethod: per10min(20),
  ensureStripeCustomer: per10min(20),
  // Irreversible: muy pocas.
  deleteAccount: perHour(3),
  // Recorre todas las reservas completadas: costosa.
  backfillSettlements: perHour(3),
  assignNearestDriver: per10min(20),
  // Con sesión; sin ella cuentan la IP seudonimizada y el correo
  // (LEAD_LIMITS en business_leads.ts).
  submitBusinessLead: perHour(5),
  // La app la llama al volver de verificar el correo.
  syncEmailVerification: per10min(20),
  // Panel: cambios de rol y bloqueos.
  setUserRole: per10min(30),
  setUserBlocked: per10min(30),
  acceptBooking: per10min(30),
};

export interface RateResult { allowed: boolean; remaining: number; resetAt: number }

export async function rateLimit(
  db: admin.firestore.Firestore,
  uid: string,
  key: string,
  limit: number,
  windowMs: number,
  now = Date.now(),
): Promise<RateResult> {
  const ref = db.collection('rateLimits').doc(`${key}__${uid}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    const start = typeof d?.windowStart === 'number' ? d.windowStart : 0;
    if (!d || start + windowMs <= now) {
      tx.set(ref, {
        uid, key, count: 1, windowStart: now,
        expireAt: admin.firestore.Timestamp.fromMillis(now + windowMs),
      });
      return { allowed: true, remaining: limit - 1, resetAt: now + windowMs };
    }
    const count = Number(d.count ?? 0);
    if (count >= limit) return { allowed: false, remaining: 0, resetAt: start + windowMs };
    tx.update(ref, { count: count + 1 });
    return { allowed: true, remaining: limit - count - 1, resetAt: start + windowMs };
  });
}

/** Punto de sustitución para las pruebas (simular un contador caído). */
export const rateLimiter = { check: rateLimit };

const exhausted = (extra: Record<string, unknown> = {}) =>
  new HttpsError('resource-exhausted', 'rate_limited', { reason: 'rate_limited', ...extra });

export async function enforceRateLimit(
  db: admin.firestore.Firestore,
  name: string,
  uid: string,
  rule: RateRule,
  now = Date.now(),
): Promise<void> {
  let result: RateResult;
  try {
    result = await rateLimiter.check(db, uid, name, rule.limit, rule.windowSeconds * 1000, now);
  } catch (e) {
    logger.error('rateLimit', 'counter unavailable', { fn: name, failOpen: rule.failOpen === true, error: String(e) });
    if (rule.failOpen) return;
    throw exhausted();
  }
  if (!result.allowed) {
    logger.warn('rateLimit', 'exceeded', { fn: name, uid });
    throw exhausted({ retryAfterSeconds: Math.max(1, Math.ceil((result.resetAt - now) / 1000)) });
  }
}
