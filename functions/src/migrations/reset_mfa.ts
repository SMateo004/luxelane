/**
 * Quitar los segundos factores de una cuenta (C4): un admin o un chófer
 * perdió el teléfono con su app autenticadora. Revoca sus sesiones y deja
 * la auditoría en admin_logs; la persona vuelve a entrar con su contraseña y
 * da de alta el factor de nuevo. El script (scripts/reset_mfa.mjs) decide
 * si escribe: DRY-RUN por defecto.
 */
import * as admin from 'firebase-admin';
import { IdentityDeps } from '../identity';
import { PromoteArgs } from './promote_admin';

export interface ResetMfaPlan { uid: string; role: unknown; factors: string[] }

export async function resetMfa(deps: IdentityDeps, args: PromoteArgs, apply: boolean): Promise<ResetMfaPlan> {
  const { uid } = await deps.auth.getUserByEmail(args.email);
  const user = await deps.auth.getUser(uid);
  const factors = (user.multiFactor?.enrolledFactors ?? []).map((f) => f.factorId);
  const role = (await deps.db.collection('users').doc(uid).get()).data()?.role ?? user.customClaims?.role ?? null;
  const plan: ResetMfaPlan = { uid, role, factors };
  if (!apply || factors.length === 0) return plan;
  await deps.auth.updateUser(uid, { multiFactor: { enrolledFactors: null } });
  // Fuera también quien tuviera el teléfono perdido con la sesión abierta.
  await deps.auth.revokeRefreshTokens(uid);
  await deps.db.collection('admin_logs').add({
    adminId: 'script:reset_mfa',
    adminEmail: null,
    action: 'reset_mfa',
    targetId: uid,
    targetType: 'user',
    details: `${factors.length} factor(es) retirado(s) (${factors.join(', ')}) · ${args.reason} · ejecutado por ${args.operator}`,
    source: 'script',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return plan;
}
