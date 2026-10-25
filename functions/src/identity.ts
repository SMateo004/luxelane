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
