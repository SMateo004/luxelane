/**
 * A6: accesibilidad de las 10 pantallas principales en Chromium.
 * - Escala de texto 1.3 y 2.0 (Flutter web la toma del font-size raíz del
 *   navegador): captura en docs/capturas/A6-accesibilidad/.
 * - Árbol de semántica: botones e imágenes sin etiqueta, objetivos táctiles
 *   menores de 48 px y los 12 primeros pasos del foco con Tab.
 * Requiere levantar.sh corriendo. Escribe docs/capturas/A6-accesibilidad/resultado.json.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas/A6-accesibilidad');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const SCREENS = [
  ['inicio', 'r', '/', 'pasajera'],
  ['login', 'r', '/trips', null],
  ['registro', 'r', '/register', null],
  ['viajes', 'r', '/trips', 'pasajera'],
  ['viaje-codigo', 'r', '/ride/r-arrived', 'pasajera'],
  ['viaje-sos', 'r', '/ride/r-verified', 'pasajera'],
  ['cancelar', 'r', '/ride/r-arriving', 'pasajera', async (p) => {
    const b = p.getByRole('button', { name: /Cancelar reserva/ }).first(); await b.scrollIntoViewIfNeeded(); await b.click(); await sleep(2500); }],
  ['chofer-inicio', 'd', '/driver', 'chofer'],
  ['chofer-viaje', 'd', '/driver/active-ride/r-arrived', 'chofer'],
  ['panel', 'r', '/admin', 'admin'],
];

async function audit(page) {
  return page.evaluate(() => {
    const nodes = [...document.querySelectorAll('flt-semantics')];
    const label = (e) => (e.getAttribute('aria-label') || e.innerText || '').replace(/\s+/g, ' ').trim();
    const interactive = nodes.filter((e) => ['button', 'switch', 'checkbox', 'radio', 'link', 'tab', 'slider'].includes(e.getAttribute('role'))
      || e.tagName === 'INPUT');
    const vis = (e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight; };
    const small = interactive.filter(vis).map((e) => ({ e, r: e.getBoundingClientRect() }))
      .filter(({ r }) => r.width < 48 || r.height < 48)
      .map(({ e, r }) => ({ rol: e.getAttribute('role'), etiqueta: label(e).slice(0, 60), ancho: Math.round(r.width), alto: Math.round(r.height) }));
    const noLabel = interactive.filter((e) => !label(e) && !e.querySelector('input'))
      .map((e) => ({ rol: e.getAttribute('role'), caja: (() => { const r = e.getBoundingClientRect(); return [Math.round(r.x), Math.round(r.y), Math.round(r.width), Math.round(r.height)]; })() }));
    const imgs = nodes.filter((e) => e.getAttribute('role') === 'img');
    return {
      interactivos: interactive.length,
      sinEtiqueta: noLabel,
      imagenes: imgs.length,
      imagenesSinEtiqueta: imgs.filter((e) => !label(e)).length,
      pequenos: small,
    };
  });
}

async function focusOrder(page, n = 12) {
  const out = [];
  for (let i = 0; i < n; i++) {
    await page.keyboard.press('Tab'); await sleep(120);
    out.push(await page.evaluate(() => {
      const e = document.activeElement;
      if (!e || e === document.body) return '(nada)';
      const r = e.getBoundingClientRect();
      return `${e.getAttribute('role') || e.tagName.toLowerCase()}: ${(e.getAttribute('aria-label') || e.innerText || e.value || '').replace(/\s+/g, ' ').trim().slice(0, 40)} @${Math.round(r.y)}`;
    }));
  }
  return out;
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const b = await L.browser();
  const result = [];
  for (const [name, app, route, user, act] of SCREENS) {
    const row = { pantalla: name };
    for (const scale of [1, 1.3, 2]) {
      const ctx = await L.context(b, { width: 390 });
      // La escala se fija antes de que arranque Flutter (la lee al iniciar)
      // y se inicia sesión en ese mismo contexto: recargar pierde la sesión
      // en el modo emuladores.
      await ctx.addInitScript((px) => {
        document.addEventListener('DOMContentLoaded', () => { document.documentElement.style.fontSize = `${px}px`; });
      }, 16 * scale);
      const p = await ctx.newPage();
      try {
        const base = app === 'd' ? L.DRIVER : L.RIDER;
        if (user) await L.login(p, base, `${user}@prueba.test`, app === 'd' ? '/driver/queue' : '/trips');
        await p.goto(L.url(base, route));
        await L.ready(p, 3500);
        if (act) await act(p);
        await L.hideEmulatorBanner(p);
        await p.screenshot({ path: path.join(OUT, `${name}_x${scale}.png`) });
        if (scale === 1) {
          Object.assign(row, await audit(p));
          row.foco = await focusOrder(p);
        }
      } catch (e) { row[`error_x${scale}`] = String(e.message).split('\n')[0]; }
      await ctx.close();
    }
    result.push(row);
    console.log(name, JSON.stringify({ sinEtiqueta: row.sinEtiqueta?.length, pequenos: row.pequenos?.length, imgSin: row.imagenesSinEtiqueta }));
  }
  await b.close();
  fs.writeFileSync(path.join(OUT, 'resultado.json'), JSON.stringify(result, null, 2));
})();
