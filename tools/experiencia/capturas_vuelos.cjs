/**
 * Capturas de los estados nuevos de vuelos (Prompt 15, Parte B) a 390, 768 y
 * 1280 px en es, en y pt (el panel, solo en español: siempre sale en
 * español), contra los emuladores (tools/experiencia/levantar.sh; solo
 * demo-luxelane). Datos FICTICIOS de seed.cjs y seed_vuelos.cjs.
 *
 * Además, para cada estado del pasajero y del chófer a 390 px: texto al
 * 200 % (font-size raíz del navegador, como accesibilidad.cjs) y el árbol de
 * semántica que lee el lector de pantalla (botones sin etiqueta y objetivos
 * de menos de 48 px).
 *
 *   node tools/experiencia/capturas_vuelos.cjs [--solo v04] [--idiomas es] [--anchos 390]
 *
 * Guarda docs/capturas/vuelos/<idioma>/<estado>_<ancho>[_x2].png y
 * docs/capturas/vuelos/manifiesto.json.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas/vuelos');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const LANGS = opt('--idiomas', 'es,en,pt').split(',');
const WIDTHS = opt('--anchos', '390,768,1280').split(',').map(Number);
const SOLO = opt('--solo', '');
const BROWSER_LOCALE = { es: 'es-BO', en: 'en-US', pt: 'pt-BR' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const SPLIT = 1100;

// Textos que se tocan, por idioma (los de los .arb).
const T = {
  es: { pickup: 'Recogida', dest: 'A dónde vas', webPickup: '¿Dónde estás?', webDest: '¿A dónde vas?',
    see: 'Ver vehículos y precios', webSee: 'VER PRECIOS', cont: 'Continuar', domestic: 'Nacional',
    international: 'Internacional', number: 'Número de vuelo', date: 'Elegir fecha', time: 'Elegir hora',
    bag: 'Sí, con equipaje facturado' },
  en: { pickup: 'Pickup', dest: 'Where are you going', webPickup: 'Where are you?', webDest: 'Where are you going?',
    see: 'See vehicles and prices', webSee: 'SEE PRICES', cont: 'Continue', domestic: 'Domestic',
    international: 'International', number: 'Flight number', date: 'Choose date', time: 'Choose time',
    bag: 'Yes, checked luggage' },
  pt: { pickup: 'Embarque', dest: 'Para onde você vai', webPickup: 'Onde você está?', webDest: 'Para onde você vai?',
    see: 'Ver veículos e preços', webSee: 'VER PREÇOS', cont: 'Continuar', domestic: 'Nacional',
    international: 'Internacional', number: 'Número do voo', date: 'Escolher data', time: 'Escolher horário',
    bag: 'Sim, com bagagem despachada' },
};

const EMU = { ...process.env, GCLOUD_PROJECT: 'demo-luxelane', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099', FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:9199' };
function seed() {
  for (const f of ['seed.cjs', 'seed_vuelos.cjs']) execFileSync('node', [path.join(__dirname, f)], { env: EMU, stdio: 'ignore' });
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

async function pickPlace(p, label, q, text) {
  const f = p.getByRole('textbox', { name: label }).first();
  await f.click(); await p.keyboard.press('Control+A'); await p.keyboard.type(q, { delay: 5 }); await sleep(2000);
  const box = await p.getByText(text, { exact: false }).last().boundingBox();
  await p.mouse.click(box.x + box.width / 2, box.y + box.height / 2); await sleep(1500);
}

/** Reserva desde el aeropuerto (lugar ficticio) hasta el paso «Tu vuelo». */
async function toFlightStep(p, w, l, type) {
  const t = T[l];
  await p.goto(L.url(L.RIDER, '/')); await L.ready(p, 3000);
  await pickPlace(p, w < 600 ? t.pickup : t.webPickup, 'aeropuerto', 'Aeropuerto Viru Viru (lugar');
  await pickPlace(p, w < 600 ? t.dest : t.webDest, 'plaza 24', 'Plaza 24 de Septiembre (lugar');
  await L.tap(p, w < 600 ? t.see : t.webSee); await sleep(4000);
  if (w < SPLIT) { await L.tap(p, t.cont); await sleep(2500); }
  await anyButton(p, new RegExp(`^${esc(type === 'domestic' ? t.domestic : t.international)}`)); await sleep(800);
  await L.type(p, t.number, 'ZZ 123');
  // Fecha: mañana en el selector (día del mes); hora: la que propone (12:00).
  await anyButton(p, new RegExp(esc(t.date))); await sleep(1200);
  const tomorrow = new Date(Date.now() + 24 * 3_600_000 - 4 * 3_600_000).getUTCDate();
  const days = p.getByRole('button', { name: new RegExp(`^${tomorrow}\\b`) });
  if (await days.count()) await days.first().click();
  await sleep(500); await anyButton(p, /^(OK|Aceptar)$/i); await sleep(800);
  await anyButton(p, new RegExp(esc(t.time))); await sleep(1200);
  await anyButton(p, /^(OK|Aceptar)$/i); await sleep(800);
  await anyButton(p, new RegExp(`^${esc(t.bag)}`)); await sleep(3000);
  // Deja a la vista el punto de recogida (o «Punto por confirmar») y la hora.
  const { width, height } = p.viewportSize();
  await p.mouse.move(width >= SPLIT ? width * 0.84 : width * 0.5, height / 2);
  await p.mouse.wheel(0, 260); await sleep(1500);
}

async function openPanel(p) {
  await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
  const entry = p.getByRole('button', { name: /^Vuelos/ }).first();
  if (await entry.count()) await entry.click();
  else await p.getByText('Vuelos', { exact: true }).first().click();
  await sleep(3000);
}

// [app, estado, usuario, ir(page, lang, width)]
const S = [
  ['r', 'v01-paso-vuelo-nacional', 'pasajera', (p, l, w) => toFlightStep(p, w, l, 'domestic')],
  ['r', 'v02-paso-vuelo-sin-punto', 'pasajera', (p, l, w) => toFlightStep(p, w, l, 'international')],
  ['r', 'v03-viaje-sin-datos', 'pasajera', async (p) => { await p.goto(L.url(L.RIDER, '/ride/v-sindatos')); await L.ready(p, 4000); }],
  ['r', 'v04-viaje-retrasado', 'pasajera', async (p) => { await p.goto(L.url(L.RIDER, '/ride/v-retrasado')); await L.ready(p, 4000); }],
  ['r', 'v05-viaje-cancelado', 'pasajera', async (p) => { await p.goto(L.url(L.RIDER, '/ride/v-cancelado')); await L.ready(p, 4000); }],
  ['d', 'v06-chofer-retrasado', 'chofer', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/v-retrasado')); await L.ready(p, 4000); }],
  ['d', 'v07-chofer-sin-datos', 'chofer', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/v-sindatos')); await L.ready(p, 4000); }],
  ['d', 'v08-chofer-sin-punto', 'chofer', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/v-sinpunto')); await L.ready(p, 4000); }],
  ['d', 'v09-chofer-solicitud', 'chofer2', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/queue')); await L.ready(p, 4000); }],
  ['p', 'v10-panel-bandeja', 'admin', async (p) => { await openPanel(p); }],
  ['p', 'v11-panel-cancelados', 'admin', async (p) => { await openPanel(p); await anyButton(p, /^Cancelados o desviados/); await sleep(2000); }],
  ['p', 'v12-panel-detalle', 'admin', async (p) => { await openPanel(p); await anyButton(p, /Sin datos/); await sleep(1500);
    await L.tap(p, 'ZZ101'); await sleep(3000); }],
  ['p', 'v13-panel-fijar', 'admin', async (p) => { await openPanel(p); await anyButton(p, /Sin datos/); await sleep(1500);
    await L.tap(p, 'ZZ101'); await sleep(3000); await anyButton(p, /^Fijar datos del vuelo/); await sleep(1500); }],
  ['p', 'v14-panel-aeropuertos', 'admin', async (p) => { await openPanel(p); await anyButton(p, /^Aeropuertos/); await sleep(2500); }],
  ['p', 'v15-panel-editor', 'admin', async (p) => { await openPanel(p); await anyButton(p, /^Aeropuertos/); await sleep(2500);
    await L.tap(p, 'VVI'); await sleep(2000); }],
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
      pequenos: interactive.map((e) => ({ e, r: e.getBoundingClientRect() })).filter(({ r }) => r.width < 48 || r.height < 48)
        .map(({ e, r }) => `${label(e).slice(0, 40)} ${Math.round(r.width)}x${Math.round(r.height)}`),
      textos: [...new Set(nodes.filter(vis).filter((e) => !e.querySelector('flt-semantics')).map(label).filter(Boolean))].slice(0, 40),
    };
  });
}

(async () => {
  seed();
  const manifest = { generado: new Date().toISOString(), idiomas: LANGS, anchos: WIDTHS, capturas: [], semantica: [] };
  const b = await L.browser();
  for (const [app, name, user, go] of S.filter((x) => !SOLO || x[1].startsWith(SOLO))) {
    const langs = app === 'p' ? ['es'] : LANGS;
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
          await L.login(page, base, `${user}@prueba.test`, home, labels);
          if (!(await loggedIn())) {
            await page.reload(); await L.ready(page, 2000);
            await L.login(page, base, `${user}@prueba.test`, home, labels);
          }
          if (!(await loggedIn())) throw new Error('sigue en el inicio de sesión');
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
  const mf = path.join(OUT, 'manifiesto.json');
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
})();
