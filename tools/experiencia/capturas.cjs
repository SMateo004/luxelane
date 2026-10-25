/**
 * Capturas de la app contra los emuladores (Parte A2 de experiencia).
 * Requiere tools/experiencia/levantar.sh corriendo.
 *
 *   node tools/experiencia/capturas.cjs                 # todo, 390/768/1280
 *   node tools/experiencia/capturas.cjs --solo F5 --anchos 390
 *
 * Guarda docs/capturas/<flujo>/<estado>_<ancho>.png y
 * docs/capturas/manifiesto.json (qué se capturó y qué falló, con el motivo).
 * Antes de cada ancho vuelve a sembrar: hay escenarios que cambian datos
 * (cancelar, reconocer un SOS) y van al final.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const L = require('./lib.cjs');

const OUT = path.join(__dirname, '../../docs/capturas');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : d; };
const SOLO = opt('--solo', '');
const WIDTHS = opt('--anchos', '390,768,1280').split(',').map(Number);

function seed() {
  execFileSync('node', [path.join(__dirname, 'seed.cjs')], {
    env: { ...process.env, GCLOUD_PROJECT: 'demo-luxelane', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
      FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' },
    stdio: 'ignore',
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const has = async (page, text) => (await page.getByText(text, { exact: false }).count()) > 0;
async function waitText(page, text, ms = 15000) {
  await page.getByText(text, { exact: false }).first().waitFor({ timeout: ms });
}
async function hold(page, text, ms) {
  const el = page.getByRole('button', { name: text }).first();
  const box = await el.boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down(); await sleep(ms); await page.mouse.up();
}

/** Callables con error del servidor (500 internal) o sin red. */
async function failCallables(page, kind) {
  await page.route(/:5001\//, (route) => (kind === 'red'
    ? route.abort('internetdisconnected')
    : route.fulfill({ status: 500, contentType: 'application/json',
      body: JSON.stringify({ error: { status: 'INTERNAL', message: 'internal' } }) })));
}
/** Emuladores «apagados»: Auth, Firestore y Functions no responden. */
async function backendDown(page) {
  await page.route(/:(5001|8080|9099)\//, (route) => route.abort('connectionrefused'));
}

// ── Escenarios ────────────────────────────────────────────────────────────
// { flow, state, app: 'r'|'d', user, geo, go(page) , mutates }
const S = [];
const add = (flow, state, o) => S.push({ flow, state, app: 'r', ...o });

// F1 acceso, registro y seguridad
add('F1-acceso', 'carga', { first: true, go: async (p, w) => { await p.goto(L.url(L.RIDER, '/')); await p.waitForSelector('flt-glass-pane, flutter-view', { timeout: 60000 }).catch(() => {}); await sleep(150); } });
add('F1-acceso', 'login', { go: async (p) => { await p.goto(L.url(L.RIDER, '/trips')); await L.ready(p); await waitText(p, 'Iniciar sesión'); } });
add('F1-acceso', 'login-error', { go: async (p) => { await p.goto(L.url(L.RIDER, '/trips')); await L.ready(p);
  await L.type(p, 'Correo', 'pasajera@prueba.test'); await L.type(p, 'Contraseña', 'incorrecta-1'); await L.tap(p, 'Iniciar sesión'); await sleep(2500); } });
add('F1-acceso', 'login-validacion', { go: async (p) => { await p.goto(L.url(L.RIDER, '/trips')); await L.ready(p); await L.tap(p, 'Iniciar sesión'); await sleep(800); } });
add('F1-acceso', 'bloqueado', { go: async (p) => { await p.goto(L.url(L.RIDER, '/trips')); await L.ready(p);
  await L.type(p, 'Correo', 'bloqueado@prueba.test'); await L.type(p, 'Contraseña', 'prueba-123'); await L.tap(p, 'Iniciar sesión'); await sleep(2500); } });
add('F1-acceso', 'registro', { go: async (p) => { await p.goto(L.url(L.RIDER, '/register')); await L.ready(p); } });
add('F1-acceso', 'registro-validacion', { go: async (p) => { await p.goto(L.url(L.RIDER, '/register')); await L.ready(p); await L.tap(p, 'Crear cuenta'); await sleep(800); } });
add('F1-acceso', 'terminos', { go: async (p) => { await p.goto(L.url(L.RIDER, '/legal/terminos')); await L.ready(p); } });
add('F1-acceso', 'privacidad', { go: async (p) => { await p.goto(L.url(L.RIDER, '/legal/privacidad')); await L.ready(p); } });
add('F1-acceso', 'verificar-correo', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/verify-email')); await L.ready(p); } });
add('F1-acceso', 'perfil', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/profile')); await L.ready(p); } });
// El pasajero no tiene segundo factor: el alta de TOTP está en el perfil del chófer.
add('F1-acceso', 'chofer-alta-dos-pasos', { app: 'd', user: 'chofer2', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/profile')); await L.ready(p, 3000);
  await L.tap(p, 'Verificación en dos pasos'); await sleep(2500); } });
add('F1-acceso', 'admin-reto-segundo-factor', { go: async (p) => { await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p);
  await L.type(p, 'Correo', 'admin2fa@prueba.test'); await L.type(p, 'Contraseña', 'prueba-123'); await L.tap(p, 'Iniciar sesión'); await sleep(3000); } });
add('F1-acceso', 'emulador-apagado', { go: async (p) => { await backendDown(p); await p.goto(L.url(L.RIDER, '/trips')); await L.ready(p);
  await L.type(p, 'Correo', 'pasajera@prueba.test'); await L.type(p, 'Contraseña', 'prueba-123'); await L.tap(p, 'Iniciar sesión'); await sleep(4000); } });

// F2/F3/F4 reserva
add('F2-reserva', 'inicio-invitado', { go: async (p) => { await p.goto(L.url(L.RIDER, '/')); await L.ready(p); } });
add('F2-reserva', 'inicio', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/')); await L.ready(p); } });
add('F2-reserva', 'sin-permiso-ubicacion', { user: 'pasajera', geo: false, go: async (p) => { await p.goto(L.url(L.RIDER, '/')); await L.ready(p);
  await L.tap(p, 'Usar mi ubicación'); await sleep(2500); } });
add('F2-reserva', 'con-ubicacion', { user: 'pasajera', geo: true, go: async (p) => { await p.goto(L.url(L.RIDER, '/')); await L.ready(p);
  await L.tap(p, 'Usar mi ubicación'); await sleep(3000); } });
add('F2-reserva', 'sin-direcciones', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/')); await L.ready(p);
  await L.tap(p, 'Ver vehículos y precios'); await sleep(1500); } });
add('F2-reserva', 'fecha-hora', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/')); await L.ready(p);
  await L.tap(p, 'Cambiar fecha y hora'); await sleep(1500); } });
add('F2-reserva', 'vehiculos', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride-type')); await L.ready(p, 4000); } });
add('F2-reserva', 'confirmar', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/booking')); await L.ready(p, 4000); } });
add('F3-por-horas', 'inicio', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/')); await L.ready(p); await L.tap(p, 'Por horas'); await sleep(1200); } });
add('F10-empresas', 'formulario', { go: async (p) => { await p.goto(L.url(L.RIDER, '/empresas')); await L.ready(p); } });
add('F10-empresas', 'validacion', { go: async (p) => { await p.goto(L.url(L.RIDER, '/empresas')); await L.ready(p);
  const b = p.getByRole('button', { name: /enviar|solicitar/i }).last(); if (await b.count()) { await b.scrollIntoViewIfNeeded(); await b.click(); } await sleep(1200); } });

// F5 día del servicio: una reserva por estado
const RIDES = [['pendiente', 'r-pending'], ['liberada', 'r-released'], ['confirmada', 'r-confirmed'], ['en-camino', 'r-arriving'],
  ['llego-codigo', 'r-arrived'], ['verificada', 'r-verified'], ['en-curso', 'r-progress'], ['completada', 'r-completed'],
  ['no-se-presento', 'r-noshow'], ['cancelada', 'r-cancelled'], ['cancelada-con-recargo', 'r-cancelled-fee']];
for (const [state, id] of RIDES) {
  add('F5-viaje', state, { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, `/ride/${id}`)); await L.ready(p, 4000); } });
}
add('F5-viaje', 'codigo-error-servidor', { user: 'pasajera', go: async (p) => { await failCallables(p, 'servidor'); await p.goto(L.url(L.RIDER, '/ride/r-arrived')); await L.ready(p, 4000); } });
add('F5-viaje', 'codigo-sin-red', { user: 'pasajera', go: async (p) => { await failCallables(p, 'red'); await p.goto(L.url(L.RIDER, '/ride/r-arrived')); await L.ready(p, 4000); } });
add('F5-viaje', 'reserva-inexistente', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/no-existe')); await L.ready(p, 4000); } });

// F6 cancelación
add('F6-cancelacion', 'sin-recargo', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-pending')); await L.ready(p, 3000);
  await L.tap(p, 'Cancelar reserva'); await waitText(p, 'Motivo'); await sleep(600); } });
add('F6-cancelacion', 'con-recargo', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-arriving')); await L.ready(p, 3000);
  await L.tap(p, 'Cancelar reserva'); await waitText(p, 'Motivo'); await sleep(600); } });
add('F6-cancelacion', 'error-servidor', { user: 'pasajera', go: async (p) => { await failCallables(p, 'servidor'); await p.goto(L.url(L.RIDER, '/ride/r-pending')); await L.ready(p, 3000);
  await L.tap(p, 'Cancelar reserva'); await sleep(2000); } });
add('F6-cancelacion', 'sin-red', { user: 'pasajera', go: async (p) => { await failCallables(p, 'red'); await p.goto(L.url(L.RIDER, '/ride/r-pending')); await L.ready(p, 3000);
  await L.tap(p, 'Cancelar reserva'); await sleep(2000); } });

// F7/F8 viajes, pago y valoración
add('F7-viajes', 'lista', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/trips')); await L.ready(p, 3000); } });
add('F7-viajes', 'vacio', { user: 'vacia', go: async (p) => { await p.goto(L.url(L.RIDER, '/trips')); await L.ready(p, 3000); } });
add('F7-viajes', 'pagos', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/payment')); await L.ready(p, 3000); } });
add('F8-valoracion', 'calificar', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-completed')); await L.ready(p, 4000); } });

// F9 SOS (pasajero)
add('F9-sos', 'boton', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-verified')); await L.ready(p, 3000); } });
add('F9-sos', 'pulsando', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-verified')); await L.ready(p, 3000);
  const el = p.getByRole('button', { name: /SOS/ }).first(); const b = await el.boundingBox();
  await p.mouse.move(b.x + b.width / 2, b.y + b.height / 2); await p.mouse.down(); await sleep(1000);
  await p.screenshot({ path: '/dev/null' }).catch(() => {}); p.__keepDown = true; } });
add('F9-sos', 'abierto', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-progress')); await L.ready(p, 4000); } });
add('F9-sos', 'ayuda', { user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-progress')); await L.ready(p, 4000);
  await L.tap(p, 'Ayuda en curso'); await sleep(1500); } });

// F13/F14 chófer
add('F13-alta-chofer', 'login', { app: 'd', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/queue')); await L.ready(p); } });
add('F13-alta-chofer', 'no-verificado', { app: 'd', user: 'nuevo', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver')); await L.ready(p, 3000); } });
add('F13-alta-chofer', 'bloqueado', { app: 'd', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/queue')); await L.ready(p);
  await L.type(p, 'Correo', 'bloqueado@prueba.test'); await L.type(p, 'Contraseña', 'prueba-123'); await L.tap(p, 'Iniciar sesión'); await sleep(3000); } });
add('F14-chofer', 'inicio', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver')); await L.ready(p, 3000); } });
add('F14-chofer', 'inicio-libre', { app: 'd', user: 'chofer2', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver')); await L.ready(p, 3000); } });
add('F14-chofer', 'conectarse-sin-ubicacion', { app: 'd', user: 'chofer2', geo: false, go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver')); await L.ready(p, 3000);
  await L.tap(p, 'Conectarse'); await sleep(3000); } });
add('F14-chofer', 'solicitudes', { app: 'd', user: 'chofer2', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/queue')); await L.ready(p, 3000); } });
add('F14-chofer', 'ganancias', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/earnings')); await L.ready(p, 3000); } });
add('F14-chofer', 'perfil', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/profile')); await L.ready(p, 3000); } });
add('F14-chofer', 'viaje-confirmado', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-confirmed')); await L.ready(p, 3000); } });
add('F14-chofer', 'liberar-motivo', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-arriving')); await L.ready(p, 3000);
  await L.tap(p, 'No puedo hacer este viaje'); await waitText(p, 'Liberar este viaje'); await sleep(500); } });
add('F14-chofer', 'en-recogida', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-arrived')); await L.ready(p, 3000); } });
add('F14-chofer', 'codigo-pasajero', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-arrived')); await L.ready(p, 3000);
  await L.tap(p, 'Ingresar código del pasajero'); await sleep(1500); } });
add('F14-chofer', 'no-aparece-confirmar', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-arrived')); await L.ready(p, 3000);
  await L.tap(p, 'El pasajero no aparece'); await waitText(p, 'Avisar a central'); await sleep(500); } });
add('F14-chofer', 'verificado', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-verified')); await L.ready(p, 3000); } });
add('F14-chofer', 'en-curso', { app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-progress')); await L.ready(p, 3000); } });

// F15/F17 panel
const TABS = [['panel', 'Panel'], ['operaciones', 'Operaciones'], ['choferes', 'Chóferes'], ['vehiculos', 'Vehículos'], ['finanzas', 'Finanzas'],
  ['tarifas', 'Tarifas'], ['empresas', 'Empresas'], ['usuarios', 'Usuarios'], ['alertas', 'Alertas'], ['auditoria', 'Auditoría'], ['configuracion', 'Configuración']];
for (const [state, tab] of TABS) {
  add('F17-panel', state, { user: 'admin', go: async (p) => { await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
    if (tab !== 'Panel') { await openTab(p, tab); } await sleep(2000); } });
}
async function openTab(p, tab) {
  const b = p.getByRole('button', { name: new RegExp(`^${tab}`) }).first();
  if (await b.count()) return b.click();
  // Móvil: menú lateral.
  const menu = p.getByRole('button', { name: /menú|menu|abrir/i }).first();
  if (await menu.count()) { await menu.click(); await sleep(800); }
  await p.getByText(tab, { exact: true }).first().click();
}
add('F17-panel', 'detalle-no-se-presento', { user: 'admin', go: async (p) => { await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
  await openTab(p, 'Operaciones'); await sleep(2000); await p.getByText(/R-NOSH/i).first().click(); await sleep(1500); } });
add('F17-panel', 'decidir-no-se-presento', { user: 'admin', go: async (p) => { await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
  await openTab(p, 'Operaciones'); await sleep(2000); await p.getByText(/R-NOSH/i).first().click(); await sleep(1500);
  await L.tap(p, 'Decidir'); await sleep(1200); } });
add('F17-panel', 'bloquear-con-viajes', { user: 'admin', go: async (p) => { await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
  await openTab(p, 'Usuarios'); await sleep(2000); await L.type(p, 'Buscar por nombre', 'Luis'); await sleep(1500);
  await p.getByRole('switch', { name: 'Bloquear' }).first().click(); await sleep(2000); } });

// A8: errores. Con la sesión ya iniciada se «apaga» el backend (Auth,
// Firestore y Functions no responden) y se recarga, o fallan las callables.
const MAIN = [['r', 'inicio', '/', 'pasajera'], ['r', 'viajes', '/trips', 'pasajera'], ['r', 'viaje', '/ride/r-arrived', 'pasajera'],
  ['r', 'perfil', '/profile', 'pasajera'], ['d', 'chofer-inicio', '/driver', 'chofer'], ['d', 'chofer-solicitudes', '/driver/queue', 'chofer2'],
  ['d', 'chofer-viaje', '/driver/active-ride/r-arrived', 'chofer'], ['r', 'panel', '/admin', 'admin']];
for (const [app, name, route, user] of MAIN) {
  const base = app === 'd' ? L.DRIVER : L.RIDER;
  add('A8-errores', `${name}-backend-caido`, { app, user, go: async (p) => { await backendDown(p); await p.goto(L.url(base, route)); await p.reload(); await L.ready(p, 6000); } });
  add('A8-errores', `${name}-sin-red`, { app, user, go: async (p) => { await p.goto(L.url(base, route)); await L.ready(p, 3000);
    await p.context().setOffline(true); await sleep(6000); } });
}
add('A8-errores', 'chofer-deslizar-sin-red', { app: 'd', user: 'chofer', go: async (p) => { await failCallables(p, 'red');
  await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-confirmed')); await L.ready(p, 3000);
  const el = p.getByRole('button', { name: /Salir hacia la recogida/ }).first(); const b = await el.boundingBox();
  await p.mouse.move(b.x + 20, b.y + b.height / 2); await p.mouse.down(); await p.mouse.move(b.x + b.width - 5, b.y + b.height / 2, { steps: 15 });
  await p.mouse.up(); await sleep(3500); } });
add('A8-errores', 'pasajero-cancelar-error-servidor', { user: 'pasajera', go: async (p) => { await failCallables(p, 'servidor');
  await p.goto(L.url(L.RIDER, '/ride/r-confirmed')); await L.ready(p, 3000); await L.tap(p, 'Cancelar reserva'); await sleep(2500); } });

// Al final: los que cambian datos.
add('F9-sos', 'reconocido-panel', { mutates: true, user: 'admin', go: async (p) => { await p.goto(L.url(L.RIDER, '/admin')); await L.ready(p, 3000);
  await L.tap(p, 'Reconocer'); await sleep(2500); } });
add('F9-sos', 'reconocido-pasajero', { mutates: true, user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-progress')); await L.ready(p, 4000); } });
add('F6-cancelacion', 'cancelada-por-pasajero', { mutates: true, user: 'pasajera', go: async (p) => { await p.goto(L.url(L.RIDER, '/ride/r-arriving')); await L.ready(p, 3000);
  await L.tap(p, 'Cancelar reserva'); await waitText(p, 'Motivo'); await sleep(400);
  await p.getByRole('button', { name: /Cancelar con recargo|Cancelar reserva/ }).last().click(); await sleep(3000); } });
add('F14-chofer', 'liberado', { mutates: true, app: 'd', user: 'chofer', go: async (p) => { await p.goto(L.url(L.DRIVER, '/driver/active-ride/r-confirmed')); await L.ready(p, 3000);
  await L.tap(p, 'No puedo hacer este viaje'); await waitText(p, 'Liberar este viaje');
  await p.getByRole('radio', { name: /Problema con el vehículo/ }).first().click(); await sleep(400);
  await p.getByRole('button', { name: 'Liberar viaje' }).click(); await sleep(3000); } });

// ── Ejecución ─────────────────────────────────────────────────────────────
(async () => {
  const manifest = { generado: new Date().toISOString(), anchos: WIDTHS, temaOscuro: 'la app no tiene tema oscuro', capturas: [] };
  const b = await L.browser();
  for (const w of WIDTHS) {
    seed();
    const want = SOLO ? SOLO.split(',') : [];
    const todo = S.filter((s) => !want.length || want.some((f) => s.flow === f || s.flow.startsWith(`${f}-`) || `${s.flow}/${s.state}` === f));
    for (const s of [...todo.filter((x) => !x.mutates), ...todo.filter((x) => x.mutates)]) {
      const file = path.join(OUT, s.flow, `${s.state}_${w}.png`);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      const ctx = await L.context(b, { width: w, geo: s.geo ?? true });
      const page = await ctx.newPage();
      const errors = [];
      page.on('pageerror', (e) => errors.push(String(e.message).slice(0, 200)));
      const t0 = Date.now();
      let estado = 'ok'; let motivo = '';
      try {
        // Inicio de sesión en cada escenario: en el modo emuladores la sesión
        // no sobrevive a una carga nueva de la página (ver el informe).
        if (s.user) await L.login(page, s.app === 'd' ? L.DRIVER : L.RIDER, `${s.user}@prueba.test`, s.app === 'd' ? '/driver/queue' : '/trips');
        await s.go(page, w);
        await L.hideEmulatorBanner(page);
        await page.screenshot({ path: file });
      } catch (e) {
        estado = 'fallo'; motivo = String(e.message).split('\n')[0].slice(0, 200);
        await page.screenshot({ path: file }).catch(() => {});
      }
      manifest.capturas.push({ flujo: s.flow, estado: s.state, ancho: w, archivo: path.relative(OUT, file), resultado: estado, motivo, erroresJs: errors, ms: Date.now() - t0 });
      console.log(`${estado === 'ok' ? '✓' : '✗'} ${s.flow}/${s.state}_${w}${motivo ? ' — ' + motivo : ''}`);
      await ctx.close();
    }
  }
  await b.close();
  const mf = path.join(OUT, 'manifiesto.json');
  if (SOLO && fs.existsSync(mf)) {
    const old = JSON.parse(fs.readFileSync(mf, 'utf8'));
    const keep = old.capturas.filter((c) => !manifest.capturas.some((n) => n.archivo === c.archivo));
    manifest.capturas = [...keep, ...manifest.capturas];
  }
  fs.writeFileSync(mf, JSON.stringify(manifest, null, 2));
})();
