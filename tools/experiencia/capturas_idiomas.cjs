/**
 * Capturas por idioma (prompt de idiomas, B5): las pantallas principales de
 * las apps del pasajero y del chófer en español, inglés y portugués, a 390,
 * 768 y 1280 px. El idioma lo pone el navegador (la app usa el del sistema).
 * Requiere tools/experiencia/levantar.sh corriendo (solo demo-luxelane).
 *
 *   node tools/experiencia/capturas_idiomas.cjs
 *   node tools/experiencia/capturas_idiomas.cjs --idiomas en --anchos 390
 *
 * Guarda docs/capturas/idiomas/<idioma>/<pantalla>_<ancho>.png y
 * docs/capturas/idiomas/manifiesto.json. Solo navega por URL (sin tocar
 * textos), para que el mismo guion valga en los tres idiomas.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas/idiomas');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const LANGS = opt('--idiomas', 'es,en,pt').split(',');
const WIDTHS = opt('--anchos', '390,768,1280').split(',').map(Number);
const BROWSER_LOCALE = { es: 'es-BO', en: 'en-US', pt: 'pt-BR' };

// [app, pantalla, ruta, usuario]
const SCREENS = [
  ['r', '01-inicio-invitado', '/', null],
  ['r', '02-iniciar-sesion', '/trips', null],
  ['r', '03-registro', '/register', null],
  ['r', '04-inicio', '/', 'pasajera'],
  ['r', '05-reserva', '/booking', 'pasajera'],
  ['r', '06-viaje-codigo', '/ride/r-arrived', 'pasajera'],
  ['r', '07-viaje-sos', '/ride/r-verified', 'pasajera'],
  ['r', '08-mis-viajes', '/trips', 'pasajera'],
  ['r', '09-pagos', '/payment', 'pasajera'],
  ['r', '10-perfil', '/profile', 'pasajera'],
  ['r', '11-terminos', '/legal/terminos', null],
  ['d', '12-chofer-inicio', '/driver', 'chofer'],
  ['d', '13-chofer-solicitudes', '/driver/queue', 'chofer2'],
  ['d', '14-chofer-recogida', '/driver/active-ride/r-arrived', 'chofer'],
];

function seed() {
  execFileSync('node', [path.join(__dirname, 'seed.cjs')], {
    env: { ...process.env, GCLOUD_PROJECT: 'demo-luxelane', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
      FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' },
    stdio: 'ignore',
  });
}

(async () => {
  const manifest = { generado: new Date().toISOString(), idiomas: LANGS, anchos: WIDTHS, capturas: [] };
  const b = await L.browser();
  seed();
  for (const lang of LANGS) {
    for (const w of WIDTHS) {
      for (const [app, name, route, user] of SCREENS) {
        const base = app === 'd' ? L.DRIVER : L.RIDER;
        const file = path.join(OUT, lang, `${name}_${w}.png`);
        fs.mkdirSync(path.dirname(file), { recursive: true });
        const ctx = await L.context(b, { width: w, geo: true, locale: BROWSER_LOCALE[lang] });
        const page = await ctx.newPage();
        const errors = [];
        page.on('pageerror', (e) => errors.push(String(e.message).slice(0, 200)));
        let estado = 'ok'; let motivo = '';
        try {
          if (user) {
            await L.login(page, base, `${user}@prueba.test`, app === 'd' ? '/driver/queue' : '/trips',
              L.LOGIN_LABELS[lang] ?? L.LOGIN_LABELS.es);
          }
          await page.goto(L.url(base, route));
          await L.ready(page, 3500);
          await L.hideEmulatorBanner(page);
          await page.screenshot({ path: file });
        } catch (e) {
          estado = 'fallo'; motivo = String(e.message).split('\n')[0].slice(0, 200);
          await page.screenshot({ path: file }).catch(() => {});
        }
        manifest.capturas.push({ idioma: lang, pantalla: name, ancho: w, archivo: path.relative(OUT, file), resultado: estado, motivo, erroresJs: errors });
        console.log(`${estado === 'ok' ? '✓' : '✗'} ${lang}/${name}_${w}${motivo ? ' — ' + motivo : ''}`);
        await ctx.close();
      }
    }
  }
  await b.close();
  fs.writeFileSync(path.join(OUT, 'manifiesto.json'), JSON.stringify(manifest, null, 2));
})();
