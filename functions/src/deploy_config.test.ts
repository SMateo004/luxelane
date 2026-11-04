/**
 * El despliegue de functions en CI: cada secreto que declara el código se
 * comprueba antes de desplegar, el job no usa --force (no borra funciones
 * sin preguntar) y las funciones retiradas tienen su borrado documentado.
 */
import { describe, it, expect } from '@jest/globals';
import { execFileSync } from 'child_process';
import { readdirSync, readFileSync } from 'fs';
import { join } from 'path';

const root = join(__dirname, '..', '..');
const ci = readFileSync(join(root, '.github', 'workflows', 'ci.yml'), 'utf8');
const deploy = readFileSync(join(root, 'DEPLOY.md'), 'utf8');
const src = readdirSync(__dirname)
  .filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts'))
  .map((f) => readFileSync(join(__dirname, f), 'utf8'))
  .join('\n');

/** Funciones retiradas del código que aún pueden existir en los proyectos. */
const RETIRED = ['onRideCompleted'];

// C5: legalVersion solo tras publicar las apps y revisar los textos, y la
// lista de pruebas en dispositivos reales antes de imponer el segundo factor.
describe('DEPLOY.md: identidad', () => {
  const section = (title: string) => {
    const i = deploy.indexOf(`### ${title}`);
    expect(i).toBeGreaterThanOrEqual(0);
    const rest = deploy.slice(i + 4);
    const j = rest.search(/\n##+ /);
    return j < 0 ? rest : rest.slice(0, j);
  };

  it('legalVersion: después de publicar las apps y de la revisión del abogado', () => {
    const s = section('Orden de legalVersion');
    const apps = s.indexOf('**Apps publicadas**');
    const lawyer = s.indexOf('**Textos revisados por el abogado**');
    const create = s.indexOf('crear `config/global.legalVersion`');
    expect(apps).toBeGreaterThanOrEqual(0);
    expect(lawyer).toBeGreaterThan(apps);
    expect(create).toBeGreaterThan(lawyer);
  });

  it.each([
    ['Alta de TOTP en el móvil'], ['Alta de TOTP en la web'], ['Segundo paso al iniciar sesión'],
    ['Reautenticación con Google'], ['Reautenticación con TOTP'], ['Bloqueo y desbloqueo'],
    ['Recuperación con reset_mfa'],
  ])('pruebas en dispositivos reales: %s', (item) => {
    expect(section('Pruebas en dispositivos reales antes de activar mfaEnforced')).toContain(`**${item}**`);
  });

  it('mfaEnforced se activa después de las pruebas', () => {
    expect(deploy).toMatch(/las pruebas en dispositivos reales\s+hechas\*\*/);
  });
});

// C6: la auditoría refleja las correcciones tras la revisión de la Parte B.
describe('docs/AUDITORIA_LUXLANE.md', () => {
  const audit = readFileSync(join(root, 'docs', 'AUDITORIA_LUXLANE.md'), 'utf8');
  const row = (id: string) => audit.split('\n').find((l) => l.startsWith(`| ${id} |`)) ?? '';

  it('D6 cerrado en código, con las correcciones C1–C5', () => {
    expect(row('D6')).toContain('CERRADO (en código)');
    for (const c of ['(C1', '(C2', '(C3)', '(C4', '(C5']) expect(row('D6')).toContain(c);
    expect(row('D6')).toContain('reset_mfa');
  });

  it('updatedBy de pricingRules ya no está pendiente de decisión', () => {
    expect(row('D13')).not.toContain('pendiente de decisión: `updatedBy`');
    expect(row('D13')).toContain('migrate:pricing-updated-by');
  });

  it('D22 explica qué callables de admin quedan sin sesión máxima', () => {
    expect(row('D22')).toContain('acknowledgeIncident, closeIncident y resolveAlert');
  });

  it('vuelos: decisión 4 diferida, Prompt 15C y el chófer que lee la reserva, pendientes', () => {
    expect(audit).toMatch(/decisión 4, DIFERIDA/);
    expect(audit).toContain('airports_parity.test.ts');
    expect(audit).toMatch(/PENDIENTE: Prompt 15C \(fuente de la ATT\)/);
    expect(audit).toMatch(/PENDIENTE ANTES DEL PILOTO[^\n]*lee la reserva entera/);
  });

  it('avisos y viaje compartido: qué se guarda, el riesgo de la posición en vivo y las preguntas para el abogado', () => {
    const i = audit.indexOf('## P. Recordatorios y viaje compartido');
    const p = i < 0 ? '' : audit.slice(i, audit.indexOf('\n## ', i + 5));
    expect(p).not.toBe('');
    expect(p).toContain('tripShares/{hash}');
    expect(p).toMatch(/Nunca el token/);
    expect(p).toMatch(/Riesgo de compartir una posición en vivo/);
    expect(p).toMatch(/Consentimiento del chófer/);
    expect(p).toMatch(/Retención de `tripShares`/);
  });

  it('ventana del chófer: qué se guarda, quién lo lee y las preguntas para el abogado', () => {
    const i = audit.indexOf('## O. Ventana del chófer');
    const o = i < 0 ? '' : audit.slice(i, audit.indexOf('\n## ', i + 5));
    expect(o).not.toBe('');
    expect(o).toContain('driverHistory/{uid}/trips/{bookingId}');
    expect(o).toContain('SUMMARY_FIELDS');
    expect(o).toMatch(/PREGUNTAS PARA EL ABOGADO/);
    expect(o).toMatch(/Retención del resumen/);
    expect(o).toMatch(/deleteAccount/);
  });
});

// 0.4: el diagnóstico de x-forwarded-for está apagado por defecto y
// documentado (encender, leer, apagar).
describe('diagnóstico de x-forwarded-for', () => {
  const index = readFileSync(join(__dirname, 'index.ts'), 'utf8');

  it('XFF_DIAGNOSTIC existe y por defecto está apagado', () => {
    expect(index).toContain("defineBoolean('XFF_DIAGNOSTIC', { default: false })");
    expect(index).toContain('xffDiagnostic: XFF_DIAGNOSTIC.value()');
  });

  it('DEPLOY.md explica cómo encenderlo, leerlo y apagarlo', () => {
    const i = deploy.indexOf('### Diagnóstico de x-forwarded-for');
    expect(i).toBeGreaterThanOrEqual(0);
    const s = deploy.slice(i, i + 3000);
    for (const t of ['XFF_DIAGNOSTIC=true', 'xff_diagnostic', 'chosenHash', 'headerElements', '**Apagar**']) {
      expect(s).toContain(t);
    }
  });
});

describe('despliegue de functions', () => {
  const secrets = [...src.matchAll(/defineSecret\('([A-Z_]+)'\)/g)].map((m) => m[1]);

  it('se encuentran los secretos del código', () => {
    expect(secrets).toEqual(expect.arrayContaining(['STRIPE_SECRET_KEY', 'PICKUP_CODE_SECRET', 'RATE_LIMIT_SALT']));
  });

  it.each(secrets.map((s) => [s]))('CI comprueba %s antes de desplegar', (s) => {
    expect(ci).toContain(`functions:secrets:get ${s}`);
  });

  it('el job de functions no usa --force', () => {
    const line = ci.split('\n').find((l) => l.includes('deploy --only functions'));
    expect(line).toBeDefined();
    expect(line).not.toContain('--force');
  });

  it.each(RETIRED.map((f) => [f]))('%s ya no está en el código y su borrado está documentado', (f) => {
    expect(src).not.toMatch(new RegExp(`export const ${f}\\b`));
    expect(deploy).toContain(`firebase functions:delete ${f}`);
  });
});

// Vencimientos de documentos de chófer (A10): runDocExpiry consulta el grupo
// de colecciones documents por expiresAt; sin el índice de grupo, falla en
// producción (el emulador no lo exige).
describe('firestore.indexes.json: registro de chóferes', () => {
  const idx = JSON.parse(readFileSync(join(root, 'firestore.indexes.json'), 'utf8')) as {
    fieldOverrides: { collectionGroup: string; fieldPath: string; indexes: { order?: string; queryScope: string }[] }[];
  };
  it('documents.expiresAt tiene índice de grupo de colecciones ascendente', () => {
    const o = idx.fieldOverrides.find((f) => f.collectionGroup === 'documents' && f.fieldPath === 'expiresAt');
    expect(o?.indexes).toEqual(expect.arrayContaining([{ order: 'ASCENDING', queryScope: 'COLLECTION_GROUP' }]));
    // Al sobrescribir el campo se conserva el índice de colección.
    expect(o?.indexes).toEqual(expect.arrayContaining([{ order: 'ASCENDING', queryScope: 'COLLECTION' }]));
  });
  it('runDocExpiry consulta ese grupo y ese campo', () => {
    expect(src).toContain("collectionGroup('documents').where('expiresAt', '<='");
  });
});

// Registro de chóferes (B5): orden, claves de config/ops y pruebas en
// dispositivo real.
describe('DEPLOY.md: registro de chóferes', () => {
  const i = deploy.indexOf('## Registro de chóferes');
  const section = i < 0 ? '' : deploy.slice(i, deploy.indexOf('\n## ', i + 5));
  it('la sección existe y las reglas van después de publicar las apps', () => {
    expect(section).not.toBe('');
    expect(section).toMatch(/no se despliegan hasta publicar las\s+apps/);
    expect(section.indexOf('**Apps**')).toBeLessThan(section.indexOf('**Reglas al final'));
  });
  it.each(['driverRequirements', 'vehicleMinYear', 'docExpiryReminderDays', 'blockOnExpiredDocs',
    'driverDocsPurgeEnabled', 'signBlob', 'DRIVER_DOCS_BUCKET'])('menciona %s', (k) => {
    expect(section).toContain(k);
  });
  it.each(['Quitar el EXIF', 'Cámara frontal en la foto en vivo', 'URL firmada de 5 minutos'])(
    'pruebas en dispositivo real: %s', (item) => {
      expect(section).toContain(item);
    });
});

describe('DEPLOY.md: vuelos', () => {
  const i = deploy.indexOf('## Vuelos (cierre/vuelos');
  const section = i < 0 ? '' : deploy.slice(i, deploy.indexOf('\n## ', i + 5));
  it('orden: functions, apps, versión mínima y reglas al final', () => {
    expect(section).not.toBe('');
    const at = (s: string) => section.indexOf(s);
    expect(at('1. **Functions**')).toBeGreaterThan(-1);
    expect(at('1. **Functions**')).toBeLessThan(at('**Apps**'));
    expect(at('**Apps**')).toBeLessThan(at('**`minAppVersion`**'));
    expect(at('**`minAppVersion`**')).toBeLessThan(at('**Reglas al final'));
  });
  it.each(['airports/{IATA}', 'flightExitMinutes', 'flightNotifyThresholdMinutes', 'flightCheckpointsMinutes',
    'flightPollMinutes', 'flightStaleMinutes', 'noShowWaitMinutes'])('menciona %s y qué pasa si falta', (k) => {
    const line = section.split('\n- ').find((b) => b.includes(k)) ?? '';
    expect(line).toMatch(/Si\s+falta/);
  });
  it('dice qué ve una app anterior', () => {
    expect(section).toContain('### Qué ve una app anterior');
  });
});

describe('DEPLOY.md: ventana del chófer', () => {
  const i = deploy.indexOf('## Ventana del chófer');
  const section = i < 0 ? '' : deploy.slice(i, deploy.indexOf('\n## ', i + 5));
  it('orden: functions, app del chófer, minDriverAppVersion y reglas al final', () => {
    expect(section).not.toBe('');
    const at = (s: string) => section.indexOf(s);
    expect(at('1. **Functions')).toBeGreaterThan(-1);
    expect(at('1. **Functions')).toBeLessThan(at('2. **App del chófer**'));
    expect(at('2. **App del chófer**')).toBeLessThan(at('3. **`minDriverAppVersion`**'));
    expect(at('3. **`minDriverAppVersion`**')).toBeLessThan(at('4. **Reglas al final'));
  });
  it('dice qué ve una app anterior del chófer y que los viajes ya cerrados no tienen resumen', () => {
    expect(section).toContain('### Qué ve una app anterior del chófer');
    expect(section).toMatch(/no ve ni el viaje en curso/);
    expect(section).toMatch(/no tienen resumen/);
    expect(section).toContain('writeDriverHistoryOnBooking');
    expect(section).toMatch(/no lee `driverHistory`/);
  });
});

describe('repositorio limpio', () => {
  it('ningún node_modules versionado (ni como enlace simbólico)', () => {
    const files = execFileSync('git', ['ls-files'], { cwd: root, encoding: 'utf8' }).split('\n');
    expect(files.filter((f) => /(^|\/)node_modules(\/|$)/.test(f))).toEqual([]);
  });
});

describe('hosting del pasajero: viaje compartido', () => {
  const fb = JSON.parse(readFileSync(join(root, 'firebase.json'), 'utf8'));
  const rider = fb.hosting.find((h: { target?: string }) => h.target === 'rider');
  it('/t y /t/** van a sharedTrip antes del comodín de la app', () => {
    const rw = rider.rewrites as Array<{ source: string; function?: { functionId: string }; destination?: string }>;
    const at = (src: string) => rw.findIndex((r) => r.source === src);
    expect(rw[at('/t')].function?.functionId).toBe('sharedTrip');
    expect(rw[at('/t/**')].function?.functionId).toBe('sharedTrip');
    expect(at('/t')).toBeLessThan(at('**'));
    expect(at('/t/**')).toBeLessThan(at('**'));
  });
  it('/t sin caché, sin indexar y sin referer; la CSP de la app no se relaja', () => {
    const t = rider.headers.find((h: { source: string }) => h.source === '/t{,/**}');
    const hv = Object.fromEntries(t.headers.map((h: { key: string; value: string }) => [h.key, h.value]));
    expect(hv).toEqual({ 'Cache-Control': 'no-store', 'X-Robots-Tag': 'noindex, nofollow', 'Referrer-Policy': 'no-referrer' });
    expect(JSON.stringify(t)).not.toMatch(/Content-Security-Policy/);
  });
});

describe('DEPLOY.md: recordatorios', () => {
  const i = deploy.indexOf('## Recordatorios y viaje compartido');
  const section = i < 0 ? '' : deploy.slice(i, deploy.indexOf('\n## ', i + 5));
  it('los desfases deben ser de 15 minutos o más porque remindersJob corre cada 5', () => {
    expect(section).toMatch(/15 minutos o más/);
    expect(section).toMatch(/remindersJob` corre cada 5 minutos/);
    const index = readFileSync(join(root, 'functions', 'src', 'index.ts'), 'utf8');
    expect(index).toMatch(/remindersJob = onSchedule\('every 5 minutes'/);
  });
  it('orden: functions → hosting → apps → minAppVersion → reglas al final', () => {
    const at = (s: string) => section.indexOf(s);
    expect(at('1. **Functions**')).toBeGreaterThan(-1);
    expect(at('1. **Functions**')).toBeLessThan(at('2. **Hosting del pasajero**'));
    expect(at('2. **Hosting del pasajero**')).toBeLessThan(at('3. **Apps**'));
    expect(at('3. **Apps**')).toBeLessThan(at('4. **`minAppVersion`**'));
    expect(at('4. **`minAppVersion`**')).toBeLessThan(at('5. **Reglas al final**'));
  });
  it.each(['TRIP_SHARE_SECRET', 'PUBLIC_WEB_BASE_URL'])('%s y qué pasa sin él', (k) => {
    const line = section.split("\n- ").find((b) => b.includes("**`" + k + "`**")) ?? "";
    expect(line).toMatch(/Sin (él|ella)/);
  });
  it('dice qué ve una app anterior y que los ajustes de recordatorios van por la consola', () => {
    expect(section).toContain('### Qué ve una app anterior');
    expect(section).toMatch(/solo en `config\/ops` desde la\s+consola/);
  });
  it('pasos manuales de los push: clave APNs y capacidad en el App ID', () => {
    expect(section).toMatch(/Clave APNs/);
    expect(section).toMatch(/Capacidad Push Notifications/);
    expect(section).toContain('Runner.entitlements');
  });
  it.each(['reminderOffsetsMinutes', 'unassignedAlertMinutes', 'tripShareGraceMinutes'])('%s y qué pasa si falta', (k) => {
    const line = section.split('\n- ').find((b) => b.includes(k)) ?? '';
    expect(line).toMatch(/Si falta/);
  });
});
