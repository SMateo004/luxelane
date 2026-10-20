#!/usr/bin/env node
// Valida un archivo de tarifas: npm run pricing:check -- --file <archivo>
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { validatePricing } from './pricing_lib.mjs';

const i = process.argv.indexOf('--file');
const file = i > 0 ? process.argv[i + 1] : null;
if (!file) {
  console.error('Uso: npm run pricing:check -- --file <archivo.json>');
  process.exit(2);
}
const { errors, warnings, missing } = validatePricing(
  // Rutas relativas al directorio desde el que se lanzó npm (también desde la raíz).
  JSON.parse(readFileSync(resolve(process.env.INIT_CWD ?? process.cwd(), file), 'utf8')),
);
for (const m of missing) console.log(`FALTA   ${m}`);
for (const w of warnings) console.log(`AVISO   ${w}`);
for (const e of errors) console.log(`ERROR   ${e}`);
console.log(`\n${missing.length} faltan, ${errors.length} errores, ${warnings.length} avisos.`);
process.exit(errors.length || missing.length ? 1 : 0);
