/**
 * Configuración que solo lee el servidor (Admin SDK), fuera de config/global
 * (que es público y que el panel escribe). A8.9.
 *
 * - config/ops: tiempos del SOS, retención y radio de llegada. Lectura solo
 *   admin, escritura denegada a los clientes (se edita en la consola).
 * - config/security: imposición del segundo factor y sesión máxima de admin
 *   (Parte B). Ningún cliente lo lee ni lo escribe.
 */
import * as admin from 'firebase-admin';
import { logger } from './logger';

/** Claves de config/ops. Antes vivían en config/global. */
export const OPS_KEYS = [
  'incidentAckSeconds',
  'incidentEscalateEverySeconds',
  'incidentLocationRetentionDays',
  'arrivalRadiusMeters',
] as const;

/**
 * config/ops. Transición: si una clave aún no está en ops pero sí en
 * config/global (proyectos configurados antes), se usa la de global y se
 * avisa en el log para moverla (DEPLOY.md).
 */
export async function opsConfig(db: admin.firestore.Firestore): Promise<Record<string, unknown>> {
  const [ops, global] = await Promise.all([
    db.collection('config').doc('ops').get(),
    db.collection('config').doc('global').get(),
  ]);
  const out: Record<string, unknown> = { ...(ops.data() ?? {}) };
  const g = global.data() ?? {};
  const legacy = OPS_KEYS.filter((k) => !(k in out) && k in g);
  for (const k of legacy) out[k] = g[k];
  if (legacy.length) logger.warn('opsConfig', 'keys still in config/global', { keys: legacy });
  return out;
}

/** config/security (Parte B): solo el servidor. */
export async function securityConfig(db: admin.firestore.Firestore): Promise<Record<string, unknown>> {
  return (await db.collection('config').doc('security').get()).data() ?? {};
}
