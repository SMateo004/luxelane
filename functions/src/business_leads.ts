/**
 * Formulario de empresas (sin cuenta). Antes la web escribía directo en
 * businessLeads; ahora pasa por aquí (matriz, H5): esquema estricto, campo
 * trampa, límite por IP y por correo, y App Check (secureCallable).
 *
 * La IP nunca se guarda: solo un HMAC-SHA256 con una sal secreta, que sirve
 * de clave del contador. Sin la sal, un hash de una IPv4 se revierte
 * probando todas; con ella, no.
 */
import { createHmac } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { logger } from './logger';
import { enforceRateLimit, RateRule } from './rate_limit';
import { parseInput } from './schemas';

/** Los mismos rangos que el formulario (business_page.dart). */
export const TRAVELLER_RANGES = ['1–10', '11–50', '51–200', 'Más de 200'] as const;

export const leadSchema = z.strictObject({
  company: z.string().trim().min(1).max(120),
  contactName: z.string().trim().min(1).max(120),
  email: z.string().trim().max(160).regex(/^[^@\s]+@[^@\s]+\.[^@\s]+$/),
  phone: z.string().trim().max(40),
  travellers: z.enum(TRAVELLER_RANGES),
  message: z.string().trim().max(2000),
  /** Campo trampa: invisible para las personas; un bot lo rellena. */
  website: z.string().max(200).optional(),
});

/** Valores de operación (frenar envíos masivos), no de negocio. */
export const LEAD_LIMITS: { perIp: RateRule; perEmail: RateRule; global: RateRule } = {
  perIp: { limit: 5, windowSeconds: 3600 },
  perEmail: { limit: 3, windowSeconds: 24 * 3600 },
  // Respaldo si alguien rota IP y correo: un único contador para todos.
  global: { limit: 100, windowSeconds: 3600 },
};

export interface LeadDeps {
  db: admin.firestore.Firestore;
  /** RATE_LIMIT_SALT. Vacía = no se aceptan solicitudes (falla cerrado). */
  salt: string;
  now?: () => number;
  /** Solo para pruebas: límites más bajos. */
  limits?: Partial<typeof LEAD_LIMITS>;
}

export interface LeadRequest {
  data: unknown;
  rawRequest?: { ip?: string; headers?: Record<string, string | string[] | undefined> };
}

/**
 * IP del cliente: el ÚLTIMO elemento de x-forwarded-for. Los primeros los
 * puede escribir el propio cliente (el proxy de Google conserva lo que llega
 * y añade al final la IP que vio). NO VERIFICADO: que en Cloud Functions
 * (2.ª gen., sobre Cloud Run) el último sea siempre el del cliente y no otro
 * salto de Google; por eso hay además un tope global.
 */
export function clientIp(req: LeadRequest): string {
  const fwd = req.rawRequest?.headers?.['x-forwarded-for'];
  const parts = (Array.isArray(fwd) ? fwd.join(',') : fwd ?? '')
    .split(',').map((p) => p.trim()).filter(Boolean);
  return parts[parts.length - 1] || req.rawRequest?.ip || 'desconocida';
}

export const pseudonym = (salt: string, kind: string, value: string) =>
  createHmac('sha256', salt).update(`${kind}:${value}`).digest('hex').slice(0, 32);

export async function submitBusinessLead(deps: LeadDeps, req: LeadRequest): Promise<{ ok: true }> {
  const input = parseInput(leadSchema, req.data);
  if (input.website) {
    // Respuesta igual que un envío válido: el bot no aprende nada.
    logger.warn('submitBusinessLead', 'honeypot', {});
    return { ok: true };
  }
  if (!deps.salt) {
    logger.error('submitBusinessLead', 'RATE_LIMIT_SALT missing', {});
    throw new HttpsError('internal', 'internal', { reason: 'internal' });
  }
  const now = deps.now?.() ?? Date.now();
  const limits = { ...LEAD_LIMITS, ...deps.limits };
  const email = input.email.toLowerCase();
  await enforceRateLimit(deps.db, 'submitBusinessLead_ip',
    pseudonym(deps.salt, 'ip', clientIp(req)), limits.perIp, now);
  await enforceRateLimit(deps.db, 'submitBusinessLead_email',
    pseudonym(deps.salt, 'email', email), limits.perEmail, now);
  await enforceRateLimit(deps.db, 'submitBusinessLead_global', 'todos', limits.global, now);

  await deps.db.collection('businessLeads').add({
    company: input.company,
    contactName: input.contactName,
    email,
    phone: input.phone,
    travellers: input.travellers,
    message: input.message,
    handled: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  logger.info('submitBusinessLead', 'received', {});
  return { ok: true };
}
