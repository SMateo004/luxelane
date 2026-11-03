/**
 * Cambios del vuelo de una reserva (prompt de vuelos, Parte B).
 *
 * - applyFlightTx: aplica un nuevo estado del vuelo (lo fija un admin o
 *   llega de la fuente). Recalcula readyAt y, con él, scheduledAt
 *   (decisión 3 de la aprobación: los usos de la hora de recogida lo
 *   siguen) y la solicitud abierta; actualiza la copia del chófer y decide
 *   los avisos (decisión 4) sin dobles avisos. El precio NO se toca: quedó
 *   fijado al crear la reserva.
 * - runFlightPoll: el planificador (pollFlights). Lee solo reservas activas
 *   con vuelo no final, respeta los puntos de revisión de config/ops,
 *   consulta la fuente (FlightProvider), guarda la caché flightBoard y
 *   aplica lo nuevo. Sin config/ops.flightCheckpointsMinutes y
 *   flightPollMinutes no hace nada.
 */
import { createHash } from 'crypto';
import * as admin from 'firebase-admin';
import type { BookingFlight } from './flight';
import { ArrivalObservation, FlightProvider, writeBoard } from './flight_provider';
import { computeReadyAt, effectiveArrival, readExitMinutes } from './flight_time';
import { AppLocale, formatLocalTime, localeOf, notice, NoticeType } from './i18n';
import { logger } from './logger';
import { opsConfig } from './ops_config';

export type PushFn = (tokens: string[], title: string, body: string, data: Record<string, string>) => Promise<void>;

export interface FlightUpdateDeps {
  db: admin.firestore.Firestore;
  now?: () => number;
  push?: PushFn;
}

/** Copia para el chófer asignado (driverView/flight): sin quién lo fijó ni el bloqueo. */
export function driverFlightView(flight: BookingFlight, readyAt: number, updatedAt: admin.firestore.Timestamp) {
  return {
    airportCode: flight.airportCode, flightType: flight.flightType, airline: flight.airline,
    flightNumber: flight.flightNumber, flightDate: flight.flightDate, scheduledArrival: flight.scheduledArrival,
    estimatedArrival: flight.estimatedArrival, actualArrival: flight.actualArrival, status: flight.status,
    dataQuality: flight.dataQuality, readyAt: admin.firestore.Timestamp.fromMillis(readyAt), updatedAt,
  };
}

export const driverFlightRef = (db: admin.firestore.Firestore, bookingId: string) =>
  db.collection('bookings').doc(bookingId).collection('driverView').doc('flight');

/** Estados del vuelo tras los que ya no hay nada que vigilar. */
const FINAL_FLIGHT = new Set(['landed', 'cancelled', 'diverted']);
/** Estados de la reserva en los que el vuelo todavía importa. */
const ACTIVE_BOOKING = new Set(['pending', 'confirmed', 'driver_arriving', 'driver_arrived']);

const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const ms = (t: unknown) => (t instanceof admin.firestore.Timestamp ? t.toMillis() : null);

/** El vuelo sigue necesitando vigilancia (lo usa la consulta del planificador). */
export function flightIsActive(bookingStatus: string, flightStatus: string, hasActual: boolean): boolean {
  if (!ACTIVE_BOOKING.has(bookingStatus)) return false;
  if (flightStatus === 'landed') return !hasActual;
  return !FINAL_FLIGHT.has(flightStatus);
}

const positiveInt = (v: unknown): v is number => typeof v === 'number' && Number.isInteger(v) && v > 0 && v <= 24 * 60;

/** Aviso pendiente de enviar por push (la bandeja se escribe en la transacción). */
interface PendingPush { tokens: string[]; title: string; body: string; type: NoticeType }

/**
 * Lee lo que applyFlightTx necesita. En una transacción de Firestore todas
 * las lecturas van antes de las escrituras: por eso es un paso aparte.
 */
export async function readForFlight(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  b: admin.firestore.DocumentData, bookingId: string) {
  const [open, rider, driver] = await Promise.all([
    tx.get(db.collection('openRequests').doc(bookingId)),
    b.riderId ? tx.get(db.collection('users').doc(b.riderId as string)) : Promise.resolve(null),
    b.driverId ? tx.get(db.collection('users').doc(b.driverId as string)) : Promise.resolve(null),
  ]);
  return { open, rider, driver };
}

export interface ApplyResult {
  readyAt: number | null;
  readyChanged: boolean;
  notified: Array<'rider' | 'driver'>;
  alerts: string[];
  pushes: PendingPush[];
}

/**
 * Escribe el vuelo nuevo [next] en la reserva [ref] (datos [b] leídos en la
 * misma transacción) y lo que se deriva. Devuelve los push para enviarlos
 * después del commit (sendPushes).
 */
export function applyFlightTx(tx: admin.firestore.Transaction, db: admin.firestore.Firestore,
  ref: admin.firestore.DocumentReference, b: admin.firestore.DocumentData, next: BookingFlight,
  reads: Awaited<ReturnType<typeof readForFlight>>, ops: Record<string, unknown>, nowMs: number): ApplyResult {
  const now = ts(nowMs);
  const prev = b.flight as BookingFlight & { notifiedReadyAt?: admin.firestore.Timestamp; alertedStatus?: string };
  const prevReady = ms(b.readyAt);
  const exit = readExitMinutes(ops);
  // Sin los minutos de salida no se recalcula: se queda el readyAt de antes.
  const computed = computeReadyAt({ scheduledArrival: ms(next.scheduledArrival), estimatedArrival: ms(next.estimatedArrival),
    actualArrival: ms(next.actualArrival), flightType: next.flightType, hasCheckedBag: next.hasCheckedBag }, exit);
  const readyAt = computed ?? prevReady;
  const readyChanged = readyAt !== null && readyAt !== prevReady;
  const result: ApplyResult = { readyAt, readyChanged, notified: [], alerts: [], pushes: [] };

  const flight: Record<string, unknown> = { ...next };
  const update: Record<string, unknown> = { updatedAt: now };
  if (readyChanged) {
    // Decisión 3: la hora de recogida sigue a readyAt (limpieza, chófer
    // ocupado, retención de la tarjeta, aviso al liberar, reactivación y
    // solicitud abierta). El precio, no.
    update.readyAt = ts(readyAt!);
    update.scheduledAt = ts(readyAt!);
    if (reads.open.exists) tx.update(reads.open.ref, { scheduledAt: ts(readyAt!) });
  }
  update.flightActive = flightIsActive(String(b.status), next.status, next.actualArrival !== null);

  const notify = (who: 'rider' | 'driver', snap: admin.firestore.DocumentSnapshot | null, type: NoticeType,
    params: (l: AppLocale) => Record<string, string>) => {
    if (!snap?.exists) return;
    const user = snap.data()!;
    const locale = localeOf(user);
    const n = notice(type, locale, params(locale));
    const nref = db.collection('users').doc(snap.id).collection('notifications').doc();
    // Bandeja: el detalle de la reserva lo ve dentro de la app.
    tx.set(nref, { id: nref.id, userId: snap.id, title: n.title, body: n.body, type, locale, bookingId: ref.id,
      isRead: false, createdAt: now });
    const tokens = (user.fcmTokens as string[] | undefined) ?? [];
    if (tokens.length) result.pushes.push({ tokens, title: n.title, body: n.body, type });
    result.notified.push(who);
  };
  const raise = (type: string, severity: string, message: string) => {
    tx.set(db.collection('adminAlerts').doc(), { type, severity, bookingId: ref.id, message, resolved: false, createdAt: now });
    result.alerts.push(type);
  };

  // Cancelado o desviado: siempre alerta alta a central y aviso sobrio a
  // pasajero y chófer; la reserva NO se cancela sola (decide un admin). Una
  // vez por estado.
  const disrupted = next.status === 'cancelled' || next.status === 'diverted';
  if (disrupted && prev.alertedStatus !== next.status) {
    raise('flight_disrupted', 'high', `El vuelo de la reserva figura como ${next.status === 'cancelled' ? 'cancelado' : 'desviado'
    }. La reserva no se cancela sola: decide qué hacer.`);
    notify('rider', reads.rider, 'flight_disrupted_rider', () => ({}));
    notify('driver', reads.driver, 'flight_disrupted_driver', () => ({}));
    flight.alertedStatus = next.status;
  } else if (readyChanged && !disrupted) {
    // Decisión 4: se avisa cuando readyAt se aleja del último readyAt
    // avisado en al menos config/ops.flightNotifyThresholdMinutes. Sin ese
    // valor no se avisa a nadie: solo una alerta para central.
    const threshold = ops.flightNotifyThresholdMinutes;
    const baseline = ms(prev.notifiedReadyAt) ?? prevReady ?? readyAt!;
    const drift = Math.abs(readyAt! - baseline) / 60_000;
    if (!positiveInt(threshold)) {
      raise('flight_time_changed', 'low', 'Cambió la hora de recogida por el vuelo y no hay umbral de aviso ' +
        '(config/ops.flightNotifyThresholdMinutes): no se avisó al pasajero ni al chófer.');
    } else if (drift >= threshold) {
      notify('rider', reads.rider, 'flight_time_changed_rider', (l) => ({ time: formatLocalTime(readyAt!, l) }));
      notify('driver', reads.driver, 'flight_time_changed_driver', (l) => ({ time: formatLocalTime(readyAt!, l) }));
      flight.notifiedReadyAt = ts(readyAt!);
    }
  }
  // La referencia de los avisos no se mueve con los cambios pequeños: el
  // siguiente aviso se mide desde el último avisado (o desde el readyAt de
  // la reserva al crearla).
  if (flight.notifiedReadyAt === undefined) {
    const base = ms(prev.notifiedReadyAt) ?? prevReady;
    if (base !== null) flight.notifiedReadyAt = ts(base);
  }
  if (flight.alertedStatus === undefined && prev.alertedStatus) flight.alertedStatus = prev.alertedStatus;
  update.flight = flight;
  tx.update(ref, update);
  if (readyAt !== null) tx.set(driverFlightRef(db, ref.id), driverFlightView(next, readyAt, now));
  return result;
}

export async function sendPushes(push: PushFn | undefined, pushes: PendingPush[]): Promise<void> {
  if (!push) return;
  for (const p of pushes) {
    // Solo título y cuerpo genéricos (sin número de vuelo) y el tipo.
    await push(p.tokens, p.title, p.body, { type: p.type }).catch((e) =>
      logger.warn('flightUpdates', 'push failed', { type: p.type, error: String(e) }));
  }
}

// ---------------------------------------------------------------------------
// B1. Planificador
// ---------------------------------------------------------------------------

/** Firma de lo que dice la fuente: si no cambia, no se toca la reserva. */
export function observationSignature(o: Pick<ArrivalObservation, 'status' | 'scheduled' | 'estimated' | 'actual'>): string {
  return createHash('sha256').update(`${o.status}|${o.scheduled}|${o.estimated}|${o.actual}`).digest('hex').slice(0, 16);
}

interface PollState { lastPollAt?: admin.firestore.Timestamp; checkpointsDone?: number[] }

/**
 * ¿Toca consultar ahora? Un punto de revisión por cada minuto de
 * config/ops.flightCheckpointsMinutes antes de la hora efectiva; desde el
 * último punto, cada flightPollMinutes hasta que aterriza.
 */
export function pollDue(arrivalMs: number, nowMs: number, checkpoints: number[], pollMinutes: number,
  state: PollState): { due: boolean; checkpoint: number | null } {
  const done = new Set(state.checkpointsDone ?? []);
  const reached = checkpoints.filter((c) => nowMs >= arrivalMs - c * 60_000).sort((a, b) => a - b);
  const pending = reached.find((c) => !done.has(c));
  if (pending !== undefined) return { due: true, checkpoint: pending };
  const last = Math.min(...checkpoints);
  if (nowMs < arrivalMs - last * 60_000) return { due: false, checkpoint: null };
  const lastPoll = ms(state.lastPollAt);
  return { due: lastPoll === null || nowMs - lastPoll >= pollMinutes * 60_000, checkpoint: null };
}

export interface PollResult {
  skipped?: 'config_missing';
  checked: number;
  queried: number;
  updated: number;
  stale: number;
}

export async function runFlightPoll(deps: FlightUpdateDeps & { provider: FlightProvider }): Promise<PollResult> {
  const db = deps.db;
  const nowMs = deps.now?.() ?? Date.now();
  const ops = await opsConfig(db, nowMs);
  const cps = Array.isArray(ops.flightCheckpointsMinutes) ? ops.flightCheckpointsMinutes.filter(positiveInt) : [];
  const pollMinutes = ops.flightPollMinutes;
  if (!cps.length || !positiveInt(pollMinutes)) return { skipped: 'config_missing', checked: 0, queried: 0, updated: 0, stale: 0 };
  const staleMinutes = positiveInt(ops.flightStaleMinutes) ? ops.flightStaleMinutes : null;

  const snap = await db.collection('bookings').where('flightActive', '==', true).get();
  const result: PollResult = { checked: snap.size, queried: 0, updated: 0, stale: 0 };
  // Una consulta por vuelo y pasada (agrupados por aeropuerto y fecha).
  const cache = new Map<string, Awaited<ReturnType<FlightProvider['getArrival']>>>();
  const groups = new Map<string, admin.firestore.QueryDocumentSnapshot[]>();
  for (const d of snap.docs) {
    const f = d.data().flight as BookingFlight | undefined;
    if (!f) continue;
    const key = `${f.airportCode}_${f.flightDate}`;
    groups.set(key, [...(groups.get(key) ?? []), d]);
  }
  for (const docs of groups.values()) {
    for (const d of docs) {
      const b = d.data();
      const f = b.flight as BookingFlight & { poll?: PollState; lockSignature?: string };
      if (!ACTIVE_BOOKING.has(String(b.status))) {
        await d.ref.update({ flightActive: false });
        continue;
      }
      const arrival = effectiveArrival({ scheduledArrival: ms(f.scheduledArrival), estimatedArrival: ms(f.estimatedArrival),
        actualArrival: ms(f.actualArrival) });
      // Dato viejo (B1): una sola alerta por episodio.
      if (staleMinutes !== null && f.dataQuality === 'ok' && f.lastObservedAt
        && nowMs - ms(f.lastObservedAt)! > staleMinutes * 60_000) {
        await db.runTransaction(async (tx) => {
          const fresh = (await tx.get(d.ref)).data();
          if ((fresh?.flight as BookingFlight | undefined)?.dataQuality !== 'ok') return;
          tx.update(d.ref, { 'flight.dataQuality': 'stale', updatedAt: ts(nowMs) });
          tx.set(driverFlightRef(db, d.id), { dataQuality: 'stale' }, { merge: true });
          tx.set(db.collection('adminAlerts').doc(), { type: 'flight_data_stale', severity: 'medium', bookingId: d.id,
            resolved: false, createdAt: ts(nowMs),
            message: `Los datos del vuelo no se actualizan desde hace más de ${staleMinutes} min. Compruébalo a mano.` });
        });
        result.stale++;
      }
      if (arrival === null) continue;
      const due = pollDue(arrival, nowMs, cps, pollMinutes, f.poll ?? {});
      if (!due.due) continue;
      const q = { airportCode: f.airportCode, flightNumber: f.flightNumber, flightDate: f.flightDate };
      const key = `${q.airportCode}_${q.flightDate}_${q.flightNumber}`;
      if (!cache.has(key)) {
        cache.set(key, await deps.provider.getArrival(q));
        result.queried++;
      }
      const obs = cache.get(key)!;
      const pollUpdate: Record<string, unknown> = {
        'flight.poll.lastPollAt': ts(nowMs),
        ...(due.checkpoint !== null
          ? { 'flight.poll.checkpointsDone': admin.firestore.FieldValue.arrayUnion(due.checkpoint) } : {}),
      };
      if (obs.kind !== 'found') {
        await d.ref.update(pollUpdate);
        continue;
      }
      await writeBoard(db, q, obs);
      const sig = observationSignature(obs);
      const pushes = await db.runTransaction(async (tx) => {
        const fresh = await tx.get(d.ref);
        const fb = fresh.data()!;
        const cur = fb.flight as BookingFlight & { lastSignature?: string; lockSignature?: string };
        const reads = await readForFlight(tx, db, fb, d.id);
        if (cur.manualLock) {
          // Bloqueo manual: la fuente no pisa nada; si difiere, una alerta
          // por dato distinto.
          const differs = obs.status !== cur.status || obs.actual !== ms(cur.actualArrival)
            || obs.estimated !== ms(cur.estimatedArrival);
          tx.update(d.ref, pollUpdate);
          if (differs && cur.lockSignature !== sig) {
            tx.update(d.ref, { 'flight.lockSignature': sig });
            tx.set(db.collection('adminAlerts').doc(), { type: 'flight_source_differs', severity: 'medium', bookingId: d.id,
              resolved: false, createdAt: ts(nowMs),
              message: 'La fuente de vuelos da otros datos que los fijados a mano (bloqueo manual). Revísalo.' });
          }
          return [];
        }
        const observedAt = ts(obs.observedAt);
        if (cur.lastSignature === sig) {
          tx.update(d.ref, { ...pollUpdate, 'flight.lastObservedAt': observedAt, 'flight.dataQuality': 'ok' });
          return [];
        }
        const next: BookingFlight & { lastSignature: string; poll?: PollState } = {
          ...cur,
          scheduledArrival: obs.scheduled !== null ? ts(obs.scheduled) : cur.scheduledArrival,
          estimatedArrival: obs.estimated !== null ? ts(obs.estimated) : null,
          actualArrival: obs.actual !== null ? ts(obs.actual) : null,
          status: obs.status, source: 'auto', lastObservedAt: observedAt, lastChangeAt: ts(nowMs), dataQuality: 'ok',
          lastSignature: sig,
          poll: {
            lastPollAt: ts(nowMs),
            checkpointsDone: [...new Set([...(cur as { poll?: PollState }).poll?.checkpointsDone ?? [],
              ...(due.checkpoint !== null ? [due.checkpoint] : [])])],
          },
        };
        const r = applyFlightTx(tx, db, d.ref, fb, next, reads, ops, nowMs);
        return r.pushes;
      });
      await sendPushes(deps.push, pushes);
      result.updated++;
    }
  }
  return result;
}
