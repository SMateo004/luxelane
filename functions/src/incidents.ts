/**
 * SOS e incidentes (D1, flujo F9). El incidente no es un estado de la
 * reserva: es una bandera aparte y el viaje (verificación, cobro) sigue su
 * curso. Lo ve quien lo disparó y el admin; la contraparte, nunca.
 *
 *   open → acknowledged → closed           (admin, cierre con nota)
 *   open/acknowledged → cancelled_by_reporter → closed
 *
 * Los tiempos de escalada son de operación (config/global), con valores
 * por defecto documentados en DEPLOY.md; no son valores de negocio.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { logger } from './logger';

export type PushFn = (tokens: string[], title: string, body: string, data: Record<string, string>) => Promise<void>;

export interface IncidentDeps {
  db: admin.firestore.Firestore;
  now?: () => number;
  /** Envío de push (FCM); si falla, el incidente sigue creado. */
  push?: PushFn;
}

/** Desde que el chófer sale hacia el pasajero hasta el final del viaje. */
export const INCIDENT_WINDOW = ['driver_arriving', 'driver_arrived', 'verified', 'in_progress'];
/** Comparte ubicación y escala mientras esté en uno de estos. */
const LIVE = ['open', 'acknowledged'];
export const RATE_LIMIT = 5;
export const RATE_WINDOW_MS = 60 * 60 * 1000;
export const DEFAULT_ACK_SECONDS = 120;
export const DEFAULT_ESCALATE_EVERY_SECONDS = 120;

const incidentError = (
  code: 'invalid-argument' | 'failed-precondition' | 'permission-denied' | 'unauthenticated' | 'not-found' | 'resource-exhausted',
  reason: string,
) => new HttpsError(code, reason, { reason });

const location = z.strictObject({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});
export const raiseSchema = z.strictObject({
  bookingId: z.string().trim().min(1).max(128),
  location: location.optional(),
  appVersion: z.string().max(40).optional(),
});
export const incidentIdSchema = z.strictObject({ incidentId: z.string().trim().min(1).max(128) });
export const closeSchema = z.strictObject({
  incidentId: z.string().trim().min(1).max(128),
  note: z.string().trim().min(10).max(1000),
});

function parse<T>(schema: z.ZodType<T>, data: unknown): T {
  const r = schema.safeParse(data);
  if (!r.success) throw incidentError('invalid-argument', 'invalid_request');
  return r.data;
}

const nowMs = (deps: IncidentDeps) => deps.now?.() ?? Date.now();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
/** Mismo ID corto que muestra la app (#ABC123). */
export const shortId = (id: string) => id.slice(0, 6).toUpperCase();
/** Tramo de 10 s: el mismo ID que exigen las reglas para las ubicaciones. */
export const locationSlot = (ms: number) => String(Math.floor(ms / 10000));

const stateRef = (db: admin.firestore.Firestore, bookingId: string) =>
  db.collection('bookings').doc(bookingId).collection('adminOnly').doc('incident');

function event(tx: admin.firestore.Transaction, ref: admin.firestore.DocumentReference, type: string,
  actor: { uid: string; role: string }, extra: Record<string, unknown> = {}) {
  tx.set(ref.collection('events').doc(), {
    type, actor, at: admin.firestore.FieldValue.serverTimestamp(), ...extra,
  });
}

function highAlert(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, at: number, data: Record<string, unknown>) {
  tx.set(db.collection('adminAlerts').doc(), { ...data, severity: 'high', createdAt: ts(at), resolved: false });
}

/** Quita el incidente de los abiertos de la reserva. */
function releaseState(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  state: admin.firestore.DocumentSnapshot, bookingId: string, reporterId: string, incidentId: string) {
  const open = { ...((state.data()?.openByReporter ?? {}) as Record<string, string>) };
  if (open[reporterId] !== incidentId) return;
  delete open[reporterId];
  const remaining = Object.values(open);
  tx.set(stateRef(db, bookingId), {
    openByReporter: open,
    incidentOpen: remaining.length > 0,
    activeIncidentId: remaining.length ? remaining[remaining.length - 1] : null,
  });
}

/** Retención de las ubicaciones al dejar de compartirse (config/global). */
async function retentionFields(db: admin.firestore.Firestore, at: number): Promise<Record<string, unknown>> {
  const days = (await db.collection('config').doc('global').get()).data()?.incidentLocationRetentionDays;
  if (typeof days === 'number' && days > 0) {
    return { locationRetentionDays: days, deleteLocationsAfter: ts(at + days * 86400000), locationsPurged: false };
  }
  // Sin configurar no se borra nada; el panel lo indica.
  return { locationRetentionDays: null, locationRetention: 'not_configured' };
}

/** Push a todos los admin con token. Nunca hace fallar el incidente. */
export async function pushToAdmins(deps: IncidentDeps, title: string, body: string, data: Record<string, string>): Promise<number> {
  const admins = await deps.db.collection('users').where('role', '==', 'admin').get();
  const tokens = admins.docs.flatMap((d) => (d.data().fcmTokens as string[] | undefined) ?? []);
  if (!tokens.length) {
    logger.warn('incidents', 'no admin push tokens', { incidentId: data.incidentId });
    return 0;
  }
  try {
    await deps.push?.(tokens, title, body, data);
  } catch (e) {
    logger.error('incidents', 'admin push failed', { incidentId: data.incidentId, error: String(e) });
  }
  return tokens.length;
}

// ---------------------------------------------------------------------------
// raiseIncident — pasajero o chófer de la reserva
// ---------------------------------------------------------------------------

export async function raiseIncident(deps: IncidentDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw incidentError('unauthenticated', 'unauthenticated');
  const input = parse(raiseSchema, data);
  const db = deps.db;
  const at = nowMs(deps);
  const bookingRef = db.collection('bookings').doc(input.bookingId);
  const rateRef = db.collection('incidentRateLimits').doc(uid);

  const result = await db.runTransaction(async (tx) => {
    const [booking, state, rate] = await Promise.all([
      tx.get(bookingRef), tx.get(stateRef(db, input.bookingId)), tx.get(rateRef),
    ]);
    if (!booking.exists) throw incidentError('not-found', 'booking_not_found');
    const b = booking.data()!;
    const role = b.riderId === uid ? 'rider' : b.driverId === uid ? 'driver' : null;
    if (!role) throw incidentError('permission-denied', 'not_in_booking');

    const recent = ((rate.data()?.recent ?? []) as number[]).filter((t) => t > at - RATE_WINDOW_MS);
    const openId = ((state.data()?.openByReporter ?? {}) as Record<string, string>)[uid];
    if (openId) {
      const ref = db.collection('incidents').doc(openId);
      const inc = await tx.get(ref);
      if (inc.exists && LIVE.includes(inc.data()!.status)) {
        // Repetir no crea otro incidente ni envía push: suma al contador.
        if (recent.length >= RATE_LIMIT) {
          return { incidentId: openId, status: inc.data()!.status, count: inc.data()!.count, alreadyOpen: true, rateLimited: true, created: false };
        }
        const count = Number(inc.data()!.count ?? 1) + 1;
        tx.update(ref, { count, lastRaisedAt: ts(at), updatedAt: ts(at) });
        event(tx, ref, 'repeated', { uid, role }, { count });
        tx.set(rateRef, { recent: [...recent, at] });
        return { incidentId: openId, status: inc.data()!.status, count, alreadyOpen: true, rateLimited: false, created: false };
      }
    }
    if (!INCIDENT_WINDOW.includes(b.status)) throw incidentError('failed-precondition', 'outside_window');
    if (recent.length >= RATE_LIMIT) throw incidentError('resource-exhausted', 'rate_limited');

    const ref = db.collection('incidents').doc();
    tx.set(ref, {
      bookingId: bookingRef.id,
      bookingShortId: shortId(bookingRef.id),
      bookingStatusAtRaise: b.status,
      reporterId: uid,
      reporterRole: role,
      status: 'open',
      count: 1,
      createdAt: ts(at),
      lastRaisedAt: ts(at),
      updatedAt: ts(at),
      escalation: { count: 0, lastAt: null },
      appVersion: input.appVersion ?? null,
    });
    event(tx, ref, 'raised', { uid, role }, { bookingStatus: b.status, hasLocation: input.location !== undefined });
    if (input.location) {
      tx.set(ref.collection('locations').doc(locationSlot(at)), { ...input.location, at: ts(at) });
    }
    tx.set(stateRef(db, bookingRef.id), {
      openByReporter: { ...((state.data()?.openByReporter ?? {}) as Record<string, string>), [uid]: ref.id },
      incidentOpen: true,
      activeIncidentId: ref.id,
    });
    highAlert(tx, db, at, {
      type: 'incident',
      bookingId: bookingRef.id,
      incidentId: ref.id,
      message: `SOS del ${role === 'rider' ? 'pasajero' : 'chófer'} en la reserva #${shortId(bookingRef.id)}.`,
    });
    tx.set(rateRef, { recent: [...recent, at] });
    return { incidentId: ref.id, status: 'open', count: 1, alreadyOpen: false, rateLimited: false, created: true };
  });

  logger.info('raiseIncident', 'result', { incidentId: result.incidentId, bookingId: input.bookingId, created: result.created });
  if (result.created) {
    await pushToAdmins(deps, 'SOS en un viaje', `Reserva #${shortId(input.bookingId)}: abre el panel y reconoce el incidente.`,
      { incidentId: result.incidentId, bookingId: input.bookingId, type: 'incident' });
  }
  const { created: _created, ...response } = result;
  void _created;
  return response;
}

// ---------------------------------------------------------------------------
// cancelIncident — falsa alarma, solo quien lo disparó
// ---------------------------------------------------------------------------

export async function cancelIncident(deps: IncidentDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw incidentError('unauthenticated', 'unauthenticated');
  const { incidentId } = parse(incidentIdSchema, data);
  const db = deps.db;
  const at = nowMs(deps);
  const ref = db.collection('incidents').doc(incidentId);
  const retention = await retentionFields(db, at);

  const outcome = await db.runTransaction(async (tx) => {
    const inc = await tx.get(ref);
    // Igual para uno ajeno que para uno inexistente.
    if (!inc.exists || inc.data()!.reporterId !== uid) throw incidentError('permission-denied', 'not_reporter');
    const d = inc.data()!;
    if (d.status === 'cancelled_by_reporter') return { status: d.status, alreadyCancelled: true, bookingId: d.bookingId as string };
    if (!LIVE.includes(d.status)) throw incidentError('failed-precondition', 'already_closed');
    const state = await tx.get(stateRef(db, d.bookingId));
    tx.update(ref, { status: 'cancelled_by_reporter', cancelledByReporter: true, cancelledAt: ts(at), updatedAt: ts(at), ...retention });
    event(tx, ref, 'cancelled_by_reporter', { uid, role: d.reporterRole });
    releaseState(tx, db, state, d.bookingId, uid, incidentId);
    // El admin recibe igual el aviso: una cancelación también se revisa.
    highAlert(tx, db, at, {
      type: 'incident_cancelled',
      bookingId: d.bookingId,
      incidentId,
      message: `SOS cancelado por quien lo disparó (reserva #${shortId(d.bookingId)}). Revisar igualmente.`,
    });
    return { status: 'cancelled_by_reporter', alreadyCancelled: false, bookingId: d.bookingId as string };
  });

  logger.info('cancelIncident', 'result', { incidentId, already: outcome.alreadyCancelled });
  if (!outcome.alreadyCancelled) {
    await pushToAdmins(deps, 'SOS cancelado', `Reserva #${shortId(outcome.bookingId)}: quien lo disparó lo canceló. Revísalo.`,
      { incidentId, bookingId: outcome.bookingId, type: 'incident_cancelled' });
  }
  return { status: outcome.status, alreadyCancelled: outcome.alreadyCancelled };
}

// ---------------------------------------------------------------------------
// acknowledgeIncident / closeIncident — solo admin, auditado aquí
// ---------------------------------------------------------------------------

export interface AdminActor { adminId: string; adminEmail: string | null }

function audit(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, actor: AdminActor,
  action: string, incidentId: string, at: number, details: string) {
  tx.set(db.collection('admin_logs').doc(), {
    adminId: actor.adminId,
    adminEmail: actor.adminEmail,
    action,
    targetId: incidentId,
    targetType: 'incident',
    details,
    createdAt: ts(at),
  });
}

export async function acknowledgeIncident(deps: IncidentDeps, actor: AdminActor, data: unknown) {
  const { incidentId } = parse(incidentIdSchema, data);
  const db = deps.db;
  const at = nowMs(deps);
  const ref = db.collection('incidents').doc(incidentId);
  return db.runTransaction(async (tx) => {
    const inc = await tx.get(ref);
    if (!inc.exists) throw incidentError('not-found', 'incident_not_found');
    const d = inc.data()!;
    if (d.status === 'acknowledged') return { status: d.status, alreadyAcknowledged: true };
    if (d.status !== 'open') throw incidentError('failed-precondition', 'not_open');
    const waited = Math.round((at - (d.createdAt as admin.firestore.Timestamp).toMillis()) / 1000);
    tx.update(ref, { status: 'acknowledged', acknowledgedAt: ts(at), acknowledgedBy: actor.adminId, updatedAt: ts(at) });
    event(tx, ref, 'acknowledged', { uid: actor.adminId, role: 'admin' }, { secondsToAck: waited });
    audit(tx, db, actor, 'acknowledge_incident', incidentId, at, `Reserva #${shortId(d.bookingId)} · ${waited} s sin reconocer`);
    return { status: 'acknowledged', alreadyAcknowledged: false };
  });
}

export async function closeIncident(deps: IncidentDeps, actor: AdminActor, data: unknown) {
  const { incidentId, note } = parse(closeSchema, data);
  const db = deps.db;
  const at = nowMs(deps);
  const ref = db.collection('incidents').doc(incidentId);
  const retention = await retentionFields(db, at);
  return db.runTransaction(async (tx) => {
    const inc = await tx.get(ref);
    if (!inc.exists) throw incidentError('not-found', 'incident_not_found');
    const d = inc.data()!;
    if (d.status === 'closed') return { status: d.status, alreadyClosed: true };
    const state = await tx.get(stateRef(db, d.bookingId));
    tx.update(ref, {
      status: 'closed', closedAt: ts(at), closedBy: actor.adminId, closeNote: note, updatedAt: ts(at),
      // Una cancelación del reporter ya fijó su retención.
      ...(d.status === 'cancelled_by_reporter' ? {} : retention),
    });
    event(tx, ref, 'closed', { uid: actor.adminId, role: 'admin' }, { note, from: d.status });
    releaseState(tx, db, state, d.bookingId, d.reporterId, incidentId);
    audit(tx, db, actor, 'close_incident', incidentId, at, `Reserva #${shortId(d.bookingId)} · ${note}`);
    return { status: 'closed', alreadyClosed: false };
  });
}

// ---------------------------------------------------------------------------
// Escalada (cada minuto) y retención de ubicaciones (diaria)
// ---------------------------------------------------------------------------

function seconds(v: unknown, fallback: number): number {
  return typeof v === 'number' && v > 0 ? v : fallback;
}

/** Reenvía la alerta y el push de los incidentes que nadie reconoció. */
export async function escalateIncidents(deps: IncidentDeps): Promise<string[]> {
  const db = deps.db;
  const at = nowMs(deps);
  const global = (await db.collection('config').doc('global').get()).data() ?? {};
  const ackMs = seconds(global.incidentAckSeconds, DEFAULT_ACK_SECONDS) * 1000;
  const everyMs = seconds(global.incidentEscalateEverySeconds, DEFAULT_ESCALATE_EVERY_SECONDS) * 1000;
  const open = await db.collection('incidents').where('status', '==', 'open').get();
  const escalated: string[] = [];
  for (const doc of open.docs) {
    const done = await db.runTransaction(async (tx) => {
      const inc = await tx.get(doc.ref);
      const d = inc.data();
      if (!d || d.status !== 'open') return null;
      const created = (d.createdAt as admin.firestore.Timestamp).toMillis();
      const last = (d.escalation?.lastAt as admin.firestore.Timestamp | null | undefined)?.toMillis();
      const due = last === undefined ? at - created >= ackMs : at - last >= everyMs;
      if (!due) return null;
      const count = Number(d.escalation?.count ?? 0) + 1;
      tx.update(doc.ref, { escalation: { count, lastAt: ts(at) }, updatedAt: ts(at) });
      event(tx, doc.ref, 'escalated', { uid: 'system', role: 'system' }, { count, secondsOpen: Math.round((at - created) / 1000) });
      highAlert(tx, db, at, {
        type: 'incident_escalated',
        bookingId: d.bookingId,
        incidentId: doc.id,
        message: `SOS sin reconocer desde hace ${Math.round((at - created) / 1000)} s (reserva #${shortId(d.bookingId)}).`,
      });
      return d.bookingId as string;
    });
    if (done) {
      escalated.push(doc.id);
      await pushToAdmins(deps, 'SOS sin reconocer', `Reserva #${shortId(done)}: nadie ha reconocido el incidente.`,
        { incidentId: doc.id, bookingId: done, type: 'incident_escalated' });
    }
  }
  if (escalated.length) logger.warn('escalateIncidents', 'escalated', { incidents: escalated });
  return escalated;
}

/** Borra las ubicaciones cuya retención venció (si se configuró). */
export async function purgeIncidentLocations(deps: IncidentDeps): Promise<string[]> {
  const db = deps.db;
  const at = nowMs(deps);
  const due = await db.collection('incidents')
    .where('locationsPurged', '==', false)
    .where('deleteLocationsAfter', '<=', ts(at))
    .get();
  for (const doc of due.docs) {
    await db.recursiveDelete(doc.ref.collection('locations'));
    await doc.ref.update({ locationsPurged: true, locationsPurgedAt: ts(at) });
  }
  return due.docs.map((d) => d.id);
}
