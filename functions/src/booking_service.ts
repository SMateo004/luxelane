/**
 * Cotización y creación de reservas en el servidor (D2). La app manda solo
 * datos del viaje; el precio lo calcula el servidor con pricingRules y
 * config/pricing. createBooking es la única forma de crear una reserva.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { CreateInput, createSchema, QuoteInput, quoteSchema } from './booking_schema';
import { tripDistance, DistanceSource } from './distance';
import { computeFare, FareBreakdown, fixedFareKey, PricingConfig } from './fare';
import type { FareRule } from './pricing';
import { buildOpenRequest } from './open_requests';
import { airportFor, areaLabel, cityOf, destinationOk, originOk, PlaceIn } from './service_area';

export interface BookingDeps {
  db: admin.firestore.Firestore;
  /** Clave de servidor de Maps (MAPS_SERVER_KEY); vacía = sin Routes API. */
  mapsKey?: string;
  fetchFn?: typeof fetch;
  now?: () => number;
}

/** Error con motivo legible por la app en details.reason. */
export function bookingError(
  code: 'invalid-argument' | 'failed-precondition' | 'permission-denied' | 'unauthenticated',
  reason: string,
  extra: Record<string, unknown> = {},
): HttpsError {
  return new HttpsError(code, reason, { reason, ...extra });
}

// Los horarios de recogida son de Bolivia (UTC-4, sin horario de verano).
const localHour = (ms: number): number =>
  Number(new Intl.DateTimeFormat('en-US', { timeZone: 'America/La_Paz', hour: 'numeric', hourCycle: 'h23' })
    .format(new Date(ms)));

/** Recogida o destino en un aeropuerto, con la ciudad del otro extremo. */
function airportTrip(origin: PlaceIn, destination: PlaceIn): { iata: string; city: string } | null {
  const from = airportFor(origin);
  const to = airportFor(destination);
  const airport = from ?? to;
  const other = from ? destination : origin;
  const city = airport ? cityOf(other)?.name : undefined;
  return airport && city ? { iata: airport.iata, city } : null;
}

export interface PricedTrip {
  price: number;
  breakdown: FareBreakdown;
  distanceSource: DistanceSource | null;
  rulesVersion: string | null;
  destination: PlaceIn & { name: string; address: string };
}

/** Valida zona y servicio y calcula el precio; no escribe nada. */
export async function priceTrip(deps: BookingDeps, trip: QuoteInput): Promise<PricedTrip> {
  const now = deps.now?.() ?? Date.now();
  if (trip.scheduledAt < now - 15 * 60 * 1000) throw bookingError('invalid-argument', 'past_pickup');

  const hourly = trip.serviceType === 'byTheHour';
  // Por horas sin destino fijo: la recogida como referencia (igual que la app).
  const destination = trip.destination ??
    { name: 'Servicio por horas', address: trip.origin.address, lat: trip.origin.lat, lng: trip.origin.lng };
  if (!originOk(trip.origin) || (!hourly && !destinationOk(trip.origin, destination))) {
    throw bookingError('invalid-argument', 'out_of_area');
  }

  const db = deps.db;
  const [global, ruleSnap, configSnap] = await Promise.all([
    db.collection('config').doc('global').get(),
    db.collection('pricingRules').doc(`${trip.vehicleClass}_${trip.serviceType}`).get(),
    db.collection('config').doc('pricing').get(),
  ]);
  const g = global.data() ?? {};
  if (g.isMaintenanceMode === true) throw bookingError('failed-precondition', 'service_unavailable');
  if (trip.vehicleClass === 'firstClass' && g.firstClassEnabled !== true) {
    throw bookingError('failed-precondition', 'class_unavailable');
  }
  const config = (configSnap.data() ?? {}) as PricingConfig;
  const rule = ruleSnap.exists ? (ruleSnap.data() as FareRule) : undefined;

  const trip2 = hourly ? null : airportTrip(trip.origin, destination);
  const hasFixed = trip2 !== null &&
    typeof config.fixedAirportFares?.[fixedFareKey(trip2.iata, trip2.city, trip.vehicleClass)] === 'number';

  let km: number | undefined;
  let distanceSource: DistanceSource | null = null;
  if (!hourly && !hasFixed) {
    const d = await tripDistance(trip.origin, destination,
      { apiKey: deps.mapsKey, routeFactor: config.routeFactor, fetchFn: deps.fetchFn });
    if (!d) throw bookingError('failed-precondition', 'pricing_unavailable');
    km = d.km;
    distanceSource = d.source;
  }

  const fare = computeFare({
    vehicleClass: trip.vehicleClass,
    serviceType: trip.serviceType,
    km,
    hours: trip.hours,
    localHour: localHour(trip.scheduledAt),
    airportTrip: trip2,
  }, rule, config);
  if (!fare.ok) {
    const code = fare.error === 'pricing_unavailable' || fare.error === 'class_unavailable'
      ? 'failed-precondition'
      : 'invalid-argument';
    throw bookingError(code, fare.error);
  }
  return {
    price: fare.price,
    breakdown: fare.breakdown,
    distanceSource,
    rulesVersion: ruleSnap.updateTime?.toDate().toISOString() ?? null,
    destination: { ...destination, name: destination.name ?? '' },
  };
}

function parse<T>(schema: { safeParse: (d: unknown) => { success: true; data: T } | { success: false; error: { issues: { path: PropertyKey[] }[] } } }, data: unknown): T {
  const r = schema.safeParse(data);
  if (!r.success) {
    const fields = [...new Set(r.error.issues.map((i) => i.path.join('.') || '(raíz)'))];
    throw bookingError('invalid-argument', 'invalid_request', { fields });
  }
  return r.data;
}

async function requireActiveRider(db: admin.firestore.Firestore, uid: string | undefined) {
  if (!uid) throw bookingError('unauthenticated', 'unauthenticated');
  const user = (await db.collection('users').doc(uid).get()).data();
  if (!user || user.role !== 'rider' || user.isActive === false) {
    throw bookingError('permission-denied', 'inactive_user');
  }
  return user;
}

export async function quoteBooking(deps: BookingDeps, uid: string | undefined, data: unknown) {
  await requireActiveRider(deps.db, uid);
  const trip = parse<QuoteInput>(quoteSchema, data);
  const priced = await priceTrip(deps, trip);
  return { price: priced.price, breakdown: priced.breakdown, distanceSource: priced.distanceSource };
}

const geo = (p: PlaceIn & { name?: string; address?: string }) => ({
  name: p.name ?? '',
  address: p.address ?? '',
  coordinates: new admin.firestore.GeoPoint(p.lat, p.lng),
});

export async function createBooking(deps: BookingDeps, uid: string | undefined, data: unknown) {
  const user = await requireActiveRider(deps.db, uid);
  const input = parse<CreateInput>(createSchema, data);
  const priced = await priceTrip(deps, input);
  // El pasajero vio un precio menor: no se cobra más sin que lo confirme.
  if (input.quotedPrice !== undefined && priced.price > input.quotedPrice) {
    throw bookingError('failed-precondition', 'price_changed', { price: priced.price });
  }

  const db = deps.db;
  const ref = db.collection('bookings').doc();
  const now = admin.firestore.Timestamp.fromMillis(deps.now?.() ?? Date.now());
  const pickupAirport = input.serviceType === 'oneWay' ? airportFor(input.origin)?.iata ?? null : null;
  const prefs = user.ridePreferences;
  const booking = {
    id: ref.id,
    riderId: uid!,
    driverId: null,
    origin: geo(input.origin),
    destination: geo(priced.destination),
    scheduledAt: admin.firestore.Timestamp.fromMillis(input.scheduledAt),
    class: input.vehicleClass,
    vehicleClass: input.vehicleClass,
    serviceType: input.serviceType,
    status: 'pending',
    estimatedPrice: priced.price,
    finalPrice: null,
    paymentId: null,
    createdAt: now,
    updatedAt: now,
    notes: input.notes?.trim() || null,
    ...(input.guest ? { guest: input.guest } : {}),
    flightNumber: input.flightNumber ?? null,
    flightType: pickupAirport ? input.flightType ?? null : null,
    pickupAirport,
    hours: input.serviceType === 'byTheHour' ? input.hours ?? null : null,
    passengerCount: input.passengerCount,
    luggageCount: input.luggageCount,
    ...(prefs && typeof prefs === 'object' && Object.keys(prefs).length ? { riderPreferences: prefs } : {}),
    pickupArea: areaLabel(input.origin),
    dropoffArea: input.serviceType === 'byTheHour' ? null : areaLabel(priced.destination),
    pricing: {
      source: 'server',
      distanceSource: priced.distanceSource,
      rulesVersion: priced.rulesVersion,
      breakdown: priced.breakdown,
    },
  };

  // Reserva y solicitud abierta juntas: nunca una sin la otra.
  await db.runTransaction(async (tx) => {
    tx.set(ref, booking);
    tx.set(db.collection('openRequests').doc(ref.id), buildOpenRequest(booking));
    if (priced.distanceSource === 'fallback') {
      tx.set(db.collection('adminAlerts').doc(), {
        type: 'distance_fallback',
        bookingId: ref.id,
        message: 'Precio calculado con línea recta × routeFactor: la ruta por calles no estuvo disponible.',
        createdAt: now,
        resolved: false,
      });
    }
  });
  return { bookingId: ref.id, price: priced.price };
}
