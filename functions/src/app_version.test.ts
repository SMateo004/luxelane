import { describe, it, expect } from '@jest/globals';
import { compareVersions, updateRequired } from './app_version';

describe('compareVersions', () => {
  it.each([
    ['1.2.3', '1.2.3', 0],
    ['1.2.3+7', '1.2.3', 0],
    ['1.10.0', '1.9.9', 1],
    ['0.9.9', '1.0.0', -1],
  ])('%s frente a %s', (a, b, sign) => {
    expect(Math.sign(compareVersions(a, b)!)).toBe(sign);
  });

  it('no compara lo que no es x.y.z', () => {
    expect(compareVersions('1.2', '1.2.0')).toBeNull();
  });
});

describe('updateRequired', () => {
  const global = { minAppVersion: '1.2.0', androidStoreUrl: 'https://play.example/app' };

  it('versión menor que el mínimo: hay que actualizar, con el enlace configurado', () => {
    expect(updateRequired(global, '1.1.9')).toEqual({
      minAppVersion: '1.2.0', androidStoreUrl: 'https://play.example/app', iosStoreUrl: undefined,
    });
  });

  it('versión ausente con el mínimo activo: hay que actualizar', () => {
    expect(updateRequired(global, undefined)).not.toBeNull();
    expect(updateRequired(global, 'no-es-version')).not.toBeNull();
  });

  it('versión igual o mayor: no', () => {
    expect(updateRequired(global, '1.2.0')).toBeNull();
    expect(updateRequired(global, '2.0.0+5')).toBeNull();
  });

  it('sin mínimo (o mal escrito) no bloquea a nadie', () => {
    expect(updateRequired({}, undefined)).toBeNull();
    expect(updateRequired({ minAppVersion: 'pronto' }, '0.0.1')).toBeNull();
  });

  it('solo acepta enlaces https', () => {
    expect(updateRequired({ minAppVersion: '1.0.0', iosStoreUrl: 'javascript:alert(1)' }, '0.1.0')?.iosStoreUrl)
      .toBeUndefined();
  });
});

describe('minDriverAppVersion', () => {
  it('la app del chófer usa su propio mínimo, independiente del del pasajero', () => {
    const global = { minAppVersion: '9.0.0', minDriverAppVersion: '2.0.0' };
    expect(updateRequired(global, '2.0.0', 'minDriverAppVersion')).toBeNull();
    expect(updateRequired(global, '1.9.9', 'minDriverAppVersion')).toMatchObject({ minAppVersion: '2.0.0' });
    expect(updateRequired({ minAppVersion: '9.0.0' }, '1.0.0', 'minDriverAppVersion')).toBeNull();
  });
});
