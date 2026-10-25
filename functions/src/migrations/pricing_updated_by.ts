/**
 * C3: pricingRules es público (la web lo lee sin sesión) y guardaba
 * `updatedBy`, el uid del admin que tocó la tarifa. Esta migración lo borra
 * de los documentos existentes; el uid queda solo en admin_logs (privado).
 * El script decide si escribe: DRY-RUN por defecto.
 */
import * as admin from 'firebase-admin';

export interface PricingCleanup { id: string; updatedBy: unknown }

/** --operator es obligatorio: queda en la auditoría. */
export function parseOperator(argv: string[]): string {
  const i = argv.indexOf('--operator');
  const v = i >= 0 ? argv[i + 1]?.trim() : undefined;
  if (!v || v.startsWith('--')) throw new Error('Falta --operator "<quién lo ejecuta>": queda en la auditoría.');
  return v;
}

export async function removePricingUpdatedBy(db: admin.firestore.Firestore, apply: boolean,
  operator: string): Promise<PricingCleanup[]> {
  const snap = await db.collection('pricingRules').get();
  const plan = snap.docs
    .filter((d) => d.data().updatedBy !== undefined)
    .map((d) => ({ id: d.id, updatedBy: d.data().updatedBy }));
  if (!apply || plan.length === 0) return plan;
  const batch = db.batch();
  for (const p of plan) {
    batch.update(db.collection('pricingRules').doc(p.id), { updatedBy: admin.firestore.FieldValue.delete() });
    // El uid anterior se conserva aquí, donde solo lo lee el admin.
    batch.set(db.collection('admin_logs').doc(), {
      adminId: 'script:migrate_pricing_updated_by',
      adminEmail: null,
      action: 'remove_pricing_updated_by',
      targetId: p.id,
      targetType: 'pricing',
      details: `updatedBy ${String(p.updatedBy)} retirado del documento público · ejecutado por ${operator}`,
      source: 'script',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return plan;
}
