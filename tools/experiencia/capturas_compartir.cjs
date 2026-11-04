/**
 * Prompt 18, C5: página pública del viaje compartido (/t) contra el emulador
 * de Firestore (solo demo-luxelane). Sirve sharedTrip en local con el código
 * compilado de functions, crea enlaces FICTICIOS y mide/captura:
 *
 * - Estados: activo (con posición), sin posición todavía, terminado,
 *   revocado, enlace inválido y sin JavaScript.
 * - 390, 768 y 1280 px en es, en y pt; 390 px con el texto al 200 % (_x2).
 * - Red lenta simulada (latencia 400 ms, 400 kbit/s): peso de la página y
 *   tiempo hasta ver el estado.
 * - Lector de pantalla: árbol de accesibilidad (encabezado, estado con
 *   aria-live, enlaces) y objetivos táctiles.
 *
 *   firebase emulators:exec --only firestore --project demo-luxelane \
 *     "node tools/experiencia/capturas_compartir.cjs"
 *
 * Guarda docs/capturas/viaje-compartido/<idioma>/<estado>_<ancho>[_x2].png y
 * manifiesto.json.
 */
'use strict';
const fs = require('fs');
const http = require('http');
const path = require('path');

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Solo contra el emulador (FIRESTORE_EMULATOR_HOST).');
process.env.GCLOUD_PROJECT = 'demo-luxelane';
const FUNCTIONS = path.join(__dirname, '../../functions');
const admin = require(path.join(FUNCTIONS, 'node_modules/firebase-admin'));
if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const share = require(path.join(FUNCTIONS, 'lib/trip_share.js'));
const { chromium } = require('playwright');

const db = admin.firestore();
const OUT = path.join(__dirname, '../../docs/capturas/viaje-compartido');
const PORT = 5053;
// Secreto y sal FICTICIOS, solo para este guion.
const deps = { db, secret: 'secreto-ficticio-capturas', salt: 'sal-ficticia-capturas', limit: { limit: 100000, windowSeconds: 600 } };
const ts = (ms) => admin.firestore.Timestamp.fromMillis(ms);
const MIN = 60_000;
const LANGS = ['es', 'en', 'pt'];
const WIDTHS = [390, 768, 1280];
const LOCALE = { es: 'es-BO', en: 'en-US', pt: 'pt-BR' };

function serve() {
  return http.createServer((req, res) => {
    let raw = '';
    req.on('data', (c) => { raw += c; });
    req.on('end', async () => {
      let body;
      try { body = raw ? JSON.parse(raw) : undefined; } catch { body = undefined; }
      const out = await share.handleSharedTrip(deps, { method: req.method, ip: '127.0.0.1',
        acceptLanguage: req.headers['accept-language'], body });
      res.writeHead(out.status, out.headers);
      res.end(req.method === 'HEAD' ? '' : out.body);
    });
  }).listen(PORT, '127.0.0.1');
}

/** Reserva FICTICIA de prueba y su enlace. */
async function trip(id, status, extra = {}) {
  const now = Date.now();
  await db.doc(`bookings/${id}`).set({
    riderId: 'ana-prueba', driverId: 'luis-prueba', status, serviceType: 'oneWay', class: 'business',
    scheduledAt: ts(now + 35 * MIN), updatedAt: ts(now), pickupArea: 'Aeropuerto', dropoffArea: 'Santa Cruz de la Sierra',
    driverInfo: { name: 'Luis Prueba', vehicle: { make: 'Marca de prueba', model: 'Modelo de prueba', color: 'Negro',
      plate: 'PRB-123' } },
    ...extra,
  });
  return (await share.createTripShare({ db, secret: deps.secret }, 'ana-prueba', { bookingId: id })).token;
}

async function seed() {
  await db.doc('config/ops').set({ tripShareGraceMinutes: 30 }, { merge: true }); // FICTICIO
  const tokens = {};
  tokens.activo = await trip('c-activo', 'driver_arriving');
  await db.doc('bookings/c-activo/tracking/driver').set({ lat: -17.7001, lng: -63.1502, updatedAt: ts(Date.now() - MIN) });
  tokens['sin-posicion'] = await trip('c-sinpos', 'confirmed');
  tokens.terminado = await trip('c-fin', 'in_progress');
  await db.doc('bookings/c-fin').update({ status: 'completed', completedAt: ts(Date.now()) });
  tokens.revocado = await trip('c-rev', 'confirmed');
  await share.revokeTripShare({ db, secret: deps.secret }, 'ana-prueba', { bookingId: 'c-rev' });
  tokens.invalido = 'AAAAAAAAAAAAAAAAAAAAAA';
  tokens['sin-javascript'] = tokens.activo;
  return tokens;
}

async function measureSlow(b, token, lang) {
  const ctx = await b.newContext({ locale: LOCALE[lang], viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  const cdp = await ctx.newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.emulateNetworkConditions', { offline: false, latency: 400,
    downloadThroughput: (400 * 1024) / 8, uploadThroughput: (400 * 1024) / 8 });
  let bytes = 0;
  cdp.on('Network.loadingFinished', (e) => { bytes += e.encodedDataLength; });
  const t0 = Date.now();
  await page.goto(`http://127.0.0.1:${PORT}/t#${token}`);
  await page.waitForSelector('#status:not(:empty)', { timeout: 30000 });
  const ms = Date.now() - t0;
  await ctx.close();
  return { bytes, msHastaEstado: ms };
}

async function a11y(page) {
  // Lo que lee el lector de pantalla: el árbol ARIA de la página.
  const arbol = (await page.locator('body').ariaSnapshot()).split('\n').slice(0, 40);
  const pequenos = await page.$$eval('a,button', (els) => els.filter((e) => {
    const r = e.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.height < 48;
  }).map((e) => e.textContent.trim().slice(0, 40)));
  return { arbol, pequenos };
}

(async () => {
  const server = serve();
  const tokens = await seed();
  const b = await chromium.launch();
  const manifest = { generado: new Date().toISOString(), capturas: [], redLenta: {}, lector: {} };
  for (const lang of LANGS) {
    manifest.redLenta[lang] = await measureSlow(b, tokens.activo, lang);
    for (const [state, token] of Object.entries(tokens)) {
      const variants = WIDTHS.map((w) => ({ w, scale: 1 })).concat([{ w: 390, scale: 2 }]);
      for (const { w, scale } of variants) {
        const ctx = await b.newContext({ locale: LOCALE[lang], viewport: { width: w, height: w < 700 ? 844 : 900 },
          javaScriptEnabled: state !== 'sin-javascript' });
        const page = await ctx.newPage();
        if (scale === 2) {
          await page.addInitScript(() => document.addEventListener('DOMContentLoaded', () => {
            document.documentElement.style.fontSize = '32px';
          }));
        }
        const file = path.join(OUT, lang, `${state}_${w}${scale === 2 ? '_x2' : ''}.png`);
        fs.mkdirSync(path.dirname(file), { recursive: true });
        let resultado = 'ok'; let motivo = '';
        try {
          await page.goto(`http://127.0.0.1:${PORT}/t#${token}`);
          if (state === 'sin-javascript') await page.waitForSelector('noscript', { state: 'attached' });
          else if (['revocado', 'invalido'].includes(state)) await page.waitForSelector('#gone:not([hidden])');
          else await page.waitForSelector('#status:not(:empty)');
          await page.screenshot({ path: file, fullPage: true });
          if (w === 390 && scale === 1) manifest.lector[`${lang}/${state}`] = await a11y(page);
        } catch (e) {
          resultado = 'fallo'; motivo = String(e.message).split('\n')[0].slice(0, 160);
          await page.screenshot({ path: file }).catch(() => {});
        }
        manifest.capturas.push({ idioma: lang, estado: state, ancho: w, escalaTexto: scale,
          archivo: path.relative(OUT, file), resultado, motivo });
        console.log(`${resultado === 'ok' ? '✓' : '✗'} ${lang}/${state}_${w}${scale === 2 ? '_x2' : ''}${motivo ? ' — ' + motivo : ''}`);
        await ctx.close();
      }
    }
  }
  await b.close();
  server.close();
  fs.writeFileSync(path.join(OUT, 'manifiesto.json'), JSON.stringify(manifest, null, 2));
  const ok = manifest.capturas.filter((c) => c.resultado === 'ok').length;
  console.log(`${ok} de ${manifest.capturas.length} capturas`);
  console.log('red lenta', JSON.stringify(manifest.redLenta));
  process.exit(0);
})();
