// Un test por celda de la matriz de acceso (matrix.ts). Cada celda ejecuta
// la operación con la identidad del rol y compara con lo esperado.
import { readFileSync, writeFileSync } from 'fs';
import { resolve } from 'path';
import { RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, Firestore, setDoc, updateDoc } from 'firebase/firestore';
import { seed, startEnv } from './setup';
import { allowed, operation, OPS, Role, ROLES, renderMatrix, seedMatrix, SPECS } from './matrix';

let env: RulesTestEnvironment;
// Tras una escritura que pasó (o una preparación), se vuelve a sembrar.
let dirty = true;

beforeAll(async () => { env = await startEnv(); });
beforeEach(async () => {
  if (!dirty) return;
  await seed(env);
  await env.withSecurityRulesDisabled((ctx) => seedMatrix(ctx.firestore() as unknown as Firestore));
  dirty = false;
});
afterAll(async () => { await env?.cleanup(); });

const dbOf = (r: Role) => (r === 'anon'
  ? env.unauthenticatedContext().firestore()
  : env.authenticatedContext(r).firestore()) as unknown as Firestore;

/** true si la operación pasó; false si las reglas la denegaron. */
async function attempt(fn: () => Promise<unknown>): Promise<boolean> {
  try {
    await fn();
    return true;
  } catch (e) {
    if ((e as { code?: string }).code === 'permission-denied') return false;
    throw e;
  }
}

describe.each(SPECS.map((s) => [s.name, s] as const))('%s', (_name, spec) => {
  describe.each(ROLES.map((r) => [r] as const))('%s', (role) => {
    test.each(OPS.map((o) => [o] as const))('%s', async (op) => {
      const write = op === 'crear' || op === 'actualizar' || op === 'borrar';
      if (op === 'crear' && spec.prepareCreate) {
        const path = spec.prepareCreate(role);
        if (path) {
          dirty = true;
          await env.withSecurityRulesDisabled((ctx) => deleteDoc(doc(ctx.firestore(), path)));
        }
      }
      const ok = await attempt(operation(spec, op, dbOf(role), role));
      if (ok && write) dirty = true;
      expect(ok ? 'permitido' : 'denegado').toBe(allowed(spec, role, op) ? 'permitido' : 'denegado');
    });
  });
});

describe('casos fuera de la tabla', () => {
  test('alta propia: un usuario nuevo crea su perfil como pasajero activo', async () => {
    dirty = true;
    expect(await attempt(() => setDoc(doc(dbOf('nuevaCuenta' as Role), 'users', 'nuevaCuenta'),
      { id: 'nuevaCuenta', role: 'rider', isActive: true }))).toBe(true);
    expect(await attempt(() => setDoc(doc(dbOf('otraCuenta' as Role), 'users', 'otraCuenta'),
      { id: 'otraCuenta', role: 'driver', isActive: true }))).toBe(false);
  });

  test('H2: el dueño no se marca isVerified a sí mismo', async () => {
    dirty = true;
    expect(await attempt(() => updateDoc(doc(dbOf('ana'), 'users', 'ana'), { isVerified: true }))).toBe(false);
    expect(await attempt(() => updateDoc(doc(dbOf('bloq'), 'users', 'bloq'), { isVerified: true }))).toBe(false);
    expect(await attempt(() => updateDoc(doc(dbOf('admin'), 'users', 'ana'), { isVerified: true }))).toBe(true);
  });
});

describe('docs/MATRIZ_ACCESO.md', () => {
  const file = resolve(__dirname, '../../../docs/MATRIZ_ACCESO.md');
  const START = '<!-- matriz:inicio -->';
  const END = '<!-- matriz:fin -->';

  test('la tabla del documento es la de matrix.ts', () => {
    const text = readFileSync(file, 'utf8');
    const expected = `${START}\n${renderMatrix()}\n${END}`;
    if (process.env.UPDATE_MATRIX === '1') {
      writeFileSync(file, text.replace(new RegExp(`${START}[\\s\\S]*${END}`), expected));
      return;
    }
    expect(text).toContain(expected);
  });
});
