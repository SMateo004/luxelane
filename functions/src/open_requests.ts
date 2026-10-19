/**
 * Solicitudes abiertas que ve un chófer verificado antes de aceptar.
 * Solo lo necesario para decidir: nada de nombres, contactos, direcciones
 * exactas, notas ni preferencias del pasajero.
 */

interface GeoLike {
  latitude: number;
  longitude: number;
}

export interface BookingForRequest {
  class?: string;
  vehicleClass?: string;
  serviceType?: string;
  scheduledAt?: unknown;
  estimatedPrice?: number;
  hours?: number | null;
  passengerCount?: number;
  luggageCount?: number;
  pickupAirport?: string | null;
  flightType?: string | null;
  pickupArea?: unknown;
  dropoffArea?: unknown;
  origin?: { coordinates?: GeoLike };
  destination?: { coordinates?: GeoLike };
}

export interface ApproxPoint {
  lat: number;
  lng: number;
}

export interface OpenRequest {
  vehicleClass: string;
  serviceType: string;
  scheduledAt: unknown;
  estimatedPrice: number;
  hours: number | null;
  passengerCount: number;
  luggageCount: number;
  pickupAirport: string | null;
  flightType: string | null;
  pickupArea: string | null;
  dropoffArea: string | null;
  pickupApprox: ApproxPoint | null;
  dropoffApprox: ApproxPoint | null;
  tripKm: number | null;
}

/** Dos decimales: unos 1,1 km. Basta para la zona, no para la puerta. */
export function approx(p?: GeoLike): ApproxPoint | null {
  if (!p || (p.latitude === 0 && p.longitude === 0)) return null;
  return {
    lat: Math.round(p.latitude * 100) / 100,
    lng: Math.round(p.longitude * 100) / 100,
  };
}

export function distanceKm(a: GeoLike, b: GeoLike): number {
  const rad = (d: number) => (d * Math.PI) / 180;
  const dLat = rad(b.latitude - a.latitude);
  const dLng = rad(b.longitude - a.longitude);
  const h = Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(h));
}

// Nombre de ciudad o aeropuerto que calcula la app; cualquier otra cosa se
// descarta.
function area(v: unknown): string | null {
  return typeof v === 'string' && v.trim() && v.length <= 80 ? v.trim() : null;
}

export function buildOpenRequest(b: BookingForRequest): OpenRequest {
  const hourly = b.serviceType === 'byTheHour';
  const from = b.origin?.coordinates;
  const to = b.destination?.coordinates;
  return {
    vehicleClass: b.class ?? b.vehicleClass ?? 'business',
    serviceType: b.serviceType ?? 'oneWay',
    scheduledAt: b.scheduledAt ?? null,
    estimatedPrice: b.estimatedPrice ?? 0,
    hours: b.hours ?? null,
    passengerCount: b.passengerCount ?? 1,
    luggageCount: b.luggageCount ?? 0,
    pickupAirport: b.pickupAirport ?? null,
    flightType: b.flightType ?? null,
    pickupArea: area(b.pickupArea),
    dropoffArea: hourly ? null : area(b.dropoffArea),
    pickupApprox: approx(from),
    dropoffApprox: hourly ? null : approx(to),
    tripKm: !hourly && approx(from) && approx(to)
      ? Math.round(distanceKm(from!, to!) * 10) / 10
      : null,
  };
}
