/**
 * Ventana del chófer, A5: el resumen del historial del chófer, campo por
 * campo. Solo los campos de SUMMARY_FIELDS; ningún dato del pasajero.
 * Datos FICTICIOS.
 */
import { describe, it, expect } from '@jest/globals';
import * as admin from 'firebase-admin';
import { buildDriverSummary, SUMMARY_FIELDS, summaryDriver } from './driver_history';

const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const T = Date.UTC(2026, 10, 20, 15);

/** Reserva con todos los datos personales posibles. */
const full = (extra: Record<string, unknown> = {}) => ({
  riderId: 'ana', driverId: 'luis', status: 'completed', serviceType: 'oneWay', vehicleClass: 'business',
  estimatedPrice: 120, finalPrice: 110, refunded: false,
  settlement: { amount: 110, commissionPct: 20, platformCommission: 22, driverPayout: 88, extra: 'x' },
  origin: { name: 'Casa (prueba)', address: 'Calle Exacta 1', coordinates: new admin.firestore.GeoPoint(-17.6448, -63.1353) },
  destination: { name: 'Oficina', address: 'Av. Exacta 2', coordinates: new admin.firestore.GeoPoint(-17.7834, -63.1821) },
  pickupArea: 'Aeropuerto', dropoffArea: 'Santa Cruz de la Sierra',
  notes: 'Nota', guest: { firstName: 'Carla', phone: '+59170000001' }, riderComment: 'Comentario',
  riderRating: 5, flight: { flightNumber: 'ZZ1' }, flightNumber: 'ZZ1', preferredDriverLanguages: ['es'],
  pricing: { breakdown: { km: 16.4 } }, startedAt: ts(T - 25 * 60_000), completedAt: ts(T), updatedAt: ts(T + 1000),
  driverInfo: { name: 'Luis', phone: '+59170000002' },
  ...extra,
});

describe('buildDriverSummary', () => {
  it('campo por campo, solo la lista cerrada', () => {
    const s = buildDriverSummary('b1', full())!;
    expect(Object.keys(s).sort()).toEqual([...SUMMARY_FIELDS].sort());
    expect(s.bookingId).toBe('b1');
    expect(s.status).toBe('completed');
    expect(s.endedAt!.toMillis()).toBe(T);
    expect(s.serviceType).toBe('oneWay');
    expect(s.vehicleClass).toBe('business');
    expect(s.pickupArea).toBe('Aeropuerto');
    expect(s.dropoffArea).toBe('Santa Cruz de la Sierra');
    expect(s.pickupApprox).toEqual({ lat: -17.64, lng: -63.14 });
    expect(s.dropoffApprox).toEqual({ lat: -17.78, lng: -63.18 });
    expect(s.distanceKm).toBe(16.4);
    expect(s.durationMinutes).toBe(25);
    expect(s.riderRating).toBe(5);
    expect(s.estimatedPrice).toBe(120);
    expect(s.finalPrice).toBe(110);
    // Solo los cuatro números del reparto: nada que llegue de más.
    expect(s.settlement).toEqual({ amount: 110, commissionPct: 20, platformCommission: 22, driverPayout: 88 });
    expect(s.refunded).toBe(false);
  });

  it('ningún dato del pasajero ni del vuelo en el resumen', () => {
    const text = JSON.stringify(buildDriverSummary('b1', full()));
    for (const pii of ['ana', 'Carla', '+591', 'Exacta', 'Casa', 'Oficina', 'Nota', 'Comentario', 'ZZ1', 'Luis', '-17.6448']) {
      expect(text).not.toContain(pii);
    }
  });

  it('por horas: sin destino ni distancia', () => {
    const s = buildDriverSummary('b1', full({ serviceType: 'byTheHour' }))!;
    expect(s.dropoffArea).toBeNull();
    expect(s.dropoffApprox).toBeNull();
    expect(s.distanceKm).toBeNull();
  });

  it('fecha de fin según el estado; sin ella, la última actualización', () => {
    expect(buildDriverSummary('b1', full({ status: 'no_show', noShowAt: ts(T + 5) }))!.endedAt!.toMillis()).toBe(T + 5);
    expect(buildDriverSummary('b1', full({ status: 'cancelled', cancelledAt: ts(T + 7) }))!.endedAt!.toMillis()).toBe(T + 7);
    expect(buildDriverSummary('b1', full({ status: 'cancelled' }))!.endedAt!.toMillis()).toBe(T + 1000);
  });

  it('valoración fuera de 1 a 5 o no entera: null; sin km de ruta, la distancia entre zonas', () => {
    expect(buildDriverSummary('b1', full({ riderRating: 7 }))!.riderRating).toBeNull();
    expect(buildDriverSummary('b1', full({ riderRating: 4.5 }))!.riderRating).toBeNull();
    expect(buildDriverSummary('b1', full({ pricing: {} }))!.distanceKm).toBeGreaterThan(0);
  });

  it('sin chófer o sin estado final: no hay resumen', () => {
    expect(buildDriverSummary('b1', full({ driverId: null }))).toBeNull();
    for (const status of ['pending', 'confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress']) {
      expect(summaryDriver(full({ status }))).toBeNull();
    }
    expect(summaryDriver(full())).toBe('luis');
  });
});
