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
