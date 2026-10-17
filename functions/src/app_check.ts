// Firebase App Check for callables: proves a call comes from the real rider,
// chauffeur or web app, not a script holding a stolen ID token.
//
// Rollout without locking anyone out: by default calls without a valid App
// Check token are only logged ("appcheck/missing"); once the logs show every
// client sends one, set APP_CHECK_ENFORCE=true (functions/.env) and redeploy.
import { CallableOptions, CallableRequest, HttpsError, onCall as rawOnCall } from 'firebase-functions/v2/https';
import { logger } from './logger';

export type AppCheckDecision = 'ok' | 'log' | 'reject';

export function appCheckDecision(hasToken: boolean, enforced: boolean): AppCheckDecision {
  if (hasToken) return 'ok';
  return enforced ? 'reject' : 'log';
}

export function appCheckEnforced(env: NodeJS.ProcessEnv = process.env): boolean {
  return env.APP_CHECK_ENFORCE === 'true';
}

function guard(req: CallableRequest<unknown>): void {
  const decision = appCheckDecision(req.app != null, appCheckEnforced());
  if (decision === 'ok') return;
  const fn = process.env.K_SERVICE ?? process.env.FUNCTION_TARGET ?? 'unknown';
  const data = { uid: req.auth?.uid ?? null };
  if (decision === 'log') return logger.info(fn, 'appcheck/missing', data);
  logger.warn(fn, 'appcheck/rejected', data);
  throw new HttpsError('unauthenticated', 'appcheck/missing');
}

type Handler<T, R> = (request: CallableRequest<T>) => R;

/** Drop-in for firebase-functions' onCall that checks App Check first. */
export function onCall<T = any, R = any>(opts: CallableOptions, handler: Handler<T, R>): ReturnType<typeof rawOnCall<T, R>>;
export function onCall<T = any, R = any>(handler: Handler<T, R>): ReturnType<typeof rawOnCall<T, R>>;
export function onCall<T = any, R = any>(a: CallableOptions | Handler<T, R>, b?: Handler<T, R>) {
  const opts = typeof a === 'function' ? {} : a;
  const handler = (typeof a === 'function' ? a : b) as Handler<T, R>;
  return rawOnCall<T, R>(opts, (req) => {
    guard(req as CallableRequest<unknown>);
    return handler(req);
  });
}
