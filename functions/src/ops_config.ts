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
 * config/global (proyectos configurados antes), se usa la de global, se
 * avisa en el log y se deja una alerta baja en adminAlerts, como mucho una
 * por día (0.3), para que el responsable la mueva (DEPLOY.md).
 */
export async function opsConfig(db: admin.firestore.Firestore, now = Date.now()): Promise<Record<string, unknown>> {
  const [ops, global] = await Promise.all([
    db.collection('config').doc('ops').get(),
    db.collection('config').doc('global').get(),
  ]);
  const out: Record<string, unknown> = { ...(ops.data() ?? {}) };
  const g = global.data() ?? {};
  const legacy = OPS_KEYS.filter((k) => !(k in out) && k in g);
  for (const k of legacy) out[k] = g[k];
  if (legacy.length) {
    logger.warn('opsConfig', 'keys still in config/global', { keys: legacy });
    await alertLegacyOnce(db, legacy, now);
  }
  return out;
}

/** Día (UTC) de la última alerta escrita por esta instancia: evita reintentos. */
let lastAlertDay: string | null = null;

/**
 * Una alerta por día como máximo: el id es el día (UTC) y create() falla si
 * ya existe, también entre instancias. Nunca rompe a quien lee la config.
 */
async function alertLegacyOnce(db: admin.firestore.Firestore, keys: readonly string[], now: number): Promise<void> {
  const day = new Date(now).toISOString().slice(0, 10);
  if (lastAlertDay === day) return;
  try {
    await db.collection('adminAlerts').doc(`ops_config_in_global_${day}`).create({
      type: 'ops_config_in_global',
      severity: 'low',
      keys: [...keys],
      message: `Mover a config/ops: ${keys.join(', ')} (se están leyendo de config/global).`,
      createdAt: admin.firestore.Timestamp.fromMillis(now),
      resolved: false,
    });
    lastAlertDay = day;
  } catch (e) {
    // 6 = ALREADY_EXISTS: otra instancia ya avisó hoy.
    if ((e as { code?: number }).code === 6) lastAlertDay = day;
    else logger.warn('opsConfig', 'legacy alert failed', { error: String(e) });
  }
}

/** Solo pruebas: olvida la última alerta de esta instancia. */
export function resetLegacyAlertForTests(): void { lastAlertDay = null; }

/** config/security (Parte B): solo el servidor. */
export async function securityConfig(db: admin.firestore.Firestore): Promise<Record<string, unknown>> {
  return (await db.collection('config').doc('security').get()).data() ?? {};
}
