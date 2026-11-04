/**
 * Reservas con vuelo de llegada (prompt de vuelos, Parte A).
 *
 * - A1: esquema del vuelo que manda la app en quoteBooking y createBooking.
 *   El cliente nunca manda readyAt ni estados: todo lo calcula el servidor.
 * - A2/A4: el vuelo de la reserva (bookings/{id}.flight, solo servidor), su
 *   readyAt y la copia para el chófer (bookings/{id}/driverView/flight).
 * - A5: datos fijados a mano por un admin, con bloqueo manual.
 * - A7: «no se presentó» forzado por un admin con motivo y auditoría.
 * - A9: aeropuertos y sus puntos de recogida (airports/{código}).
 *
 * Minutos, umbrales y puntos de recogida salen de config/ops y de la
 * colección airports: aquí no hay ninguno fijo.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { AdminActor, changedFields, reasonSchema, writeAudit } from './admin_audit';
import { readPolicy } from './cancellation_policy';
import { cleanText } from './driver_application';
import { readBoard } from './flight_provider';
import { applyFlightTx, driverFlightRef, driverFlightView, PushFn, readForFlight, sendPushes } from './flight_updates';
import { FlightInput } from './flight_schema';
import {
  computeReadyAt, DEFAULT_TIME_ZONE, FlightStatus, FLIGHT_STATUSES, FlightType, localToUtcMs, readExitMinutes,
} from './flight_time';
import { opsConfig } from './ops_config';
import { docId, parseInput } from './schemas';
import { airportFor, PlaceIn } from './service_area';
import { alert, appendEvent } from './trip_flow';

const flightError = (code: 'invalid-argument' | 'failed-precondition' | 'not-found', reason: string,
  extra: Record<string, unknown> = {}) => new HttpsError(code, reason, { reason, ...extra });

const clean = cleanText;

// ---------------------------------------------------------------------------
// A1. Lo que manda la app
// ---------------------------------------------------------------------------


export type FlightSource = 'passenger' | 'manual' | 'auto';
export type DataQuality = 'ok' | 'stale' | 'none';

/** bookings/{id}.flight (horas como Timestamp; solo lo escribe el servidor). */
export interface BookingFlight {
  airportCode: string;
  flightType: FlightType;
  airline: string | null;
  flightNumber: string;
  flightDate: string;
  scheduledArrival: admin.firestore.Timestamp;
  hasCheckedBag: boolean;
  estimatedArrival: admin.firestore.Timestamp | null;
  actualArrival: admin.firestore.Timestamp | null;
  status: FlightStatus;
  source: FlightSource;
  lastObservedAt: admin.firestore.Timestamp | null;
  lastChangeAt: admin.firestore.Timestamp;
  dataQuality: DataQuality;
  /** Fijado a mano por un admin (A5): ninguna fuente automática lo pisa. */
  manualLock: boolean;
}

export interface ResolvedFlight {
  flight: BookingFlight;
  readyAt: number;
  /** El aeropuerto no tiene punto de recogida para este tipo de vuelo. */
  pickupPointMissing: boolean;
}

const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const tsOrNull = (ms: number | null) => (ms === null ? null : ts(ms));

/**
 * Valida el vuelo contra la reserva, el aeropuerto y config/ops y calcula
 * readyAt. Lee la caché flightBoard (nunca la fuente externa). No escribe.
 */
export async function resolveFlight(db: admin.firestore.Firestore, f: FlightInput,
  trip: { origin: PlaceIn; serviceType: string }, nowMs: number): Promise<ResolvedFlight> {
  // Solo recogida en un aeropuerto, y que sea el del vuelo.
  const pickup = trip.serviceType === 'oneWay' ? airportFor(trip.origin)?.iata ?? null : null;
  if (pickup !== f.airportCode) throw flightError('invalid-argument', 'flight_not_airport_pickup');
  const [airport, ops, board] = await Promise.all([
    db.collection('airports').doc(f.airportCode).get(),
    opsConfig(db, nowMs),
    readBoard(db, { airportCode: f.airportCode, flightNumber: f.flightNumber, flightDate: f.flightDate }),
  ]);
  if (!airport.exists) throw flightError('failed-precondition', 'airport_unknown');
  const exit = readExitMinutes(ops);
  // Sin los minutos de salida no se inventan: la reserva con vuelo no se crea.
  if (!exit) throw flightError('failed-precondition', 'flight_config_missing');

  const declared = localToUtcMs(f.flightDate, f.scheduledArrival)!;
  const now = ts(nowMs);
  const flight: BookingFlight = {
    airportCode: f.airportCode, flightType: f.flightType, airline: f.airline ?? null, flightNumber: f.flightNumber,
    flightDate: f.flightDate, hasCheckedBag: f.hasCheckedBag,
    // La hora leída de la fuente, si ya está en la caché; si no, la del billete.
    scheduledArrival: ts(board?.scheduled ?? declared),
    estimatedArrival: tsOrNull(board?.estimated ?? null),
    actualArrival: tsOrNull(board?.actual ?? null),
    status: board?.status ?? 'scheduled',
    source: board ? 'auto' : 'passenger',
    lastObservedAt: board ? ts(board.observedAt) : null,
    lastChangeAt: now,
    dataQuality: board ? 'ok' : 'none',
    manualLock: false,
  };
  const readyAt = computeReadyAt({
    scheduledArrival: board?.scheduled ?? declared, estimatedArrival: board?.estimated ?? null,
    actualArrival: board?.actual ?? null, flightType: f.flightType, hasCheckedBag: f.hasCheckedBag,
  }, exit)!;
  const points = (airport.data()?.pickupPoints ?? {}) as Record<string, unknown>;
  return { flight, readyAt, pickupPointMissing: !validPoint(points[f.flightType]) };
}

// La copia para el chófer y su ruta viven en flight_updates.ts.
export { driverFlightRef, driverFlightView };

// ---------------------------------------------------------------------------
// A5. Datos fijados por un admin
// ---------------------------------------------------------------------------

const epochMs = z.number().int().positive().max(4_102_444_800_000);

export const setFlightSchema = z.strictObject({
  bookingId: docId,
  status: z.enum(FLIGHT_STATUSES as unknown as [FlightStatus, ...FlightStatus[]]),
  estimatedArrival: epochMs.nullable().optional(),
  actualArrival: epochMs.nullable().optional(),
  reason: reasonSchema,
}).refine((i) => i.status !== 'landed' || typeof i.actualArrival === 'number',
  { message: 'actualArrival', path: ['actualArrival'] });

export interface FlightDeps { db: admin.firestore.Firestore; now?: () => number; push?: PushFn }
const nowOf = (d: FlightDeps) => d.now?.() ?? Date.now();

/**
 * Fija hora estimada, real y estado (source=manual) y deja el bloqueo
 * manual: mientras esté, ninguna fuente automática pisa estos campos.
 * Recalcula readyAt. Auditoría en la misma transacción.
 */
export async function adminSetFlightInfo(deps: FlightDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(setFlightSchema, data);
  const db = deps.db;
  const nowMs = nowOf(deps);
  const ops = await opsConfig(db, nowMs);
  if (!readExitMinutes(ops)) throw flightError('failed-precondition', 'flight_config_missing');
  const ref = db.collection('bookings').doc(input.bookingId);
  const out = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const b = snap.data();
    if (!b) throw flightError('not-found', 'booking_not_found');
    const f = b.flight as BookingFlight | undefined;
    if (!f) throw flightError('failed-precondition', 'booking_without_flight');
    const reads = await readForFlight(tx, db, b, ref.id);
    const now = ts(nowMs);
    const next: BookingFlight = {
      ...f,
      estimatedArrival: input.estimatedArrival === undefined ? f.estimatedArrival : tsOrNull(input.estimatedArrival),
      actualArrival: input.actualArrival === undefined ? f.actualArrival : tsOrNull(input.actualArrival),
      status: input.status, source: 'manual', lastObservedAt: now, lastChangeAt: now, dataQuality: 'ok', manualLock: true,
    };
    // readyAt, scheduledAt, solicitud abierta, copia del chófer y avisos.
    const r = applyFlightTx(tx, db, ref, b, next, reads, ops, nowMs);
    writeAudit(tx, db, {
      actor, operation: 'set_flight_info', collection: 'bookings', docId: ref.id, targetType: 'booking',
      changes: changedFields({ status: f.status, estimatedArrival: f.estimatedArrival, actualArrival: f.actualArrival,
        readyAt: b.readyAt ?? null, manualLock: f.manualLock },
      { status: next.status, estimatedArrival: next.estimatedArrival, actualArrival: next.actualArrival,
        readyAt: r.readyAt === null ? null : ts(r.readyAt), manualLock: true }),
      reason: input.reason, details: `Vuelo fijado a mano (${next.status})`,
    });
    return { result: { status: next.status, readyAt: r.readyAt, manualLock: true }, pushes: r.pushes };
  });
  await sendPushes(deps.push, out.pushes);
  return out.result;
}

export const clearLockSchema = z.strictObject({ bookingId: docId, reason: reasonSchema });

/** Quita el bloqueo manual: la fuente automática vuelve a poder actualizar el vuelo. */
export async function adminClearFlightLock(deps: FlightDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(clearLockSchema, data);
  const db = deps.db;
  const ref = db.collection('bookings').doc(input.bookingId);
  return db.runTransaction(async (tx) => {
    const b = (await tx.get(ref)).data();
    if (!b) throw flightError('not-found', 'booking_not_found');
    const f = b.flight as BookingFlight | undefined;
    if (!f) throw flightError('failed-precondition', 'booking_without_flight');
    if (!f.manualLock) return { manualLock: false, changed: false };
    const now = ts(nowOf(deps));
    tx.update(ref, { 'flight.manualLock': false, updatedAt: now });
    writeAudit(tx, db, {
      actor, operation: 'clear_flight_lock', collection: 'bookings', docId: ref.id, targetType: 'booking',
      changes: { manualLock: { before: true, after: false } }, reason: input.reason, details: 'Bloqueo manual del vuelo quitado',
    });
    return { manualLock: false, changed: true };
  });
}

// ---------------------------------------------------------------------------
// A7. «No se presentó» forzado por un admin (vuelo sin datos, retrasado…)
// ---------------------------------------------------------------------------

export const forceNoShowSchema = z.strictObject({ bookingId: docId, reason: reasonSchema });

/**
 * Cuando la regla del vuelo (aterrizado y espera cumplida) no deja al
 * chófer marcarlo, solo un admin puede, con motivo y auditoría. Desde
 * driver_arrived y con política de cancelación (como el chófer). No cobra:
 * la decisión sobre el pago sigue siendo adminUpdateBooking.
 */
export async function adminForceNoShow(deps: FlightDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(forceNoShowSchema, data);
  const db = deps.db;
  const { policy } = readPolicy(await opsConfig(db, nowOf(deps)));
  if (!policy || policy.noShowWaitMinutes === undefined) throw flightError('failed-precondition', 'no_show_disabled');
  const ref = db.collection('bookings').doc(input.bookingId);
  return db.runTransaction(async (tx) => {
    const b = (await tx.get(ref)).data();
    if (!b) throw flightError('not-found', 'booking_not_found');
    if (b.status === 'no_show') return { status: 'no_show', alreadyApplied: true };
    if (b.status !== 'driver_arrived') {
      throw flightError('failed-precondition', 'invalid_transition', { from: b.status, to: 'no_show' });
    }
    const now = ts(nowOf(deps));
    const driverRef = b.driverId ? db.collection('driverProfiles').doc(b.driverId as string) : null;
    const driver = driverRef ? await tx.get(driverRef) : null;
    tx.update(ref, { status: 'no_show', noShowAt: now, updatedAt: now });
    if (driver?.exists) {
      tx.update(driverRef!, { isAvailable: driver.data()?.online !== false && driver.data()?.docsBlocked !== true });
    }
    appendEvent(tx, db, ref.id, {
      from: 'driver_arrived', to: 'no_show', actor: { uid: actor.adminId, role: 'admin' }, source: 'admin',
      extra: { method: 'admin_force_no_show', flightStatus: (b.flight as BookingFlight | undefined)?.status ?? null },
    });
    alert(tx, db, {
      type: 'rider_no_show', severity: 'medium', bookingId: ref.id, driverId: b.driverId ?? null,
      message: 'Un admin marcó que el pasajero no apareció. Revisa la reserva y decide el pago.',
    });
    writeAudit(tx, db, {
      actor, operation: 'force_no_show', collection: 'bookings', docId: ref.id, targetType: 'booking',
      changes: { status: { before: 'driver_arrived', after: 'no_show' } }, reason: input.reason,
      details: 'No se presentó, forzado por un admin', context: { flightStatus: (b.flight as BookingFlight | undefined)?.status ?? null },
    });
    return { status: 'no_show', alreadyApplied: false };
  });
}

// ---------------------------------------------------------------------------
// A9. Aeropuertos y puntos de recogida
// ---------------------------------------------------------------------------

const point = z.strictObject({
  name: z.string().max(160).transform(clean).refine((s) => s.length >= 1 && s.length <= 80, { message: 'name' }),
  instructions: z.string().max(1000).transform(clean).refine((s) => s.length <= 500, { message: 'instructions' }),
  lat: z.number().finite().min(-90).max(90),
  lng: z.number().finite().min(-180).max(180),
}).refine((p) => !(p.lat === 0 && p.lng === 0), { message: 'coordinates', path: ['lat'] });

export type PickupPoint = z.infer<typeof point>;

function validPoint(p: unknown): p is PickupPoint {
  return point.safeParse(p).success;
}

export const upsertAirportSchema = z.strictObject({
  code: z.string().regex(/^[A-Z]{3}$/),
  name: z.string().max(240).transform(clean).refine((s) => s.length >= 2 && s.length <= 120, { message: 'name' }),
  city: z.string().max(160).transform(clean).refine((s) => s.length >= 2 && s.length <= 80, { message: 'city' }),
  /** Las horas se calculan en UTC-4 fijo: solo La Paz. */
  timeZone: z.literal(DEFAULT_TIME_ZONE).default(DEFAULT_TIME_ZONE),
  pickupPoints: z.strictObject({
    domestic: point.nullable().optional(),
    international: point.nullable().optional(),
  }),
  reason: reasonSchema,
});

/**
 * Crea o cambia un aeropuerto y sus puntos de recogida (nacional e
 * internacional; null quita uno). airportsPublic/{código} guarda lo mínimo
 * para el selector sin sesión: código, nombre y ciudad.
 */
export async function adminUpsertAirport(deps: FlightDeps, actor: AdminActor, data: unknown) {
  const input = parseInput(upsertAirportSchema, data);
  const db = deps.db;
  const ref = db.collection('airports').doc(input.code);
  const pubRef = db.collection('airportsPublic').doc(input.code);
  return db.runTransaction(async (tx) => {
    const before = (await tx.get(ref)).data();
    const now = ts(nowOf(deps));
    const prevPoints = (before?.pickupPoints ?? {}) as Record<string, PickupPoint | null>;
    const pickupPoints = {
      domestic: input.pickupPoints.domestic === undefined ? prevPoints.domestic ?? null : input.pickupPoints.domestic,
      international: input.pickupPoints.international === undefined
        ? prevPoints.international ?? null : input.pickupPoints.international,
    };
    const doc = { code: input.code, name: input.name, city: input.city, timeZone: input.timeZone, pickupPoints, updatedAt: now };
    tx.set(ref, doc);
    tx.set(pubRef, { code: input.code, name: input.name, city: input.city });
    writeAudit(tx, db, {
      actor, operation: before ? 'update_airport' : 'create_airport', collection: 'airports', docId: input.code,
      targetType: 'airport',
      changes: changedFields(before ? { name: before.name, city: before.city, timeZone: before.timeZone,
        pickupPoints: before.pickupPoints } : undefined, { name: doc.name, city: doc.city, timeZone: doc.timeZone, pickupPoints }),
      reason: input.reason, details: `Aeropuerto ${input.code}`,
    });
    return { code: input.code, created: !before };
  });
}
