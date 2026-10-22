import { describe, it, expect } from '@jest/globals';
import { codesMatch, newPickupSalt, pickupCode, pickupExpired, PICKUP_CODE_TTL_MS } from './pickup_code';

describe('pickupCode', () => {
  it('siempre 4 dígitos y estable para la misma reserva y sal', () => {
    const c = pickupCode('secreto', 'b1', 'sal');
    expect(c).toMatch(/^\d{4}$/);
    expect(pickupCode('secreto', 'b1', 'sal')).toBe(c);
  });

  it('cambia con el secreto, la reserva o la sal', () => {
    const codes = new Set<string>();
    for (let i = 0; i < 50; i++) codes.add(pickupCode('secreto', 'b1', `sal-${i}`));
    // 50 sales distintas no dan todas el mismo código.
    expect(codes.size).toBeGreaterThan(40);
    // Con otro secreto o en otra reserva, la misma sal da otros códigos.
    const salts = Array.from({ length: 20 }, (_, i) => `sal-${i}`);
    expect(salts.some((s) => pickupCode('otro', 'b1', s) !== pickupCode('secreto', 'b1', s))).toBe(true);
    expect(salts.some((s) => pickupCode('secreto', 'b2', s) !== pickupCode('secreto', 'b1', s))).toBe(true);
  });

  it('sin secreto no calcula nada (falla cerrado)', () => {
    expect(() => pickupCode('', 'b1', 'sal')).toThrow('PICKUP_CODE_SECRET missing');
  });

  it('la sal es aleatoria', () => {
    expect(newPickupSalt()).toMatch(/^[0-9a-f]{32}$/);
    expect(newPickupSalt()).not.toBe(newPickupSalt());
  });
});

describe('codesMatch', () => {
  it.each<[string, string, boolean]>([
    ['0420', '0420', true],
    ['0420', '0421', false],
    ['0420', '420', false],
    ['0420', '04200', false],
    ['0420', '', false],
  ])('%s frente a %s → %s', (a, b, ok) => {
    expect(codesMatch(a, b)).toBe(ok);
  });
});

describe('pickupExpired', () => {
  it('vence pasadas 4 horas desde la llegada', () => {
    expect(pickupExpired(0, PICKUP_CODE_TTL_MS)).toBe(false);
    expect(pickupExpired(0, PICKUP_CODE_TTL_MS + 1)).toBe(true);
  });
});
