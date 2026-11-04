/**
 * Capturas de la ventana del chófer (Prompt 17, Parte B): historial y
 * ganancias leídos de driverHistory, «Ganancias de hoy» del inicio y el
 * cierre del viaje cuando la reserva sale de la ventana, a 390, 768 y
 * 1280 px en es, en y pt, contra los emuladores (tools/experiencia/
 * levantar.sh; solo demo-luxelane). Datos FICTICIOS de seed.cjs y
 * seed_ventana.cjs; el cierre lo provoca este guion con el Admin SDK sobre
 * el emulador.
 *
 * Además, para cada estado del pasajero y del chófer a 390 px: texto al
 * 200 % (font-size raíz del navegador, como accesibilidad.cjs) y el árbol de
 * semántica que lee el lector de pantalla (botones sin etiqueta y objetivos
 * de menos de 48 px).
 *
 *   node tools/experiencia/capturas_ventana.cjs [--solo w04] [--idiomas es] [--anchos 390]
 *
 * Guarda docs/capturas/ventana-chofer/<idioma>/<estado>_<ancho>[_x2].png y
 * docs/capturas/ventana-chofer/manifiesto.json.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas/ventana-chofer');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const LANGS = opt('--idiomas', 'es,en,pt').split(',');
const WIDTHS = opt('--anchos', '390,768,1280').split(',').map(Number);
const SOLO = opt('--solo', '');
// Varios procesos a la vez (uno por idioma): cada uno con su manifiesto.
const MANIFEST = opt('--manifiesto', 'manifiesto.json');
const BROWSER_LOCALE = { es: 'es-BO', en: 'en-US', pt: 'pt-BR' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const SPLIT = 1100;

const EMU = { ...process.env, GCLOUD_PROJECT: 'demo-luxelane', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099', FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:9199' };
function seed() {
  for (const f of ['seed.cjs', 'seed_ventana.cjs']) execFileSync('node', [path.join(__dirname, f)], { env: EMU, stdio: 'ignore' });
}

/** Desplaza (rueda sobre el contenido) hasta ver el elemento y lo toca. */
async function reach(page, el) {
  const { width, height } = page.viewportSize();
  // Desde 1100 px la reserva tiene el resumen a la derecha con su propio
  // desplazamiento: la rueda va sobre esa columna.
  const x = width >= SPLIT ? width * 0.84 : width * 0.5;
  const inView = async () => {
    if (!(await el.count())) return false;
    const box = await el.boundingBox({ timeout: 500 }).catch(() => null);
    return !!box && box.y >= 0 && box.y + box.height <= height;
  };
  for (let i = 0; i < 60 && !(await inView()); i++) {
    await page.mouse.move(x, height / 2);
    await page.mouse.wheel(0, 350); await page.waitForTimeout(250);
  }
  await el.scrollIntoViewIfNeeded().catch(() => {});
  await el.click();
}
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
// LuxButton repite su texto en la etiqueta accesible («Continuar Continuar»).
const named = (name) => new RegExp(`^${esc(name)}( ${esc(name)})?$`);
const button = (page, name) => reach(page, page.getByRole('button', { name: named(name) }).first());
const anyButton = (page, re) => reach(page, page.getByRole('button', { name: re }).first());

/**
 * Inicio de sesión que espera al botón real: con la semántica aún sin crear,
 * L.tap caía en el título «Iniciar sesión» y no enviaba nada.
 */
async function login(page, base, email, home, labels) {
  await page.goto(L.url(base, home)); await L.ready(page);
  // Texto insertado de una vez: tecla a tecla, Flutter web a veces pierde
  // alguna y el emulador responde INVALID_PASSWORD.
  for (const [label, value] of [[labels.email, email], [labels.password, 'prueba-123']]) {
    const field = page.getByLabel(label, { exact: false }).first();
    await field.click(); await page.keyboard.press('Control+A'); await page.keyboard.press('Delete');
    await page.keyboard.insertText(value); await sleep(300);
  }
  const btn = page.getByRole('button', { name: named(labels.submit) });
  for (let i = 0; i < 20 && !(await btn.count()); i++) await sleep(500);
  await btn.first().click();
  await sleep(4000); await L.ready(page, 500);
}

// Admin SDK contra el emulador: cierra la reserva como lo haría el servidor
// (el disparador writeDriverHistoryOnBooking lo emula callables.cjs).
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const admin = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));
if (!admin.apps.length) admin.initializeApp({ projectId: 'demo-luxelane' });
const fdb = admin.firestore();
const nowTs = () => admin.firestore.Timestamp.now();
let seq = 0;

/** Reserva FICTICIA en curso de chofer, abierta en su pantalla, que luego se cierra. */
async function closeWhileWatching(p, lang, w, status) {
  const id = `w-${status}-${lang}-${w}-${Date.now() % 100000}-${seq++}`;
  const geo = (lat, lng) => new admin.firestore.GeoPoint(lat, lng);
  await fdb.doc(`bookings/${id}`).set({
    riderId: 'pasajera', driverId: 'chofer', status: 'in_progress', serviceType: 'oneWay', class: 'business',
    vehicleClass: 'business', estimatedPrice: 120, finalPrice: null, passengerCount: 1, luggageCount: 0,
    origin: { name: 'Aeropuerto Viru Viru', address: 'Aeropuerto (prueba)', coordinates: geo(-17.6448, -63.1353) },
    destination: { name: 'Plaza principal', address: 'Plaza (prueba)', coordinates: geo(-17.7834, -63.1821) },
    pickupArea: 'Aeropuerto', dropoffArea: 'Santa Cruz de la Sierra', scheduledAt: nowTs(), createdAt: nowTs(),
    updatedAt: nowTs(), startedAt: nowTs(),
    driverInfo: { name: 'Luis Prueba', photoUrl: null, rating: 4.9,
      vehicle: { make: 'Marca de prueba', model: 'Modelo de prueba', plate: 'PRB-CHO', color: 'Negro' } },
  });
  await sleep(2000);
  await p.goto(L.url(L.DRIVER, `/driver/active-ride/${id}`)); await L.ready(p, 4000);
  const at = nowTs();
  await fdb.doc(`bookings/${id}`).update(status === 'completed'
    ? { status: 'completed', completedAt: at, finalPrice: 120, updatedAt: at }
    : { status: 'cancelled', cancelledBy: 'rider', cancelledAt: at, cancellationReason: 'changed_plans', updatedAt: at });
  // La reserva sale de la ventana; la app lee el resumen (reintentos 2 y 4 s).
  await sleep(9000); await L.ready(p, 500);
}

// [app, estado, usuario, ir(page, lang, width)]
const S = [
  ['d', 'w01-ganancias', 'chofer', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/earnings')); await L.ready(p, 4000); }],
  ['d', 'w02-ganancias-vacio', 'chofer2', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/earnings')); await L.ready(p, 4000); }],
  ['d', 'w03-inicio-hoy', 'chofer', async (p) => { await p.goto(L.url(L.DRIVER, '/driver')); await L.ready(p, 5000); }],
  ['d', 'w04-cierre-terminado', 'chofer', (p, l, w) => closeWhileWatching(p, l, w, 'completed')],
  ['d', 'w05-cierre-cancelado', 'chofer', (p, l, w) => closeWhileWatching(p, l, w, 'cancelled')],
];

async function audit(page) {
  return page.evaluate(() => {
    const nodes = [...document.querySelectorAll('flt-semantics')];
    const label = (e) => (e.getAttribute('aria-label') || e.innerText || '').replace(/\s+/g, ' ').trim();
    const vis = (e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight; };
    const interactive = nodes.filter((e) => ['button', 'switch', 'checkbox', 'radio', 'link', 'tab'].includes(e.getAttribute('role'))
      || e.tagName === 'INPUT').filter(vis);
    return {
      interactivos: interactive.length,
      sinEtiqueta: interactive.filter((e) => !label(e) && !e.querySelector('input')).length,
      // Para encontrarlos: rol, tamaño, posición y el texto más cercano.
      sinEtiquetaDetalle: interactive.filter((e) => !label(e) && !e.querySelector('input')).map((e) => {
        const r = e.getBoundingClientRect();
        const near = nodes.filter((n) => n !== e && label(n)).map((n) => ({ n, d: Math.hypot(n.getBoundingClientRect().x - r.x, n.getBoundingClientRect().y - r.y) }))
          .sort((a, b) => a.d - b.d).slice(0, 3).map(({ n }) => label(n).slice(0, 40));
        return `${e.getAttribute('role') || e.tagName} ${Math.round(r.width)}x${Math.round(r.height)} @${Math.round(r.x)},${Math.round(r.y)} cerca de: ${near.join(' | ')}`;
      }),
      // Solo los que están enteros en la ventana: uno cortado por el borde
      // (p. ej. «Cancelar reserva», 48 px) daba 27 px y no es pequeño.
      pequenos: interactive.map((e) => ({ e, r: e.getBoundingClientRect() }))
        .filter(({ r }) => r.top >= 0 && r.bottom <= innerHeight && r.left >= 0 && r.right <= innerWidth)
        .filter(({ r }) => r.width < 48 || r.height < 48)
        .map(({ e, r }) => `${label(e).slice(0, 40)} ${Math.round(r.width)}x${Math.round(r.height)}`),
      textos: [...new Set(nodes.filter(vis).filter((e) => !e.querySelector('flt-semantics')).map(label).filter(Boolean))].slice(0, 40),
    };
  });
}

(async () => {
  // Con varios procesos, se siembra una vez antes (seed.cjs recrea las cuentas).
  if (!args.includes('--sin-siembra')) seed();
  const manifest = { generado: new Date().toISOString(), idiomas: LANGS, anchos: WIDTHS, capturas: [], semantica: [] };
  const b = await L.browser();
  for (const [app, name, user, go] of S.filter((x) => !SOLO || x[1].startsWith(SOLO))) {
    const langs = LANGS;
    for (const lang of langs) {
      const variants = WIDTHS.map((w) => ({ w, scale: 1 }));
      if (app !== 'p' && WIDTHS.includes(390)) variants.push({ w: 390, scale: 2 });
      for (const { w, scale } of variants) {
        const base = app === 'd' ? L.DRIVER : L.RIDER;
        const file = path.join(OUT, lang, `${name}_${w}${scale === 2 ? '_x2' : ''}.png`);
        fs.mkdirSync(path.dirname(file), { recursive: true });
        const ctx = await L.context(b, { width: w, locale: BROWSER_LOCALE[lang] });
        if (scale !== 1) {
          await ctx.addInitScript((px) => {
            document.addEventListener('DOMContentLoaded', () => { document.documentElement.style.fontSize = `${px}px`; });
          }, 16 * scale);
        }
        const page = await ctx.newPage();
        // Motivo del rechazo del emulador de Auth, si lo hay (para el manifiesto).
        let authError = '';
        page.on('response', async (r) => {
          if (r.url().includes('signInWithPassword') && r.status() >= 400) authError = (await r.text().catch(() => '')).replace(/\s+/g, ' ').slice(0, 160);
        });
        let estado = 'ok'; let motivo = '';
        try {
          const labels = L.LOGIN_LABELS[lang] ?? L.LOGIN_LABELS.es;
          // El inicio de sesión a veces no entra a la primera: un reintento, y
          // si sigue en el login la captura es un fallo (no un «ok» engañoso).
          const onLogin = async () => (await page.getByLabel(labels.password, { exact: false }).count()) > 0;
          const home = app === 'd' ? '/driver/queue' : '/trips';
          const loggedIn = async () => {
            for (let i = 0; i < 15; i++) { if (!(await onLogin())) return true; await sleep(1000); }
            return false;
          };
          await login(page, base, `${user}@prueba.test`, home, labels);
          if (!(await loggedIn())) {
            await page.reload(); await L.ready(page, 2000);
            await login(page, base, `${user}@prueba.test`, home, labels);
          }
          if (!(await loggedIn())) throw new Error(`sigue en el inicio de sesión ${authError}`);
          await go(page, lang, w);
          if (await onLogin()) throw new Error('sigue en el inicio de sesión');
          await L.hideEmulatorBanner(page);
          await page.screenshot({ path: file });
          if (w === 390 && scale === 1) manifest.semantica.push({ idioma: lang, estado: name, ...(await audit(page)) });
        } catch (e) {
          estado = 'fallo'; motivo = String(e.message).split('\n')[0].slice(0, 200);
          await page.screenshot({ path: file }).catch(() => {});
        }
        manifest.capturas.push({ idioma: lang, estado: name, ancho: w, escalaTexto: scale,
          archivo: path.relative(OUT, file), resultado: estado, motivo });
        console.log(`${estado === 'ok' ? '✓' : '✗'} ${lang}/${name}_${w}${scale === 2 ? '_x2' : ''}${motivo ? ' — ' + motivo : ''}`);
        await ctx.close();
      }
    }
  }
  await b.close();
  const mf = path.join(OUT, MANIFEST);
  let out = manifest;
  if (SOLO && fs.existsSync(mf)) {
    const old = JSON.parse(fs.readFileSync(mf, 'utf8'));
    const key = (c) => `${c.idioma}/${c.estado}/${c.ancho}/${c.escalaTexto}`;
    const keep = new Set(manifest.capturas.map(key));
    out = { ...old, generado: manifest.generado,
      capturas: [...old.capturas.filter((c) => !keep.has(key(c))), ...manifest.capturas],
      semantica: [...(old.semantica || []).filter((s) => !manifest.semantica.some((n) => n.estado === s.estado && n.idioma === s.idioma)),
        ...manifest.semantica] };
  }
  fs.writeFileSync(mf, JSON.stringify(out, null, 2));
  const ok = out.capturas.filter((c) => c.resultado === 'ok').length;
  console.log(`${ok} de ${out.capturas.length} capturas`);
  // La app del Admin SDK mantiene vivo el proceso: se cierra a mano.
  process.exit(0);
})();
