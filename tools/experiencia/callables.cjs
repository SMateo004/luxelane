/**
 * Ejecutor local de Cloud Functions para revisar la app (Parte A de
 * experiencia). Sustituye al emulador de Functions de firebase-tools, que en
 * este entorno manda por el proxy incluso las llamadas a 127.0.0.1.
 *
 * - Callables: protocolo de Firebase en http://127.0.0.1:5001/<proyecto>/
 *   us-central1/<nombre>, con el token verificado contra el emulador de Auth.
 * - Triggers de Firestore (creado / actualizado / escrito) de colecciones de
 *   primer nivel: se disparan escuchando los cambios en el emulador.
 * Usa el código compilado real (functions/lib). Solo demo-luxelane.
 * Lo que llama a Stripe no se ejecuta (la clave es ficticia).
 */
'use strict';
const http = require('http');
const fs = require('fs');
const path = require('path');

const PROJECT = 'demo-luxelane';
if ((process.env.GCLOUD_PROJECT || PROJECT) !== PROJECT) throw new Error(`Solo ${PROJECT}.`);
for (const v of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST']) {
  if (!process.env[v]) throw new Error(`Falta ${v}: solo contra los emuladores.`);
}
process.env.GCLOUD_PROJECT = PROJECT;
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: PROJECT });
// Secretos ficticios (functions/.secret.local, que escribe levantar.sh).
const secrets = path.join(__dirname, '../../functions/.secret.local');
for (const line of fs.readFileSync(secrets, 'utf8').split('\n')) {
  const m = line.match(/^([A-Z_]+)=(.*)$/);
  if (m) process.env[m[1]] = m[2];
}

const FUNCTIONS = path.join(__dirname, '../../functions');
const admin = require(path.join(FUNCTIONS, 'node_modules/firebase-admin'));
const fns = require(path.join(FUNCTIONS, 'lib/index.js'));
const STRIPE = new Set(['createPaymentIntent', 'capturePayment', 'refundPayment', 'listPaymentMethods',
  'setDefaultPaymentMethod', 'attachPaymentMethod', 'detachPaymentMethod', 'ensureStripeCustomer',
  'createStripeCustomer', 'captureOnCompletion']);
const STATUS = { 'invalid-argument': 400, 'failed-precondition': 400, 'out-of-range': 400, unauthenticated: 401,
  'permission-denied': 403, 'not-found': 404, 'already-exists': 409, aborted: 409, 'resource-exhausted': 429,
  cancelled: 499, unimplemented: 501, internal: 500, unknown: 500, unavailable: 503, 'deadline-exceeded': 504 };

const callables = {};
const triggers = [];
for (const [name, fn] of Object.entries(fns)) {
  const ep = fn && fn.__endpoint;
  if (!ep || STRIPE.has(name)) continue;
  if (ep.callableTrigger) callables[name] = fn;
  else if (ep.eventTrigger && ep.eventTrigger.eventType.startsWith('google.cloud.firestore.document.v1.')) {
    const doc = (ep.eventTrigger.eventFilterPathPatterns || {}).document || '';
    const m = doc.match(/^([^/]+)\/\{([^}]+)\}$/);
    if (m) triggers.push({ name, fn, collection: m[1], param: m[2], kind: ep.eventTrigger.eventType.split('.').pop() });
  }
}

async function auth(req) {
  const h = req.headers.authorization || '';
  if (!h.startsWith('Bearer ')) return undefined;
  try {
    const token = await admin.auth().verifyIdToken(h.slice(7));
    return { uid: token.uid, token, rawToken: h.slice(7) };
  } catch { return undefined; }
}

function send(res, code, body) {
  res.writeHead(code, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Firebase-AppCheck, X-Firebase-GMPID, X-Client-Version, X-Firebase-Client',
    'Access-Control-Allow-Methods': 'POST, OPTIONS' });
  res.end(JSON.stringify(body));
}

http.createServer((req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, {});
  const name = req.url.split('?')[0].split('/').pop();
  let raw = '';
  req.on('data', (c) => { raw += c; });
  req.on('end', async () => {
    if (STRIPE.has(name)) {
      return send(res, 503, { error: { status: 'UNAVAILABLE', message: 'stripe_not_in_local_review', details: { reason: 'stripe_not_in_local_review' } } });
    }
    const fn = callables[name];
    if (!fn) return send(res, 404, { error: { status: 'NOT_FOUND', message: 'not_found' } });
    try {
      const body = raw ? JSON.parse(raw) : {};
      const result = await fn.run({ data: body.data ?? null, auth: await auth(req), app: {},
        rawRequest: Object.assign(req, { ip: '127.0.0.1', body }), acceptsStreaming: false });
      send(res, 200, { result: result === undefined ? null : result });
    } catch (e) {
      const code = e && e.code && STATUS[e.code] ? e.code : 'internal';
      if (code === 'internal') console.error(`[${name}]`, e);
      send(res, STATUS[code], { error: { status: code.toUpperCase().replace(/-/g, '_'), message: e.message || code, details: e.details } });
    }
  });
}).listen(5001, '127.0.0.1', () => console.log(`Callables locales en :5001 (${Object.keys(callables).length})`));

// Triggers: el primer snapshot de cada colección solo llena la caché.
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
for (const collection of [...new Set(triggers.map((t) => t.collection))]) {
  const prev = new Map();
  let first = true;
  db.collection(collection).onSnapshot((snap) => {
    const changes = snap.docChanges();
    for (const ch of changes) {
      const id = ch.doc.id;
      const before = prev.get(id);
      const after = ch.type === 'removed' ? undefined : ch.doc;
      if (after) prev.set(id, after); else prev.delete(id);
      if (first) continue;
      for (const t of triggers.filter((x) => x.collection === collection)) {
        const created = ch.type === 'added';
        if (t.kind === 'created' && !created) continue;
        if (t.kind === 'updated' && ch.type !== 'modified') continue;
        if (t.kind === 'deleted' && ch.type !== 'removed') continue;
        const empty = { exists: false, data: () => undefined, ref: ch.doc.ref, id };
        const data = t.kind === 'created' ? after : { before: before || empty, after: after || empty };
        Promise.resolve(t.fn.run({ data, params: { [t.param]: id } }))
          .catch((e) => console.error(`[trigger ${t.name}]`, e.message || e));
      }
    }
    first = false;
  });
}
console.log(`Triggers locales: ${triggers.map((t) => t.name).join(', ')}`);
