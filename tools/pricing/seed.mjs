#!/usr/bin/env node
/*
 * Carga un archivo de tarifas en Firestore. DRY-RUN por defecto.
 *   npm run pricing:seed -- --file <archivo> --project <id>            # dry-run
 *   npm run pricing:seed -- --file <archivo> --project <id> --apply    # escribe
 * Se niega con luxelane-4e7ae. Con FIRESTORE_EMULATOR_HOST escribe en el emulador.
 */
import { readFileSync } from 'fs';
import { resolve } from 'path';
import { assertTarget, seedPlan, validatePricing } from './pricing_lib.mjs';

const arg = (name) => {
  const i = process.argv.indexOf(name);
  return i > 0 ? process.argv[i + 1] : null;
};
const file = arg('--file');
const project = arg('--project');
const apply = process.argv.includes('--apply');

try {
  if (!file) throw new Error('Falta --file <archivo.json>.');
  const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
  assertTarget({ project, emulatorHost });
  const doc = JSON.parse(readFileSync(resolve(process.env.INIT_CWD ?? process.cwd(), file), 'utf8'));
  const { errors, missing } = validatePricing(doc);
  if (errors.length || missing.length) {
    throw new Error(`El archivo no pasa pricing:check (${missing.length} faltan, ${errors.length} errores). Corrígelo antes de cargarlo.`);
  }
  console.log(`Proyecto: ${project}${emulatorHost ? ` (emulador ${emulatorHost})` : ''}`);
  console.log(`Modo: ${apply ? 'APLICAR (escribe)' : 'DRY-RUN (no escribe nada)'}`);
  const plan = seedPlan(doc);
  for (const w of plan) console.log(`  ${w.merge ? 'actualizar' : 'escribir'} ${w.path} (${Object.keys(w.data).join(', ')})`);
  if (!apply) {
    console.log('DRY-RUN: no se escribió nada. Repite con --apply para escribir.');
    process.exit(0);
  }
  const { default: admin } = await import('firebase-admin');
  admin.initializeApp({ projectId: project });
  const db = admin.firestore();
  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();
  for (const w of plan) {
    const data = w.path.startsWith('pricingRules/') ? { ...w.data, updatedAt: now, updatedBy: 'pricing-seed' } : w.data;
    batch.set(db.doc(w.path), data, { merge: Boolean(w.merge) });
  }
  await batch.commit();
  console.log(`Escritos ${plan.length} documentos.`);
} catch (e) {
  console.error(`Error: ${e.message}`);
  process.exit(1);
}
