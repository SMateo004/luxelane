import { describe, it, expect } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';
import { parsePromoteArgs } from './promote_admin';
import { checkTarget, PRODUCTION_FLAG } from './production_guard';

const SCRIPT = readFileSync(join(__dirname, '../../../scripts/promote_admin.mjs'), 'utf8');
const ok = ['--email', 'Ana@Example.com', '--reason', 'primer admin', '--operator', 'Responsable'];

describe('parsePromoteArgs', () => {
  it('exige correo, motivo y quién lo ejecuta', () => {
    expect(parsePromoteArgs(ok)).toEqual({ email: 'ana@example.com', reason: 'primer admin', operator: 'Responsable' });
    expect(() => parsePromoteArgs(ok.slice(2))).toThrow('--email');
    expect(() => parsePromoteArgs(['--email', 'no-es-correo', ...ok.slice(2)])).toThrow('--email');
    expect(() => parsePromoteArgs([...ok.slice(0, 2), ...ok.slice(4)])).toThrow('--reason');
    expect(() => parsePromoteArgs(ok.slice(0, 4))).toThrow('--operator');
  });
});

describe('scripts/promote_admin.mjs', () => {
  it('no trae proyecto ni correo fijos', () => {
    expect(SCRIPT).not.toMatch(/projectId:\s*'/);
    expect(SCRIPT).not.toContain("'luxelane-4e7ae'");
    expect(SCRIPT).not.toMatch(/const email = '/);
  });

  it('es ESM válido: require solo vía createRequire', () => {
    expect(SCRIPT).toContain("import { createRequire } from 'node:module'");
    expect(SCRIPT).toContain('const require = createRequire(');
  });

  it('pasa por la guarda de producción y escribe solo con --apply', () => {
    expect(SCRIPT).toContain('checkTarget(argv, process.env.FIRESTORE_EMULATOR_HOST)');
    expect(SCRIPT).toContain('promoteAdmin({ db: admin.firestore(), auth: admin.auth() }, args, apply)');
    // La guarda: sin --apply es DRY-RUN; producción solo con la bandera larga.
    expect(checkTarget(['--project', 'staging'], undefined).apply).toBe(false);
    expect(() => checkTarget(['--project', 'luxelane-4e7ae', '--apply'], undefined)).toThrow('Se niega');
    expect(checkTarget(['--project', 'luxelane-4e7ae', PRODUCTION_FLAG], undefined).production).toBe(true);
  });
});
