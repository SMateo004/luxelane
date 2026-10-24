/**
 * El admin marca una alerta de adminAlerts como revisada. Solo el servidor
 * escribe alertas y su auditoría (admin_logs), en la misma transacción.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { docId } from './schemas';

export const resolveSchema = z.strictObject({
  alertId: docId,
  note: z.string().trim().max(500).optional(),
});

export async function resolveAdminAlert(
  db: admin.firestore.Firestore,
  actor: { adminId: string; adminEmail: string | null },
  data: unknown,
): Promise<{ resolved: true; alreadyResolved: boolean }> {
  const parsed = resolveSchema.safeParse(data);
  if (!parsed.success) throw new HttpsError('invalid-argument', 'invalid_request', { reason: 'invalid_request' });
  const { alertId, note } = parsed.data;
  const ref = db.collection('adminAlerts').doc(alertId);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'alert_not_found', { reason: 'alert_not_found' });
    // Marcarla dos veces no cambia nada ni duplica la auditoría.
    if (snap.data()?.resolved === true) return { resolved: true as const, alreadyResolved: true };
    const now = admin.firestore.Timestamp.now();
    tx.update(ref, {
      resolved: true,
      resolvedAt: now,
      resolvedBy: actor.adminId,
      ...(note ? { resolutionNote: note } : {}),
    });
    tx.set(db.collection('admin_logs').doc(), {
      adminId: actor.adminId,
      adminEmail: actor.adminEmail,
      action: 'resolve_alert',
      targetId: alertId,
      targetType: 'alert',
      details: `${snap.data()?.type ?? 'alerta'}${note ? ` · ${note}` : ''}`,
      createdAt: now,
    });
    return { resolved: true as const, alreadyResolved: false };
  });
}
