import { describe, it, expect } from '@jest/globals';
import {
  CancellationPolicy, noShowAvailableAt, readPolicy, retainedCents, retentionFor, RetentionInput,
} from './cancellation_policy';

const NOW = Date.UTC(2026, 9, 26, 12);
const MIN = 60_000;
// Porcentajes y minutos de PRUEBA, ficticios: los de negocio los pone el
// responsable en config/ops.
const policy: CancellationPolicy = {
  stages: [
    { fromStatus: 'confirmed', percent: 11, graceMinutes: 5 },
    { fromStatus: 'driver_arriving', percent: 37 },
    { fromStatus: 'driver_arrived', percent: 73 },
    { fromStatus: 'no_show', percent: 100 },
  ],
  noShowWaitMinutes: 15,
};
const input = (over: Partial<RetentionInput> = {}): RetentionInput =>
  ({ status: 'driver_arriving', cause: 'rider', stageEnteredMs: NOW - 30 * MIN, now: NOW, ...over });

describe('readPolicy (A7)', () => {
  it('sin política: missing; mal formada: invalid', () => {
    expect(readPolicy({})).toEqual({ policy: null, state: 'missing' });
    for (const bad of [
      { stages: [{ fromStatus: 'confirmed', percent: 101 }] },
      { stages: [{ fromStatus: 'confirmed', percent: -1 }] },
      { stages: [{ fromStatus: 'pending', percent: 10 }] },
      { stages: [{ fromStatus: 'confirmed', percent: 10 }, { fromStatus: 'confirmed', percent: 20 }] },
      { stages: [], extra: 1 },
      // La de antes (B3) ya no es válida.
      { freeWithinMinutesOfBooking: 5, feeType: 'percent', feeValue: 10 },
    ]) {
      expect(readPolicy({ cancellationPolicy: bad })).toEqual({ policy: null, state: 'invalid' });
    }
    expect(readPolicy({ cancellationPolicy: policy })).toEqual({ policy, state: 'ok' });
  });
});

describe('retentionFor (A7)', () => {
  it('sin política: 0 % y lo anota (no_policy / policy_invalid)', () => {
    expect(retentionFor(null, 'missing', input())).toEqual({ percent: 0, basis: 'no_policy' });
    expect(retentionFor(null, 'invalid', input())).toEqual({ percent: 0, basis: 'policy_invalid' });
  });

  it('antes de asignar chófer: siempre 0 %', () => {
    expect(retentionFor(policy, 'ok', input({ status: 'pending' }))).toEqual({ percent: 0, basis: 'no_driver' });
  });

  it('cada etapa con su porcentaje', () => {
    expect(retentionFor(policy, 'ok', input({ status: 'confirmed' }))).toEqual({ percent: 11, basis: 'stage' });
    expect(retentionFor(policy, 'ok', input({ status: 'driver_arriving' }))).toEqual({ percent: 37, basis: 'stage' });
    expect(retentionFor(policy, 'ok', input({ status: 'driver_arrived' }))).toEqual({ percent: 73, basis: 'stage' });
    expect(retentionFor(policy, 'ok', input({ status: 'no_show' }))).toEqual({ percent: 100, basis: 'stage' });
  });

  it('etapa sin configurar: 0 %', () => {
    const p: CancellationPolicy = { stages: [{ fromStatus: 'driver_arrived', percent: 50 }] };
    expect(retentionFor(p, 'ok', input({ status: 'confirmed' }))).toEqual({ percent: 0, basis: 'no_stage' });
  });

  it('gracia: 0 % dentro de los minutos desde que entró en la etapa; sin hora, a favor del cliente', () => {
    expect(retentionFor(policy, 'ok', input({ status: 'confirmed', stageEnteredMs: NOW - 5 * MIN })))
      .toEqual({ percent: 0, basis: 'grace' });
    expect(retentionFor(policy, 'ok', input({ status: 'confirmed', stageEnteredMs: NOW - 5 * MIN - 1 })))
      .toEqual({ percent: 11, basis: 'stage' });
    expect(retentionFor(policy, 'ok', input({ status: 'confirmed', stageEnteredMs: null })))
      .toEqual({ percent: 0, basis: 'grace' });
  });

  it('causa del chófer, del sistema o de la plataforma: 0 % siempre', () => {
    for (const cause of ['driver', 'system', 'platform'] as const) {
      expect(retentionFor(policy, 'ok', input({ status: 'driver_arrived', cause })))
        .toEqual({ percent: 0, basis: `${cause}_cause` });
    }
  });
});

describe('retainedCents: redondeo a favor del cliente y tope', () => {
  it('hacia abajo al céntimo', () => {
    expect(retainedCents(999, 37)).toBe(369); // 369,63 → 369
    expect(retainedCents(1, 99)).toBe(0);
    expect(retainedCents(10000, 25)).toBe(2500); // exacto, sin perder un céntimo por coma flotante
    expect(retainedCents(8605, 12.5)).toBe(1075); // 1075,625 → 1075
  });

  it('nunca más que lo pagado ni negativo', () => {
    expect(retainedCents(5000, 100)).toBe(5000);
    expect(retainedCents(0, 100)).toBe(0);
    expect(retainedCents(5000, 0)).toBe(0);
  });
});

describe('noShowAvailableAt (B4)', () => {
  it('con espera configurada; sin política o sin espera: null (no se puede marcar)', () => {
    expect(noShowAvailableAt(policy, NOW)).toBe(NOW + 15 * MIN);
    expect(noShowAvailableAt(null, NOW)).toBeNull();
    expect(noShowAvailableAt({ stages: [] }, NOW)).toBeNull();
  });
});
