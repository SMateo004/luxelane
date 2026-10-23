/**
 * Transiciones del viaje desde la recogida hasta el final (D1). Solo el
 * servidor cambia el estado: valida el grafo, quién lo pide y el estado
 * actual, y deja cada paso en bookings/{id}/events (solo anexado).
 *
 *   confirmed → driver_arriving → driver_arrived → verified → in_progress → completed
 *
 * driver_arrived → verified solo con el código del pasajero (verifyPickup)
 * o forzado por el admin con motivo (adminOverrideVerify).
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { docId } from './schemas';
import { updateRequired } from './app_version';
import { codesMatch, MAX_PICKUP_ATTEMPTS, newPickupSalt, pickupCode, pickupExpired, PICKUP_CODE_TTL_MS } from './pickup_code';
import { distanceKm } from './service_area';
import { logger } from './logger';

export interface TripDeps {
  db: admin.firestore.Firestore;
  /** PICKUP_CODE_SECRET; vacío = no hay códigos (falla cerrado). */
  pickupSecret?: string;
  now?: () => number;
}

type Status = 'pending' | 'confirmed' | 'driver_arriving' | 'driver_arrived' | 'verified'
  | 'in_progress' | 'completed' | 'cancelled';

/** Pasos que el chófer asignado da con advanceBooking. */
export const DRIVER_STEPS: Readonly<Partial<Record<Status, Status>>> = {
  confirmed: 'driver_arriving',
  driver_arriving: 'driver_arrived',
  verified: 'in_progress',
  in_progress: 'completed',
};

/** Ya pasó por la verificación (para responder igual a un reintento). */
const PAST_VERIFIED: readonly Status[] = ['verified', 'in_progress', 'completed'];

type Source = 'driver_app' | 'admin' | 'system';

const tripError = (
  code: 'invalid-argument' | 'failed-precondition' | 'permission-denied' | 'unauthenticated' | 'not-found',
  reason: string,
  extra: Record<string, unknown> = {},
) => new HttpsError(code, reason, { reason, ...extra });

const bookingId = docId;
const location = z.strictObject({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  accuracy: z.number().min(0).max(100000).optional(),
});
const appVersion = z.string().max(40).optional();

export const advanceSchema = z.strictObject({
  bookingId,
  to: z.enum(['driver_arriving', 'driver_arrived', 'in_progress', 'completed']),
  location: location.optional(),
  appVersion,
});
export const pickupCodeSchema = z.strictObject({ bookingId });
export const verifySchema = z.strictObject({
  bookingId,
  code: z.string().regex(/^\d{4}$/),
  location: location.optional(),
  appVersion,
});
export const overrideSchema = z.strictObject({
  bookingId,
  reason: z.string().trim().min(5).max(500),
});

function parse<T>(schema: z.ZodType<T>, data: unknown): T {
  const r = schema.safeParse(data);
  if (!r.success) {
    const fields = [...new Set(r.error.issues.map((i) => i.path.join('.') || '(raíz)'))];
    throw tripError('invalid-argument', 'invalid_request', { fields });
  }
  return r.data;
}

const now = (deps: TripDeps) => deps.now?.() ?? Date.now();

async function globalConfig(db: admin.firestore.Firestore): Promise<Record<string, unknown>> {
  return (await db.collection('config').doc('global').get()).data() ?? {};
}

async function requireActiveDriver(db: admin.firestore.Firestore, uid: string | undefined): Promise<string> {
  if (!uid) throw tripError('unauthenticated', 'unauthenticated');
  const user = (await db.collection('users').doc(uid).get()).data();
  if (!user || user.role !== 'driver' || user.isActive === false) {
    throw tripError('permission-denied', 'inactive_driver');
  }
  return uid;
}

/** La app del chófer más vieja que config/global.minDriverAppVersion no avanza viajes. */
function requireDriverApp(global: Record<string, unknown>, version: string | undefined): void {
  const update = updateRequired(global, version, 'minDriverAppVersion');
  if (update) throw tripError('failed-precondition', 'app_update_required', update);
}

function requireSecret(deps: TripDeps): string {
  if (!deps.pickupSecret) {
    logger.error('pickup', 'PICKUP_CODE_SECRET missing', {});
    throw tripError('failed-precondition', 'pickup_unavailable');
  }
  return deps.pickupSecret;
}

const bookingRef = (db: admin.firestore.Firestore, id: string) => db.collection('bookings').doc(id);
/** Sal y contador de intentos: solo el servidor los lee (las reglas lo niegan a todos). */
const pickupRef = (db: admin.firestore.Firestore, id: string) =>
  bookingRef(db, id).collection('private').doc('pickup');

interface EventInput {
  type?: 'transition' | 'pickup_locked';
  from: Status;
  to: Status;
  actor: { uid: string; role: 'driver' | 'rider' | 'admin' | 'system' };
  source: Source;
  appVersion?: string | null;
  location?: z.infer<typeof location>;
  extra?: Record<string, unknown>;
  locationExtra?: Record<string, unknown>;
}

/**
 * Anexa un evento. La ubicación del chófer va aparte (eventLocations, solo
 * para el admin), con el mismo ID que el evento.
 */
function appendEvent(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, id: string, e: EventInput): void {
  const ref = bookingRef(db, id).collection('events').doc();
  tx.set(ref, {
    type: e.type ?? 'transition',
    from: e.from,
    to: e.to,
    actor: e.actor,
    source: e.source,
    at: admin.firestore.FieldValue.serverTimestamp(),
    appVersion: e.appVersion ?? null,
    hasLocation: e.location !== undefined,
    ...(e.extra ?? {}),
  });
  if (e.location) {
    tx.set(bookingRef(db, id).collection('eventLocations').doc(ref.id), {
      ...e.location,
      ...(e.locationExtra ?? {}),
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

function alert(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, data: Record<string, unknown>): void {
  tx.set(db.collection('adminAlerts').doc(), {
    ...data,
    createdAt: admin.firestore.Timestamp.now(),
    resolved: false,
  });
}

/** Distancia al punto de recogida; null si no hay con qué comparar. */
function arrivalCheck(
  booking: Record<string, unknown>,
  loc: z.infer<typeof location> | undefined,
  radius: unknown,
): { extra: Record<string, unknown>; distanceMeters?: number; far: boolean } {
  // Sin ubicación no hay nada que comparar (y se avisa, ver advanceBooking).
  if (!loc) return { extra: { arrivalCheck: 'no_location' }, far: false };
  if (typeof radius !== 'number' || !(radius > 0)) return { extra: { arrivalCheck: 'no_radius' }, far: false };
  const pickup = (booking.origin as { coordinates?: admin.firestore.GeoPoint } | undefined)?.coordinates;
  if (!pickup) return { extra: { arrivalCheck: 'no_pickup' }, far: false };
  const distanceMeters = Math.round(distanceKm(loc.lat, loc.lng, pickup.latitude, pickup.longitude) * 1000);
  const far = distanceMeters > radius;
  return { extra: { arrivalCheck: 'compared', farFromPickup: far }, distanceMeters, far };
}

// ---------------------------------------------------------------------------
// advanceBooking — los pasos del chófer
// ---------------------------------------------------------------------------

export async function advanceBooking(deps: TripDeps, uid: string | undefined, data: unknown) {
  const driverId = await requireActiveDriver(deps.db, uid);
  const input = parse(advanceSchema, data);
  const global = await globalConfig(deps.db);
  requireDriverApp(global, input.appVersion);
  const db = deps.db;
  const ref = bookingRef(db, input.bookingId);
  const at = admin.firestore.Timestamp.fromMillis(now(deps));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw tripError('not-found', 'booking_not_found');
    const b = snap.data()!;
    if (b.driverId !== driverId) throw tripError('permission-denied', 'not_assigned');
    const from = b.status as Status;
    // Doble envío o reintento tras perder la respuesta: ya está hecho.
    if (from === input.to) return { status: from, alreadyApplied: true };
    if (DRIVER_STEPS[from] !== input.to) {
      throw tripError('failed-precondition', 'invalid_transition', { from, to: input.to });
    }

    const update: Record<string, unknown> = { status: input.to, updatedAt: at };
    let extra: Record<string, unknown> = {};
    let locationExtra: Record<string, unknown> = {};
    if (input.to === 'driver_arrived') {
      update.arrivedAt = at;
      tx.set(pickupRef(db, ref.id), { salt: newPickupSalt(), arrivedAt: at, failedAttempts: 0 });
      const check = arrivalCheck(b, input.location, global.arrivalRadiusMeters);
      extra = check.extra;
      if (check.distanceMeters !== undefined) locationExtra = { distanceMeters: check.distanceMeters };
      if (check.far) {
        alert(tx, db, {
          type: 'far_from_pickup',
          bookingId: ref.id,
          driverId,
          distanceMeters: check.distanceMeters,
          message: 'El chófer marcó «Llegué» lejos del punto de recogida.',
        });
      }
      if (!input.location) {
        alert(tx, db, {
          type: 'arrival_without_location',
          severity: 'low',
          bookingId: ref.id,
          driverId,
          message: 'El chófer marcó «Llegué» sin enviar su ubicación.',
        });
      }
    } else if (input.to === 'in_progress') {
      update.startedAt = at;
    } else if (input.to === 'completed') {
      update.completedAt = at;
    }
    tx.update(ref, update);
    appendEvent(tx, db, ref.id, {
      from,
      to: input.to,
      actor: { uid: driverId, role: 'driver' },
      source: 'driver_app',
      appVersion: input.appVersion,
      // La ubicación se guarda en llegada, verificación y fin.
      location: input.to === 'driver_arrived' || input.to === 'completed' ? input.location : undefined,
      extra,
      locationExtra,
    });
    return { status: input.to, alreadyApplied: false };
  });
}

/**
 * Sal y hora de llegada de la reserva. Una reserva que llegó a
 * driver_arrived sin advanceBooking (panel o antes de este cambio) la recibe
 * ahora, con la hora de su llegada si consta.
 */
async function pickupState(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, id: string,
  b: admin.firestore.DocumentData, at: admin.firestore.Timestamp) {
  const ref = pickupRef(db, id);
  const snap = await tx.get(ref);
  if (snap.exists) {
    const d = snap.data()!;
    return { salt: d.salt as string, arrivedAt: d.arrivedAt as admin.firestore.Timestamp, failedAttempts: Number(d.failedAttempts ?? 0), created: null };
  }
  const created = { salt: newPickupSalt(), arrivedAt: (b.arrivedAt as admin.firestore.Timestamp | undefined) ?? at, failedAttempts: 0 };
  return { ...created, created };
}

// ---------------------------------------------------------------------------
// getPickupCode — el pasajero ve su código mientras el chófer espera
// ---------------------------------------------------------------------------

export async function getPickupCode(deps: TripDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw tripError('unauthenticated', 'unauthenticated');
  const input = parse(pickupCodeSchema, data);
  const secret = requireSecret(deps);
  const db = deps.db;
  const ref = bookingRef(db, input.bookingId);
  const nowMs = now(deps);

  const state = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    // Igual para una reserva ajena que para una inexistente.
    if (!snap.exists || snap.data()!.riderId !== uid) throw tripError('permission-denied', 'not_your_booking');
    const b = snap.data()!;
    if (b.status !== 'driver_arrived') throw tripError('failed-precondition', 'not_at_pickup', { status: b.status });
    if (b.pickupLocked === true) throw tripError('failed-precondition', 'pickup_locked');
    const s = await pickupState(tx, db, ref.id, b, admin.firestore.Timestamp.fromMillis(nowMs));
    if (s.created) tx.set(pickupRef(db, ref.id), s.created);
    return s;
  });
  if (pickupExpired(state.arrivedAt.toMillis(), nowMs)) throw tripError('failed-precondition', 'code_expired');
  return {
    code: pickupCode(secret, ref.id, state.salt),
    expiresAt: state.arrivedAt.toMillis() + PICKUP_CODE_TTL_MS,
  };
}

// ---------------------------------------------------------------------------
// verifyPickup — el chófer escribe el código que le da el pasajero
// ---------------------------------------------------------------------------

type VerifyOutcome =
  | { kind: 'ok'; already: boolean }
  | { kind: 'wrong'; attemptsLeft: number }
  | { kind: 'locked' }
  | { kind: 'expired' };

export async function verifyPickup(deps: TripDeps, uid: string | undefined, data: unknown) {
  const driverId = await requireActiveDriver(deps.db, uid);
  const input = parse(verifySchema, data);
  requireDriverApp(await globalConfig(deps.db), input.appVersion);
  const secret = requireSecret(deps);
  const db = deps.db;
  const ref = bookingRef(db, input.bookingId);
  const nowMs = now(deps);
  const at = admin.firestore.Timestamp.fromMillis(nowMs);

  // Los fallos también se guardan: por eso la transacción devuelve el
  // resultado y el error se lanza después (lanzarlo dentro lo desharía).
  const outcome = await db.runTransaction<VerifyOutcome>(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw tripError('not-found', 'booking_not_found');
    const b = snap.data()!;
    if (b.driverId !== driverId) throw tripError('permission-denied', 'not_assigned');
    if (PAST_VERIFIED.includes(b.status)) return { kind: 'ok', already: true };
    if (b.status !== 'driver_arrived') throw tripError('failed-precondition', 'not_at_pickup', { status: b.status });
    if (b.pickupLocked === true) return { kind: 'locked' };

    const s = await pickupState(tx, db, ref.id, b, at);
    if (s.created) tx.set(pickupRef(db, ref.id), s.created);
    if (pickupExpired(s.arrivedAt.toMillis(), nowMs)) return { kind: 'expired' };

    if (codesMatch(pickupCode(secret, ref.id, s.salt), input.code)) {
      tx.update(ref, { status: 'verified', verifiedAt: at, verifiedBy: 'pickup_code', updatedAt: at });
      appendEvent(tx, db, ref.id, {
        from: 'driver_arrived',
        to: 'verified',
        actor: { uid: driverId, role: 'driver' },
        source: 'driver_app',
        appVersion: input.appVersion,
        location: input.location,
        extra: { method: 'pickup_code' },
      });
      return { kind: 'ok', already: false };
    }

    const failed = s.failedAttempts + 1;
    tx.set(pickupRef(db, ref.id), { failedAttempts: failed }, { merge: true });
    if (failed < MAX_PICKUP_ATTEMPTS) return { kind: 'wrong', attemptsLeft: MAX_PICKUP_ATTEMPTS - failed };

    tx.update(ref, { pickupLocked: true, updatedAt: at });
    appendEvent(tx, db, ref.id, {
      type: 'pickup_locked',
      from: 'driver_arrived',
      to: 'driver_arrived',
      actor: { uid: driverId, role: 'driver' },
      source: 'driver_app',
      appVersion: input.appVersion,
      location: input.location,
      extra: { failedAttempts: failed },
    });
    alert(tx, db, {
      type: 'pickup_locked',
      bookingId: ref.id,
      driverId,
      message: `Verificación bloqueada tras ${failed} códigos incorrectos.`,
    });
    return { kind: 'locked' };
  });

  // Nunca se registra el código, ni el escrito ni el esperado.
  logger.info('verifyPickup', 'result', { bookingId: ref.id, driverId, outcome: outcome.kind });
  switch (outcome.kind) {
    case 'ok':
      return { status: 'verified', alreadyVerified: outcome.already };
    case 'wrong':
      throw tripError('failed-precondition', 'wrong_code', { attemptsLeft: outcome.attemptsLeft });
    case 'locked':
      throw tripError('failed-precondition', 'pickup_locked');
    case 'expired':
      throw tripError('failed-precondition', 'code_expired');
  }
}

// ---------------------------------------------------------------------------
// adminOverrideVerify — excepción operativa con motivo obligatorio
// ---------------------------------------------------------------------------

export async function adminOverrideVerify(
  deps: TripDeps,
  actor: { adminId: string; adminEmail: string | null },
  data: unknown,
) {
  const input = parse(overrideSchema, data);
  const db = deps.db;
  const ref = bookingRef(db, input.bookingId);
  const at = admin.firestore.Timestamp.fromMillis(now(deps));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw tripError('not-found', 'booking_not_found');
    const b = snap.data()!;
    if (PAST_VERIFIED.includes(b.status)) return { status: b.status as Status, alreadyVerified: true };
    if (b.status !== 'driver_arrived') throw tripError('failed-precondition', 'not_at_pickup', { status: b.status });

    tx.update(ref, { status: 'verified', verifiedAt: at, verifiedBy: 'admin_override', updatedAt: at });
    appendEvent(tx, db, ref.id, {
      from: 'driver_arrived',
      to: 'verified',
      actor: { uid: actor.adminId, role: 'admin' },
      source: 'admin',
      extra: { method: 'admin_override', reason: input.reason },
    });
    alert(tx, db, {
      type: 'pickup_override',
      bookingId: ref.id,
      adminId: actor.adminId,
      message: `Verificación forzada por el admin: ${input.reason}`,
    });
    tx.set(db.collection('admin_logs').doc(), {
      adminId: actor.adminId,
      adminEmail: actor.adminEmail,
      action: 'override_verify',
      targetId: ref.id,
      targetType: 'booking',
      details: input.reason,
      createdAt: at,
    });
    return { status: 'verified' as Status, alreadyVerified: false };
  });
}
