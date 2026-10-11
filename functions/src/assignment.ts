// Selección de chófer para assignNearestDriver.

export interface LatLng {
  lat: number;
  lng: number;
}

export interface DriverCandidate {
  driverId: string;
  isAvailable?: boolean;
  documentsVerified?: boolean;
  location?: LatLng | null;
}

/** Distancia en km entre dos puntos (haversine). */
export function distanceKm(a: LatLng, b: LatLng): number {
  const R = 6371;
  const rad = (d: number) => (d * Math.PI) / 180;
  const dLat = rad(b.lat - a.lat);
  const dLng = rad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

const validPoint = (p?: LatLng | null): p is LatLng =>
  !!p && Number.isFinite(p.lat) && Number.isFinite(p.lng) && !(p.lat === 0 && p.lng === 0);

/**
 * Chóferes elegibles (disponibles y verificados, sin repetir) ordenados del
 * más cercano al más lejano a la recogida. Los que no tienen ubicación van al
 * final; si la recogida no tiene coordenadas se mantiene el orden recibido.
 */
export function rankCandidates(candidates: DriverCandidate[], pickup?: LatLng | null): string[] {
  const seen = new Set<string>();
  const eligible = candidates.filter((c) => {
    if (!c.isAvailable || !c.documentsVerified || seen.has(c.driverId)) return false;
    seen.add(c.driverId);
    return true;
  });
  if (!validPoint(pickup)) return eligible.map((c) => c.driverId);

  const dist = (c: DriverCandidate) =>
    validPoint(c.location) ? distanceKm(pickup, c.location) : Number.POSITIVE_INFINITY;
  return eligible
    .map((c, i) => ({ c, i, d: dist(c) }))
    .sort((a, b) => a.d - b.d || a.i - b.i)
    .map((x) => x.c.driverId);
}
