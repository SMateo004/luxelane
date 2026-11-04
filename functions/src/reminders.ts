/**
 * Recordatorios programados (Prompt 18, Parte A, decisiones 1 a 5).
 *
 * - Hora ancla: bookings/{id}.scheduledAt (con vuelo ya sigue a readyAt).
 * - config/ops.reminderOffsetsMinutes = { rider: [...], driver: [...] }:
 *   minutos antes de la hora ancla. Sin la clave o vacía, nada para esa
 *   persona.
 * - Pasajero: desde que la reserva está pagada hasta que el chófer llega.
 *   Chófer: desde que acepta o se le asigna hasta que llega.
 * - config/ops.unassignedAlertMinutes: si a esa hora una reserva pagada
 *   sigue sin chófer, UNA alerta alta para central. Sin la clave, nada.
 *
 * La reserva guarda `reminders` (solo el servidor):
 *   { nextAt, sent, skipped, anchor, riderSince, driverSince, driverFor }
 * nextAt es la hora del próximo envío pendiente (null si no hay): la tarea
 * consulta `reminders.nextAt <= ahora` y no recorre la colección.
 *
 * Nunca se envía un recordatorio cuya hora ya había pasado cuando la persona
 * empezó a recibirlos (pago o asignación: `riderSince`/`driverSince`) ni
 * cuando cambió la hora ancla: quedan en `skipped`. Las claves son por
 * persona y desfase (`rider:60`, `driver:30`, `unassigned`): cada una se
 * envía una sola vez aunque la tarea se reintente. Al cambiar de chófer, las
 * claves del chófer se reinician para el nuevo.
 */
import * as admin from 'firebase-admin';
import { formatLocalTime, localeOf, notice, NoticeType } from './i18n';
import { logger } from './logger';
import { opsConfig } from './ops_config';

/** Tope técnico de un desfase: 7 días (no es un valor de negocio). */
const MAX_OFFSET_MINUTES = 7 * 24 * 60;

const RIDER_STATES = new Set(['pending', 'confirmed', 'driver_arriving']);
const DRIVER_STATES = new Set(['confirmed', 'driver_arriving']);

export interface ReminderConfig {
  rider: number[];
  driver: number[];
  unassigned: number | null;
}

const offsets = (v: unknown): number[] => (Array.isArray(v)
  ? [...new Set(v.filter((m): m is number => Number.isInteger(m) && m > 0 && m <= MAX_OFFSET_MINUTES))]
    .sort((a, b) => b - a)
  : []);

export function readReminderConfig(ops: Record<string, unknown>): ReminderConfig {
  const r = (ops.reminderOffsetsMinutes ?? {}) as Record<string, unknown>;
  const u = ops.unassignedAlertMinutes;
  return {
    rider: offsets(r?.rider),
    driver: offsets(r?.driver),
    unassigned: Number.isInteger(u) && (u as number) > 0 && (u as number) <= MAX_OFFSET_MINUTES ? u as number : null,
  };
}

export interface ReminderState {
  nextAt: number | null;
  sent: string[];
  skipped: string[];
  anchor: number | null;
  riderSince: number | null;
  driverSince: number | null;
  driverFor: string | null;
}

export type ReminderKind = 'rider' | 'driver' | 'unassigned';
export interface DueItem { key: string; kind: ReminderKind; at: number }

type Data = admin.firestore.DocumentData;
const tsMs = (v: unknown): number | null => (v instanceof admin.firestore.Timestamp ? v.toMillis() : null);

/** Lo que guardaba la reserva (o un estado vacío). */
export function readState(b: Data | undefined): ReminderState {
  const r = (b?.reminders ?? {}) as Record<string, unknown>;
  const list = (v: unknown) => (Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : []);
  return {
    nextAt: tsMs(r.nextAt), sent: list(r.sent), skipped: list(r.skipped), anchor: tsMs(r.anchor),
    riderSince: tsMs(r.riderSince), driverSince: tsMs(r.driverSince),
    driverFor: typeof r.driverFor === 'string' ? r.driverFor : null,
  };
}

/**
 * Plan de recordatorios a la hora [now]: el estado nuevo y los envíos cuya
 * hora llegó (due). Puro: sin lecturas ni escrituras.
 */
export function planReminders(b: Data | undefined, paid: boolean, cfg: ReminderConfig, now: number,
  prev: ReminderState): { state: ReminderState; due: DueItem[] } {
  const anchor = tsMs(b?.scheduledAt);
  const status = String(b?.status ?? '');
  const driverId = typeof b?.driverId === 'string' && b.driverId ? b.driverId : null;
  const riderActive = paid && RIDER_STATES.has(status);
  const driverActive = driverId !== null && DRIVER_STATES.has(status);

  let sent = [...prev.sent];
  let skipped = [...prev.skipped];
  // Otro chófer: empieza de cero con los suyos (solo los pendientes).
  const driverChanged = driverActive && prev.driverFor !== driverId;
  if (driverChanged) {
    sent = sent.filter((k) => !k.startsWith('driver:'));
    skipped = skipped.filter((k) => !k.startsWith('driver:'));
  }
  const riderSince = riderActive ? prev.riderSince ?? now : null;
  const driverSince = driverActive ? (driverChanged ? now : prev.driverSince ?? now) : null;

  const items: DueItem[] = [];
  if (anchor !== null) {
    if (riderActive) for (const m of cfg.rider) items.push({ key: `rider:${m}`, kind: 'rider', at: anchor - m * 60_000 });
    if (driverActive) for (const m of cfg.driver) items.push({ key: `driver:${m}`, kind: 'driver', at: anchor - m * 60_000 });
    // La alerta sí sale aunque su hora ya pasara: es para central.
    if (cfg.unassigned !== null && paid && status === 'pending' && !driverId) {
      items.push({ key: 'unassigned', kind: 'unassigned', at: anchor - cfg.unassigned * 60_000 });
    }
  }
  const since = (i: DueItem) => (i.kind === 'rider' ? riderSince : i.kind === 'driver' ? driverSince : null);
  const anchorMoved = prev.anchor !== null && anchor !== null && prev.anchor !== anchor;
  for (const i of items) {
    if (sent.includes(i.key) || skipped.includes(i.key) || i.kind === 'unassigned') continue;
    const s = since(i);
    // Su hora ya había pasado al empezar a recibirlos o al moverse la hora
    // ancla: no se envía (no se acumulan ni salen de golpe).
    if ((s !== null && i.at < s) || (anchorMoved && i.at <= now)) skipped.push(i.key);
  }
  const pending = items.filter((i) => !sent.includes(i.key) && !skipped.includes(i.key));
  const due = pending.filter((i) => i.at <= now);
  const rest = pending.filter((i) => i.at > now);
  const nextAt = due.length ? now : rest.length ? Math.min(...rest.map((i) => i.at)) : null;
  return {
    state: { nextAt, sent, skipped, anchor, riderSince, driverSince, driverFor: driverActive ? driverId : null },
    due,
  };
}

const toTs = (v: number | null) => (v === null ? null : admin.firestore.Timestamp.fromMillis(v));
export const stateDoc = (s: ReminderState) => ({
  nextAt: toTs(s.nextAt), sent: s.sent, skipped: s.skipped, anchor: toTs(s.anchor),
  riderSince: toTs(s.riderSince), driverSince: toTs(s.driverSince), driverFor: s.driverFor,
});

const same = (a: ReminderState, b: ReminderState) => JSON.stringify(a) === JSON.stringify(b);

export interface ReminderDeps {
  db: admin.firestore.Firestore;
  now?: () => number;
  /** Envío push (respeta config/global.pushNotificationsEnabled). */
  push?: (tokens: string[], title: string, body: string, data: Record<string, string>) => Promise<void>;
}

const paidOf = (snap: admin.firestore.DocumentSnapshot) => snap.data()?.paymentStatus === 'paid';
const stateRefOf = (db: admin.firestore.Firestore, id: string) =>
  db.collection('bookings').doc(id).collection('payment').doc('state');

/**
 * Recalcula `reminders` de una reserva (A3): lo llaman los disparadores de la
 * reserva y de su estado de pago. Si los envíos ya vencidos son legítimos
 * (hora llegada sin cambio de hora ancla ni de persona), no los marca: los
 * envía la tarea. No escribe si nada cambia (sin bucles de disparadores).
 */
export async function rescheduleReminders(deps: ReminderDeps, bookingId: string): Promise<'unchanged' | 'written' | 'missing'> {
  const db = deps.db;
  const now = deps.now?.() ?? Date.now();
  const cfg = readReminderConfig(await opsConfig(db, now));
  const ref = db.collection('bookings').doc(bookingId);
  return db.runTransaction(async (tx) => {
    const [snap, pay] = await Promise.all([tx.get(ref), tx.get(stateRefOf(db, bookingId))]);
    if (!snap.exists) return 'missing';
    const prev = readState(snap.data());
    const { state } = planReminders(snap.data(), paidOf(pay), cfg, now, prev);
    if (same(prev, state)) return 'unchanged';
    tx.update(ref, { reminders: stateDoc(state) });
    return 'written';
  });
}

const NOTICE: Record<'rider' | 'driver', NoticeType> = { rider: 'reminder_rider', driver: 'reminder_driver' };

/**
 * Envía lo que toca de una reserva a la hora [now] (A2): bandeja y alerta
 * en la misma transacción que marca las claves como enviadas, push después.
 * Un reintento no repite nada: las claves ya están en `sent`.
 */
export async function processBookingReminders(deps: ReminderDeps, bookingId: string, now: number,
  cfg: ReminderConfig): Promise<string[]> {
  const db = deps.db;
  const ref = db.collection('bookings').doc(bookingId);
  const pushes: Array<{ tokens: string[]; title: string; body: string; type: string }> = [];
  const sentNow = await db.runTransaction(async (tx) => {
    pushes.length = 0;
    const [snap, pay] = await Promise.all([tx.get(ref), tx.get(stateRefOf(db, bookingId))]);
    if (!snap.exists) return [];
    const b = snap.data()!;
    const { state, due } = planReminders(b, paidOf(pay), cfg, now, readState(b));
    const people = new Map<string, admin.firestore.DocumentSnapshot>();
    for (const i of due) {
      const uid = i.kind === 'rider' ? b.riderId : i.kind === 'driver' ? b.driverId : null;
      if (typeof uid === 'string' && !people.has(uid)) people.set(uid, await tx.get(db.collection('users').doc(uid)));
    }
    const at = admin.firestore.Timestamp.fromMillis(now);
    const anchor = tsMs(b.scheduledAt)!;
    for (const i of due) {
      state.sent.push(i.key);
      if (i.kind === 'unassigned') {
        tx.set(db.collection('adminAlerts').doc(`unassigned_${bookingId}`), {
          type: 'booking_unassigned', severity: 'high', bookingId, resolved: false, createdAt: at,
          message: 'Reserva pagada sin chófer cerca de la hora de recogida.',
        });
        continue;
      }
      const user = people.get(i.kind === 'rider' ? b.riderId : b.driverId);
      if (!user?.exists) continue;
      const locale = localeOf(user.data());
      // Sin datos personales en la pantalla bloqueada: solo la hora.
      const n = notice(NOTICE[i.kind], locale, { time: formatLocalTime(anchor, locale) });
      const nref = db.collection('users').doc(user.id).collection('notifications').doc(`reminder_${bookingId}_${i.key}`);
      tx.set(nref, { id: nref.id, userId: user.id, title: n.title, body: n.body, type: NOTICE[i.kind], locale,
        bookingId, isRead: false, createdAt: at });
      const tokens = (user.data()?.fcmTokens as string[] | undefined) ?? [];
      if (tokens.length) pushes.push({ tokens, title: n.title, body: n.body, type: NOTICE[i.kind] });
    }
    // nextAt de lo que queda tras enviar lo vencido.
    const left = planReminders(b, paidOf(pay), cfg, now, state);
    tx.update(ref, { reminders: stateDoc(left.state) });
    return due.map((i) => i.key);
  });
  for (const p of pushes) {
    // Un token inválido o un fallo del proveedor no corta el resto.
    await deps.push?.(p.tokens, p.title, p.body, { type: p.type, bookingId }).catch((e) =>
      logger.warn('reminders', 'push failed', { type: p.type, error: String(e) }));
  }
  return sentNow;
}

/** Cuántas reservas por pasada (las demás, en la siguiente). */
export const REMINDERS_BATCH = 200;

/** remindersJob: reservas con nextAt vencido, una transacción por reserva. */
export async function runReminders(deps: ReminderDeps): Promise<{ bookings: number; sent: number }> {
  const db = deps.db;
  const now = deps.now?.() ?? Date.now();
  const cfg = readReminderConfig(await opsConfig(db, now));
  // Interruptor «Notificaciones push» del panel (config/global): apagado, la
  // bandeja se escribe igual y no sale ningún push.
  const pushOn = (await db.collection('config').doc('global').get()).data()?.pushNotificationsEnabled !== false;
  const run: ReminderDeps = pushOn ? deps : { ...deps, push: undefined };
  const snap = await db.collection('bookings')
    .where('reminders.nextAt', '<=', admin.firestore.Timestamp.fromMillis(now))
    .orderBy('reminders.nextAt').limit(REMINDERS_BATCH).get();
  let sent = 0;
  for (const d of snap.docs) {
    try {
      sent += (await processBookingReminders(run, d.id, now, cfg)).length;
    } catch (e) {
      logger.error('reminders', 'booking failed', { bookingId: d.id, error: String(e) });
    }
  }
  return { bookings: snap.size, sent };
}
