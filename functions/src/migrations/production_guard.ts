/**
 * Guarda común de los scripts que escriben con el Admin SDK (backfill de
 * claims, promote_admin): exigen --project, un proyecto demo-* solo con el
 * emulador, y se niegan a tocar producción salvo con una bandera explícita y
 * larga. Por defecto todos van en DRY-RUN.
 */
export const PRODUCTION_PROJECT = 'luxelane-4e7ae';
export const PRODUCTION_FLAG = '--i-understand-this-writes-to-production-luxelane-4e7ae';

export interface Target { project: string; apply: boolean; production: boolean }

export function checkTarget(argv: string[], emulatorHost: string | undefined): Target {
  const i = argv.indexOf('--project');
  const project = i >= 0 ? argv[i + 1] : undefined;
  if (!project || project.startsWith('--')) throw new Error('Falta --project <id>. No hay proyecto por defecto.');
  if (project.startsWith('demo-') && !emulatorHost) {
    throw new Error('Un proyecto demo-* solo existe en el emulador: define FIRESTORE_EMULATOR_HOST.');
  }
  const production = project === PRODUCTION_PROJECT;
  if (production && !argv.includes(PRODUCTION_FLAG)) {
    throw new Error(`Se niega a correr contra ${PRODUCTION_PROJECT} sin ${PRODUCTION_FLAG}.`);
  }
  return { project, apply: argv.includes('--apply'), production };
}
