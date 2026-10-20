import { describe, it, expect } from '@jest/globals';
import { isTransient, withRetryPolicy } from './retry_policy';

const err = (code: unknown) => Object.assign(new Error('x'), { code });

describe('isTransient', () => {
  it.each<[string, boolean, unknown]>([
    ['UNAVAILABLE', true, err(14)],
    ['DEADLINE_EXCEEDED', true, err(4)],
    ['ABORTED', true, err(10)],
    ['unavailable', true, err('unavailable')],
    ['FCM caído', true, err('messaging/server-unavailable')],
    ['FCM error interno', true, { errorInfo: { code: 'messaging/internal-error' } }],
    ['red', true, err('ECONNRESET')],
    ['INVALID_ARGUMENT', false, err(3)],
    ['NOT_FOUND', false, err(5)],
    ['PERMISSION_DENIED', false, err(7)],
    ['FAILED_PRECONDITION (índice que falta)', false, err(9)],
    ['argumento de FCM', false, err('messaging/invalid-argument')],
    ['error de programación', false, new TypeError('x is undefined')],
    ['sin error', false, undefined],
  ])('%s → transitorio: %s', (_name, expected, e) => {
    expect(isTransient(e)).toBe(expected);
  });
});

describe('withRetryPolicy', () => {
  it('relanza un error transitorio para que la plataforma reintente', async () => {
    await expect(withRetryPolicy('t', {}, async () => { throw err(14); })).rejects.toThrow();
  });

  it('un error permanente se registra y no se relanza', async () => {
    await expect(withRetryPolicy('t', {}, async () => { throw err(5); })).resolves.toBeUndefined();
    await expect(withRetryPolicy('t', {}, async () => { throw new TypeError('bug'); })).resolves.toBeUndefined();
  });
});
