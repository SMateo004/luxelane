import { describe, it, expect } from '@jest/globals';
import { assertTarget, classifyInFlight, remedyFor } from './trips_in_flight';

describe('classifyInFlight', () => {
  it('bloquean los viajes que avanzaron con la app antigua (sin eventos)', () => {
    const r = classifyInFlight([
      { id: 'a', status: 'driver_arriving', serverFlow: false },
      { id: 'b', status: 'driver_arrived', serverFlow: true },
      { id: 'c', status: 'in_progress', serverFlow: false },
      { id: 'd', status: 'confirmed', serverFlow: false },
      { id: 'e', status: 'completed', serverFlow: false },
      { id: 'f', status: 'verified', serverFlow: true },
    ]);
    expect(r.total).toBe(5);
    expect(r.byStatus).toEqual({ driver_arriving: 1, driver_arrived: 1, in_progress: 1, confirmed: 1, verified: 1 });
    expect(r.blocking.map((t) => t.id)).toEqual(['a', 'c']);
  });

  it('sin viajes activos no hay nada que bloquee', () => {
    expect(classifyInFlight([{ id: 'x', status: 'cancelled', serverFlow: false }]))
      .toEqual({ total: 0, byStatus: {}, blocking: [] });
  });

  it('cada paso tiene su salida si queda atascado', () => {
    expect(remedyFor('in_progress')).toContain('Completado');
    expect(remedyFor('driver_arrived')).toContain('Forzar verificación');
  });
});

describe('assertTarget', () => {
  it('nunca contra luxelane-4e7ae', () => {
    expect(() => assertTarget('luxelane-4e7ae', undefined)).toThrow('no se ejecuta contra luxelane-4e7ae');
    expect(() => assertTarget('luxelane-4e7ae', 'localhost:8080')).toThrow();
  });

  it('demo-* solo con el emulador', () => {
    expect(() => assertTarget('demo-luxelane', undefined)).toThrow('emulador');
    expect(() => assertTarget('demo-luxelane', '127.0.0.1:8080')).not.toThrow();
    expect(() => assertTarget('luxelane-staging', undefined)).not.toThrow();
  });
});
