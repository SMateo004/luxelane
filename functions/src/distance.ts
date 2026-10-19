/**
 * Distancia por calles de un traslado: Routes API con la clave del servidor
 * y, si falla o no hay clave, línea recta × routeFactor (config/pricing).
 * Nunca inventa una distancia: sin ninguna de las dos devuelve null.
 */
import { distanceKm, PlaceIn } from './service_area';

export type DistanceSource = 'routes' | 'fallback';

export interface TripDistance {
  km: number;
  source: DistanceSource;
}

type FetchFn = typeof fetch;

const ROUTES_URL = 'https://routes.googleapis.com/directions/v2:computeRoutes';
const TIMEOUT_MS = 5000;

export async function routesKm(
  origin: PlaceIn,
  destination: PlaceIn,
  apiKey: string,
  fetchFn: FetchFn = fetch,
): Promise<number | null> {
  const point = (p: PlaceIn) => ({ location: { latLng: { latitude: p.lat, longitude: p.lng } } });
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), TIMEOUT_MS);
  try {
    const res = await fetchFn(ROUTES_URL, {
      method: 'POST',
      signal: abort.signal,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.distanceMeters',
      },
      body: JSON.stringify({ origin: point(origin), destination: point(destination), travelMode: 'DRIVE' }),
    });
    if (!res.ok) return null;
    const body = (await res.json()) as { routes?: { distanceMeters?: number }[] };
    const meters = body.routes?.[0]?.distanceMeters;
    return typeof meters === 'number' && meters >= 0 ? meters / 1000 : null;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

export async function tripDistance(
  origin: PlaceIn,
  destination: PlaceIn,
  opts: { apiKey?: string; routeFactor?: unknown; fetchFn?: FetchFn },
): Promise<TripDistance | null> {
  const key = opts.apiKey?.trim();
  if (key) {
    const km = await routesKm(origin, destination, key, opts.fetchFn);
    if (km !== null) return { km, source: 'routes' };
  }
  const factor = opts.routeFactor;
  if (typeof factor === 'number' && Number.isFinite(factor) && factor >= 1) {
    return {
      km: distanceKm(origin.lat, origin.lng, destination.lat, destination.lng) * factor,
      source: 'fallback',
    };
  }
  return null;
}
