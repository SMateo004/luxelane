/**
 * El despliegue de functions en CI: cada secreto que declara el código se
 * comprueba antes de desplegar, el job no usa --force (no borra funciones
 * sin preguntar) y las funciones retiradas tienen su borrado documentado.
 */
import { describe, it, expect } from '@jest/globals';
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
