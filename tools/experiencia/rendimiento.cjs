/**
 * A7: rendimiento de la build web (modo emuladores) en Chromium.
 * - Carga en frío con red limitada («4G lenta» de DevTools: 1,6 Mbps de
 *   bajada, 0,75 Mbps de subida, 562,5 ms de latencia) y sin límite:
 *   primera pintura (FCP del navegador), primer fotograma de Flutter
 *   (evento flutter-first-frame) e «interactivo» (el árbol de semántica ya
 *   tiene el botón principal de la pantalla).
 * - Documentos de Firestore que recibe cada pantalla principal (cuenta los
 *   documentChange/document de las respuestas del emulador) y peticiones
 *   repetidas (mismo método, URL y cuerpo más de una vez).
 * Requiere levantar.sh. Escribe docs/capturas/A7-rendimiento/resultado.json.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas/A7-rendimiento');
const SLOW_4G = { offline: false, downloadThroughput: (1.6 * 1024 * 1024) / 8, uploadThroughput: (750 * 1024) / 8, latency: 562.5 };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function coldLoad(b, route, ready, throttle, width = 390) {
  const ctx = await L.context(b, { width });
  const page = await ctx.newPage();
  const cdp = await ctx.newCDPSession(page);
  await cdp.send('Network.enable');
  await cdp.send('Network.setCacheDisabled', { cacheDisabled: true });
  if (throttle) await cdp.send('Network.emulateNetworkConditions', SLOW_4G);
  let bytes = 0; let requests = 0;
  cdp.on('Network.loadingFinished', (e) => { bytes += e.encodedDataLength; requests++; });
  await page.addInitScript(() => {
    window.__ff = null;
    window.addEventListener('flutter-first-frame', () => { window.__ff = performance.now(); });
  });
  const t0 = Date.now();
  await page.goto(L.url(L.RIDER, route), { timeout: 600_000 });
  // Primer fotograma de Flutter.
  await page.waitForFunction(() => window.__ff !== null, null, { timeout: 600_000, polling: 200 });
  const ff = await page.evaluate(() => window.__ff);
  const fcp = await page.evaluate(() => performance.getEntriesByName('first-contentful-paint')[0]?.startTime ?? null);
  // Interactivo: activar semántica y esperar el botón principal.
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.getByText(ready, { exact: false }).first().waitFor({ timeout: 600_000 });
  const tti = Date.now() - t0;
  await sleep(1500);
  await ctx.close();
  return { ruta: route, ancho: width, limitada: throttle, fcp_ms: fcp && Math.round(fcp), primer_fotograma_ms: Math.round(ff), interactivo_ms: tti,
    transferido_kb: Math.round(bytes / 1024), peticiones: requests };
}

const SCREENS = [
  ['inicio', 'r', '/', 'pasajera'], ['viajes', 'r', '/trips', 'pasajera'], ['viaje', 'r', '/ride/r-arrived', 'pasajera'],
  ['perfil', 'r', '/profile', 'pasajera'], ['chofer-inicio', 'd', '/driver', 'chofer'], ['chofer-solicitudes', 'd', '/driver/queue', 'chofer2'],
  ['chofer-ganancias', 'd', '/driver/earnings', 'chofer'], ['panel', 'r', '/admin', 'admin'],
];

/** Cuenta en la página los documentos que llegan por el canal Listen de
 * Firestore (el SDK usa fetch en streaming: se lee una copia del cuerpo). */
function countFirestore() {
  window.__fs = { docs: 0, targets: [], callables: [] };
  const of = window.fetch;
  window.fetch = async function (input, init) {
    const u = String((input && input.url) || input);
    const body = init && typeof init.body === 'string' ? init.body : '';
    if (/:5001\//.test(u)) window.__fs.callables.push(`${u.split('/').pop()} ${body.slice(0, 120)}`);
    const res = await of.apply(this, arguments);
    if (/:8080\/.*Listen\/channel/.test(u)) {
      try {
        const reader = res.clone().body.getReader(); const dec = new TextDecoder();
        (async () => { for (;;) { const { done, value } = await reader.read(); if (done) break;
          window.__fs.docs += (dec.decode(value).match(/"documentChange"/g) || []).length; } })();
      } catch (e) { /* sin cuerpo */ }
    }
    return res;
  };
}

async function reads(b, [name, app, route, user]) {
  const ctx = await L.context(b, { width: 1280 });
  await ctx.addInitScript(countFirestore);
  const page = await ctx.newPage();
  const base = app === 'd' ? L.DRIVER : L.RIDER;
  // Se entra por una pantalla neutra y se navega dentro de la app (sin
  // recargar: en el modo emuladores una carga nueva pierde la sesión). El
  // admin siempre aterriza en /admin: su cifra incluye el inicio de sesión.
  // El chófer abre todas sus suscripciones al iniciar sesión (DriverBloc):
  // se cuenta desde el inicio de sesión, aterrizando en la pantalla.
  const landing = app === 'd' ? route : (user === 'admin' ? '/admin' : '/profile');
  await L.login(page, base, `${user}@prueba.test`, landing);
  await sleep(3000);
  const start = await page.evaluate(() => ({ docs: window.__fs.docs, t: window.__fs.targets.length, c: window.__fs.callables.length }));
  if (route !== landing) await page.evaluate((r) => { location.hash = `#${r}`; }, route);
  await sleep(8000);
  const end = await page.evaluate(() => window.__fs);
  await ctx.close();
  const dup = (list) => Object.entries(list.reduce((m, k) => ({ ...m, [k]: (m[k] || 0) + 1 }), {}))
    .filter(([, n]) => n > 1).map(([k, n]) => ({ peticion: k.slice(0, 200), veces: n }));
  const callables = end.callables.slice(route !== landing ? start.c : 0);
  return { pantalla: name, desde: route !== landing ? 'navegación en la app' : 'inicio de sesión',
    documentos_firestore: end.docs - (route !== landing ? start.docs : 0),
    callables: callables.map((c) => c.split(' ')[0]), callables_repetidas: dup(callables) };
}

/** Pide una vez cada archivo comprimible para que serve.cjs tenga la
 * versión comprimida en caché (como un CDN): así no se mide el tiempo de
 * comprimir en el servidor local. */
async function warm() {
  const http = require('http');
  for (const [dir, port] of [['web-emu', 5050], ['web-emu-driver', 5051]]) {
    const root = path.join(__dirname, '../../build', dir);
    const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]));
    for (const f of walk(root).filter((x) => /\.(html|js|mjs|json|css|wasm|svg|otf|ttf)$/.test(x))) {
      await new Promise((ok) => http.get({ port, path: '/' + path.relative(root, f), headers: { 'Accept-Encoding': 'br, gzip' } },
        (r) => { r.resume(); r.on('end', ok); }).on('error', ok));
    }
  }
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  await warm();
  const b = await L.browser();
  const carga = [];
  // SOLO_LECTURAS=1: solo las lecturas de Firestore (minutos en vez de la
  // carga en frío con red lenta).
  if (!process.env.SOLO_LECTURAS) {
    for (const throttle of [false, true]) carga.push(await coldLoad(b, '/', 'Ver vehículos y precios', throttle));
    // A 1280 px el inicio es la home web (foto de cabecera y, antes, vídeos).
    for (const throttle of [false, true]) carga.push(await coldLoad(b, '/', /Ver precios/i, throttle, 1280));
    carga.push(await coldLoad(b, '/legal/terminos', 'Quiénes somos', true));
  }
  console.log(JSON.stringify(carga));
  const lecturas = [];
  for (const s of SCREENS) {
    try { lecturas.push(await reads(b, s)); } catch (e) { lecturas.push({ pantalla: s[0], error: String(e.message).split('\n')[0] }); }
    console.log(JSON.stringify(lecturas.at(-1)).slice(0, 400));
  }
  await b.close();
  // Peso: build del modo emuladores (CanvasKit local). En hosting los
  // archivos van comprimidos: se calcula su tamaño con brotli y gzip.
  const zlib = require('zlib');
  const WEB = path.join(__dirname, '../../build/web-emu');
  const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]));
  const all = walk(WEB).map((f) => ({ f: path.relative(WEB, f), b: fs.statSync(f).size }));
  const big = all.sort((a, z) => z.b - a.b).slice(0, 12).map(({ f, b }) => {
    const buf = fs.readFileSync(path.join(WEB, f));
    const text = /\.(js|json|wasm|html|css)$/.test(f);
    return { archivo: f, kb: Math.round(b / 1024),
      brotli_kb: text ? Math.round(zlib.brotliCompressSync(buf).length / 1024) : null,
      gzip_kb: text ? Math.round(zlib.gzipSync(buf, { level: 9 }).length / 1024) : null };
  });
  const peso = { total_mb: +(all.reduce((s, x) => s + x.b, 0) / 1048576).toFixed(1), archivos: all.length, mayores: big };
  fs.writeFileSync(path.join(OUT, process.env.SALIDA || 'resultado.json'), JSON.stringify({ red_4g_lenta: SLOW_4G, carga, lecturas, peso }, null, 2));
  console.log(JSON.stringify(peso));
})();
