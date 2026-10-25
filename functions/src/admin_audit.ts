/**
 * Auditoría de las escrituras de admin (Parte A). La escribe el servidor en
 * la MISMA transacción que el cambio: o ocurren las dos cosas o ninguna.
 *
 * Cada entrada lleva la forma antigua (adminId, action, targetId,
 * targetType, details), que el panel ya lee, y la nueva: operación, actor
 * (uid y rol), colección y documento, valores antes y después SOLO de los
 * campos cambiados, motivo y hora del servidor. El panel lee las dos sin
 * migrar nada (A9).
 */
import * as admin from 'firebase-admin';
import { z } from 'zod';

export interface AdminActor { adminId: string; adminEmail: string | null }

/** Motivo de una operación sensible: obligatorio, de 10 a 500 caracteres. */
export const reasonSchema = z.string().trim().min(10).max(500);

export interface FieldChange { before: unknown; after: unknown }

function comparable(v: unknown): unknown {
  if (v instanceof admin.firestore.Timestamp) return { __ts: v.toMillis() };
  if (v === undefined) return null;
  return v;
}

const same = (a: unknown, b: unknown) => JSON.stringify(comparable(a)) === JSON.stringify(comparable(b));

/**
 * Solo los campos de [after] cuyo valor cambia respecto de [before]. Los
 * valores ausentes antes quedan como null.
 */
export function changedFields(before: Record<string, unknown> | undefined,
  after: Record<string, unknown>): Record<string, FieldChange> {
  const out: Record<string, FieldChange> = {};
  for (const [k, v] of Object.entries(after)) {
    const prev = before?.[k];
    if (!same(prev, v)) out[k] = { before: prev ?? null, after: v ?? null };
  }
  return out;
}

export interface AuditInput {
  actor: AdminActor;
  /** Nombre de la operación (también va en action, la forma antigua). */
  operation: string;
  collection: string;
  docId: string;
  /** targetType de la forma antigua: booking, payment, pricing, driver… */
  targetType: string;
  changes: Record<string, FieldChange>;
  reason: string | null;
  /** Resumen legible para la lista del panel. */
  details: string;
  /** Datos que ayudan a leer el cambio (p. ej. el importe original). */
  context?: Record<string, unknown>;
}

export function writeAudit(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, a: AuditInput): void {
  tx.set(db.collection('admin_logs').doc(), {
    adminId: a.actor.adminId,
    adminEmail: a.actor.adminEmail,
    action: a.operation,
    targetId: a.docId,
    targetType: a.targetType,
    details: a.reason ? `${a.details} · Motivo: ${a.reason}` : a.details,
    operation: a.operation,
    actor: { uid: a.actor.adminId, role: 'admin' },
    collection: a.collection,
    docPath: `${a.collection}/${a.docId}`,
    changes: a.changes,
    reason: a.reason,
    ...(a.context ? { context: a.context } : {}),
    source: 'server',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
