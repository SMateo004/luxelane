/**
 * B4: con config/security.mfaEnforced true, las callables de admin (y las
 * del chófer marcadas) exigen un token con segundo factor; con false o sin
 * el documento, no (fase 1).
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { resolveAlert as resolveAlertFn } from '../index';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const run = (token: Record<string, unknown>) =>
  (resolveAlertFn as unknown as Runnable).run({ auth: { uid: 'jefa', token }, app: {}, data: { alertId: 'a1' } });
const NOW_S = Math.floor(Date.now() / 1000);
const TOTP = { role: 'admin', auth_time: NOW_S, firebase: { sign_in_provider: 'password', sign_in_second_factor: 'totp' } };
const NO_2FA = { role: 'admin', auth_time: NOW_S, firebase: { sign_in_provider: 'password' } };

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  try { await p; } catch (e) { return ((e as HttpsError).details as { reason?: string } | undefined)?.reason; }
  return 'ok';
}

beforeEach(async () => {
  for (const col of ['users', 'adminAlerts', 'admin_logs', 'config', 'rateLimits']) {
    const snap = await db.collection(col).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.doc('users/jefa').set({ role: 'admin', isActive: true });
  await db.doc('adminAlerts/a1').set({ type: 'x', resolved: false });
});
afterAll(async () => {
  // Sin dejar config/security para otras suites.
  await db.doc('config/security').delete();
  await admin.app().delete();
});

describe('segundo factor en las callables de admin', () => {
  it('fase 1 (sin config/security): no se exige', async () => {
    expect(await reason(run(NO_2FA))).toBe('ok');
  });

  it('mfaEnforced false: no se exige', async () => {
    await db.doc('config/security').set({ mfaEnforced: false });
    expect(await reason(run(NO_2FA))).toBe('ok');
  });

  it('mfaEnforced true: sin segundo factor, mfa_required', async () => {
    await db.doc('config/security').set({ mfaEnforced: true });
    expect(await reason(run(NO_2FA))).toBe('mfa_required');
  });

  it('mfaEnforced true: con TOTP, pasa', async () => {
    await db.doc('config/security').set({ mfaEnforced: true });
    expect(await reason(run(TOTP))).toBe('ok');
  });
});
