import { describe, it, expect } from '@jest/globals';
import { readFileSync } from 'fs';
import { join } from 'path';

const SCRIPT = readFileSync(join(__dirname, '../../../scripts/reset_mfa.mjs'), 'utf8');

describe('scripts/reset_mfa.mjs (C4)', () => {
  it('no trae proyecto ni correo fijos y es ESM con createRequire', () => {
    expect(SCRIPT).not.toMatch(/projectId:\s*'/);
    expect(SCRIPT).not.toContain("'luxelane-4e7ae'");
    expect(SCRIPT).toContain("import { createRequire } from 'node:module'");
  });

  it('pasa por la guarda de producción, exige correo, motivo y operador, y escribe solo con --apply', () => {
    expect(SCRIPT).toContain('checkTarget(argv, process.env.FIRESTORE_EMULATOR_HOST)');
    expect(SCRIPT).toContain('parsePromoteArgs(argv)');
    expect(SCRIPT).toContain('resetMfa({ db: admin.firestore(), auth: admin.auth() }, args, apply)');
  });
});
