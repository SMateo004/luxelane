/**
 * Vuelos, decisión 4 (diferida): mientras la detección de aeropuertos siga en
 * dos listas fijas, la del servidor (service_area.ts) y la de la app
 * (lib/core/utils/service_area.dart) deben ser iguales: código IATA,
 * coordenadas y nombre. Si alguien cambia una sola, este test falla.
 */
import { describe, it, expect } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';
import { AIRPORTS } from './service_area';

const root = join(__dirname, '..', '..');
const DART = join(root, 'lib', 'core', 'utils', 'service_area.dart');

interface Airport { iata: string; name: string; lat: number; lng: number }

/** Lee las entradas `ServiceAirport('IATA', 'Nombre', lat, lng)` del archivo de la app. */
export function parseDartAirports(src: string): Airport[] {
  const block = src.slice(src.indexOf('static const airports'));
  const re = /ServiceAirport\(\s*'([^']*)',[^\n]*\n\s*'([^']*)',[^\n]*\n\s*(-?[\d.]+),\s*\n\s*(-?[\d.]+),?\s*\)/g;
  return [...block.matchAll(re)].map((m) => ({ iata: m[1], name: m[2], lat: Number(m[3]), lng: Number(m[4]) }));
}

const server = AIRPORTS.map(({ iata, name, lat, lng }) => ({ iata, name, lat, lng }));

describe('aeropuertos: servidor y app iguales', () => {
  const app = parseDartAirports(readFileSync(DART, 'utf8'));

  it('la app tiene los mismos aeropuertos, en el mismo orden, con el mismo código, nombre y coordenadas', () => {
    expect(app.length).toBeGreaterThan(0);
    expect(app).toEqual(server);
  });

  it('la comparación detecta una coordenada, un nombre o un aeropuerto distintos', () => {
    const src = readFileSync(DART, 'utf8');
    const moved = parseDartAirports(src.replace('-17.6447', '-17.6448'));
    expect(moved).not.toEqual(server);
    const renamed = parseDartAirports(src.replace("'Aeropuerto El Trompillo'", "'Aeropuerto Trompillo'"));
    expect(renamed).not.toEqual(server);
    const missing = parseDartAirports(src.replace("'UYU'", "'UYX'"));
    expect(missing).not.toEqual(server);
  });
});
