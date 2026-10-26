import { describe, it, expect } from '@jest/globals';
import { buildOpenRequest } from './open_requests';

const booking = {
  riderId: 'ana',
  class: 'business',
  serviceType: 'oneWay',
  scheduledAt: 'ts',
  estimatedPrice: 120,
  passengerCount: 2,
  luggageCount: 1,
  pickupAirport: 'VVI',
  flightType: 'international',
  pickupArea: 'Aeropuerto Internacional Viru Viru',
  dropoffArea: 'Santa Cruz de la Sierra',
  origin: { address: 'Terminal, puerta 3', coordinates: { latitude: -17.64471, longitude: -63.13532 } },
  destination: { address: 'Calle Exacta 123', coordinates: { latitude: -17.78339, longitude: -63.18211 } },
  notes: 'Toque el timbre',
  flightNumber: 'AA922',
  riderPreferences: { music: 'jazz' },
  guest: { firstName: 'Carla', phone: '+59170000001', email: 'c@example.com' },
};

describe('buildOpenRequest', () => {
  it('no copia datos personales ni direcciones exactas', () => {
    const r = buildOpenRequest(booking) as unknown as Record<string, unknown>;
    for (const k of ['riderId', 'origin', 'destination', 'notes', 'flightNumber', 'riderPreferences', 'guest']) {
      expect(r).not.toHaveProperty(k);
    }
    const text = JSON.stringify(r);
    for (const secret of ['Exacta', 'puerta 3', 'timbre', 'AA922', 'jazz', 'Carla', '+5917', 'example.com']) {
      expect(text).not.toContain(secret);
    }
  });

  it('da lo necesario para decidir, con la zona aproximada', () => {
    const r = buildOpenRequest(booking);
    expect(r).toMatchObject({
      vehicleClass: 'business',
      serviceType: 'oneWay',
      estimatedPrice: 120,
      passengerCount: 2,
      luggageCount: 1,
      pickupAirport: 'VVI',
      flightType: 'international',
      pickupArea: 'Aeropuerto Internacional Viru Viru',
      dropoffArea: 'Santa Cruz de la Sierra',
      pickupApprox: { lat: -17.64, lng: -63.14 },
      dropoffApprox: { lat: -17.78, lng: -63.18 },
    });
    expect(r.tripKm).toBeGreaterThan(15);
    expect(r.tripKm).toBeLessThan(17);
  });

  it('por horas no tiene destino', () => {
    const r = buildOpenRequest({ ...booking, serviceType: 'byTheHour', hours: 4 });
    expect(r).toMatchObject({ hours: 4, dropoffArea: null, dropoffApprox: null, tripKm: null });
  });

  it('descarta zonas que no son un nombre corto', () => {
    const r = buildOpenRequest({ ...booking, pickupArea: 'x'.repeat(81), dropoffArea: 42 });
    expect(r.pickupArea).toBeNull();
    expect(r.dropoffArea).toBeNull();
  });

  it('lleva quién la liberó (sin repetir), para no ofrecérsela otra vez (E18)', () => {
    expect(buildOpenRequest({ ...booking, releasedBy: ['chofer2', 'chofer2', 7] }).releasedBy)
      .toEqual(['chofer2']);
    expect(buildOpenRequest(booking).releasedBy).toEqual([]);
  });
});
