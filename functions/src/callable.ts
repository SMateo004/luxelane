/**
 * Único punto de entrada de las callables: App Check (en dos fases con
 * APP_CHECK_ENFORCE), límites de tasa y traducción de errores. Un test
 * estático (callable_security.test.ts) falla si alguna callable exportada
 * no pasa por aquí.
 */
import * as admin from 'firebase-admin';
import { CallableOptions, CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { defineBoolean } from 'firebase-functions/params';
import { toClientError } from './errors';
import { logger } from './logger';
import { requireRole, Role } from './identity';
import { enforceRateLimit, RATE_LIMITS } from './rate_limit';

/**
 * false: se registra si llegó un token válido de App Check (para ver las
 * métricas antes de imponerlo). true: sin token válido se rechaza.
 *
 * firebase-functions 5.1.1 solo acepta un booleano fijo en
 * `enforceAppCheck`, así que la imposición se hace aquí, en tiempo de
 * ejecución: el SDK deja `req.app` vacío si el token falta o no es válido.
 */
export const APP_CHECK_ENFORCE = defineBoolean('APP_CHECK_ENFORCE', { default: false });

export interface SecureMeta {
  name: string;
  role?: Role;
}

/** Marca de las callables que pasan por secureCallable (la mira el test). */
export const SECURED_MARK = '__luxelaneSecured';

/** Registra el resultado de App Check y, si se impone, rechaza sin token. */
export function appCheckGate(name: string, req: Pick<CallableRequest, 'app'>, enforce: boolean): void {
  const valid = req.app !== undefined;
  // Solo el nombre de la función y el resultado: nada personal.
  if (valid) logger.info('appCheck', 'token', { fn: name, appCheck: 'valid' });
  else logger.warn('appCheck', 'token', { fn: name, appCheck: 'missing', enforced: enforce });
  if (!valid && enforce) {
    throw new HttpsError('unauthenticated', 'app_check_required', { reason: 'app_check_required' });
  }
}

function enforcing(): boolean {
  try {
    return APP_CHECK_ENFORCE.value();
  } catch {
    return false;
  }
}

/** Exigencias de identidad de una callable (Parte B). */
export interface SecurityOptions {
  /** Rol exigido: del claim (o de Firestore en la transición), con isActive. */
  role?: Role;
}

export function secureCallable<T>(
  name: string,
  opts: CallableOptions,
  handler: (req: CallableRequest) => T | Promise<T>,
  security: SecurityOptions = {},
) {
  const fn = onCall(opts, async (req) => {
    try {
      appCheckGate(name, req, enforcing());
      // Sin sesión no hay a quién contar: el handler responde unauthenticated.
      const rule = RATE_LIMITS[name];
      if (rule && req.auth?.uid) await enforceRateLimit(admin.firestore(), name, req.auth.uid, rule);
      if (security.role) {
        await requireRole(admin.firestore(), req.auth as { uid: string; token: Record<string, unknown> } | undefined, security.role);
      }
      return await handler(req);
    } catch (e) {
      // Al cliente solo un código permitido y un motivo corto.
      throw toClientError(name, e);
    }
  });
  Object.defineProperty(fn, SECURED_MARK, { value: { name, ...security } satisfies SecureMeta });
  return fn;
}
