/**
 * B5 (decisión 6): operaciones sensibles con inicio de sesión de menos de
 * 5 minutos y callables de admin con sesión de menos de
 * config/security.adminSessionMaxHours (12 h por defecto).
 */
import { describe, it, expect, beforeEach, afterAll } from '@jest/globals';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  acknowledgeIncident as ackFn, adminOverrideVerify as overrideFn, closeIncident as closeFn,
  deleteAccount as deleteAccountFn, resolveAlert as resolveAlertFn,
} from '../index';
import { recentAuthGate } from '../callable';

const db = admin.firestore();
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Runnable = { run: (r: any) => Promise<any> };
const nowS = () => Math.floor(Date.now() / 1000);

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
  await db.doc('users/ana').set({ role: 'rider', isActive: true });
  await db.doc('adminAlerts/a1').set({ type: 'x', resolved: false });
});
afterAll(async () => {
  // Sin dejar config/security para otras suites.
  await db.doc('config/security').delete();
  await admin.app().delete();
});

const token = (authTime?: number, extra: Record<string, unknown> = {}) =>
  ({ ...(authTime === undefined ? {} : { auth_time: authTime }), ...extra });
// Una de admin con sesión máxima: llegar a booking_not_found es haber
// pasado los candados.
const override = (authTime?: number) => (overrideFn as unknown as Runnable).run({
  auth: { uid: 'jefa', token: token(authTime) }, app: {}, data: { bookingId: 'no-existe', reason: 'prueba' },
});
const resolve = (uid: string, t: Record<string, unknown>) => (resolveAlertFn as unknown as Runnable).run({
  auth: { uid, token: t }, app: {}, data: { alertId: 'a1' },
});
const ack = (t: Record<string, unknown>) => (ackFn as unknown as Runnable).run({
  auth: { uid: 'jefa', token: t }, app: {}, data: { incidentId: 'no-existe' },
});
const close = (t: Record<string, unknown>) => (closeFn as unknown as Runnable).run({
  auth: { uid: 'jefa', token: t }, app: {}, data: { incidentId: 'no-existe', note: 'nota de cierre de prueba' },
});
const PASSED = 'booking_not_found';

describe('sesión máxima de admin', () => {
  it('sesión de hace 1 hora: pasa', async () => {
    expect(await reason(override(nowS() - 3600))).toBe(PASSED);
  });

  it('sesión de hace 13 horas: reauth_required', async () => {
    expect(await reason(override(nowS() - 13 * 3600))).toBe('reauth_required');
  });

  it('sin auth_time: reauth_required', async () => {
    expect(await reason(override())).toBe('reauth_required');
  });

  it('adminSessionMaxHours en config/security manda', async () => {
    await db.doc('config/security').set({ adminSessionMaxHours: 1 });
    expect(await reason(override(nowS() - 2 * 3600))).toBe('reauth_required');
    expect(await reason(override(nowS() - 600))).toBe(PASSED);
  });
});

describe('incidentes y alertas: sin sesión máxima (C1)', () => {
  const old = () => token(nowS() - 13 * 3600);

  it('sesión de hace 13 horas: resolveAlert, acknowledgeIncident y closeIncident no piden volver a entrar', async () => {
    expect(await reason(resolve('jefa', old()))).toBe('ok');
    expect(await reason(ack(old()))).not.toBe('reauth_required');
    expect(await reason(close(old()))).not.toBe('reauth_required');
    expect(await reason(resolve('jefa', {}))).toBe('ok');
  });

  it('siguen exigiendo el rol admin', async () => {
    expect(await reason(resolve('ana', old()))).toBe('admin_required');
  });

  it('con mfaEnforced siguen exigiendo el segundo factor', async () => {
    await db.doc('config/security').set({ mfaEnforced: true });
    expect(await reason(resolve('jefa', old()))).toBe('mfa_required');
    expect(await reason(ack(old()))).toBe('mfa_required');
    expect(await reason(close(old()))).toBe('mfa_required');
    const totp = token(nowS() - 13 * 3600, { firebase: { sign_in_second_factor: 'totp' } });
    expect(await reason(resolve('jefa', totp))).toBe('ok');
  });
});

describe('operaciones sensibles: menos de 5 minutos', () => {
  const del = (authTime: number) => (deleteAccountFn as unknown as Runnable).run({
    auth: { uid: 'ana', token: { auth_time: authTime } }, app: {}, data: null,
  });

  it('deleteAccount con sesión de hace 10 minutos: reauth_required', async () => {
    expect(await reason(del(nowS() - 600))).toBe('reauth_required');
    expect((await db.doc('users/ana').get()).exists).toBe(true);
  });

  it('el candado deja pasar una sesión de hace 1 minuto', () => {
    expect(() => recentAuthGate({ auth_time: nowS() - 60 }, 300)).not.toThrow();
    expect(() => recentAuthGate({ auth_time: nowS() - 301 }, 300)).toThrow('reauth_required');
  });
});
