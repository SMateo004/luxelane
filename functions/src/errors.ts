/**
 * Errores de las callables. Al cliente solo llegan siete códigos y un
 * motivo corto (details.reason); nunca mensajes de Stripe, Firestore o
 * zod, ni trazas. secureCallable pasa todo error por toClientError.
 */
import { FunctionsErrorCode, HttpsError } from 'firebase-functions/v2/https';
import { logger } from './logger';

/** Código canónico (el que ve el SDK) → código que documentamos al cliente. */
export const CLIENT_CODES = {
  'invalid-argument': 'invalid_request',
  unauthenticated: 'unauthenticated',
  'permission-denied': 'permission_denied',
  'failed-precondition': 'failed_precondition',
  'resource-exhausted': 'resource_exhausted',
  'not-found': 'not_found',
  internal: 'internal',
} as const;

type AllowedCode = keyof typeof CLIENT_CODES;
export type ClientCode = (typeof CLIENT_CODES)[AllowedCode];

/** Los demás códigos se pliegan a uno permitido; si no, internal. */
const FOLD: Partial<Record<FunctionsErrorCode, AllowedCode>> = {
  'already-exists': 'failed-precondition',
  aborted: 'failed-precondition',
  'out-of-range': 'invalid-argument',
};

/** Motivo corto en minúsculas: nunca texto libre. */
const TOKEN = /^[a-z][a-z0-9_-]{0,63}$/;
const isToken = (v: unknown): v is string => typeof v === 'string' && TOKEN.test(v);
const isNum = (v: unknown): v is number => typeof v === 'number' && Number.isFinite(v);

/** Únicos datos extra que pueden viajar al cliente, con su forma. */
const SAFE_DETAILS: Record<string, (v: unknown) => boolean> = {
  fields: (v) => Array.isArray(v) && v.length <= 20 &&
    v.every((f) => typeof f === 'string' && /^[\p{L}0-9_.()]{1,64}$/u.test(f)),
  price: isNum,
  attemptsLeft: isNum,
  retryAfterSeconds: isNum,
  minAppVersion: (v) => typeof v === 'string' && /^\d{1,4}(\.\d{1,4}){0,3}$/.test(v),
  androidStoreUrl: (v) => typeof v === 'string' && v.startsWith('https://') && v.length <= 500,
  iosStoreUrl: (v) => typeof v === 'string' && v.startsWith('https://') && v.length <= 500,
  from: isToken,
  to: isToken,
  status: isToken,
};

function allowedCode(code: FunctionsErrorCode): AllowedCode {
  if (code in CLIENT_CODES) return code as AllowedCode;
  return FOLD[code] ?? 'internal';
}

/**
 * Lo único que ve el cliente: código permitido, mensaje = código del
 * cliente y details con `code`, `reason` y los campos de SAFE_DETAILS.
 */
export function toClientError(fn: string, e: unknown): HttpsError {
  if (!(e instanceof HttpsError)) {
    // Error inesperado (Stripe, Firestore, un fallo de código): al log,
    // tachado; al cliente, internal sin más.
    logger.error(fn, 'unexpected error', { error: e });
    return clientError('internal', 'internal');
  }
  const code = allowedCode(e.code);
  const raw = (e.details && typeof e.details === 'object' ? e.details : {}) as Record<string, unknown>;
  if (code === 'internal' || e.code !== code) {
    logger.error(fn, 'internal error', { code: e.code, error: e.message, reason: raw.reason });
  }
  const reason = code === 'internal' && raw.reason !== 'payment_failed'
    ? 'internal'
    : isToken(raw.reason) ? raw.reason : isToken(e.message) ? e.message : CLIENT_CODES[code];
  const extra: Record<string, unknown> = {};
  for (const [k, ok] of Object.entries(SAFE_DETAILS)) if (ok(raw[k])) extra[k] = raw[k];
  return clientError(code, reason, extra);
}

function clientError(code: AllowedCode, reason: string, extra: Record<string, unknown> = {}): HttpsError {
  return new HttpsError(code, CLIENT_CODES[code], { code: CLIENT_CODES[code], reason, ...extra });
}

// Ayudas de los handlers: el argumento es el motivo corto (details.reason).

const withReason = (code: AllowedCode, reason: string) => new HttpsError(code, reason, { reason });

export function unauthenticated(reason = 'unauthenticated'): HttpsError {
  return withReason('unauthenticated', reason);
}

export function permissionDenied(reason = 'permission_denied'): HttpsError {
  return withReason('permission-denied', reason);
}

export function invalidArgument(reason: string): HttpsError {
  return withReason('invalid-argument', reason);
}

export function notFound(reason = 'not_found'): HttpsError {
  return withReason('not-found', reason);
}

export function failedPrecondition(reason: string): HttpsError {
  return withReason('failed-precondition', reason);
}

export function internal(): HttpsError {
  return withReason('internal', 'internal');
}

/** El pago falló en Stripe. El detalle va al log del servidor, no aquí. */
export function paymentFailed(): HttpsError {
  return withReason('internal', 'payment_failed');
}
