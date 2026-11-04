import { describe, it, expect } from '@jest/globals';
import { createSchema, quoteSchema } from './booking_schema';
import { flightInputSchema } from './flight_schema';

// Vuelo FICTICIO de prueba.
const F = { airportCode: 'VVI', flightType: 'domestic', airline: 'Aerolínea de prueba', flightNumber: 'zz 0123',
  flightDate: '2026-11-20', scheduledArrival: '23:50', hasCheckedBag: true };

describe('flightInputSchema (A1)', () => {
  it('normaliza el número y sanea la aerolínea', () => {
    const r = flightInputSchema.parse({ ...F, airline: '  Aerolínea \u0007 de   prueba ' });
    expect(r.flightNumber).toBe('ZZ123');
    expect(r.airline).toBe('Aerolínea de prueba');
  });

  it.each([
    ['número inválido', { flightNumber: '12345' }],
    ['aerolínea con enlace', { airline: 'mira https://x.test' }],
    ['aerolínea con correo', { airline: 'a@b.test' }],
    ['aerolínea de más de 40', { airline: 'A'.repeat(41) }],
    ['fecha que no existe', { flightDate: '2026-02-30' }],
    ['hora inválida', { scheduledArrival: '24:10' }],
    ['tipo desconocido', { flightType: 'regional' }],
    ['sin equipaje declarado', { hasCheckedBag: undefined }],
    ['aeropuerto en minúsculas', { airportCode: 'vvi' }],
    ['readyAt mandado por el cliente', { readyAt: 1 }],
    ['estado mandado por el cliente', { status: 'landed' }],
  ])('%s: rechazado', (_n, patch) => {
    expect(flightInputSchema.safeParse({ ...F, ...patch }).success).toBe(false);
  });

  it('aerolínea opcional', () => {
    const { airline: _a, ...sin } = F;
    expect(flightInputSchema.safeParse(sin).success).toBe(true);
  });

  it('quoteBooking y createBooking lo aceptan opcional (una app antigua no lo manda)', () => {
    const trip = { origin: { address: 'x', lat: -17.64, lng: -63.13 }, destination: { address: 'y', lat: -17.78, lng: -63.18 },
      scheduledAt: 1_900_000_000_000, vehicleClass: 'business', serviceType: 'oneWay' };
    expect(quoteSchema.safeParse(trip).success).toBe(true);
    expect(quoteSchema.safeParse({ ...trip, flight: F }).success).toBe(true);
    expect(quoteSchema.safeParse({ ...trip, flight: { ...F, flightNumber: 'x' } }).success).toBe(false);
    const create = { ...trip, passengerCount: 1, luggageCount: 0, requestId: '3f0e2b8e-1a2b-4c3d-8e9f-0a1b2c3d4e5f',
      channel: 'native' };
    const ok = createSchema.safeParse({ ...create, flight: F });
    expect(ok.success).toBe(true);
  });
});
