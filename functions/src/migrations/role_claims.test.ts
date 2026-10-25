import { describe, it, expect } from '@jest/globals';
import { planRoleClaim } from './role_claims';
import { checkTarget, PRODUCTION_FLAG } from './production_guard';

describe('planRoleClaim', () => {
  it('añade el claim que falta', () => {
    expect(planRoleClaim('ana', 'rider', undefined)).toEqual({ uid: 'ana', from: null, to: 'rider' });
  });
  it('corrige un claim distinto del documento', () => {
    expect(planRoleClaim('luis', 'driver', { role: 'rider' })).toEqual({ uid: 'luis', from: 'rider', to: 'driver' });
  });
  it('no toca lo que ya coincide ni roles desconocidos', () => {
    expect(planRoleClaim('jefa', 'admin', { role: 'admin' })).toBeNull();
    expect(planRoleClaim('x', 'superadmin', undefined)).toBeNull();
  });
});

describe('checkTarget', () => {
  it('exige --project', () => {
    expect(() => checkTarget([], undefined)).toThrow('Falta --project');
  });
  it('se niega a producción sin la bandera larga', () => {
    expect(() => checkTarget(['--project', 'luxelane-4e7ae', '--apply'], undefined)).toThrow('Se niega');
    expect(checkTarget(['--project', 'luxelane-4e7ae', PRODUCTION_FLAG], undefined))
      .toEqual({ project: 'luxelane-4e7ae', apply: false, production: true });
  });
  it('demo-* solo con el emulador; por defecto dry-run', () => {
    expect(() => checkTarget(['--project', 'demo-luxelane'], undefined)).toThrow('emulador');
    expect(checkTarget(['--project', 'demo-luxelane'], '127.0.0.1:8080'))
      .toEqual({ project: 'demo-luxelane', apply: false, production: false });
  });
});
