import { describe, it, expect } from '@jest/globals';
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { airportFor, areaLabel, cityOf, destinationOk, originOk, PlaceIn } from './service_area';

// Paridad con lib/core/utils/service_area.dart: mismas entradas, misma salida
// (la esperada la generó la versión Dart; ver
// test/core/utils/service_area_parity_test.dart).
const fixtures = resolve(__dirname, '../../test/fixtures');
const inputs = JSON.parse(readFileSync(`${fixtures}/service_area_inputs.json`, 'utf8'));
const expected = JSON.parse(readFileSync(`${fixtures}/service_area_expected.json`, 'utf8'));

describe('service_area.ts igual que service_area.dart', () => {
  const places: Record<string, PlaceIn> = {};
  for (const p of inputs.places) places[p.id] = p;

  it('ciudad, aeropuerto, zona y recogida válida', () => {
    const out: Record<string, unknown> = {};
    for (const [id, p] of Object.entries(places)) {
      out[id] = {
        city: cityOf(p)?.name ?? null,
        airport: airportFor(p)?.iata ?? null,
        areaLabel: areaLabel(p),
        originOk: originOk(p),
      };
    }
    expect(out).toEqual(expected.places);
  });

  it('destino en la misma ciudad', () => {
    const out = inputs.trips.map(([from, to]: [string, string]) => ({
      from,
      to,
      destinationOk: destinationOk(places[from], places[to]),
    }));
    expect(out).toEqual(expected.trips);
  });

  it('el servidor exige coordenadas en el destino (la app las deja pasar)', () => {
    expect(destinationOk(places.scz_centro, places.sin_coords)).toBe(false);
  });
});
