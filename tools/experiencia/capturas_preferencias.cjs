/**
 * Capturas de los estados nuevos de preferencias (B5 del prompt de
 * preferencias) a 390, 768 y 1280 px, en español y en inglés, contra los
 * emuladores (tools/experiencia/levantar.sh; solo demo-luxelane). Los datos
 * son los de seed.cjs (preferencias FICTICIAS de la pasajera).
 *
 *   node tools/experiencia/capturas_preferencias.cjs
 *
 * Guarda docs/capturas/preferencias/<idioma>/<estado>_<ancho>.png y su
 * manifiesto.json.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas/preferencias');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const LANGS = opt('--idiomas', 'es,en').split(',');
const WIDTHS = opt('--anchos', '390,768,1280').split(',').map(Number);
const SOLO = opt('--solo', '');
const BROWSER_LOCALE = { es: 'es-BO', en: 'en-US', pt: 'pt-BR' };
const ENTRY = { es: 'Preferencias para tu chófer', en: 'Preferences for your chauffeur', pt: 'Preferências para o seu motorista' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// [app, estado, usuario, ir(page, lang)]
const S = [
  ['r', '01-perfil-resumen', 'pasajera', async (p) => { await p.goto(L.url(L.RIDER, '/profile')); await L.ready(p, 3000); }],
  ['r', '02-preferencias', 'pasajera', async (p, lang) => { await p.goto(L.url(L.RIDER, '/profile')); await L.ready(p, 3000);
    await L.tap(p, ENTRY[lang]); await sleep(2000); }],
  ['r', '03-viaje-pasajero', 'pasajera', async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-arrived')); await L.ready(p, 4000); }],
  ['d', '04-chofer-viaje', 'chofer', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-arrived')); await L.ready(p, 4000); }],
  ['d', '05-chofer-solicitud', 'chofer2', async (p) => { await p.goto(L.url(L.DRIVER, '/driver/queue')); await L.ready(p, 3000); }],
  ['r', '06-panel-detalle', 'admin', async (p) => { await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
    const tab = p.getByRole('button', { name: /^Operaciones/ }).first();
    if (await tab.count()) await tab.click(); else {
      const menu = p.getByRole('button', { name: /menú|menu|abrir/i }).first(); if (await menu.count()) { await menu.click(); await sleep(800); }
      await p.getByText('Operaciones', { exact: true }).first().click();
    }
    await sleep(2000); await L.type(p, 'Buscar por código', 'R-ARRI'); await sleep(1200); await L.tap(p, 'R-ARRI'); await sleep(2000); }],
];

(async () => {
  execFileSync('node', [path.join(__dirname, 'seed.cjs')], {
    env: { ...process.env, GCLOUD_PROJECT: 'demo-luxelane', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
      FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' }, stdio: 'ignore' });
  const manifest = { generado: new Date().toISOString(), idiomas: LANGS, anchos: WIDTHS, capturas: [] };
  const b = await L.browser();
  for (const lang of LANGS) {
    for (const w of WIDTHS) {
      for (const [app, name, user, go] of S.filter((x) => !SOLO || x[1].startsWith(SOLO))) {
        const base = app === 'd' ? L.DRIVER : L.RIDER;
        const file = path.join(OUT, lang, `${name}_${w}.png`);
        fs.mkdirSync(path.dirname(file), { recursive: true });
        const ctx = await L.context(b, { width: w, geo: true, locale: BROWSER_LOCALE[lang] });
        const page = await ctx.newPage();
        let estado = 'ok'; let motivo = '';
        try {
          // El inicio de sesión sale en el idioma del navegador; tras entrar,
          // el panel del admin pasa a español.
          await L.login(page, base, `${user}@prueba.test`, app === 'd' ? '/driver/queue' : '/trips',
            L.LOGIN_LABELS[lang] ?? L.LOGIN_LABELS.es);
          await go(page, lang);
          await L.hideEmulatorBanner(page);
          await page.screenshot({ path: file });
        } catch (e) {
          estado = 'fallo'; motivo = String(e.message).split('\n')[0].slice(0, 200);
          await page.screenshot({ path: file }).catch(() => {});
        }
        manifest.capturas.push({ idioma: lang, estado: name, ancho: w, archivo: path.relative(OUT, file), resultado: estado, motivo });
        console.log(`${estado === 'ok' ? '✓' : '✗'} ${lang}/${name}_${w}${motivo ? ' — ' + motivo : ''}`);
        await ctx.close();
      }
    }
  }
  await b.close();
  const mf = path.join(OUT, 'manifiesto.json');
  if (SOLO && fs.existsSync(mf)) {
    const old = JSON.parse(fs.readFileSync(mf, 'utf8'));
    manifest.capturas = [...old.capturas.filter((c) => !manifest.capturas.some((n) => n.archivo === c.archivo)), ...manifest.capturas];
  }
  fs.writeFileSync(mf, JSON.stringify(manifest, null, 2));
})();
