/** Utilidades de Playwright para la app Flutter web contra los emuladores. */
'use strict';
const path = require('path');
const { chromium } = require('playwright');

const RIDER = 'http://localhost:5050';
const DRIVER = 'http://localhost:5051';
const FBJS = path.join(__dirname, 'node_modules/firebase');

/** La app usa la estrategia de URL con «#» (la de Flutter por omisión). */
const url = (base, route) => `${base}/#${route}`;

/** Chromium con el proxy de la sesión, salvo para localhost. */
async function browser() {
  const proxy = process.env.HTTPS_PROXY;
  return chromium.launch({
    args: proxy ? [`--proxy-server=${proxy}`, '--proxy-bypass-list=localhost;127.0.0.1'] : [],
  });
}

/** Contexto con el SDK de Firebase servido desde node_modules (gstatic puede estar bloqueado). */
async function context(b, { width = 390, height, geo = false, offline = false, storageState } = {}) {
  const ctx = await b.newContext({
    viewport: { width, height: height ?? (width < 700 ? 844 : width < 1000 ? 1024 : 800) },
    deviceScaleFactor: 1,
    locale: 'es-BO',
    ...(storageState ? { storageState } : {}),
    timezoneId: 'America/La_Paz',
    ...(geo ? { geolocation: { latitude: -17.7834, longitude: -63.1821 }, permissions: ['geolocation'] } : {}),
  });
  await ctx.route('https://www.gstatic.com/firebasejs/**', (route) => {
    const f = route.request().url().split('/').pop();
    route.fulfill({ path: path.join(FBJS, f), contentType: 'text/javascript' });
  });
  if (offline) await ctx.setOffline(true);
  return ctx;
}

/** Espera a que Flutter pinte y activa el árbol de semántica (para buscar por texto). */
async function ready(page, ms = 2500) {
  await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 60_000 });
  await page.waitForTimeout(ms);
  await page.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    if (p) p.click();
    // El aviso del emulador de Auth tapa la barra inferior: fuera de las capturas.
    document.querySelectorAll('.firebase-emulator-warning').forEach((e) => e.remove());
  });
  await page.waitForTimeout(500);
}

async function hideEmulatorBanner(page) {
  await page.evaluate(() => document.querySelectorAll('.firebase-emulator-warning').forEach((e) => e.remove()));
}

/** Escribe en el campo con esa etiqueta. */
async function type(page, label, value) {
  const field = page.getByLabel(label, { exact: false }).first();
  await field.click();
  await page.keyboard.press('Control+A');
  await page.keyboard.type(value, { delay: 5 });
}

async function tap(page, text, opts = {}) {
  let el = page.getByRole('button', { name: text, exact: opts.exact ?? false }).first();
  if (!(await el.count())) el = page.getByText(text, { exact: opts.exact ?? false }).first();
  // Fuera de la vista (listas de Flutter): desplaza con la rueda hasta verlo.
  for (let i = 0; i < 8 && (await el.count()) && !(await el.isVisible().catch(() => false)); i++) {
    await page.mouse.move(page.viewportSize().width / 2, page.viewportSize().height / 2);
    await page.mouse.wheel(0, 400); await page.waitForTimeout(300);
  }
  await el.scrollIntoViewIfNeeded().catch(() => {});
  return el.click();
}

/** Inicia sesión. Una ruta privada lleva al login (abrir /login directo
 * deja al invitado en el inicio web). */
async function login(page, base, email, privatePath = '/trips') {
  await page.goto(url(base, privatePath));
  await ready(page);
  await type(page, 'Correo', email);
  await type(page, 'Contraseña', 'prueba-123');
  await tap(page, 'Iniciar sesión');
  await page.waitForTimeout(4000);
  await ready(page, 500);
}

module.exports = { url, RIDER, DRIVER, browser, context, ready, type, tap, login, hideEmulatorBanner };
