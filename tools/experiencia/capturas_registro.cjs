/**
 * Capturas de los estados nuevos del registro de chóferes (Parte B) a 390,
 * 768 y 1280 px en es, en y pt (el panel, solo en español: siempre sale en
 * español), contra los emuladores (tools/experiencia/levantar.sh; solo
 * demo-luxelane). Datos FICTICIOS de seed.cjs y seed_registro.cjs.
 *
 * Además, para cada estado del chófer a 390 px: texto al 200 % (font-size
 * raíz del navegador, como accesibilidad.cjs) y el árbol de semántica que
 * lee el lector de pantalla (botones sin etiqueta y objetivos < 48 px).
 *
 *   node tools/experiencia/capturas_registro.cjs [--solo r05] [--idiomas es] [--anchos 390]
 *
 * Guarda docs/capturas/registro/<idioma>/<estado>_<ancho>[_x2].png y
 * docs/capturas/registro/manifiesto.json.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas/registro');
const FIXTURE = path.join(__dirname, 'fixtures/documento_ficticio.jpg');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const LANGS = opt('--idiomas', 'es,en,pt').split(',');
const WIDTHS = opt('--anchos', '390,768,1280').split(',').map(Number);
const SOLO = opt('--solo', '');
const BROWSER_LOCALE = { es: 'es-BO', en: 'en-US', pt: 'pt-BR' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Textos que se tocan, por idioma (los de los .arb).
const T = {
  es: { start: 'Convertir en cuenta de chófer', upload: 'Subir', reupload: 'Volver a subir', back: 'Atrás',
    cont: 'Continuar', take: 'Tomar foto', use: 'Usar esta foto' },
  en: { start: 'Convert to a chauffeur account', upload: 'Upload', reupload: 'Upload again', back: 'Back',
    cont: 'Continue', take: 'Take photo', use: 'Use this photo' },
  pt: { start: 'Converter em conta de motorista', upload: 'Enviar', reupload: 'Enviar novamente', back: 'Voltar',
    cont: 'Continuar', take: 'Tirar foto', use: 'Usar esta foto' },
};

const EMU = { ...process.env, GCLOUD_PROJECT: 'demo-luxelane', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099', FIREBASE_STORAGE_EMULATOR_HOST: '127.0.0.1:9199' };
function seed() {
  for (const f of ['seed.cjs', 'seed_registro.cjs']) {
    execFileSync('node', [path.join(__dirname, f)], { env: EMU, stdio: 'ignore' });
  }
}
/** Escribe un documento de config en el emulador (y lo deshace al terminar). */
function config(doc, data) {
  execFileSync('node', ['-e', `
    const admin = require(${JSON.stringify(path.join(__dirname, '../../functions/node_modules/firebase-admin'))});
    admin.initializeApp({ projectId: 'demo-luxelane' });
    const d = JSON.parse(process.argv[1]);
    const ref = admin.firestore().doc(${JSON.stringify(doc)});
    (d === null ? ref.delete() : ref.set(d, { merge: true })).then(() => process.exit(0));`, JSON.stringify(data)],
  { env: EMU, stdio: 'ignore' });
}

/** Desplaza (rueda sobre el contenido) hasta ver el elemento y lo toca. */
async function reach(page, el) {
  const { width, height } = page.viewportSize();
  // «Visible» para Playwright incluye lo que está fuera de la ventana (el
  // lienzo de Flutter no se desplaza con scrollIntoView): se mira la caja.
  const inView = async () => {
    // Flutter web solo crea la semántica de lo que está cerca de la vista:
    // sin nodo todavía, se sigue desplazando (sin esperar).
    if (!(await el.count())) return false;
    const box = await el.boundingBox({ timeout: 500 }).catch(() => null);
    return !!box && box.y >= 0 && box.y + box.height <= height;
  };
  for (let i = 0; i < 80 && !(await inView()); i++) {
    await page.mouse.move(width * 0.7, height / 2);
    await page.mouse.wheel(0, 350); await page.waitForTimeout(250);
  }
  await el.scrollIntoViewIfNeeded().catch(() => {});
  await el.click();
}

// LuxButton repite su texto en la etiqueta accesible («Continuar Continuar»).
const named = (name) => new RegExp(`^${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}( ${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})?$`);

async function buttonByIndex(page, name, i) {
  await reach(page, page.getByRole('button', { name: named(name) }).nth(i));
}

async function button(page, name) {
  await reach(page, page.getByRole('button', { name: named(name) }).first());
}

/** Toma la foto con el selector de archivos del navegador (image_picker web). */
async function takePhoto(page, label) {
  const [chooser] = await Promise.all([page.waitForEvent('filechooser', { timeout: 15000 }), button(page, label)]);
  await chooser.setFiles(FIXTURE);
  await sleep(2500);
}

// [app, estado, usuario, ir(page, lang), {antes, despues}]
const S = [
  ['d', 'r01-previa', 'aspirante', async () => {}],
  ['d', 'r02-previa-confirmar', 'aspirante', async (p, l) => { await button(p, T[l].start); await sleep(1200); }],
  ['d', 'r03-datos', 'regdatos', async () => {}],
  ['d', 'r04-vehiculo', 'regdocs', async (p, l) => { await button(p, T[l].back); await sleep(1500); }],
  ['d', 'r05-documentos', 'regdocs', async () => {}],
  ['d', 'r06-foto-en-vivo', 'regdocs', async (p, l) => { await buttonByIndex(p, T[l].upload, 0); await sleep(1500); }],
  ['d', 'r07-revision-foto', 'regdocs', async (p, l) => {
    await buttonByIndex(p, T[l].reupload, 2); await sleep(1500); await takePhoto(p, T[l].take); }],
  ['d', 'r08-falta-vencimiento', 'regdocs', async (p, l) => {
    await buttonByIndex(p, T[l].reupload, 2); await sleep(1500); await takePhoto(p, T[l].take);
    await button(p, T[l].use); await sleep(1500); }],
  ['d', 'r09-resumen', 'regdocs', async (p, l) => { await button(p, T[l].cont); await sleep(1500); }],
  ['d', 'r10-segundo-factor', 'regdocs', async (p, l) => { await button(p, T[l].cont); await sleep(1500); },
    { before: () => config('config/security', { mfaEnforced: true }), after: () => config('config/security', { mfaEnforced: false }) }],
  ['d', 'r11-en-revision', 'regrevision', async () => {}],
  ['d', 'r12-no-aprobada', 'regrechazada', async () => {}],
  ['d', 'r13-sin-requisitos', 'regdatos', async () => {},
    { before: () => config('config/ops', { driverRequirements: null }), after: seed }],
  ['r', 'p01-bandeja', 'admin', async (p) => { await openPanel(p); }],
  ['r', 'p02-detalle', 'admin', async (p) => { await openPanel(p); await L.tap(p, 'Rita Prueba'); await sleep(2500); }],
  ['r', 'p03-visor', 'admin', async (p) => { await openPanel(p); await L.tap(p, 'Rita Prueba'); await sleep(2500);
    await reach(p, p.getByRole('button', { name: /^Ver documento: Foto de perfil/ }).first()); await sleep(4000); }],
  ['r', 'p04-rechazo', 'admin', async (p) => { await openPanel(p); await L.tap(p, 'Rita Prueba'); await sleep(2500);
    await reach(p, p.getByRole('button', { name: /^Rechazar documento: Foto de perfil/ }).first()); await sleep(1500); }],
  ['r', 'p05-decision', 'admin', async (p) => { await openPanel(p); await L.tap(p, 'Rita Prueba'); await sleep(2500);
    await button(p, 'Decisión final'); await sleep(1500); }],
  ['r', 'p06-bitacora', 'admin', async (p) => { await openPanel(p); await L.tap(p, 'Rita Prueba'); await sleep(2500);
    await button(p, 'Bitácora de accesos'); await sleep(2000); }],
  ['r', 'p07-vencimientos', 'admin', async (p) => { await openPanel(p); await L.tap(p, 'Vencimientos próximos'); await sleep(3000); }],
  ['r', 'p08-sin-requisitos', 'admin', async (p) => { await openPanel(p); await L.tap(p, 'Rita Prueba'); await sleep(2500); },
    { before: () => config('config/ops', { driverRequirements: null }), after: seed }],
];

async function openPanel(p) {
  await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
  const entry = p.getByRole('button', { name: /Solicitudes de chófer/ }).first();
  if (await entry.count()) await entry.click();
  else await p.getByText('Solicitudes de chófer', { exact: false }).first().click();
  await sleep(2500);
}

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
      // Lo que lee el lector de pantalla: nodos hoja, sin repetir.
      textos: [...new Set(nodes.filter(vis).filter((e) => !e.querySelector('flt-semantics')).map(label).filter(Boolean))].slice(0, 40),
    };
  });
}

(async () => {
  seed();
  const manifest = { generado: new Date().toISOString(), idiomas: LANGS, anchos: WIDTHS, capturas: [], semantica: [] };
  const b = await L.browser();
  for (const [app, name, user, go, hooks] of S.filter((x) => !SOLO || x[1].startsWith(SOLO))) {
    // El panel sale siempre en español: una sola pasada.
    const langs = app === 'r' ? ['es'] : LANGS;
    if (hooks?.before) hooks.before();
    for (const lang of langs) {
      const variants = WIDTHS.map((w) => ({ w, scale: 1 }));
      if (app === 'd' && WIDTHS.includes(390)) variants.push({ w: 390, scale: 2 });
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
          await L.login(page, base, `${user}@prueba.test`, app === 'd' ? '/driver' : '/trips',
            L.LOGIN_LABELS[lang] ?? L.LOGIN_LABELS.es);
          await L.ready(page, 3000);
          await go(page, lang);
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
    if (hooks?.after) hooks.after();
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
