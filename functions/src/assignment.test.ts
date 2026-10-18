import { describe, it, expect } from '@jest/globals';
import { distanceKm, rankCandidates } from './assignment';
import { fromCents, toCents } from './money';

const laPaz = { lat: -16.5, lng: -68.15 };

describe('rankCandidates', () => {
  it('descarta chóferes no disponibles, no verificados o repetidos', () => {
    expect(
      rankCandidates([
        { driverId: 'a', isAvailable: false, documentsVerified: true },
        { driverId: 'b', isAvailable: true, documentsVerified: false },
        { driverId: 'c', isAvailable: true, documentsVerified: true },
        { driverId: 'c', isAvailable: true, documentsVerified: true },
      ]),
    ).toEqual(['c']);
  });

  it('ordena por cercanía a la recogida; sin ubicación al final', () => {
    expect(
      rankCandidates(
        [
          { driverId: 'sin-ubicacion', isAvailable: true, documentsVerified: true },
          { driverId: 'lejos', isAvailable: true, documentsVerified: true, location: { lat: -17.78, lng: -63.18 } },
          { driverId: 'cerca', isAvailable: true, documentsVerified: true, location: { lat: -16.51, lng: -68.12 } },
        ],
        laPaz,
      ),
    ).toEqual(['cerca', 'lejos', 'sin-ubicacion']);
  });

  it('sin coordenadas de recogida mantiene el orden', () => {
    const c = [
      { driverId: 'x', isAvailable: true, documentsVerified: true, location: laPaz },
      { driverId: 'y', isAvailable: true, documentsVerified: true },
    ];
    expect(rankCandidates(c, { lat: 0, lng: 0 })).toEqual(['x', 'y']);
  });
});

describe('distanceKm', () => {
  it('La Paz – Santa Cruz ≈ 550 km', () => {
    expect(distanceKm(laPaz, { lat: -17.78, lng: -63.18 })).toBeGreaterThan(500);
    expect(distanceKm(laPaz, { lat: -17.78, lng: -63.18 })).toBeLessThan(600);
  });
});

describe('money', () => {
  it('convierte bolivianos y centavos sin errores de coma flotante', () => {
    expect(toCents(125.5)).toBe(12550);
    expect(toCents(0.1 + 0.2)).toBe(30);
    expect(fromCents(12550)).toBe(125.5);
  });
});
