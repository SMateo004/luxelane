#!/usr/bin/env node
/*
 * C3: borra `updatedBy` (uid del admin) de los documentos públicos de
 * pricingRules y deja una entrada en admin_logs por documento.
 * DRY-RUN por defecto; escribe solo con --apply. Se niega a correr contra
 * luxelane-4e7ae salvo con --i-understand-this-writes-to-production-luxelane-4e7ae.
 *
 *   npm run migrate:pricing-updated-by -- --project staging --operator "Nombre"           # dry-run
 *   npm run migrate:pricing-updated-by -- --project staging --operator "Nombre" --apply   # escribe
 *
 * Con FIRESTORE_EMULATOR_HOST trabaja contra el emulador.
 */
const admin = require('firebase-admin');
const { checkTarget } = require('../lib/migrations/production_guard');
const { parseOperator, removePricingUpdatedBy } = require('../lib/migrations/pricing_updated_by');

async function main() {
  const argv = process.argv.slice(2);
  const { project, apply, production } = checkTarget(argv, process.env.FIRESTORE_EMULATOR_HOST);
  const operator = parseOperator(argv);
  console.log(`Proyecto: ${project}${production ? ' (PRODUCCIÓN)' : ''}`);
  console.log(`Modo: ${apply ? 'APLICAR (escribe)' : 'DRY-RUN (no escribe nada)'}`);
  admin.initializeApp({ projectId: project });
  const plan = await removePricingUpdatedBy(admin.firestore(), apply, operator);
  for (const p of plan) console.log(`  pricingRules/${p.id}: quitar updatedBy`);
  console.log(`Documentos con updatedBy: ${plan.length}.`);
  console.log(apply ? 'Cambios aplicados (con admin_logs).' : 'DRY-RUN: no se escribió nada. Repite con --apply para aplicar.');
}

main().then(() => process.exit(0)).catch((e) => { console.error(`Error: ${e.message}`); process.exit(1); });
