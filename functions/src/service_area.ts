/**
 * Área de servicio: copia de lib/core/utils/service_area.dart para validar
 * en el servidor. Un test de paridad (service_area.test.ts y
 * test/core/utils/service_area_parity_test.dart) comprueba que ambos lados
 * dan la misma salida para los mismos casos (test/fixtures/).
 */

export interface PlaceIn {
  name?: string;
  address?: string;
  lat: number;
  lng: number;
}

export interface ServiceCity {
  name: string;
  lat: number;
  lng: number;
  radiusKm: number;
}

export interface ServiceAirport {
  iata: string;
  name: string;
  lat: number;
  lng: number;
}

export const CITIES: ServiceCity[] = [
  { name: 'Santa Cruz de la Sierra', lat: -17.7833, lng: -63.1821, radiusKm: 30 },
  { name: 'La Paz', lat: -16.5, lng: -68.15, radiusKm: 25 },
  { name: 'Cochabamba', lat: -17.3895, lng: -66.1568, radiusKm: 25 },
  { name: 'Sucre', lat: -19.0333, lng: -65.2627, radiusKm: 35 },
  { name: 'Oruro', lat: -17.9647, lng: -67.106, radiusKm: 20 },
  { name: 'Potosí', lat: -19.5836, lng: -65.7531, radiusKm: 20 },
  { name: 'Tarija', lat: -21.5355, lng: -64.7296, radiusKm: 20 },
  { name: 'Trinidad', lat: -14.8333, lng: -64.9, radiusKm: 15 },
  { name: 'Cobija', lat: -11.0267, lng: -68.7692, radiusKm: 15 },
];

export const AIRPORTS: ServiceAirport[] = [
  { iata: 'VVI', name: 'Aeropuerto Internacional Viru Viru', lat: -17.6447, lng: -63.1353 },
  { iata: 'SRZ', name: 'Aeropuerto El Trompillo', lat: -17.8117, lng: -63.1717 },
  { iata: 'LPB', name: 'Aeropuerto Internacional El Alto', lat: -16.5131, lng: -68.1922 },
  { iata: 'CBB', name: 'Aeropuerto Internacional Jorge Wilstermann', lat: -17.4211, lng: -66.1769 },
  { iata: 'SRE', name: 'Aeropuerto Internacional Alcantarí', lat: -19.2467, lng: -65.1494 },
  { iata: 'TJA', name: 'Aeropuerto Capitán Oriel Lea Plaza', lat: -21.5558, lng: -64.7014 },
  { iata: 'ORU', name: 'Aeropuerto Internacional Juan Mendoza', lat: -17.9625, lng: -67.0761 },
  { iata: 'POI', name: 'Aeropuerto Capitán Nicolás Rojas', lat: -19.5433, lng: -65.7236 },
  { iata: 'TDD', name: 'Aeropuerto Teniente Jorge Henrich', lat: -14.8186, lng: -64.9181 },
  { iata: 'CIJ', name: 'Aeropuerto Capitán Aníbal Arab', lat: -11.0403, lng: -68.7825 },
  { iata: 'UYU', name: 'Aeropuerto Joya Andina', lat: -20.4464, lng: -66.8486 },
];

export const FALLBACK_RADIUS_KM = 30;
const AIRPORT_RADIUS_KM = 1.2;
const NAMED_AIRPORT_RADIUS_KM = 6;

export const hasCoords = (p: PlaceIn): boolean => p.lat !== 0 || p.lng !== 0;

export function distanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const rad = (d: number) => (d * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLng = rad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371 * Math.asin(Math.sqrt(a));
}

export function cityOf(p: PlaceIn): ServiceCity | null {
  if (!hasCoords(p)) return null;
  let best: ServiceCity | null = null;
  let bestKm = Infinity;
  for (const c of CITIES) {
    const km = distanceKm(p.lat, p.lng, c.lat, c.lng);
    if (km <= c.radiusKm && km < bestKm) {
      best = c;
      bestKm = km;
    }
  }
  return best;
}

const AIRPORT_WORD = /\b(aeropuerto|airport|aerodromo|terminal aerea)\b/;
const STREET_PREFIX =
  /^(av|avda|avenida|calle|c|pasaje|psje|carretera|camino|barrio|b|urb|urbanizacion|zona|villa)\b/;

const fold = (s: string): string => s
  .toLowerCase()
  .replace(/[áàä]/g, 'a')
  .replace(/[éèë]/g, 'e')
  .replace(/[íìï]/g, 'i')
  .replace(/[óòö]/g, 'o')
  .replace(/[úùü]/g, 'u')
  .trim();

export function airportAt(p: PlaceIn): ServiceAirport | null {
  if (!hasCoords(p)) return null;
  for (const a of AIRPORTS) {
    if (distanceKm(p.lat, p.lng, a.lat, a.lng) <= AIRPORT_RADIUS_KM) return a;
  }
  return null;
}

function namedAirport(p: PlaceIn): boolean {
  const name = fold(p.name ?? '');
  return name !== '' && AIRPORT_WORD.test(name) && !STREET_PREFIX.test(name);
}

export function airportFor(p: PlaceIn): ServiceAirport | null {
  const exact = airportAt(p);
  if (exact || !namedAirport(p) || !hasCoords(p)) return exact;
  let best: ServiceAirport | null = null;
  let bestKm = NAMED_AIRPORT_RADIUS_KM;
  for (const a of AIRPORTS) {
    const km = distanceKm(p.lat, p.lng, a.lat, a.lng);
    if (km <= bestKm) {
      best = a;
      bestKm = km;
    }
  }
  return best;
}

/** Ciudad a la que sirve el aeropuerto (El Alto → La Paz). */
export const airportCity = (a: ServiceAirport): string | null =>
  cityOf({ lat: a.lat, lng: a.lng })?.name ?? null;

/** La recogida se puede atender: tiene coordenadas y está en una ciudad o aeropuerto. */
export const originOk = (origin: PlaceIn): boolean =>
  hasCoords(origin) && (cityOf(origin) !== null || airportFor(origin) !== null);

/**
 * El destino está en la ciudad de la recogida (o, fuera de toda ciudad, a
 * menos de 30 km). A diferencia de la app, el servidor exige coordenadas.
 */
export function destinationOk(origin: PlaceIn, destination: PlaceIn): boolean {
  if (!hasCoords(origin) || !hasCoords(destination)) return false;
  const city = cityOf(origin);
  if (city) return cityOf(destination)?.name === city.name;
  return distanceKm(origin.lat, origin.lng, destination.lat, destination.lng) <= FALLBACK_RADIUS_KM;
}

/** Zona sin la dirección exacta: el aeropuerto o la ciudad. */
export const areaLabel = (p: PlaceIn): string | null =>
  airportFor(p)?.name ?? cityOf(p)?.name ?? null;
