import { describe, it, expect } from '@jest/globals';
import { driverBookkeeping, driverSnapshot, isExpiredPending, isRecentlySeen, nextRating, riderMessage } from './lifecycle';

describe('driverBookkeeping', () => {
  it('al completar libera al chófer y suma el viaje', () => {
    expect(driverBookkeeping({ status: 'in_progress', driverId: 'd' }, { status: 'completed', driverId: 'd' }))
      .toEqual({ driverId: 'd', release: true, countRide: true });
  });

  it('al cancelar con chófer asignado solo lo libera', () => {
    expect(driverBookkeeping({ status: 'confirmed', driverId: 'd' }, { status: 'cancelled', driverId: 'd' }))
      .toEqual({ driverId: 'd', release: true, countRide: false });
  });

  it('sin chófer o sin cambio de estado no hace nada', () => {
    expect(driverBookkeeping({ status: 'pending' }, { status: 'cancelled' })).toBeNull();
    expect(driverBookkeeping({ status: 'completed', driverId: 'd' }, { status: 'completed', driverId: 'd' })).toBeNull();
    expect(driverBookkeeping({ status: 'confirmed', driverId: 'd' }, { status: 'driver_arriving', driverId: 'd' })).toBeNull();
  });
});

describe('riderMessage', () => {
  it('distingue quién canceló', () => {
    expect(riderMessage('cancelled', 'rider')?.body).toContain('Cancelaste');
    expect(riderMessage('cancelled', 'system')?.body).toContain('No se te cobrará');
    expect(riderMessage('pending')).toBeNull();
  });
});

describe('driverSnapshot', () => {
  it('resume chófer y vehículo para el pasajero', () => {
    expect(driverSnapshot({ displayName: ' Luis ', phone: '+591 7' }, { make: 'Toyota', model: 'Camry', color: 'Negro', plate: '123ABC' }))
      .toEqual({ driverName: 'Luis', driverPhone: '+591 7', driverPhotoUrl: null, vehicleLabel: 'Toyota Camry Negro', vehiclePlate: '123ABC' });
  });

  it('sin datos usa valores seguros', () => {
    expect(driverSnapshot(undefined, undefined).driverName).toBe('Tu chófer');
  });
});

describe('isExpiredPending', () => {
  const now = Date.UTC(2026, 9, 15, 12);
  it('no cancela reservas programadas para el futuro aunque sean viejas', () => {
    expect(isExpiredPending({ status: 'pending', scheduledAtMs: now + 3 * 86400e3 }, now)).toBe(false);
  });
  it('cancela una pendiente cuya hora de recogida ya pasó', () => {
    expect(isExpiredPending({ status: 'pending', scheduledAtMs: now - 3600e3 }, now)).toBe(true);
  });
  it('respeta el margen y solo toca pendientes', () => {
    expect(isExpiredPending({ status: 'pending', scheduledAtMs: now - 10 * 60e3 }, now)).toBe(false);
    expect(isExpiredPending({ status: 'confirmed', scheduledAtMs: now - 3600e3 }, now)).toBe(false);
  });
});

describe('isRecentlySeen', () => {
  const now = Date.UTC(2026, 9, 15, 12);
  it('acepta chóferes con señal reciente', () => {
    expect(isRecentlySeen(now - 60e3, now)).toBe(true);
  });
  it('descarta chóferes sin señal o con señal vieja', () => {
    expect(isRecentlySeen(undefined, now)).toBe(false);
    expect(isRecentlySeen(now - 20 * 60e3, now)).toBe(false);
  });
});

describe('nextRating', () => {
  it('la primera valoración define la media', () => {
    expect(nextRating({}, 4)).toEqual({ rating: 4, ratingSum: 4, ratingCount: 1 });
  });
  it('acumula y redondea a dos decimales', () => {
    expect(nextRating({ ratingSum: 9, ratingCount: 2 }, 5)).toEqual({ rating: 4.67, ratingSum: 14, ratingCount: 3 });
  });
  it('acota valores fuera de rango', () => {
    expect(nextRating({}, 9).rating).toBe(5);
    expect(nextRating({}, 0).rating).toBe(1);
  });
});
