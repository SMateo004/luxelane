import { describe, it, expect } from '@jest/globals';
import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';

/**
 * Vuelos, decisión 3: cuando readyAt cambia, scheduledAt cambia con él, pero
 * el precio queda el de la reserva. Evidencia en el código: solo
 * booking_service.ts calcula precios (computeFare dentro de priceTrip,
 * llamado por quoteBooking y createBooking) y solo createBooking escribe
 * estimatedPrice. Ningún cambio de vuelo (flight.ts, flight_updates.ts)
 * toca el precio.
 */
const src = (f: string) => readFileSync(join(__dirname, f), 'utf8');
const files = readdirSync(__dirname).filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts'));

describe('el precio se fija al crear la reserva', () => {
  it('computeFare solo se llama en priceTrip (booking_service.ts)', () => {
    const callers = files.filter((f) => /\bcomputeFare\(/.test(src(f)) && f !== 'fare.ts');
    expect(callers).toEqual(['booking_service.ts']);
    expect(src('booking_service.ts').match(/\bcomputeFare\(/g)).toHaveLength(1);
  });

  it('priceTrip solo lo usan quoteBooking y createBooking', () => {
    const callers = files.filter((f) => /\bpriceTrip\(/.test(src(f)));
    expect(callers).toEqual(['booking_service.ts']);
    // La definición y dos llamadas (cotizar y reservar).
    expect(src('booking_service.ts').match(/\bpriceTrip\(/g)).toHaveLength(3);
  });

  it('estimatedPrice solo se escribe al crear la reserva', () => {
    const writers = files.filter((f) => /estimatedPrice:\s*(priced|input|fare)/.test(src(f)));
    expect(writers).toEqual(['booking_service.ts']);
  });

  it('los cambios de vuelo no tocan precio ni desglose', () => {
    for (const f of ['flight.ts', 'flight_updates.ts']) {
      expect(src(f)).not.toMatch(/estimatedPrice|finalPrice|pricing\b|computeFare|priceTrip/);
    }
  });
});
