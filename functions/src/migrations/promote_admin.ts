/**
 * Nombrar administrador desde la línea de comandos (B9), para el primer
 * admin o una emergencia; el resto se hace con setUserRole desde el panel.
 * Fija el claim y el documento, revoca las sesiones del afectado y deja la
 * auditoría en admin_logs. El script (scripts/promote_admin.mjs) decide si
 * escribe: DRY-RUN por defecto.
 */
import * as admin from 'firebase-admin';
import { IdentityDeps } from '../identity';

export interface PromoteArgs { email: string; reason: string; operator: string }

function value(argv: string[], flag: string): string | undefined {
  const i = argv.indexOf(flag);
  const v = i >= 0 ? argv[i + 1] : undefined;
  return v && !v.startsWith('--') ? v.trim() : undefined;
}

/** --email, --reason y --operator son obligatorios: quedan en la auditoría. */
export function parsePromoteArgs(argv: string[]): PromoteArgs {
  const email = value(argv, '--email')?.toLowerCase();
  const reason = value(argv, '--reason');
  const operator = value(argv, '--operator');
  if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new Error('Falta --email <correo> válido.');
  if (!reason) throw new Error('Falta --reason "<motivo>": queda en la auditoría.');
  if (!operator) throw new Error('Falta --operator "<quién lo ejecuta>": queda en la auditoría.');
  return { email, reason, operator };
}

export interface PromotePlan { uid: string; fromRole: unknown; fromClaim: unknown; changes: boolean }

export async function promoteAdmin(deps: IdentityDeps, args: PromoteArgs, apply: boolean): Promise<PromotePlan> {
  const { uid } = await deps.auth.getUserByEmail(args.email);
  const ref = deps.db.collection('users').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) throw new Error('La cuenta existe en Auth pero no tiene perfil en users: que entre una vez en la app.');
  if (snap.data()?.isActive === false) throw new Error('La cuenta está bloqueada: desbloquéala antes (setUserBlocked).');
  const user = await deps.auth.getUser(uid);
  const plan: PromotePlan = {
    uid,
    fromRole: snap.data()?.role ?? null,
    fromClaim: user.customClaims?.role ?? null,
    changes: snap.data()?.role !== 'admin' || user.customClaims?.role !== 'admin',
  };
  if (!apply || !plan.changes) return plan;
  await deps.auth.setCustomUserClaims(uid, { ...(user.customClaims ?? {}), role: 'admin' });
  const batch = deps.db.batch();
  batch.update(ref, { role: 'admin', roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp() });
  batch.set(deps.db.collection('admin_logs').doc(), {
    adminId: 'script:promote_admin',
    adminEmail: null,
    action: 'promote_admin',
    targetId: uid,
    targetType: 'user',
    details: `${plan.fromRole ?? 'sin rol'} → admin · ${args.reason} · ejecutado por ${args.operator}`,
    source: 'script',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await batch.commit();
  // Vuelve a entrar con el rol nuevo (y, con mfaEnforced, con su segundo factor).
  await deps.auth.revokeRefreshTokens(uid);
  return plan;
}
