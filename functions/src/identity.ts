/**
 * Identidad (Parte B): verificación de correo, roles con custom claims,
 * bloqueo, términos y dispositivos del chófer. Todo lo escribe el servidor;
 * el cliente no puede tocar estos campos (firestore.rules).
 *
 * Auth se inyecta (AuthAdmin) para probarlo contra el emulador de Firestore
 * sin el de Auth.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

/** Lo que usamos de admin.auth(). */
export interface AuthAdmin {
  getUser(uid: string): Promise<{ uid: string; email?: string; emailVerified: boolean; disabled: boolean;
    customClaims?: Record<string, unknown> }>;
  setCustomUserClaims(uid: string, claims: Record<string, unknown> | null): Promise<void>;
  revokeRefreshTokens(uid: string): Promise<void>;
  updateUser(uid: string, props: { disabled?: boolean }): Promise<unknown>;
}

export interface IdentityDeps {
  db: admin.firestore.Firestore;
  auth: AuthAdmin;
}

export const realAuth = (): AuthAdmin => admin.auth() as unknown as AuthAdmin;

const idError = (code: 'failed-precondition' | 'permission-denied' | 'not-found' | 'unauthenticated', reason: string) =>
  new HttpsError(code, reason, { reason });

/**
 * El correo verificado lo dice Auth, no el cliente: si Auth lo da por
 * verificado, users/{uid}.isVerified pasa a true (H6). Idempotente.
 */
export async function syncEmailVerification(deps: IdentityDeps, uid: string): Promise<{ verified: boolean }> {
  const user = await deps.auth.getUser(uid);
  if (!user.emailVerified) return { verified: false };
  const ref = deps.db.collection('users').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) throw idError('not-found', 'profile_not_found');
  if (snap.data()?.isVerified !== true) {
    await ref.update({ isVerified: true, emailVerifiedAt: admin.firestore.FieldValue.serverTimestamp() });
  }
  return { verified: true };
}

/** Reservar exige el correo verificado en el token (decisión 1). */
export function requireVerifiedEmail(token: Record<string, unknown> | undefined): void {
  if (token?.email_verified !== true) throw idError('failed-precondition', 'email_not_verified');
}

// ---------------------------------------------------------------------------
// Roles (decisión 4): el rol sale del custom claim `role`, que solo fija el
// servidor. Transición: sin claim, se usa users/{uid}.role hasta confirmar
// el backfill. isActive siempre se lee de Firestore: un token revocado
// sigue valiendo hasta una hora y el bloqueo debe ser inmediato.
// ---------------------------------------------------------------------------

export const ROLES = ['rider', 'driver', 'admin'] as const;
export type Role = (typeof ROLES)[number];
export const isRole = (v: unknown): v is Role => typeof v === 'string' && (ROLES as readonly string[]).includes(v);

/** false mientras dure la transición; true cuando el backfill esté confirmado. */
export const CLAIM_ONLY = false;

export interface ResolvedRole { role: Role | null; isActive: boolean; source: 'claim' | 'firestore' | 'none' }

export async function resolveRole(
  db: admin.firestore.Firestore,
  auth: { uid: string; token: Record<string, unknown> } | undefined,
): Promise<ResolvedRole> {
  if (!auth) return { role: null, isActive: false, source: 'none' };
  const doc = (await db.collection('users').doc(auth.uid).get()).data();
  const isActive = doc !== undefined && doc.isActive !== false;
  if (isRole(auth.token.role)) return { role: auth.token.role, isActive, source: 'claim' };
  if (!CLAIM_ONLY && isRole(doc?.role)) return { role: doc!.role as Role, isActive, source: 'firestore' };
  return { role: null, isActive, source: 'none' };
}

/** Rol exigido y cuenta activa; si no, permission_denied (o unauthenticated). */
export async function requireRole(
  db: admin.firestore.Firestore,
  auth: { uid: string; token: Record<string, unknown> } | undefined,
  role: Role,
): Promise<string> {
  if (!auth) throw idError('unauthenticated', 'unauthenticated');
  const r = await resolveRole(db, auth);
  if (r.role !== role) throw idError('permission-denied', `${role}_required`);
  if (!r.isActive) throw idError('permission-denied', 'inactive_user');
  return auth.uid;
}

export interface AdminActor { adminId: string; adminEmail: string | null }

function audit(tx: admin.firestore.Transaction | admin.firestore.WriteBatch, db: admin.firestore.Firestore,
  actor: AdminActor, action: string, targetId: string, details: string): void {
  (tx as admin.firestore.WriteBatch).set(db.collection('admin_logs').doc(), {
    adminId: actor.adminId,
    adminEmail: actor.adminEmail,
    action,
    targetId,
    targetType: 'user',
    details,
    source: 'server',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Cambia el rol: claim y documento, revoca las sesiones del afectado (que
 * vuelva a entrar con el rol nuevo) y deja la auditoría en el servidor.
 */
export async function setUserRole(deps: IdentityDeps, actor: AdminActor, input: { uid: string; role: Role }) {
  if (input.uid === actor.adminId) throw idError('failed-precondition', 'cannot_change_own_role');
  const ref = deps.db.collection('users').doc(input.uid);
  const snap = await ref.get();
  if (!snap.exists) throw idError('not-found', 'user_not_found');
  const previous = snap.data()?.role ?? null;
  const user = await deps.auth.getUser(input.uid);
  await deps.auth.setCustomUserClaims(input.uid, { ...(user.customClaims ?? {}), role: input.role });
  const batch = deps.db.batch();
  batch.update(ref, { role: input.role, roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp() });
  audit(batch, deps.db, actor, 'set_role', input.uid, `${previous ?? 'sin rol'} → ${input.role}`);
  await batch.commit();
  await deps.auth.revokeRefreshTokens(input.uid);
  return { uid: input.uid, role: input.role, previous };
}
