/**
 * Backfill del custom claim `role` (B2): cada usuario recibe en Auth el rol
 * de users/{uid}.role. Solo planifica; el script decide si escribe.
 */
import { isRole, Role } from '../identity';

export interface ClaimChange { uid: string; from: unknown; to: Role }

export function planRoleClaim(uid: string, docRole: unknown, claims: Record<string, unknown> | undefined): ClaimChange | null {
  if (!isRole(docRole)) return null;
  const current = claims?.role;
  return current === docRole ? null : { uid, from: current ?? null, to: docRole };
}
