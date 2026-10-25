/**
 * Toda callable exportada pasa por secureCallable (App Check, límites,
 * errores). Una función nueva no puede saltárselo sin que el CI lo note.
 * El emulador no simula App Check: aquí se prueba la puerta con
 * peticiones con y sin `app` (lo que el SDK rellena si el token es válido).
 */
import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';
import * as index from './index';
import { appCheckGate, secureCallable, SECURED_MARK } from './callable';
import { RATE_LIMITS } from './rate_limit';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Exported = Record<string, any>;

const callables = Object.entries(index as Exported)
  .filter(([, fn]) => fn?.__endpoint?.callableTrigger !== undefined);

describe('cobertura de App Check en las callables', () => {
  it('se encuentran todas las callables exportadas', () => {
    expect(callables.length).toBeGreaterThanOrEqual(23);
  });

  it.each(callables.map(([name]) => [name]))('%s pasa por secureCallable', (name) => {
    const fn = (index as Exported)[name];
    expect(fn[SECURED_MARK]).toEqual(expect.objectContaining({ name }));
  });

  it.each(callables.map(([name]) => [name]))('%s tiene límite de tasa', (name) => {
    expect(RATE_LIMITS[name]).toEqual(expect.objectContaining({
      limit: expect.any(Number), windowSeconds: expect.any(Number),
    }));
  });

  // Las callables de admin exigen el rol en secureCallable (claim o, en la
  // transición, Firestore) además de su comprobación interna.
  const ADMIN_ONLY = ['adminOverrideVerify', 'acknowledgeIncident', 'closeIncident', 'resolveAlert',
    'refundPayment', 'backfillSettlements', 'setUserRole', 'setUserBlocked', 'adminUpdateBooking'];
  it.each(ADMIN_ONLY.map((n) => [n]))('%s exige rol admin', (name) => {
    expect((index as Exported)[name][SECURED_MARK]).toEqual(expect.objectContaining({ role: 'admin' }));
  });

  // Segundo factor (decisión 3): admin siempre (por el rol) y las del chófer.
  it.each([['advanceBooking'], ['verifyPickup'], ['acceptBooking']])('%s exige segundo factor si se impone', (name) => {
    expect((index as Exported)[name][SECURED_MARK]).toEqual(expect.objectContaining({ requireMfa: true }));
  });

  // Reautenticación reciente (decisión 6).
  it.each([['deleteAccount'], ['setDefaultPaymentMethod'], ['detachPaymentMethod']])('%s exige sesión reciente', (name) => {
    expect((index as Exported)[name][SECURED_MARK]).toEqual(expect.objectContaining({ recentAuthSeconds: 300 }));
  });

  // C1: atender un SOS o una alerta no espera a volver a entrar; el resto
  // de las de admin sí tienen la sesión máxima.
  it('solo incidentes y alertas quedan fuera de adminSessionMaxHours', () => {
    const skipped = Object.entries(index as Exported)
      .filter(([, f]) => f?.[SECURED_MARK]?.skipAdminSessionLimit === true)
      .map(([n]) => n).sort();
    expect(skipped).toEqual(['acknowledgeIncident', 'closeIncident', 'resolveAlert']);
    for (const n of skipped) expect((index as Exported)[n][SECURED_MARK].role).toBe('admin');
  });

  it('solo el SOS deja pasar si el contador falla', () => {
    const failOpen = Object.entries(RATE_LIMITS).filter(([, r]) => r.failOpen).map(([n]) => n);
    expect(failOpen).toEqual(['raiseIncident']);
  });

  it('ningún archivo de src define una callable con onCall directamente', () => {
    const dir = __dirname;
    const offenders = readdirSync(dir)
      .filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts') && f !== 'callable.ts')
      .filter((f) => /\bonCall\s*\(/.test(readFileSync(join(dir, f), 'utf8')));
    expect(offenders).toEqual([]);
  });

  it('los triggers y las funciones programadas no se tocan', () => {
    const others = Object.entries(index as Exported)
      .filter(([, fn]) => fn?.__endpoint && fn.__endpoint.callableTrigger === undefined);
    expect(others.length).toBeGreaterThan(0);
    for (const [, fn] of others) expect(fn[SECURED_MARK]).toBeUndefined();
  });
});

describe('appCheckGate', () => {
  afterEach(() => { jest.restoreAllMocks(); });

  it('sin imponer: deja pasar y registra solo si llegó el token', () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    const log = jest.spyOn(console, 'log').mockImplementation(() => undefined);
    expect(() => appCheckGate('quoteBooking', { app: undefined }, false)).not.toThrow();
    appCheckGate('quoteBooking', { app: { appId: 'x', token: {} } } as never, false);
    const out = [...warn.mock.calls, ...log.mock.calls].map((c) => String(c[0])).join('\n');
    expect(out).toContain('"appCheck":"missing"');
    expect(out).toContain('"appCheck":"valid"');
    expect(out).not.toMatch(/uid|appId|token":\{/);
  });

  it('imponiendo: sin token se rechaza con app_check_required', () => {
    jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    try {
      appCheckGate('createBooking', { app: undefined }, true);
      throw new Error('no rechazó');
    } catch (e) {
      expect(e).toMatchObject({ code: 'unauthenticated', details: { reason: 'app_check_required' } });
    }
    expect(() => appCheckGate('createBooking', { app: { appId: 'x' } } as never, true)).not.toThrow();
  });
});

describe('APP_CHECK_ENFORCE (parámetro de despliegue)', () => {
  const fn = secureCallable('prueba', {}, () => 'ok');
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const run = (req: any) => (fn as unknown as { run: (r: any) => Promise<any> }).run(req);
  afterEach(() => {
    delete process.env.APP_CHECK_ENFORCE;
    jest.restoreAllMocks();
  });

  it('por defecto (false) funciona sin token', async () => {
    jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    await expect(run({ data: {} })).resolves.toBe('ok');
  });

  it('con true rechaza sin token y acepta con token', async () => {
    jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    jest.spyOn(console, 'log').mockImplementation(() => undefined);
    process.env.APP_CHECK_ENFORCE = 'true';
    await expect(run({ data: {} })).rejects.toMatchObject({ details: { reason: 'app_check_required' } });
    await expect(run({ data: {}, app: { appId: 'x' } })).resolves.toBe('ok');
  });
});
