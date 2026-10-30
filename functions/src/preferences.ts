/**
 * Preferencias del pasajero para su chófer (decisiones 1–6 del prompt de
 * preferencias). Listas cerradas salvo la nota. El perfil las guarda en
 * users/{uid}.tripPreferences, escrito solo por updatePreferences; cada
 * reserva guarda su copia saneada en bookings/{id}/driverView/preferences.
 *
 * Son un deseo, no una garantía: nada aquí empareja chóferes por idioma ni
 * por preferencias (decisión 6).
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { opsConfig } from './ops_config';

/** Idiomas del chófer que puede preferir el pasajero (decisión 1). */
export const DRIVER_LANGUAGES = ['es', 'en', 'pt'] as const;
export const CABIN_TEMPERATURES = ['cool', 'mild', 'no_preference'] as const;
export const CONVERSATION = ['chatty', 'quiet', 'no_preference'] as const;
/** Estilos genéricos, sin artistas ni marcas (propuesta, pendiente de revisión). */
export const MUSIC_GENRES = ['classical', 'jazz', 'instrumental', 'pop', 'rock', 'latin', 'electronic', 'folk'] as const;
export const MUSIC_STYLES = [...MUSIC_GENRES, 'none', 'no_preference'] as const;
/** Necesidades prácticas (propuesta, pendiente de revisión). */
export const NEEDS = [
  'extra_luggage', 'luggage_assistance', 'child_seat', 'booster_seat',
  'boarding_assistance', 'folding_wheelchair', 'pet_in_carrier',
] as const;

export const NOTE_MAX = 200;
export const PLAYLIST_URL_MAX = 300;

export type DriverLanguage = (typeof DRIVER_LANGUAGES)[number];
export type Need = (typeof NEEDS)[number];

export interface TripPreferences {
  preferredDriverLanguages: DriverLanguage[];
  cabinTemperature: (typeof CABIN_TEMPERATURES)[number];
  conversation: (typeof CONVERSATION)[number];
  musicStyle: (typeof MUSIC_STYLES)[number];
  playlistUrl: string | null;
  needs: Need[];
  note: string | null;
}

export const EMPTY_PREFERENCES: TripPreferences = {
  preferredDriverLanguages: [],
  cabinTemperature: 'no_preference',
  conversation: 'no_preference',
  musicStyle: 'no_preference',
  playlistUrl: null,
  needs: [],
  note: null,
};

// Controles (C0, C1), separadores de línea y de párrafo, y marcas de
// dirección que pueden disfrazar el texto. Se cambian por un espacio.
const CONTROL = new RegExp('[\\u0000-\\u001F\\u007F-\\u009F\\u2028\\u2029\\u200B-\\u200F' +
  '\\u202A-\\u202E\\u2060-\\u2069\\uFEFF]', 'g');

/** Nota sin controles ni saltos de línea, espacios simples; vacía = null. */
export function cleanNote(raw: string): string | null {
  const s = raw.replace(CONTROL, ' ').replace(/\s+/g, ' ').trim();
  return s ? s : null;
}

// Enlaces en la nota: un esquema (https://, mailto:…), www. o un dominio
// con una terminación habitual.
const LINK = new RegExp(
  '([a-z][a-z0-9+.-]*://|\\b(mailto|tel|sms|whatsapp|intent|javascript|data):|\\bwww\\.|' +
  '\\b[a-z0-9-]+\\.(com|net|org|io|bo|me|ly|app|co|info|link|xyz|gl|be|to|page|site|dev)\\b)', 'i');

export const hasLink = (s: string): boolean => LINK.test(s);

const uniqueList = <T extends string>(values: readonly [T, ...T[]]) =>
  z.array(z.enum(values)).max(values.length)
    .refine((a) => new Set(a).size === a.length, { message: 'duplicated' });

const noteField = z.string().max(NOTE_MAX * 4)
  .refine((s) => [...(cleanNote(s) ?? '')].length <= NOTE_MAX, { message: 'too long' })
  .refine((s) => !hasLink(cleanNote(s) ?? ''), { message: 'link' });

/** Entrada de updatePreferences y de createBooking.preferences. */
export const preferencesSchema = z.strictObject({
  preferredDriverLanguages: uniqueList(DRIVER_LANGUAGES).optional(),
  cabinTemperature: z.enum(CABIN_TEMPERATURES).optional(),
  conversation: z.enum(CONVERSATION).optional(),
  musicStyle: z.enum(MUSIC_STYLES).optional(),
  playlistUrl: z.string().max(PLAYLIST_URL_MAX).nullable().optional(),
  needs: uniqueList(NEEDS).optional(),
  note: noteField.nullable().optional(),
});

export type PreferencesInput = z.infer<typeof preferencesSchema>;

/** Hosts permitidos de config/ops.playlistHosts, en minúsculas. */
export function playlistHostsOf(ops: Record<string, unknown>): string[] {
  const raw = ops.playlistHosts;
  if (!Array.isArray(raw)) return [];
  return [...new Set(raw
    .filter((h): h is string => typeof h === 'string')
    .map((h) => h.trim().toLowerCase())
    .filter((h) => /^[a-z0-9.-]{1,253}$/.test(h)))];
}

export async function loadPlaylistHosts(db: admin.firestore.Firestore): Promise<string[]> {
  return playlistHostsOf(await opsConfig(db));
}

const playlistRejected = () => new HttpsError('invalid-argument', 'playlist_not_allowed',
  { reason: 'playlist_not_allowed', fields: ['playlistUrl'] });

/**
 * La URL de la lista: https, sin credenciales ni puerto, de un host de la
 * lista. null si no es válida. Nunca se abre ni se descarga aquí.
 */
export function validPlaylistUrl(raw: string, hosts: readonly string[]): string | null {
  if (!hosts.length || raw.length > PLAYLIST_URL_MAX || /\s/.test(raw)) return null;
  let u: URL;
  try {
    u = new URL(raw);
  } catch {
    return null;
  }
  if (u.protocol !== 'https:' || u.username || u.password || u.port) return null;
  if (!hosts.includes(u.hostname.toLowerCase())) return null;
  const out = u.toString();
  return out.length <= PLAYLIST_URL_MAX ? out : null;
}

const ordered = <T extends string>(all: readonly T[], picked: readonly T[] | undefined): T[] =>
  all.filter((v) => picked?.includes(v));

/**
 * Copia saneada de una entrada ya validada por el esquema. Estricta: una
 * URL fuera de la lista es un error. Laxa (perfil guardado antes de cambiar
 * la lista): la URL se descarta.
 */
export function sanitizePreferences(input: PreferencesInput, hosts: readonly string[],
  mode: 'strict' | 'lenient' = 'strict'): TripPreferences {
  let playlistUrl: string | null = null;
  const rawUrl = input.playlistUrl?.trim();
  if (rawUrl) {
    playlistUrl = validPlaylistUrl(rawUrl, hosts);
    if (!playlistUrl && mode === 'strict') throw playlistRejected();
  }
  return {
    preferredDriverLanguages: ordered(DRIVER_LANGUAGES, input.preferredDriverLanguages),
    cabinTemperature: input.cabinTemperature ?? 'no_preference',
    conversation: input.conversation ?? 'no_preference',
    musicStyle: input.musicStyle ?? 'no_preference',
    playlistUrl,
    needs: ordered(NEEDS, input.needs),
    note: input.note ? cleanNote(input.note) : null,
  };
}

/**
 * Preferencias del perfil para una reserva nueva. Se vuelven a validar: si
 * algo ya no pasa (p. ej. cambió la lista de hosts), se descarta solo eso.
 * Sin tripPreferences, las antiguas ridePreferences que escribía la app
 * (quiet, temperature, music, luggageHelp) se traducen a la lista cerrada.
 */
export function profilePreferences(user: Record<string, unknown> | undefined,
  hosts: readonly string[]): TripPreferences {
  const saved = user?.tripPreferences;
  if (saved && typeof saved === 'object') {
    const { updatedAt: _u, ...rest } = saved as Record<string, unknown>;
    const r = preferencesSchema.safeParse(rest);
    return r.success ? sanitizePreferences(r.data, hosts, 'lenient') : { ...EMPTY_PREFERENCES };
  }
  return legacyPreferences(user?.ridePreferences);
}

/** ridePreferences de las apps anteriores → lista cerrada. */
export function legacyPreferences(raw: unknown): TripPreferences {
  const out: TripPreferences = { ...EMPTY_PREFERENCES, preferredDriverLanguages: [], needs: [] };
  if (!raw || typeof raw !== 'object') return out;
  const p = raw as Record<string, unknown>;
  if (p.quiet === true) out.conversation = 'quiet';
  if (p.temperature === 'cool' || p.temperature === 'mild') out.cabinTemperature = p.temperature;
  if (p.music === false) out.musicStyle = 'none';
  if (p.luggageHelp === true) out.needs = ['luggage_assistance'];
  return out;
}

export function isEmptyPreferences(p: TripPreferences): boolean {
  return !p.preferredDriverLanguages.length && !p.needs.length && !p.note && !p.playlistUrl &&
    p.cabinTemperature === 'no_preference' && p.conversation === 'no_preference' &&
    p.musicStyle === 'no_preference';
}

/** Documento de la copia por reserva (bookings/{id}/driverView/preferences). */
export function driverViewDoc(bookingId: string, riderId: string, prefs: TripPreferences,
  source: 'trip' | 'profile', now: admin.firestore.Timestamp) {
  return { bookingId, riderId, ...prefs, source, createdAt: now };
}

export const driverViewRef = (db: admin.firestore.Firestore, bookingId: string) =>
  db.collection('bookings').doc(bookingId).collection('driverView').doc('preferences');

function parseOrReject(data: unknown): PreferencesInput {
  const r = preferencesSchema.safeParse(data);
  if (!r.success) {
    const fields = [...new Set(r.error.issues.map((i) => String(i.path[0] ?? '(raíz)')))];
    throw new HttpsError('invalid-argument', 'invalid_request', { reason: 'invalid_request', fields });
  }
  return r.data;
}

/** Valida y sanea unas preferencias que manda la app (perfil o viaje). */
export function parsePreferences(data: unknown, hosts: readonly string[]): TripPreferences {
  return sanitizePreferences(parseOrReject(data), hosts, 'strict');
}

export interface PreferencesDeps {
  db: admin.firestore.Firestore;
  now?: () => number;
}

async function requireActiveRider(db: admin.firestore.Firestore, uid: string | undefined) {
  if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { reason: 'unauthenticated' });
  const user = (await db.collection('users').doc(uid).get()).data();
  if (!user || user.role !== 'rider' || user.isActive === false) {
    throw new HttpsError('permission-denied', 'inactive_user', { reason: 'inactive_user' });
  }
}

/** updatePreferences: guarda las del perfil. No toca reservas ya creadas. */
export async function updatePreferences(deps: PreferencesDeps, uid: string | undefined, data: unknown) {
  await requireActiveRider(deps.db, uid);
  const prefs = parsePreferences(data, await loadPlaylistHosts(deps.db));
  await deps.db.collection('users').doc(uid!).update({
    tripPreferences: { ...prefs, updatedAt: admin.firestore.Timestamp.fromMillis(deps.now?.() ?? Date.now()) },
  });
  return { preferences: prefs };
}

/** Lo que la app necesita para ofrecer los campos: sin la lista de hosts. */
export async function preferenceOptions(deps: PreferencesDeps, uid: string | undefined) {
  if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { reason: 'unauthenticated' });
  return { playlistEnabled: (await loadPlaylistHosts(deps.db)).length > 0, noteMax: NOTE_MAX };
}
