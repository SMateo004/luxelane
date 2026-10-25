/** Auth de Firebase simulado para las pruebas de integración (sin el emulador de Auth). */
import { AuthAdmin } from '../identity';

export function fakeAuth(users: Record<string, { email?: string; emailVerified?: boolean; disabled?: boolean;
  claims?: Record<string, unknown>; factors?: { uid: string; factorId: string }[] }>) {
  const calls: string[] = [];
  const auth: AuthAdmin = {
    async getUser(uid) {
      const u = users[uid];
      if (!u) throw Object.assign(new Error('no user'), { code: 'auth/user-not-found' });
      return { uid, emailVerified: u.emailVerified === true, disabled: u.disabled === true, customClaims: u.claims,
        multiFactor: u.factors ? { enrolledFactors: u.factors } : undefined };
    },
    async getUserByEmail(email) {
      const uid = Object.keys(users).find((k) => users[k].email === email);
      if (!uid) throw Object.assign(new Error('no user'), { code: 'auth/user-not-found' });
      return { uid };
    },
    async setCustomUserClaims(uid, claims) { calls.push(`claims:${uid}:${JSON.stringify(claims)}`); users[uid].claims = claims ?? undefined; },
    async revokeRefreshTokens(uid) { calls.push(`revoke:${uid}`); },
    async updateUser(uid, props) {
      calls.push(`update:${uid}:${JSON.stringify(props)}`);
      const { multiFactor, ...rest } = props;
      Object.assign(users[uid], rest);
      if (multiFactor) users[uid].factors = [];
      return {};
    },
  };
  return { auth, calls };
}
