/**
 * Viaje compartido (Prompt 18, Parte B, decisiones 6 a 9).
 *
 * - El pasajero dueño crea un enlace de seguimiento de su reserva entre
 *   confirmed e in_progress (createTripShare). Token de 128 bits aleatorios;
 *   se guarda solo su HMAC (TRIP_SHARE_SECRET) como id de tripShares/{hash}.
 *   Como mucho un enlace activo por reserva: crear otro revoca el anterior.
 *   Lo revoca el pasajero (revokeTripShare) o un admin con auditoría
 *   (adminRevokeTripShare).
 * - Caduca cuando la reserva llega a un estado final, más
 *   config/ops.tripShareGraceMinutes si existe (si no, al instante), y como
 *   tarde TRIP_SHARE_MAX_HOURS después de crearlo (tope técnico).
 * - Lo que ve quien lo abre (sharedTrip, sin sesión): lista cerrada de
 *   publicView(). Nunca teléfono, apellido, precio, pago, notas,
 *   preferencias, vuelo, código, correo, ids internos ni la dirección exacta;
 *   el destino, solo como zona (pickupArea/dropoffArea, como openRequests).
 * - El token viaja en el fragmento de la URL (/t#<token>): el navegador no lo
 *   manda al servidor al pedir la página ni en el Referer, y no queda en los
 *   registros de peticiones de la plataforma. La página lo envía en el cuerpo
 *   de un POST a la misma función.
 */
import { createHmac, randomBytes, randomUUID } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { AdminActor, reasonSchema, writeAudit } from './admin_audit';
import { pseudonym } from './business_leads';
import { AppLocale, formatLocalTime, MessageKey, t } from './i18n';
import { logger } from './logger';
import { opsConfig } from './ops_config';
import { enforceRateLimit, RateRule } from './rate_limit';
import { docId, parseInput } from './schemas';

/** Tope técnico de vida de un enlace (no es un valor de negocio). */
export const TRIP_SHARE_MAX_HOURS = 24;
/** Cada cuánto consulta la página (técnico). */
export const POLL_SECONDS = 15;
/** Lecturas por IP (con hash) en 10 minutos: unas 4 personas mirando. */
export const SHARED_TRIP_LIMIT: RateRule = { limit: 160, windowSeconds: 600 };

export const SHARE_STATES = ['confirmed', 'driver_arriving', 'driver_arrived', 'verified', 'in_progress'];
const LIVE_STATES = ['driver_arriving', 'driver_arrived', 'verified', 'in_progress'];
const FINAL_STATES = ['completed', 'cancelled', 'no_show'];

export interface ShareDeps {
  db: admin.firestore.Firestore;
  /** TRIP_SHARE_SECRET. Vacío: no se crean ni se leen enlaces (falla cerrado). */
  secret: string;
  now?: () => number;
}

const nowOf = (d: { now?: () => number }) => d.now?.() ?? Date.now();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const ms = (v: unknown): number | null => (v instanceof admin.firestore.Timestamp ? v.toMillis() : null);
const shareError = (code: 'failed-precondition' | 'not-found' | 'permission-denied' | 'internal', reason: string) =>
  new HttpsError(code, reason, { reason });

export const hashToken = (secret: string, token: string) =>
  createHmac('sha256', secret).update(`trip-share:${token}`).digest('hex');

/** 128 bits aleatorios, en base64url (22 caracteres). */
export const newToken = () => randomBytes(16).toString('base64url');
const TOKEN_RE = /^[A-Za-z0-9_-]{22}$/;

const shares = (db: admin.firestore.Firestore) => db.collection('tripShares');

function requireSecret(deps: ShareDeps): void {
  if (!deps.secret) {
    logger.error('tripShare', 'TRIP_SHARE_SECRET missing', {});
    throw shareError('internal', 'internal');
  }
}

export const bookingSchema = z.strictObject({ bookingId: docId });
export const adminRevokeSchema = z.strictObject({ bookingId: docId, reason: reasonSchema });

/** Revoca en la transacción los enlaces activos de la reserva (lecturas antes). */
async function activeShares(tx: admin.firestore.Transaction, db: admin.firestore.Firestore, bookingId: string) {
  return (await tx.get(shares(db).where('bookingId', '==', bookingId).where('active', '==', true))).docs;
}

export async function createTripShare(deps: ShareDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { reason: 'unauthenticated' });
  const { bookingId } = parseInput(bookingSchema, data);
  requireSecret(deps);
  const db = deps.db;
  const now = nowOf(deps);
  const token = newToken();
  const hash = hashToken(deps.secret, token);
  const ref = db.collection('bookings').doc(bookingId);
  const maxUntil = now + TRIP_SHARE_MAX_HOURS * 3_600_000;
  await db.runTransaction(async (tx) => {
    const b = (await tx.get(ref)).data();
    // Ajena o inexistente: la misma respuesta (sin pistas).
    if (!b || b.riderId !== uid) throw shareError('not-found', 'booking_not_found');
    if (!SHARE_STATES.includes(String(b.status))) throw shareError('failed-precondition', 'share_not_available');
    const prev = await activeShares(tx, db, bookingId);
    for (const d of prev) tx.update(d.ref, { active: false, revokedAt: ts(now), revokedBy: 'replaced' });
    tx.set(shares(db).doc(hash), {
      bookingId, riderId: uid, active: true, createdAt: ts(now), maxUntil: ts(maxUntil), revokedAt: null, revokedBy: null,
    });
  });
  logger.info('tripShare', 'created', { bookingId });
  return { token, path: `/t#${token}`, maxUntil };
}

export async function revokeTripShare(deps: ShareDeps, uid: string | undefined, data: unknown) {
  if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { reason: 'unauthenticated' });
  const { bookingId } = parseInput(bookingSchema, data);
  const db = deps.db;
  const now = nowOf(deps);
  const ref = db.collection('bookings').doc(bookingId);
  const revoked = await db.runTransaction(async (tx) => {
    const b = (await tx.get(ref)).data();
    if (!b || b.riderId !== uid) throw shareError('not-found', 'booking_not_found');
    const prev = await activeShares(tx, db, bookingId);
    for (const d of prev) tx.update(d.ref, { active: false, revokedAt: ts(now), revokedBy: 'rider' });
    return prev.length;
  });
  logger.info('tripShare', 'revoked', { bookingId, revoked });
  return { revoked };
}

export async function adminRevokeTripShare(deps: { db: admin.firestore.Firestore; now?: () => number }, actor: AdminActor,
  data: unknown) {
  const input = parseInput(adminRevokeSchema, data);
  const db = deps.db;
  const now = nowOf(deps);
  const revoked = await db.runTransaction(async (tx) => {
    const prev = await activeShares(tx, db, input.bookingId);
    for (const d of prev) tx.update(d.ref, { active: false, revokedAt: ts(now), revokedBy: 'admin' });
    writeAudit(tx, db, {
      actor, operation: 'revoke_trip_share', collection: 'bookings', docId: input.bookingId, targetType: 'booking',
      changes: prev.length ? { tripShareActive: { before: true, after: false } } : {}, reason: input.reason,
      details: prev.length ? 'Enlace de seguimiento revocado' : 'Sin enlace activo que revocar',
    });
    return prev.length;
  });
  return { revoked };
}

/** Estado del enlace de la reserva para el pasajero y el panel (sin token). */
export async function tripShareStatus(db: admin.firestore.Firestore, bookingId: string) {
  const snap = await shares(db).where('bookingId', '==', bookingId).where('active', '==', true).limit(1).get();
  const d = snap.docs[0]?.data();
  return d ? { active: true, createdAt: ms(d.createdAt), maxUntil: ms(d.maxUntil) } : { active: false };
}

// ---------------------------------------------------------------------------
// Lectura pública
// ---------------------------------------------------------------------------

type Data = admin.firestore.DocumentData;

function endedAt(b: Data): number | null {
  const at = b.status === 'completed' ? b.completedAt : b.status === 'no_show' ? b.noShowAt : b.cancelledAt;
  return ms(at) ?? ms(b.updatedAt);
}

/** El enlace sirve ahora: activo, dentro del tope y, si el viaje terminó, del margen. */
function stillValid(share: Data, b: Data, graceMinutes: number, now: number): boolean {
  if (share.active !== true) return false;
  const max = ms(share.maxUntil);
  if (max === null || now >= max) return false;
  if (!FINAL_STATES.includes(String(b.status))) return true;
  const end = endedAt(b);
  return end !== null && now < end + graceMinutes * 60_000;
}

/** Nombre de pila: la primera palabra del nombre del chófer. */
const firstName = (v: unknown) => (typeof v === 'string' ? v.trim().split(/\s+/)[0] ?? '' : '').slice(0, 40);
const str = (v: unknown, max = 40) => (typeof v === 'string' && v.trim() ? v.trim().slice(0, max) : null);

export interface PublicView {
  state: 'active' | 'finished';
  status: string;
  statusKey: string;
  pickupTime: string | null;
  driverName: string | null;
  vehicle: { make: string | null; model: string | null; color: string | null; plate: string | null } | null;
  pickupArea: string | null;
  destinationArea: string | null;
  position: { lat: number; lng: number; at: string } | null;
}

/** Únicos campos que puede devolver la lectura pública (el test los compara). */
export const PUBLIC_FIELDS = ['state', 'status', 'statusKey', 'pickupTime', 'driverName', 'vehicle', 'pickupArea',
  'destinationArea', 'position'] as const;

function statusKey(status: string): string {
  if (status === 'pending') return 'share.status.searching';
  if (status === 'confirmed') return 'share.status.assigned';
  if (status === 'driver_arriving') return 'share.status.arriving';
  if (status === 'driver_arrived') return 'share.status.arrived';
  if (status === 'verified' || status === 'in_progress') return 'share.status.onTrip';
  if (status === 'completed') return 'share.status.completed';
  return 'share.status.inactive';
}

/** La vista pública (lista cerrada), o null si el enlace no sirve. */
export async function readSharedTrip(deps: ShareDeps, token: string, locale: AppLocale): Promise<PublicView | null> {
  if (!deps.secret || !TOKEN_RE.test(token)) return null;
  const db = deps.db;
  const now = nowOf(deps);
  const share = (await shares(db).doc(hashToken(deps.secret, token)).get()).data();
  if (!share) return null;
  const bookingRef = db.collection('bookings').doc(String(share.bookingId));
  const [bSnap, ops] = await Promise.all([bookingRef.get(), opsConfig(db, now)]);
  const b = bSnap.data();
  if (!b) return null;
  const graceRaw = ops.tripShareGraceMinutes;
  const grace = Number.isInteger(graceRaw) && (graceRaw as number) > 0 ? graceRaw as number : 0;
  if (!stillValid(share, b, grace, now)) return null;

  const status = String(b.status);
  const withDriver = SHARE_STATES.includes(status) && typeof b.driverId === 'string';
  const info = (b.driverInfo ?? {}) as Data;
  const v = (info.vehicle ?? {}) as Data;
  let position: PublicView['position'] = null;
  if (LIVE_STATES.includes(status)) {
    const p = (await bookingRef.collection('tracking').doc('driver').get()).data();
    const at = ms(p?.updatedAt);
    if (typeof p?.lat === 'number' && typeof p?.lng === 'number' && at !== null) {
      position = { lat: p.lat, lng: p.lng, at: formatLocalTime(at, locale) };
    }
  }
  const anchor = ms(b.scheduledAt);
  const key = statusKey(status);
  return {
    state: FINAL_STATES.includes(status) ? 'finished' : 'active',
    status: t(key as MessageKey, locale),
    statusKey: key,
    pickupTime: anchor === null ? null : formatLocalTime(anchor, locale),
    driverName: withDriver ? firstName(info.name) || null : null,
    vehicle: withDriver
      ? { make: str(v.make), model: str(v.model), color: str(v.color), plate: str(v.plate, 16) } : null,
    pickupArea: str(b.pickupArea, 80),
    destinationArea: b.serviceType === 'byTheHour' ? null : str(b.dropoffArea, 80),
    position,
  };
}

// ---------------------------------------------------------------------------
// Página y respuesta HTTP (sharedTrip)
// ---------------------------------------------------------------------------

export function pickLocale(acceptLanguage: string | undefined): AppLocale {
  for (const part of (acceptLanguage ?? '').split(',')) {
    const tag = part.split(';')[0].trim().toLowerCase();
    if (tag.startsWith('es')) return 'es';
    if (tag.startsWith('pt')) return 'pt';
    if (tag.startsWith('en')) return 'en';
  }
  return 'es';
}

export interface HttpOut { status: number; headers: Record<string, string>; body: string }

function headers(contentType: string, nonce?: string): Record<string, string> {
  return {
    'Content-Type': contentType,
    'Cache-Control': 'no-store',
    'X-Robots-Tag': 'noindex, nofollow',
    'Referrer-Policy': 'no-referrer',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Content-Security-Policy': [
      "default-src 'none'",
      nonce ? `script-src 'nonce-${nonce}'` : "script-src 'none'",
      nonce ? `style-src 'nonce-${nonce}'` : "style-src 'none'",
      "connect-src 'self'",
      "img-src 'none'",
      "base-uri 'none'",
      "form-action 'none'",
      "frame-ancestors 'none'",
    ].join('; '),
  };
}

const esc = (s: string) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);

/** Textos de la página, del catálogo del servidor, en el idioma pedido. */
function pageTexts(locale: AppLocale) {
  const keys = ['share.page.title', 'share.page.loading', 'share.page.unavailableTitle', 'share.page.unavailableBody',
    'share.page.noScript', 'share.page.pickupTime', 'share.page.driver', 'share.page.vehicle', 'share.page.pickupArea',
    'share.page.destinationArea', 'share.page.position', 'share.page.positionAt', 'share.page.noPosition',
    'share.page.openMap', 'share.page.autoUpdate', 'share.page.finished', 'share.page.tooMany'] as const;
  // {time} se rellena en la página con la hora de cada posición.
  return Object.fromEntries(keys.map((k) => [k.replace('share.page.', ''),
    t(k, locale, k === 'share.page.positionAt' ? { time: '{time}' } : {})])) as Record<string, string>;
}

/** Página ligera (sin el framework de la app): estilos y script en línea con nonce. */
export function renderPage(locale: AppLocale): HttpOut {
  const nonce = randomUUID().replace(/-/g, '');
  const tx = pageTexts(locale);
  const body = `<!doctype html>
<html lang="${locale}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="referrer" content="no-referrer">
<title>${esc(tx.title)}</title>
<style nonce="${nonce}">
:root{color-scheme:light dark;--ink:#14213d;--muted:#4a5568;--bg:#f7f8fb;--card:#fff;--line:#d9dee7}
@media (prefers-color-scheme:dark){:root{--ink:#f2f4f8;--muted:#c3c9d4;--bg:#0f1420;--card:#18202f;--line:#2b3547}}
*{box-sizing:border-box}body{margin:0;font:1rem/1.5 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:var(--ink);background:var(--bg)}
main{max-width:34rem;margin:0 auto;padding:1rem}
h1{font-size:1.5rem;margin:.5rem 0 1rem}
.card{background:var(--card);border:1px solid var(--line);border-radius:.75rem;padding:1rem;margin-bottom:.75rem}
.status{font-size:1.25rem;font-weight:600}
dl{margin:0}dt{color:var(--muted);font-size:.875rem;margin-top:.75rem}dd{margin:0}
a{color:inherit;display:inline-block;min-height:48px;line-height:48px}
.note{color:var(--muted);font-size:.875rem}
[hidden]{display:none!important}
@media (prefers-reduced-motion:reduce){*{transition:none!important;animation:none!important}}
</style>
</head>
<body>
<main>
<h1>${esc(tx.title)}</h1>
<noscript><p class="card">${esc(tx.noScript)}</p></noscript>
<section id="loading" class="card" aria-live="polite" hidden>${esc(tx.loading)}</section>
<section id="gone" class="card" hidden><h2 class="status">${esc(tx.unavailableTitle)}</h2><p>${esc(tx.unavailableBody)}</p></section>
<section id="busy" class="card" hidden><p>${esc(tx.tooMany)}</p></section>
<section id="trip" hidden>
<div class="card"><p id="status" class="status" role="status" aria-live="polite"></p><p id="finished" class="note" hidden>${esc(tx.finished)}</p></div>
<div class="card"><dl>
<dt>${esc(tx.pickupTime)}</dt><dd id="pickupTime"></dd>
<div id="driverBox"><dt>${esc(tx.driver)}</dt><dd id="driver"></dd><dt>${esc(tx.vehicle)}</dt><dd id="vehicle"></dd></div>
<div id="pickupBox"><dt>${esc(tx.pickupArea)}</dt><dd id="pickupArea"></dd></div>
<div id="destBox"><dt>${esc(tx.destinationArea)}</dt><dd id="destinationArea"></dd></div>
<dt>${esc(tx.position)}</dt><dd><span id="position"></span> <a id="map" hidden>${esc(tx.openMap)}</a></dd>
</dl></div>
<p class="note">${esc(tx.autoUpdate)}</p>
</section>
</main>
<script nonce="${nonce}">
(function(){
var T=${JSON.stringify({ positionAt: tx.positionAt, noPosition: tx.noPosition })};
var token=location.hash.replace(/^#/,'');
function $(id){return document.getElementById(id)}
function show(id){['loading','gone','busy','trip'].forEach(function(s){$(s).hidden=s!==id})}
function put(id,v){$(id).textContent=v||''}
function box(id,on){$(id).hidden=!on}
function tick(){
fetch(location.pathname,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token:token}),cache:'no-store',credentials:'omit',referrerPolicy:'no-referrer'})
.then(function(r){if(r.status===429){show('busy');return null}return r.json()})
.then(function(d){if(!d)return later();if(d.state==='unavailable'){show('gone');return}
put('status',d.status);put('pickupTime',d.pickupTime);
box('driverBox',!!d.driverName);put('driver',d.driverName);
var v=d.vehicle;put('vehicle',v?[v.make,v.model,v.color,v.plate].filter(Boolean).join(' · '):'');
box('pickupBox',!!d.pickupArea);put('pickupArea',d.pickupArea);
box('destBox',!!d.destinationArea);put('destinationArea',d.destinationArea);
if(d.position){put('position',T.positionAt.replace('{time}',d.position.at));var m=$('map');m.href='geo:'+d.position.lat+','+d.position.lng;m.hidden=false}
else{put('position',T.noPosition);$('map').hidden=true}
$('finished').hidden=d.state!=='finished';show('trip');if(d.state==='active')later()})
.catch(later)}
function later(){setTimeout(tick,${POLL_SECONDS * 1000})}
if(!token){show('gone')}else{show('loading');tick()}
})();
</script>
</body>
</html>`;
  return { status: 200, headers: headers('text/html; charset=utf-8', nonce), body };
}

export interface SharedTripRequest {
  method: string;
  ip: string;
  acceptLanguage?: string;
  body?: unknown;
}

const json = (status: number, payload: unknown): HttpOut =>
  ({ status, headers: headers('application/json; charset=utf-8'), body: JSON.stringify(payload) });

/**
 * sharedTrip: GET devuelve la página (sin token); POST {token} devuelve la
 * vista. Token inexistente, caducado, revocado o mal formado: la misma
 * respuesta (200, { state: 'unavailable' }). Límite de tasa por IP con hash.
 * Nada del token va a los registros.
 */
export async function handleSharedTrip(deps: ShareDeps & { salt: string; limit?: RateRule }, req: SharedTripRequest):
  Promise<HttpOut> {
  const locale = pickLocale(req.acceptLanguage);
  if (req.method === 'GET' || req.method === 'HEAD') return renderPage(locale);
  if (req.method !== 'POST') return { status: 405, headers: { ...headers('text/plain; charset=utf-8'), Allow: 'GET, POST' }, body: '' };
  if (!deps.salt) {
    logger.error('sharedTrip', 'RATE_LIMIT_SALT missing', {});
    return json(503, { state: 'unavailable' });
  }
  try {
    await enforceRateLimit(deps.db, 'sharedTrip_ip', pseudonym(deps.salt, 'ip', req.ip), deps.limit ?? SHARED_TRIP_LIMIT,
      nowOf(deps));
  } catch {
    return json(429, { state: 'busy' });
  }
  const token = typeof (req.body as { token?: unknown } | undefined)?.token === 'string'
    ? (req.body as { token: string }).token : '';
  const view = await readSharedTrip(deps, token, locale).catch((e) => {
    logger.error('sharedTrip', 'read failed', { error: String(e) });
    return null;
  });
  return json(200, view ?? { state: 'unavailable' });
}
